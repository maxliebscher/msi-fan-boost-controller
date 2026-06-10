$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$coreScript = Join-Path $baseDir "msi-fanboost-cycle.ps1"
$statePath = Join-Path $baseDir "msi-fanboost-cycle.state"
$configPath = Join-Path $baseDir "fan-boost-ui.config.json"

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = New-Object System.Text.UTF8Encoding($false)

$defaultBoostSeconds = 60
$defaultPauseSeconds = 840
$language = Get-Culture

$i18n = @{
    "de-DE" = @{
        title = "MSI Fan Boost Controller"
        statusLabel = "Status"
        active = "AKTIV"
        inactive = "INAKTIV"
        processId = "Prozess-ID"
        boostPause = "Boost / Pause"
        cycleTotal = "Cycle gesamt"
        fanSpeed = "Fan-Speed"
        menuTitle = "Menü"
        menu1 = "Starten"
        menu2 = "Stoppen"
        menu3 = "Status aktualisieren"
        menu4 = "Boostzeit ändern (aktuell {0}s)"
        menu5 = "Pausenzeit ändern (aktuell {0}s)"
        menu6 = "Beenden"
        unknownProcess = "nicht aktiv"
        choicePrompt = "Auswahl (1-6)"
        msgWarnConfig = "WARN: Config nicht lesbar, nutze Defaultwerte."
        msgStarted = "Gestartet (PID {0})."
        msgStartedUac = "Start ausgelöst (UAC kann noch blockieren)."
        msgNoRun = "Kein bekannter laufender Prozess."
        msgStartBlocked = "Lauf bereits aktiv (PID {0})."
        msgStop = "Prozess {0} wurde gestoppt."
        msgStopFail = "Stop fehlgeschlagen: {0}"
        msgBoostInvalid = "Ungültige Zahl für Boost."
        msgPauseInvalid = "Ungültige Zahl für Pause."
        msgStatusRefresh = "Status aktualisiert."
        msgBoostSet = "Neue Boostzeit: {0} s"
        msgPauseSet = "Neue Pausenzeit: {0} s"
        msgNoSelection = "Bitte 1 bis 6 wählen."
        msgNoSecLessOne = "Pause darf nicht kleiner als 1 Sekunde sein."
        msgHint = "Hinweis"
        stateRunning = "running"
        stateStopped = "stopped"
        stateOffline = "offline"
    }
    "de" = @{
        title = "MSI Fan Boost Controller"
        statusLabel = "Status"
        active = "AKTIV"
        inactive = "INAKTIV"
        processId = "Prozess-ID"
        boostPause = "Boost / Pause"
        cycleTotal = "Cycle gesamt"
        fanSpeed = "Fan-Speed"
        menuTitle = "Menü"
        menu1 = "Starten"
        menu2 = "Stoppen"
        menu3 = "Status aktualisieren"
        menu4 = "Boostzeit ändern (aktuell {0}s)"
        menu5 = "Pausenzeit ändern (aktuell {0}s)"
        menu6 = "Beenden"
        unknownProcess = "nicht aktiv"
        choicePrompt = "Auswahl (1-6)"
        msgWarnConfig = "WARN: Config nicht lesbar, nutze Defaultwerte."
        msgStarted = "Gestartet (PID {0})."
        msgStartedUac = "Start ausgelöst (UAC kann noch blockieren)."
        msgNoRun = "Kein bekannter laufender Prozess."
        msgStartBlocked = "Lauf bereits aktiv (PID {0})."
        msgStop = "Prozess {0} wurde gestoppt."
        msgStopFail = "Stop fehlgeschlagen: {0}"
        msgBoostInvalid = "Ungültige Zahl für Boost."
        msgPauseInvalid = "Ungültige Zahl für Pause."
        msgStatusRefresh = "Status aktualisiert."
        msgBoostSet = "Neue Boostzeit: {0} s"
        msgPauseSet = "Neue Pausenzeit: {0} s"
        msgNoSelection = "Bitte 1 bis 6 wählen."
        msgNoSecLessOne = "Pause darf nicht kleiner als 1 Sekunde sein."
        msgHint = "Hinweis"
        stateRunning = "running"
        stateStopped = "stopped"
        stateOffline = "offline"
    }
    "fr" = @{
        title = "MSI Fan Boost Controller"
        statusLabel = "État"
        active = "ACTIF"
        inactive = "INACTIF"
        processId = "ID du processus"
        boostPause = "Boost / Pause"
        cycleTotal = "Cycle total"
        fanSpeed = "Vitesse du ventilateur"
        menuTitle = "Menu"
        menu1 = "Démarrer"
        menu2 = "Arrêter"
        menu3 = "Actualiser l'état"
        menu4 = "Modifier la durée de boost (actuelle {0}s)"
        menu5 = "Modifier la durée de pause (actuelle {0}s)"
        menu6 = "Quitter"
        unknownProcess = "inactif"
        choicePrompt = "Choix (1-6)"
        msgWarnConfig = "ATTENTION : configuration illisible, valeurs par défaut utilisées."
        msgStarted = "Démarré (PID {0})."
        msgStartedUac = "Démarrage lancé (UAC peut encore bloquer)."
        msgNoRun = "Aucun processus actif connu."
        msgStartBlocked = "Déjà en cours (PID {0})."
        msgStop = "Processus {0} arrêté."
        msgStopFail = "Échec de l'arrêt : {0}"
        msgBoostInvalid = "Nombre invalide pour le boost."
        msgPauseInvalid = "Nombre invalide pour la pause."
        msgStatusRefresh = "État actualisé."
        msgBoostSet = "Nouvelle durée de boost : {0} s"
        msgPauseSet = "Nouvelle durée de pause : {0} s"
        msgNoSelection = "Veuillez choisir 1 à 6."
        msgNoSecLessOne = "La pause doit être d'au moins 1 seconde."
        msgHint = "Note"
        stateRunning = "running"
        stateStopped = "stopped"
        stateOffline = "offline"
    }
    "fr-FR" = @{
        title = "MSI Fan Boost Controller"
        statusLabel = "État"
        active = "ACTIF"
        inactive = "INACTIF"
        processId = "ID du processus"
        boostPause = "Boost / Pause"
        cycleTotal = "Cycle total"
        fanSpeed = "Vitesse du ventilateur"
        menuTitle = "Menu"
        menu1 = "Démarrer"
        menu2 = "Arrêter"
        menu3 = "Actualiser l'état"
        menu4 = "Modifier la durée de boost (actuelle {0}s)"
        menu5 = "Modifier la durée de pause (actuelle {0}s)"
        menu6 = "Quitter"
        unknownProcess = "inactif"
        choicePrompt = "Choix (1-6)"
        msgWarnConfig = "ATTENTION : configuration illisible, valeurs par défaut utilisées."
        msgStarted = "Démarré (PID {0})."
        msgStartedUac = "Démarrage lancé (UAC peut encore bloquer)."
        msgNoRun = "Aucun processus actif connu."
        msgStartBlocked = "Déjà en cours (PID {0})."
        msgStop = "Processus {0} arrêté."
        msgStopFail = "Échec de l'arrêt : {0}"
        msgBoostInvalid = "Nombre invalide pour le boost."
        msgPauseInvalid = "Nombre invalide pour la pause."
        msgStatusRefresh = "État actualisé."
        msgBoostSet = "Nouvelle durée de boost : {0} s"
        msgPauseSet = "Nouvelle durée de pause : {0} s"
        msgNoSelection = "Veuillez choisir 1 à 6."
        msgNoSecLessOne = "La pause doit être d'au moins 1 seconde."
        msgHint = "Note"
        stateRunning = "running"
        stateStopped = "stopped"
        stateOffline = "offline"
    }
    "es" = @{
        title = "Controlador de MSI Fan Boost"
        statusLabel = "Estado"
        active = "ACTIVO"
        inactive = "INACTIVO"
        processId = "ID de proceso"
        boostPause = "Boost / Pausa"
        cycleTotal = "Ciclo total"
        fanSpeed = "Velocidad de ventilador"
        menuTitle = "Menú"
        menu1 = "Iniciar"
        menu2 = "Detener"
        menu3 = "Actualizar estado"
        menu4 = "Cambiar tiempo de boost (actual {0}s)"
        menu5 = "Cambiar tiempo de pausa (actual {0}s)"
        menu6 = "Salir"
        unknownProcess = "sin actividad"
        choicePrompt = "Selecciona (1-6)"
        msgWarnConfig = "ADVERTENCIA: no se puede leer la configuración, se usan valores por defecto."
        msgStarted = "Iniciado (PID {0})."
        msgStartedUac = "Inicio solicitado (UAC aún puede bloquear)."
        msgNoRun = "No hay proceso activo conocido."
        msgStartBlocked = "Ya se está ejecutando (PID {0})."
        msgStop = "Proceso {0} detenido."
        msgStopFail = "No se pudo detener: {0}"
        msgBoostInvalid = "Número no válido para boost."
        msgPauseInvalid = "Número no válido para pausa."
        msgStatusRefresh = "Estado actualizado."
        msgBoostSet = "Nuevo tiempo de boost: {0} s"
        msgPauseSet = "Nuevo tiempo de pausa: {0} s"
        msgNoSelection = "Elige del 1 al 6."
        msgNoSecLessOne = "La pausa debe ser al menos 1 segundo."
        msgHint = "Nota"
        stateRunning = "running"
        stateStopped = "stopped"
        stateOffline = "offline"
    }
    "es-ES" = @{
        title = "Controlador de MSI Fan Boost"
        statusLabel = "Estado"
        active = "ACTIVO"
        inactive = "INACTIVO"
        processId = "ID de proceso"
        boostPause = "Boost / Pausa"
        cycleTotal = "Ciclo total"
        fanSpeed = "Velocidad de ventilador"
        menuTitle = "Menú"
        menu1 = "Iniciar"
        menu2 = "Detener"
        menu3 = "Actualizar estado"
        menu4 = "Cambiar tiempo de boost (actual {0}s)"
        menu5 = "Cambiar tiempo de pausa (actual {0}s)"
        menu6 = "Salir"
        unknownProcess = "sin actividad"
        choicePrompt = "Selecciona (1-6)"
        msgWarnConfig = "ADVERTENCIA: no se puede leer la configuración, se usan valores por defecto."
        msgStarted = "Iniciado (PID {0})."
        msgStartedUac = "Inicio solicitado (UAC aún puede bloquear)."
        msgNoRun = "No hay proceso activo conocido."
        msgStartBlocked = "Ya se está ejecutando (PID {0})."
        msgStop = "Proceso {0} detenido."
        msgStopFail = "No se pudo detener: {0}"
        msgBoostInvalid = "Número no válido para boost."
        msgPauseInvalid = "Número no válido para pausa."
        msgStatusRefresh = "Estado actualizado."
        msgBoostSet = "Nuevo tiempo de boost: {0} s"
        msgPauseSet = "Nuevo tiempo de pausa: {0} s"
        msgNoSelection = "Elige del 1 al 6."
        msgNoSecLessOne = "La pausa debe ser al menos 1 segundo."
        msgHint = "Nota"
        stateRunning = "running"
        stateStopped = "stopped"
        stateOffline = "offline"
    }
    "pt" = @{
        title = "Controlador de MSI Fan Boost"
        statusLabel = "Estado"
        active = "ATIVO"
        inactive = "INATIVO"
        processId = "ID do processo"
        boostPause = "Boost / Pausa"
        cycleTotal = "Ciclo total"
        fanSpeed = "Velocidade da ventoinha"
        menuTitle = "Menu"
        menu1 = "Iniciar"
        menu2 = "Parar"
        menu3 = "Atualizar status"
        menu4 = "Alterar tempo do boost (atual {0}s)"
        menu5 = "Alterar tempo de pausa (atual {0}s)"
        menu6 = "Sair"
        unknownProcess = "sem atividade"
        choicePrompt = "Escolha (1-6)"
        msgWarnConfig = "ATENÇÃO: configuração ilegível, usando padrão."
        msgStarted = "Iniciado (PID {0})."
        msgStartedUac = "Início solicitado (UAC ainda pode bloquear)."
        msgNoRun = "Nenhum processo ativo conhecido."
        msgStartBlocked = "Já está em execução (PID {0})."
        msgStop = "Processo {0} parado."
        msgStopFail = "Falha ao parar: {0}"
        msgBoostInvalid = "Número inválido para boost."
        msgPauseInvalid = "Número inválido para pausa."
        msgStatusRefresh = "Status atualizado."
        msgBoostSet = "Novo tempo de boost: {0} s"
        msgPauseSet = "Novo tempo de pausa: {0} s"
        msgNoSelection = "Escolha de 1 a 6."
        msgNoSecLessOne = "A pausa deve ser de pelo menos 1 segundo."
        msgHint = "Observação"
        stateRunning = "running"
        stateStopped = "stopped"
        stateOffline = "offline"
    }
    "pt-BR" = @{
        title = "Controlador de MSI Fan Boost"
        statusLabel = "Estado"
        active = "ATIVO"
        inactive = "INATIVO"
        processId = "ID do processo"
        boostPause = "Boost / Pausa"
        cycleTotal = "Ciclo total"
        fanSpeed = "Velocidade da ventoinha"
        menuTitle = "Menu"
        menu1 = "Iniciar"
        menu2 = "Parar"
        menu3 = "Atualizar status"
        menu4 = "Alterar tempo de boost (atual {0}s)"
        menu5 = "Alterar tempo de pausa (atual {0}s)"
        menu6 = "Sair"
        unknownProcess = "sem atividade"
        choicePrompt = "Escolha (1-6)"
        msgWarnConfig = "AVISO: configuração ilegível, usando padrão."
        msgStarted = "Iniciado (PID {0})."
        msgStartedUac = "Início solicitado (UAC ainda pode bloquear)."
        msgNoRun = "Nenhum processo ativo conhecido."
        msgStartBlocked = "Já está em execução (PID {0})."
        msgStop = "Processo {0} parado."
        msgStopFail = "Falha ao parar: {0}"
        msgBoostInvalid = "Número inválido para boost."
        msgPauseInvalid = "Número inválido para pausa."
        msgStatusRefresh = "Status atualizado."
        msgBoostSet = "Novo tempo de boost: {0} s"
        msgPauseSet = "Novo tempo de pausa: {0} s"
        msgNoSelection = "Escolha de 1 a 6."
        msgNoSecLessOne = "A pausa deve ser de pelo menos 1 segundo."
        msgHint = "Observação"
        stateRunning = "running"
        stateStopped = "stopped"
        stateOffline = "offline"
    }
    "ru-RU" = @{
        title = "MSI Fan Boost Controller"
        statusLabel = "Статус"
        active = "АКТИВНО"
        inactive = "НЕАКТИВНО"
        processId = "ID процесса"
        boostPause = "Буст / Пауза"
        cycleTotal = "Полный цикл"
        fanSpeed = "Скорость вентилятора"
        menuTitle = "Меню"
        menu1 = "Запуск"
        menu2 = "Стоп"
        menu3 = "Обновить статус"
        menu4 = "Изменить время буста (текущее {0}с)"
        menu5 = "Изменить время паузы (текущее {0}с)"
        menu6 = "Выход"
        unknownProcess = "не активен"
        choicePrompt = "Выбор (1-6)"
        msgWarnConfig = "ВНИМАНИЕ: конфиг не прочитан, используются значения по умолчанию."
        msgStarted = "Запущено (PID {0})."
        msgStartedUac = "Запрос на запуск отправлен (UAC может блокировать)."
        msgNoRun = "Нет известных запущенных процессов."
        msgStartBlocked = "Уже работает (PID {0})."
        msgStop = "Процесс {0} остановлен."
        msgStopFail = "Не удалось остановить: {0}"
        msgBoostInvalid = "Неверное число для буста."
        msgPauseInvalid = "Неверное число для паузы."
        msgStatusRefresh = "Статус обновлен."
        msgBoostSet = "Новое время буста: {0} с"
        msgPauseSet = "Новое время паузы: {0} с"
        msgNoSelection = "Выберите 1-6."
        msgNoSecLessOne = "Пауза должна быть не менее 1 секунды."
        msgHint = "Примечание"
        stateRunning = "running"
        stateStopped = "stopped"
        stateOffline = "offline"
    }
    "it" = @{
        title = "Controller MSI Fan Boost"
        statusLabel = "Stato"
        active = "ATTIVO"
        inactive = "INATTIVO"
        processId = "ID processo"
        boostPause = "Boost / Pausa"
        cycleTotal = "Ciclo totale"
        fanSpeed = "Velocità ventola"
        menuTitle = "Menu"
        menu1 = "Avvia"
        menu2 = "Arresta"
        menu3 = "Aggiorna stato"
        menu4 = "Modifica tempo boost (attuale {0}s)"
        menu5 = "Modifica pausa (attuale {0}s)"
        menu6 = "Esci"
        unknownProcess = "non attivo"
        choicePrompt = "Scelta (1-6)"
        msgWarnConfig = "ATTENZIONE: impostazioni non leggibili, uso i valori predefiniti."
        msgStarted = "Avviato (PID {0})."
        msgStartedUac = "Avvio richiesto (UAC potrebbe bloccare)."
        msgNoRun = "Nessun processo attivo noto."
        msgStartBlocked = "Già in esecuzione (PID {0})."
        msgStop = "Processo {0} arrestato."
        msgStopFail = "Arresto fallito: {0}"
        msgBoostInvalid = "Numero non valido per boost."
        msgPauseInvalid = "Numero non valido per pausa."
        msgStatusRefresh = "Stato aggiornato."
        msgBoostSet = "Nuovo tempo boost: {0} s"
        msgPauseSet = "Nuovo tempo pausa: {0} s"
        msgNoSelection = "Seleziona da 1 a 6."
        msgNoSecLessOne = "La pausa deve essere almeno 1 secondo."
        msgHint = "Nota"
        stateRunning = "running"
        stateStopped = "stopped"
        stateOffline = "offline"
    }
    "it-IT" = @{
        title = "Controller MSI Fan Boost"
        statusLabel = "Stato"
        active = "ATTIVO"
        inactive = "INATTIVO"
        processId = "ID processo"
        boostPause = "Boost / Pausa"
        cycleTotal = "Ciclo totale"
        fanSpeed = "Velocità ventola"
        menuTitle = "Menu"
        menu1 = "Avvia"
        menu2 = "Arresta"
        menu3 = "Aggiorna stato"
        menu4 = "Modifica tempo boost (attuale {0}s)"
        menu5 = "Modifica pausa (attuale {0}s)"
        menu6 = "Esci"
        unknownProcess = "non attivo"
        choicePrompt = "Scelta (1-6)"
        msgWarnConfig = "ATTENZIONE: impostazioni non leggibili, uso i valori predefiniti."
        msgStarted = "Avviato (PID {0})."
        msgStartedUac = "Avvio richiesto (UAC potrebbe bloccare)."
        msgNoRun = "Nessun processo attivo noto."
        msgStartBlocked = "Già in esecuzione (PID {0})."
        msgStop = "Processo {0} arrestato."
        msgStopFail = "Arresto fallito: {0}"
        msgBoostInvalid = "Numero non valido per boost."
        msgPauseInvalid = "Numero non valido per pausa."
        msgStatusRefresh = "Stato aggiornato."
        msgBoostSet = "Nuovo tempo boost: {0} s"
        msgPauseSet = "Nuovo tempo pausa: {0} s"
        msgNoSelection = "Seleziona da 1 a 6."
        msgNoSecLessOne = "La pausa deve essere almeno 1 secondo."
        msgHint = "Nota"
        stateRunning = "running"
        stateStopped = "stopped"
        stateOffline = "offline"
    }
    "en-US" = @{
        title = "MSI Fan Boost Controller"
        statusLabel = "Status"
        active = "ACTIVE"
        inactive = "INACTIVE"
        processId = "Process ID"
        boostPause = "Boost / Pause"
        cycleTotal = "Total cycle"
        fanSpeed = "Fan speed"
        menuTitle = "Menu"
        menu1 = "Start"
        menu2 = "Stop"
        menu3 = "Refresh status"
        menu4 = "Change boost time (currently {0}s)"
        menu5 = "Change pause time (currently {0}s)"
        menu6 = "Exit"
        unknownProcess = "not running"
        choicePrompt = "Select (1-6)"
        msgWarnConfig = "WARN: Config unreadable, using defaults."
        msgStarted = "Started (PID {0})."
        msgStartedUac = "Start requested (UAC may still block)."
        msgNoRun = "No known running process."
        msgStartBlocked = "Already running (PID {0})."
        msgStop = "Process {0} stopped."
        msgStopFail = "Stop failed: {0}"
        msgBoostInvalid = "Invalid number for boost."
        msgPauseInvalid = "Invalid number for pause."
        msgStatusRefresh = "Status refreshed."
        msgBoostSet = "New boost time: {0} s"
        msgPauseSet = "New pause time: {0} s"
        msgNoSelection = "Please pick 1 to 6."
        msgNoSecLessOne = "Pause must be at least 1 second."
        msgHint = "Notice"
        stateRunning = "running"
        stateStopped = "stopped"
        stateOffline = "offline"
    }
    "en" = @{
        title = "MSI Fan Boost Controller"
        statusLabel = "Status"
        active = "ACTIVE"
        inactive = "INACTIVE"
        processId = "Process ID"
        boostPause = "Boost / Pause"
        cycleTotal = "Total cycle"
        fanSpeed = "Fan speed"
        menuTitle = "Menu"
        menu1 = "Start"
        menu2 = "Stop"
        menu3 = "Refresh status"
        menu4 = "Change boost time (currently {0}s)"
        menu5 = "Change pause time (currently {0}s)"
        menu6 = "Exit"
        unknownProcess = "not running"
        choicePrompt = "Select (1-6)"
        msgWarnConfig = "WARN: Config unreadable, using defaults."
        msgStarted = "Started (PID {0})."
        msgStartedUac = "Start requested (UAC may still block)."
        msgNoRun = "No known running process."
        msgStartBlocked = "Already running (PID {0})."
        msgStop = "Process {0} stopped."
        msgStopFail = "Stop failed: {0}"
        msgBoostInvalid = "Invalid number for boost."
        msgPauseInvalid = "Invalid number for pause."
        msgStatusRefresh = "Status refreshed."
        msgBoostSet = "New boost time: {0} s"
        msgPauseSet = "New pause time: {0} s"
        msgNoSelection = "Please pick 1 to 6."
        msgNoSecLessOne = "Pause must be at least 1 second."
        msgHint = "Notice"
        stateRunning = "running"
        stateStopped = "stopped"
        stateOffline = "offline"
    }
}

function T($key) {
    $lang = $language.Name
    $fallback = "en-US"
    if ($i18n.ContainsKey($lang) -and $i18n[$lang].ContainsKey($key)) {
        return $i18n[$lang][$key]
    }
    if ($i18n.ContainsKey($language.TwoLetterISOLanguageName) -and $i18n[$language.TwoLetterISOLanguageName].ContainsKey($key)) {
        return $i18n[$language.TwoLetterISOLanguageName][$key]
    }
    return $i18n[$fallback][$key]
}

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
            Write-Host (T "msgWarnConfig")
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

function Get-State {
    if (-not (Test-Path $statePath)) { return $null }
    try {
        return Get-Content -Path $statePath -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Format-StateLine($state) {
    if ($null -eq $state) {
        return [pscustomobject]@{
            Running = $false
            Status = "offline"
            ProcessId = "-"
            BoostSeconds = 60
            PauseSeconds = 840
            CycleSeconds = 900
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

    return [pscustomobject]@{
        Running = $running
        Status = if ($running) { (T "stateRunning") } else { (T "stateStopped") }
        ProcessId = if ($state.ProcessId) { $state.ProcessId } else { "-" }
        BoostSeconds = $state.BoostSeconds
        PauseSeconds = $state.PauseSeconds
        CycleSeconds = $state.CycleSeconds
        LastFanSpeed = if ($state.LastFanSpeed) { $state.LastFanSpeed } else { "n/a" }
    }
}

function Render-Menu {
    param([string]$statusMessage = "")

    $state = Format-StateLine (Get-State)

    Clear-Host
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host ("  {0}" -f (T "title")) -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("{0}      : " -f (T "statusLabel")) -NoNewline
    if ($state.Running) {
        Write-Host (T "active") -ForegroundColor Green -NoNewline
    } else {
        Write-Host (T "inactive") -ForegroundColor DarkGray -NoNewline
    }
    Write-Host " ($($state.Status))"
    Write-Host ("{0}  : " -f (T "processId")) -NoNewline
    Write-Host $state.ProcessId -ForegroundColor Yellow
    Write-Host ("{0} : " -f (T "boostPause")) -NoNewline
    Write-Host ("{0}s / {1}s" -f $state.BoostSeconds, $state.PauseSeconds) -ForegroundColor Yellow
    Write-Host ("{0}: {1}s" -f (T "cycleTotal"), $state.CycleSeconds) -ForegroundColor Yellow
    Write-Host ("{0}  : " -f (T "fanSpeed")) -NoNewline
    Write-Host $state.LastFanSpeed -ForegroundColor Magenta
    Write-Host ""
    Write-Host (T "menuTitle") -ForegroundColor Cyan
    Write-Host " 1) $(T "menu1")"
    Write-Host " 2) $(T "menu2")"
    Write-Host " 3) $(T "menu3")"
    Write-Host (" 4) " + ((T "menu4") -f $global:boostSeconds))
    Write-Host (" 5) " + ((T "menu5") -f $global:pauseSeconds))
    Write-Host " 6) $(T "menu6")"
    Write-Host ""
    if ($statusMessage) {
        Write-Host ("{0}     : " -f (T "msgHint")) -NoNewline
        Write-Host $statusMessage -ForegroundColor DarkYellow
    } else {
        Write-Host ""
    }
    Write-Host ""
}

function Start-FanCycle($boost, $pause) {
    if ($pause -lt 1) {
        return T "msgNoSecLessOne"
    }

    $state = Get-State
    if ($state) {
        try {
            $proc = Get-Process -Id $state.ProcessId -ErrorAction SilentlyContinue
            if ($proc) {
                return (T "msgStartBlocked" -f $state.ProcessId)
            }
        }
        catch {}
    }

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
        $cycleSeconds
    )
    $proc = Start-Process powershell -ArgumentList $args -Verb RunAs -PassThru
    Start-Sleep -Milliseconds 800
    if ($proc -and $proc.Id) {
        return (T "msgStarted" -f $proc.Id)
    }
    return T "msgStartedUac"
}

function Stop-FanCycle {
    $state = Get-State
    if ($null -eq $state -or -not $state.ProcessId) {
        return T "msgNoRun"
    }

    try {
        Stop-Process -Id $state.ProcessId -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $statePath -ErrorAction SilentlyContinue
        return (T "msgStop" -f $state.ProcessId)
    }
    catch {
        return (T "msgStopFail" -f $_.Exception.Message)
    }
}

$config = Load-Config
$global:boostSeconds = [int]$config.BoostSeconds
$global:pauseSeconds = [int]$config.PauseSeconds

$message = ""
while ($true) {
    Render-Menu -statusMessage $message
    $message = ""
    $selection = Read-Host (T "choicePrompt")
    switch ($selection.Trim()) {
        "1" {
            $message = Start-FanCycle -boost $global:boostSeconds -pause $global:pauseSeconds
        }
        "2" {
            $message = Stop-FanCycle
        }
        "3" {
            $message = T "msgStatusRefresh"
        }
        "4" {
            $new = Read-Host ((T "menu4") -f $global:boostSeconds)
            if ([int]::TryParse($new, [ref]$global:boostSeconds)) {
                Save-Config $global:boostSeconds $global:pauseSeconds
                $message = (T "msgBoostSet" -f $global:boostSeconds)
            } else {
                $message = T "msgBoostInvalid"
            }
        }
        "5" {
            $new = Read-Host ((T "menu5") -f $global:pauseSeconds)
            if ([int]::TryParse($new, [ref]$global:pauseSeconds)) {
                Save-Config $global:boostSeconds $global:pauseSeconds
                $message = (T "msgPauseSet" -f $global:pauseSeconds)
            } else {
                $message = T "msgPauseInvalid"
            }
        }
        "6" {
            break
        }
        default {
            $message = T "msgNoSelection"
        }
    }
}
