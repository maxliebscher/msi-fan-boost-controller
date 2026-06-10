param(
    [int]$BoostSeconds = 60,
    [int]$CycleSeconds = 900
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
$script:LastFanSpeed = "<noch nicht gemessen>"
$script:NextFanSample = [DateTime]::MinValue

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
            Running = $running
            LastFanSpeed = $script:LastFanSpeed
        }
        $payload | ConvertTo-Json -Compress | Set-Content -LiteralPath $statePath -Encoding UTF8
    }
    catch {}
}

function Load-MsiApi {
    $base = "C:\Program Files (x86)\MSI\MSI Center"
    [Environment]::CurrentDirectory = $base

    Get-ChildItem $base -File -Filter "*.dll" | ForEach-Object {
        try { [Reflection.Assembly]::LoadFrom($_.FullName) | Out-Null } catch {}
    }

    $asm = [Reflection.Assembly]::LoadFrom((Join-Path $base "Base Module\API_NB_Base Module.dll"))
    $pluginType = $asm.GetType("API_Base_Module.PluginClass")
    try {
        $plugin = [Activator]::CreateInstance($pluginType)
        [void]$pluginType.GetMethod("MainEntry").Invoke($plugin, @())
    }
    catch {
        Write-Status ("MainEntry Hinweis: " + $_.Exception.Message)
        if ($_.Exception.InnerException) {
            Write-Status ("MainEntry Detail: " + $_.Exception.InnerException.Message)
        }
    }
    return $asm.GetType("API_Base_Module.UserScenario")
}

function Set-FanMode($mode) {
    try {
        [void]$script:ScenarioType.GetMethod("setFan").Invoke($null, @([int]$mode, [bool]$true))
        Write-Status "Fanmode $mode gesetzt."
        return $true
    }
    catch {
        Write-Status ("Fanmode-Fehler " + $mode + ": " + $_.Exception.Message)
        if ($_.Exception.InnerException) {
            Write-Status ("Fanmode-Detail " + $mode + ": " + $_.Exception.InnerException.Message)
        }
        return $false
    }
}

function Get-FanSpeedText {
    try {
        $value = $script:ScenarioType.GetMethod("GetFanSpeed").Invoke($null, @())
        if ($null -eq $value) {
            return "<leer>"
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

    Write-Status "MSI Fan-API Warmup: mode 4,5,6,0,1 mit kurzen Wartezeiten."
    foreach ($mode in @(4, 5, 6, 0, 1)) {
        [void](Set-FanMode $mode)
        Start-Sleep -Seconds 8
        Write-Status ("Warmup RPM nach mode " + $mode + ": " + (Get-FanSpeedText))
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
                    Write-Status "PAUSE: Fanmode $normalMode gesetzt."
                    return "pause"
                }
                "start" {
                    $script:Paused = $false
                    Write-Status "START: Zyklus aktiv."
                }
                "status" {
                    $state = $label
                    if ($script:Paused) {
                        $state = "pausiert"
                    }
                    Write-Status ("STATUS: " + $state + " | FanSpeed: " + $script:LastFanSpeed)
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
                    Write-Status "Befehle: pause, start, status, quit"
                }
            }
        }
        Start-Sleep -Milliseconds 250
    }
    return $null
}

Set-Content -LiteralPath $logPath -Value ("MSI FanBoost Cycle Start " + (Get-Date).ToString("s")) -Encoding UTF8

$script:Paused = $false
$script:StopRequested = $false
$script:FanApiWarmed = $false
$script:ScenarioType = Load-MsiApi

Write-Host ""
Write-Host "MSI FanBoost Cycle"
Write-Host "Befehle im Fenster: pause, start, status, quit"
Write-Host "Zyklus: $boostSeconds Sekunden Boost, dann $pauseSeconds Sekunden Pause; Wiederholung alle $cycleSeconds Sekunden."
Write-Host "Fenster schließen beendet den Lauf. Beim Beenden wird Fanmode $normalMode gesetzt."
Write-Host ""

Update-State -status "running" -running $true

try {
    Warmup-FanApi

    while (-not $script:StopRequested) {
        if ($script:Paused) {
            $result = Wait-WithCommands 1 "pausiert"
            if ($result -eq "quit") { break }
            continue
        }

        Refresh-FanSpeed
        Write-Status ("BOOST AN: Fanmode " + $boostMode + " für " + $boostSeconds + " Sekunden. FanSpeed: " + $script:LastFanSpeed)
        [void](Set-FanMode $boostMode)
        $result = Wait-WithCommands $boostSeconds "Boost läuft"
        if ($result -eq "quit") { break }
        if ($result -eq "pause") { continue }

        Refresh-FanSpeed
        Write-Status ("BOOST AUS: Fanmode " + $normalMode + ". FanSpeed: " + $script:LastFanSpeed)
        [void](Set-FanMode $normalMode)

        Write-Status "Warte $pauseSeconds Sekunden bis zum nächsten Boost."
        $result = Wait-WithCommands $pauseSeconds "wartet"
        if ($result -eq "quit") { break }
    }
}
finally {
    Write-Status "Beende: Fanmode $normalMode wird gesetzt."
    try { [void](Set-FanMode $normalMode) } catch {}
    Update-State -status "stopped" -running $false
    try { Remove-Item -LiteralPath $statePath -ErrorAction SilentlyContinue } catch {}
}
