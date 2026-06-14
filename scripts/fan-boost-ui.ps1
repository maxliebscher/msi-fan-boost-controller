param(
    [string]$Language = "en-US"
)

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$coreScript = Join-Path $baseDir "msi-fanboost-cycle.ps1"
$statePath = Join-Path $baseDir "msi-fanboost-cycle.state"
$logPath = Join-Path $baseDir "msi-fanboost-cycle.log"
$stopSignalPath = Join-Path $baseDir "msi-fanboost-cycle.stop"
$configPath = Join-Path $baseDir "fan-boost-ui.config.json"

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = New-Object System.Text.UTF8Encoding($false)

$defaultBoostSeconds = 60
$defaultPauseSeconds = 840
$menuRefreshSeconds = 5
$script:uiIndent = "  "

function Load-Config {
    $cfg = [ordered]@{
        BoostSeconds = $defaultBoostSeconds
        PauseSeconds = $defaultPauseSeconds
    }

    if (Test-Path $configPath) {
        try {
            $loaded = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            if ($loaded.BoostSeconds -gt 0) { $cfg.BoostSeconds = [int]$loaded.BoostSeconds }
            if ($loaded.PauseSeconds -gt 0) { $cfg.PauseSeconds = [int]$loaded.PauseSeconds }
        }
        catch {
            Write-Host "WARN: Config unreadable, using defaults."
        }
    }
    return $cfg
}

function Save-Config($boost, $pause) {
    $cfg = [ordered]@{
        BoostSeconds = [int]$boost
        PauseSeconds = [int]$pause
    }
    try { $cfg | ConvertTo-Json | Set-Content -Path $configPath -Encoding UTF8 } catch {}
}

function Write-UiLog($message) {
    try {
        $line = (Get-Date).ToString("HH:mm:ss") + " UI: " + $message
        Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
    }
    catch {}
}

function Get-State {
    if (-not (Test-Path $statePath)) { return $null }

    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        try {
            $stream = [System.IO.File]::Open($statePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            try {
                $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
                try {
                    $json = $reader.ReadToEnd()
                }
                finally {
                    $reader.Dispose()
                }
            }
            finally {
                $stream.Dispose()
            }

            if (-not [string]::IsNullOrWhiteSpace($json)) {
                return $json | ConvertFrom-Json
            }
        }
        catch {
            Start-Sleep -Milliseconds 50
        }
    }

    return $null
}

function Format-StateLine($state) {
    if ($null -eq $state) {
        return [pscustomobject]@{
            Running = $false
            Status = "offline"
            ProcessId = "-"
            BoostSeconds = $global:boostSeconds
            PauseSeconds = $global:pauseSeconds
            CycleSeconds = $global:boostSeconds + $global:pauseSeconds
            LastFanSpeed = "n/a"
        }
    }

    $running = $false
    try {
        $proc = Get-Process -Id $state.ProcessId -ErrorAction SilentlyContinue
        if ($proc) { $running = $true }
    }
    catch {
        $running = $false
    }

    if (-not $running) {
        Remove-Item -LiteralPath $statePath -ErrorAction SilentlyContinue
    }

    return [pscustomobject]@{
        Running = $running
        Status = if ($running) { "running" } else { "stopped" }
        ProcessId = if ($running -and $state.ProcessId) { $state.ProcessId } else { "-" }
        BoostSeconds = if ($state.BoostSeconds) { $state.BoostSeconds } else { $global:boostSeconds }
        PauseSeconds = if ($state.PauseSeconds) { $state.PauseSeconds } else { $global:pauseSeconds }
        CycleSeconds = if ($state.CycleSeconds) { $state.CycleSeconds } else { $global:boostSeconds + $global:pauseSeconds }
        LastFanSpeed = if ($running -and $state.LastFanSpeed) { $state.LastFanSpeed } else { "n/a" }
    }
}

function Convert-LogLineForDisplay([string]$line) {
    $prefix = ""
    $message = $line
    if ($line -match "^(\d{2}:\d{2}:\d{2})\s+(.*)$") {
        $prefix = $matches[1] + " "
        $message = $matches[2]
    }

    switch -Regex ($message) {
        "^Fanmode (\d+) gesetzt\.$" {
            return $prefix + ("Fan mode {0} set." -f $matches[1])
        }
        "^Warte (\d+) Sekunden bis zum nächsten Boost\.$" {
            return $prefix + ("Waiting {0} seconds until the next boost." -f $matches[1])
        }
        "^BOOST AN: Fanmode (\d+) für (\d+) Sekunden\. FanSpeed: (.*)$" {
            return $prefix + ("BOOST ON: fan mode {0} for {1} seconds. Fan speed: {2}" -f $matches[1], $matches[2], $matches[3])
        }
        "^BOOST AUS: Fanmode (\d+)\. FanSpeed: (.*)$" {
            return $prefix + ("BOOST OFF: fan mode {0}. Fan speed: {1}" -f $matches[1], $matches[2])
        }
        "^Warmup RPM nach mode (\d+): (.*)$" {
            return $prefix + ("Warmup RPM after mode {0}: {1}" -f $matches[1], $matches[2])
        }
        "^MSI Fan-API Warmup: mode 4,5,6,0,1 mit kurzen Wartezeiten\.$" {
            return $prefix + "MSI fan API warmup: mode 4,5,6,0,1 with short waits."
        }
        "^PAUSE: Fanmode (\d+) gesetzt\.$" {
            return $prefix + ("PAUSE: Fan mode {0} set." -f $matches[1])
        }
        "^START: Zyklus aktiv\.$" {
            return $prefix + "START: cycle active."
        }
        default {
            return $line
        }
    }
}

function Get-LogLines([int]$count = 12) {
    if (-not (Test-Path $logPath)) {
        return @()
    }

    try {
        return @(Get-Content -LiteralPath $logPath -Tail $count -ErrorAction Stop | ForEach-Object { Convert-LogLineForDisplay $_ })
    }
    catch {
        return @()
    }
}

function Render-Menu {
    param(
        [string]$statusMessage = "",
        [bool]$flashStatus = $false
    )

    $state = Format-StateLine (Get-State)
    $logLines = Get-LogLines 12
    $pad = $script:uiIndent

    Clear-Host
    Write-Host ($pad + "===============================") -ForegroundColor Cyan
    Write-Host ($pad + "  MSI Fan Boost Controller") -ForegroundColor Cyan
    Write-Host ($pad + "===============================") -ForegroundColor Cyan
    Write-Host ""
    Write-Host ($pad + "Status      : ") -NoNewline
    if ($state.Running) {
        Write-Host "ACTIVE" -ForegroundColor Green -NoNewline
    } else {
        Write-Host "INACTIVE" -ForegroundColor DarkGray -NoNewline
    }
    Write-Host " ($($state.Status))"
    Write-Host ($pad + "Process ID  : ") -NoNewline
    Write-Host $state.ProcessId -ForegroundColor Yellow
    Write-Host ($pad + "Boost / Pause : ") -NoNewline
    Write-Host ("{0}s / {1}s" -f $state.BoostSeconds, $state.PauseSeconds) -ForegroundColor Yellow
    Write-Host ($pad + ("Total cycle: {0}s" -f $state.CycleSeconds)) -ForegroundColor Yellow
    Write-Host ($pad + "Fan speed  : ") -NoNewline
    Write-Host $state.LastFanSpeed -ForegroundColor Magenta
    Write-Host ""
    Write-Host ($pad + "Menu") -ForegroundColor Cyan
    Write-Host ($pad + " 1) Start")
    Write-Host ($pad + " 2) Stop")
    Write-Host ($pad + " 3) Refresh status")
    Write-Host ($pad + (" 4) Change boost time (currently {0}s)" -f $global:boostSeconds))
    Write-Host ($pad + (" 5) Change pause time (currently {0}s)" -f $global:pauseSeconds))
    Write-Host ($pad + " 6) Exit")
    Write-Host ""
    if ($statusMessage) {
        Write-Host ($pad + "Notice      : ") -NoNewline
        if ($flashStatus) {
            Write-Host $statusMessage -ForegroundColor Black -BackgroundColor Yellow
        } else {
            Write-Host $statusMessage -ForegroundColor DarkYellow
        }
    } else {
        Write-Host ""
    }
    Write-Host ""
    Write-Host ($pad + "Live log") -ForegroundColor Cyan
    Write-Host ($pad + "-------------------------------") -ForegroundColor DarkCyan
    if ($logLines.Count -gt 0) {
        foreach ($line in $logLines) {
            Write-Host ($pad + $line) -ForegroundColor DarkGray
        }
    } else {
        Write-Host ($pad + "No log data yet.") -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Flash-StatusLine([string]$message) {
    Render-Menu -statusMessage $message -flashStatus $true
    Start-Sleep -Milliseconds 180
    Render-Menu -statusMessage ""
    Start-Sleep -Milliseconds 120
    Render-Menu -statusMessage $message -flashStatus $true
    Start-Sleep -Milliseconds 260
}

function Start-FanCycle($boost, $pause) {
    Write-UiLog ("Start requested ({0}s boost / {1}s pause)." -f $boost, $pause)

    if ($pause -lt 1) {
        Write-UiLog "Start rejected: pause must be at least 1 second."
        return "Pause must be at least 1 second."
    }

    if (-not (Test-Path -LiteralPath $coreScript)) {
        Write-UiLog ("Start rejected: worker script not found at {0}" -f $coreScript)
        return "Worker script not found: $coreScript"
    }

    $state = Get-State
    if ($state) {
        try {
            $proc = Get-Process -Id $state.ProcessId -ErrorAction SilentlyContinue
            if ($proc) {
                Write-UiLog ("Start skipped: already running (PID {0})." -f $state.ProcessId)
                return ("Already running (PID {0})." -f $state.ProcessId)
            }
        }
        catch {}
    }

    Remove-Item -LiteralPath $stopSignalPath -ErrorAction SilentlyContinue

    $cycleSeconds = $boost + $pause
    $args = @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $coreScript,
        "-BoostSeconds",
        $boost,
        "-CycleSeconds",
        $cycleSeconds,
        "-ParentProcessId",
        $PID
    )
    $proc = Start-Process powershell -ArgumentList $args -Verb RunAs -WindowStyle Hidden -PassThru
    Start-Sleep -Milliseconds 800
    if ($proc -and $proc.Id) {
        Write-UiLog ("Worker launched (PID {0})." -f $proc.Id)
        return ("Started (PID {0})." -f $proc.Id)
    }
    Write-UiLog "Worker launch requested; waiting for UAC."
    return "Start requested (UAC may still block)."
}

function Stop-FanCycle {
    param([bool]$Silent = $false)

    if (-not $Silent) {
        Write-UiLog "Stop requested."
    }

    $state = Get-State
    if ($null -eq $state -or -not $state.ProcessId) {
        if (-not $Silent) {
            Write-UiLog "Stop skipped: no known running process."
        }
        return "No known running process."
    }

    try {
        Set-Content -LiteralPath $stopSignalPath -Value "stop" -Encoding ASCII
        for ($attempt = 0; $attempt -lt 20; $attempt++) {
            $proc = Get-Process -Id $state.ProcessId -ErrorAction SilentlyContinue
            if ($null -eq $proc) {
                Remove-Item -LiteralPath $statePath -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $stopSignalPath -ErrorAction SilentlyContinue
                if (-not $Silent) {
                    Write-UiLog ("Worker stopped gracefully (PID {0})." -f $state.ProcessId)
                }
                return ("Process {0} stopped." -f $state.ProcessId)
            }
            Start-Sleep -Milliseconds 250
        }

        Stop-Process -Id $state.ProcessId -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $statePath -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $stopSignalPath -ErrorAction SilentlyContinue
        if (-not $Silent) {
            Write-UiLog ("Worker forced to stop (PID {0})." -f $state.ProcessId)
        }
        return ("Process {0} stopped." -f $state.ProcessId)
    }
    catch {
        if (-not $Silent) {
            Write-UiLog ("Stop failed: {0}" -f $_.Exception.Message)
        }
        return ("Stop failed: {0}" -f $_.Exception.Message)
    }
}

function Read-MenuSelection([string]$statusMessage) {
    while ($true) {
        Render-Menu -statusMessage $statusMessage
        Write-Host -NoNewline ($script:uiIndent + "Select (1-6): ")

        try {
            $deadline = (Get-Date).AddSeconds($menuRefreshSeconds)
            while ((Get-Date) -lt $deadline) {
                if ([Console]::KeyAvailable) {
                    $key = [Console]::ReadKey($true)
                    if ("123456".Contains([string]$key.KeyChar)) {
                        Write-Host $key.KeyChar
                        Flash-StatusLine ("Selected {0}" -f $key.KeyChar)
                        return [string]$key.KeyChar
                    }
                    if ($key.Key -eq [ConsoleKey]::Enter) {
                        continue
                    }
                }
                Start-Sleep -Milliseconds 50
            }
        }
        catch {
            return (Read-Host "Select (1-6)")
        }
    }
}

$config = Load-Config
$global:boostSeconds = [int]$config.BoostSeconds
$global:pauseSeconds = [int]$config.PauseSeconds

$message = ""
try {
    while ($true) {
        $selection = Read-MenuSelection -statusMessage $message
        $message = ""
        switch ($selection.Trim()) {
            "1" {
                $message = Start-FanCycle -boost $global:boostSeconds -pause $global:pauseSeconds
            }
            "2" {
                $message = Stop-FanCycle
            }
            "3" {
                Write-UiLog "Refresh requested."
                $message = "Status refreshed."
            }
            "4" {
                $new = Read-Host "New boost time in seconds"
                if ([int]::TryParse($new, [ref]$global:boostSeconds) -and $global:boostSeconds -gt 0) {
                    Save-Config $global:boostSeconds $global:pauseSeconds
                    Write-UiLog ("Boost time changed to {0}s." -f $global:boostSeconds)
                    $message = ("New boost time: {0} s" -f $global:boostSeconds)
                } else {
                    Write-UiLog ("Invalid boost time input: {0}" -f $new)
                    $message = "Invalid number for boost."
                }
            }
            "5" {
                $new = Read-Host "New pause time in seconds"
                if ([int]::TryParse($new, [ref]$global:pauseSeconds) -and $global:pauseSeconds -gt 0) {
                    Save-Config $global:boostSeconds $global:pauseSeconds
                    Write-UiLog ("Pause time changed to {0}s." -f $global:pauseSeconds)
                    $message = ("New pause time: {0} s" -f $global:pauseSeconds)
                } else {
                    Write-UiLog ("Invalid pause time input: {0}" -f $new)
                    $message = "Invalid number for pause."
                }
            }
            "6" {
                Write-UiLog "Exit requested."
                [void](Stop-FanCycle)
                return
            }
            default {
                $message = "Please pick 1 to 6."
            }
        }
    }
}
finally {
    [void](Stop-FanCycle -Silent $true)
}
