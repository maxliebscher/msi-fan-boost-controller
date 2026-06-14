param(
    [int]$BoostSeconds = 60,
    [int]$CycleSeconds = 900,
    [int]$ParentProcessId = 0
)

$ErrorActionPreference = "Continue"

$boostMode = 2
$normalMode = 0
$statePath = Join-Path $PSScriptRoot "msi-fanboost-cycle.state"
$logPath = Join-Path $PSScriptRoot "msi-fanboost-cycle.log"

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = New-Object System.Text.UTF8Encoding($false)

$boostSeconds = [Math]::Max(1, $BoostSeconds)
$cycleSeconds = [Math]::Max([Math]::Max(1, $BoostSeconds + 1), $CycleSeconds)
$pauseSeconds = $cycleSeconds - $boostSeconds

$script:LastFanSpeed = "<not measured yet>"
$script:NextFanSample = [DateTime]::MinValue
$script:Paused = $false
$script:StopRequested = $false
$script:FanApiWarmed = $false
$script:ScenarioType = $null

function Write-Status($message) {
    $line = (Get-Date).ToString("HH:mm:ss") + " " + $message
    Write-Host $line
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
}

function Update-State([string]$status, [bool]$running = $false) {
    try {
        $payload = [ordered]@{
            Status = $status
            StartedAt = (Get-Date).ToString("s")
            BoostSeconds = $boostSeconds
            CycleSeconds = $cycleSeconds
            PauseSeconds = $pauseSeconds
            ProcessId = $PID
            ParentProcessId = $ParentProcessId
            Running = $running
            LastFanSpeed = $script:LastFanSpeed
        }
        $payload | ConvertTo-Json -Compress | Set-Content -LiteralPath $statePath -Encoding UTF8
    }
    catch {}
}

function Test-ParentAlive {
    if ($ParentProcessId -le 0) {
        return $true
    }

    try {
        $parent = Get-Process -Id $ParentProcessId -ErrorAction SilentlyContinue
        return ($null -ne $parent)
    }
    catch {
        return $false
    }
}

function Invoke-QuietMsiApi([scriptblock]$Action) {
    $oldOut = [Console]::Out
    $oldErr = [Console]::Error
    $sinkOut = New-Object System.IO.StringWriter
    $sinkErr = New-Object System.IO.StringWriter

    try {
        [Console]::SetOut($sinkOut)
        [Console]::SetError($sinkErr)
        return & $Action
    }
    finally {
        [Console]::SetOut($oldOut)
        [Console]::SetError($oldErr)
        $noise = ($sinkOut.ToString() + $sinkErr.ToString()).Trim()
        if ($noise) {
            Add-Content -LiteralPath $logPath -Value ((Get-Date).ToString("HH:mm:ss") + " MSI API console output suppressed.") -Encoding UTF8
        }
        $sinkOut.Dispose()
        $sinkErr.Dispose()
    }
}

function Load-MsiApi {
    $base = "C:\Program Files (x86)\MSI\MSI Center"
    $moduleDll = Join-Path $base "Base Module\API_NB_Base Module.dll"

    if (-not (Test-Path -LiteralPath $base)) {
        throw "MSI Center was not found at: $base"
    }
    if (-not (Test-Path -LiteralPath $moduleDll)) {
        throw "MSI Center Base Module API was not found at: $moduleDll"
    }

    [Environment]::CurrentDirectory = $base

    Get-ChildItem $base -File -Filter "*.dll" | ForEach-Object {
        try { [Reflection.Assembly]::LoadFrom($_.FullName) | Out-Null } catch {}
    }

    $asm = [Reflection.Assembly]::LoadFrom($moduleDll)
    $pluginType = $asm.GetType("API_Base_Module.PluginClass")
    if ($null -eq $pluginType) {
        throw "MSI API type API_Base_Module.PluginClass was not found."
    }

    try {
        $plugin = [Activator]::CreateInstance($pluginType)
        [void](Invoke-QuietMsiApi { $pluginType.GetMethod("MainEntry").Invoke($plugin, @()) })
    }
    catch {
        Write-Status ("MainEntry notice: " + $_.Exception.Message)
        if ($_.Exception.InnerException) {
            Write-Status ("MainEntry detail: " + $_.Exception.InnerException.Message)
        }
    }

    $scenarioType = $asm.GetType("API_Base_Module.UserScenario")
    if ($null -eq $scenarioType) {
        throw "MSI API type API_Base_Module.UserScenario was not found."
    }
    return $scenarioType
}

function Set-FanMode($mode) {
    try {
        [void](Invoke-QuietMsiApi { $script:ScenarioType.GetMethod("setFan").Invoke($null, @([int]$mode, [bool]$true)) })
        Write-Status ("Fan mode {0} set." -f $mode)
        return $true
    }
    catch {
        Write-Status ("Fan mode error {0}: {1}" -f $mode, $_.Exception.Message)
        if ($_.Exception.InnerException) {
            Write-Status ("Fan mode detail {0}: {1}" -f $mode, $_.Exception.InnerException.Message)
        }
        return $false
    }
}

function Get-FanSpeedText {
    try {
        $value = Invoke-QuietMsiApi { $script:ScenarioType.GetMethod("GetFanSpeed").Invoke($null, @()) }
        if ($null -eq $value) {
            return "<empty>"
        }
        return [string]$value
    }
    catch {
        if ($_.Exception.InnerException) {
            return "ERR " + $_.Exception.InnerException.Message
        }
        return "ERR " + $_.Exception.Message
    }
}

function Refresh-FanSpeed {
    $script:LastFanSpeed = Get-FanSpeedText
    Update-State -status "running" -running $true
}

function Warmup-FanApi {
    if ($script:FanApiWarmed) {
        return
    }

    Write-Status "MSI fan API warmup: mode 4,5,6,0,1 with short waits."
    foreach ($mode in @(4, 5, 6, 0, 1)) {
        if (-not (Test-ParentAlive)) {
            $script:StopRequested = $true
            return
        }
        [void](Set-FanMode $mode)
        Start-Sleep -Seconds 8
        Write-Status ("Warmup RPM after mode {0}: {1}" -f $mode, (Get-FanSpeedText))
    }
    $script:FanApiWarmed = $true
}

function Read-CommandNonBlocking {
    try {
        if (-not [Console]::KeyAvailable) {
            return $null
        }
    }
    catch {
        return $null
    }

    return [Console]::ReadLine()
}

function Wait-WithCommands($seconds, [string]$label) {
    $script:NextFanSample = (Get-Date).AddSeconds(1)
    $deadline = (Get-Date).AddSeconds($seconds)

    while ((Get-Date) -lt $deadline) {
        if (-not (Test-ParentAlive)) {
            Write-Status "Parent UI process is gone; stopping worker."
            $script:StopRequested = $true
            return "quit"
        }

        if ((Get-Date) -ge $script:NextFanSample) {
            Refresh-FanSpeed
            $script:NextFanSample = (Get-Date).AddSeconds(5)
        }

        $cmd = Read-CommandNonBlocking
        if ($cmd) {
            switch ($cmd.Trim().ToLowerInvariant()) {
                "pause" {
                    $script:Paused = $true
                    [void](Set-FanMode $normalMode)
                    Write-Status ("PAUSE: fan mode {0} set." -f $normalMode)
                    return "pause"
                }
                "start" {
                    $script:Paused = $false
                    Write-Status "START: cycle active."
                }
                "status" {
                    $state = $label
                    if ($script:Paused) {
                        $state = "paused"
                    }
                    Write-Status ("STATUS: {0} | Fan speed: {1}" -f $state, $script:LastFanSpeed)
                }
                "quit" {
                    $script:StopRequested = $true
                    return "quit"
                }
                "exit" {
                    $script:StopRequested = $true
                    return "quit"
                }
                default {
                    Write-Status "Commands: pause, start, status, quit"
                }
            }
        }
        Start-Sleep -Milliseconds 250
    }
    return $null
}

Set-Content -LiteralPath $logPath -Value ("MSI FanBoost Cycle Start " + (Get-Date).ToString("s")) -Encoding UTF8
Update-State -status "starting" -running $true

try {
    $script:ScenarioType = Load-MsiApi

    Write-Host ""
    Write-Host "MSI FanBoost Cycle"
    Write-Host "Commands in this window: pause, start, status, quit"
    Write-Host ("Cycle: {0} seconds boost, then {1} seconds pause; repeats every {2} seconds." -f $boostSeconds, $pauseSeconds, $cycleSeconds)
    Write-Host ("Closing the UI ends the run. On exit, fan mode {0} is set." -f $normalMode)
    Write-Host ""

    Update-State -status "running" -running $true
    Warmup-FanApi

    while (-not $script:StopRequested) {
        if ($script:Paused) {
            $result = Wait-WithCommands 1 "paused"
            if ($result -eq "quit") { break }
            continue
        }

        Refresh-FanSpeed
        Write-Status ("BOOST ON: fan mode {0} for {1} seconds. Fan speed: {2}" -f $boostMode, $boostSeconds, $script:LastFanSpeed)
        [void](Set-FanMode $boostMode)
        $result = Wait-WithCommands $boostSeconds "boost running"
        if ($result -eq "quit") { break }
        if ($result -eq "pause") { continue }

        Refresh-FanSpeed
        Write-Status ("BOOST OFF: fan mode {0}. Fan speed: {1}" -f $normalMode, $script:LastFanSpeed)
        [void](Set-FanMode $normalMode)

        Write-Status ("Waiting {0} seconds until the next boost." -f $pauseSeconds)
        $result = Wait-WithCommands $pauseSeconds "waiting"
        if ($result -eq "quit") { break }
    }
}
catch {
    Write-Status ("FATAL: " + $_.Exception.Message)
}
finally {
    Write-Status ("Exiting: fan mode {0} will be set." -f $normalMode)
    try {
        if ($null -ne $script:ScenarioType) {
            [void](Set-FanMode $normalMode)
        }
    }
    catch {}
    Update-State -status "stopped" -running $false
    try { Remove-Item -LiteralPath $statePath -ErrorAction SilentlyContinue } catch {}
}
