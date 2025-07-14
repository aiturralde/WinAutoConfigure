<#
.SYNOPSIS
    Sistema avanzado de interfaz de usuario para WinAutoConfigure v3.0
.DESCRIPTION
    Proporciona componentes de UI modernos incluyendo notificaciones,
    progreso visual, selectores interactivos y asistentes de configuración
.NOTES
    Compatibilidad total con la nueva arquitectura orientada a objetos
#>

# Importar módulos comunes si están disponibles
if (Get-Command "Write-Log" -ErrorAction SilentlyContinue) {
    $script:HasLogging = $true
} else {
    $script:HasLogging = $false
}

function Show-ModernToastNotification {
    <#
    .SYNOPSIS
        Notificaciones modernas del sistema con iconos y acciones
    #>
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Type = "Info",
        [string[]]$Actions = @(),
        [int]$Duration = 5000
    )
    
    try {
        # Intentar usar BurntToast si está disponible
        if (Get-Module -ListAvailable -Name BurntToast -ErrorAction SilentlyContinue) {
            Import-Module BurntToast -Force
            
            $iconPath = switch ($Type) {
                "Success" { "ms-appx:///Assets/StatusCircleCheckmark.png" }
                "Warning" { "ms-appx:///Assets/StatusTriangleExclamation.png" }
                "Error" { "ms-appx:///Assets/StatusCircleErrorX.png" }
                default { "ms-appx:///Assets/StatusCircleInformation.png" }
            }
            
            $toastParams = @{
                Text = @($Title, $Message)
                AppLogo = $iconPath
                Sound = "Default"
            }
            
            if ($Actions.Count -gt 0) {
                $toastParams.Button = $Actions | ForEach-Object { 
                    New-BTButton -Content $_ -Arguments "action=$_"
                }
            }
            
            New-BurntToastNotification @toastParams
        } else {
            # Fallback mejorado con Windows Forms
            Add-Type -AssemblyName System.Windows.Forms
            Add-Type -AssemblyName System.Drawing
            
            $balloon = New-Object System.Windows.Forms.NotifyIcon
            $balloon.Icon = [System.Drawing.SystemIcons]::Information
            
            $balloonType = switch ($Type) {
                "Error" { [System.Windows.Forms.ToolTipIcon]::Error }
                "Warning" { [System.Windows.Forms.ToolTipIcon]::Warning }
                "Success" { [System.Windows.Forms.ToolTipIcon]::Info }
                default { [System.Windows.Forms.ToolTipIcon]::Info }
            }
            
            $balloon.BalloonTipIcon = $balloonType
            $balloon.BalloonTipText = $Message
            $balloon.BalloonTipTitle = $Title
            $balloon.Visible = $true
            $balloon.ShowBalloonTip($Duration)
            
            # Limpiar después del tiempo especificado
            Start-Sleep -Milliseconds $Duration
            $balloon.Dispose()
        }
    }
    catch {
        if ($script:HasLogging) {
            Write-Log "Error mostrando notificación: $($_.Exception.Message)" -Level "WARNING"
        } else {
            Write-Warning "Error mostrando notificación: $($_.Exception.Message)"
        }
    }
}

function Show-InteractiveProgress {
    <#
    .SYNOPSIS
        Barra de progreso interactiva con estimación de tiempo
    #>
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete,
        [int]$SecondsRemaining = -1,
        [int]$Id = 1
    )
    
    $progressParams = @{
        Activity = $Activity
        Status = $Status
        PercentComplete = $PercentComplete
        Id = $Id
    }
    
    if ($SecondsRemaining -ge 0) {
        $progressParams.SecondsRemaining = $SecondsRemaining
    }
    
    Write-Progress @progressParams
}

function Show-ModuleSelector {
    <#
    .SYNOPSIS
        Selector interactivo de módulos para configuración personalizada
    #>
    param([hashtable]$AvailableModules)
    
    Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                  SELECTOR DE MÓDULOS                     ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    $moduleKeys = $AvailableModules.Keys | Sort-Object
    $selectedModules = @()
    
    for ($i = 0; $i -lt $moduleKeys.Count; $i++) {
        $module = $moduleKeys[$i]
        $info = $AvailableModules[$module]
        
        Write-Host "║ [$($i+1)] $module" -ForegroundColor White
        Write-Host "║     $($info.description)" -ForegroundColor Gray
        if ($info.estimated_time_minutes) {
            Write-Host "║     Tiempo estimado: $($info.estimated_time_minutes) minutos" -ForegroundColor Yellow
        }
        Write-Host "║" -ForegroundColor Cyan
    }
    
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    do {
        $selection = Read-Host "Seleccione módulos (1-$($moduleKeys.Count), separados por comas, o 'all' para todos)"
        
        if ($selection.ToLower() -eq "all") {
            $selectedModules = $moduleKeys
            break
        }
        
        try {
            $indices = $selection -split "," | ForEach-Object { [int]$_.Trim() }
            $validIndices = $indices | Where-Object { $_ -ge 1 -and $_ -le $moduleKeys.Count }
            
            if ($validIndices.Count -eq $indices.Count) {
                $selectedModules = $validIndices | ForEach-Object { $moduleKeys[$_ - 1] }
                break
            } else {
                Write-Host "❌ Algunos números están fuera del rango válido" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "❌ Formato inválido. Use números separados por comas" -ForegroundColor Red
        }
    } while ($true)
    
    return $selectedModules
}

function Show-ConfigurationWizard {
    <#
    .SYNOPSIS
        Asistente interactivo para configuración inicial
    #>
    param([hashtable]$DefaultSettings = @{})
    
    $wizardConfig = @{}
    
    Write-Host @"

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              🧙‍♂️ ASISTENTE DE CONFIGURACIÓN 🧙‍♂️               ║
║                                                              ║
║           Configuración personalizada paso a paso           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Magenta
    
    # Pregunta 1: Tipo de usuario
    Write-Host "1️⃣  ¿Cuál describe mejor tu uso principal?" -ForegroundColor Cyan
    Write-Host "   [1] Gaming y entretenimiento" -ForegroundColor White
    Write-Host "   [2] Desarrollo de software" -ForegroundColor White
    Write-Host "   [3] Uso general/oficina" -ForegroundColor White
    Write-Host "   [4] Servidor/laboratorio" -ForegroundColor White
    
    do {
        $userType = Read-Host "Selección (1-4)"
    } while ($userType -notmatch "^[1-4]$")
    
    $wizardConfig.user_type = switch ($userType) {
        "1" { "gaming" }
        "2" { "development" }
        "3" { "general" }
        "4" { "server" }
    }
    
    # Pregunta 2: Características de Windows
    Write-Host "`n2️⃣  ¿Qué características de Windows necesitas?" -ForegroundColor Cyan
    Write-Host "   [Y/N] Hyper-V (virtualización)" -ForegroundColor White
    Write-Host "   [Y/N] WSL (Windows Subsystem for Linux)" -ForegroundColor White
    Write-Host "   [Y/N] Windows Containers" -ForegroundColor White
    
    $wizardConfig.windows_features = @{
        "Microsoft-Hyper-V-All" = (Read-Host "Hyper-V (Y/N)").ToUpper() -eq "Y"
        "Microsoft-Windows-Subsystem-Linux" = (Read-Host "WSL (Y/N)").ToUpper() -eq "Y"
        "Containers" = (Read-Host "Containers (Y/N)").ToUpper() -eq "Y"
    }
    
    # Pregunta 3: Aplicaciones principales
    Write-Host "`n3️⃣  ¿Qué tipo de aplicaciones prefieres?" -ForegroundColor Cyan
    Write-Host "   [1] Paquete mínimo (solo esenciales)" -ForegroundColor White
    Write-Host "   [2] Paquete estándar (navegador, office, multimedia)" -ForegroundColor White
    Write-Host "   [3] Paquete completo (todo incluido)" -ForegroundColor White
    Write-Host "   [4] Personalizado (seleccionar individualmente)" -ForegroundColor White
    
    do {
        $appChoice = Read-Host "Selección (1-4)"
    } while ($appChoice -notmatch "^[1-4]$")
    
    $wizardConfig.application_package = switch ($appChoice) {
        "1" { "minimal" }
        "2" { "standard" }
        "3" { "complete" }
        "4" { "custom" }
    }
    
    # Pregunta 4: Configuración automática
    Write-Host "`n4️⃣  ¿Prefieres configuración automática o manual?" -ForegroundColor Cyan
    Write-Host "   [1] Automática (sin interrupciones)" -ForegroundColor White
    Write-Host "   [2] Semi-automática (confirmaciones importantes)" -ForegroundColor White
    Write-Host "   [3] Manual (confirmar cada paso)" -ForegroundColor White
    
    do {
        $autoChoice = Read-Host "Selección (1-3)"
    } while ($autoChoice -notmatch "^[1-3]$")
    
    $wizardConfig.automation_level = switch ($autoChoice) {
        "1" { "full" }
        "2" { "semi" }
        "3" { "manual" }
    }
    
    # Mostrar resumen
    Write-Host "`n📋 RESUMEN DE CONFIGURACIÓN:" -ForegroundColor Green
    Write-Host "   • Tipo de usuario: $($wizardConfig.user_type)" -ForegroundColor White
    Write-Host "   • Paquete de apps: $($wizardConfig.application_package)" -ForegroundColor White
    Write-Host "   • Nivel de automatización: $($wizardConfig.automation_level)" -ForegroundColor White
    Write-Host "   • Características Windows:" -ForegroundColor White
    
    foreach ($feature in $wizardConfig.windows_features.Keys) {
        $status = if ($wizardConfig.windows_features[$feature]) { "✅" } else { "❌" }
        Write-Host "     $status $feature" -ForegroundColor Gray
    }
    
    $confirm = Read-Host "`n¿Confirmar configuración? (Y/N)"
    if ($confirm.ToUpper() -ne "Y") {
        Write-Host "❌ Configuración cancelada" -ForegroundColor Red
        return $null
    }
    
    return $wizardConfig
}

function Show-SystemStatus {
    <#
    .SYNOPSIS
        Dashboard de estado del sistema con información detallada
    #>
    
    Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    ESTADO DEL SISTEMA                    ║" -ForegroundColor Green
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Green
    
    # Información del sistema
    $os = Get-WmiObject -Class Win32_OperatingSystem
    $computer = Get-WmiObject -Class Win32_ComputerSystem
    $processor = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
    
    Write-Host "║ 💻 Sistema: $($os.Caption)" -ForegroundColor White
    Write-Host "║ 🔧 Versión: $($os.Version) (Build $($os.BuildNumber))" -ForegroundColor White
    Write-Host "║ 🖥️  Equipo: $($computer.Model)" -ForegroundColor White
    Write-Host "║ ⚡ CPU: $($processor.Name)" -ForegroundColor White
    Write-Host "║ 🧠 RAM: $([math]::Round($computer.TotalPhysicalMemory / 1GB, 2)) GB" -ForegroundColor White
    
    # Estado de PowerShell
    Write-Host "║" -ForegroundColor Green
    Write-Host "║ 🔷 PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    Write-Host "║ 🔐 Administrador: $(if(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')){'✅ Sí'}else{'❌ No'})" -ForegroundColor $(if(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')){'Green'}else{'Red'})
    
    # Espacio en disco
    $systemDrive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $env:SystemDrive }
    $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
    $totalSpaceGB = [math]::Round($systemDrive.Size / 1GB, 2)
    $usedPercentage = [math]::Round((($totalSpaceGB - $freeSpaceGB) / $totalSpaceGB) * 100, 1)
    
    Write-Host "║" -ForegroundColor Green
    Write-Host "║ 💾 Disco Sistema: $freeSpaceGB GB libres de $totalSpaceGB GB ($usedPercentage% usado)" -ForegroundColor White
    
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
}

function Show-CompletionSummary {
    <#
    .SYNOPSIS
        Resumen final de configuración con estadísticas
    #>
    param(
        [hashtable]$ExecutionResults,
        [datetime]$StartTime,
        [datetime]$EndTime
    )
    
    $duration = $EndTime - $StartTime
    $totalSteps = $ExecutionResults.Keys.Count
    $successfulSteps = ($ExecutionResults.Values | Where-Object { $_ -eq $true }).Count
    $failedSteps = $totalSteps - $successfulSteps
    
    Write-Host @"

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              🎉 CONFIGURACIÓN COMPLETADA 🎉                 ║
║                                                              ║
║                    ¡Felicitaciones!                         ║
║              Windows 11 está listo para usar                ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  📊 ESTADÍSTICAS:                                           ║
║     • Duración total: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s                        ║
║     • Pasos ejecutados: $totalSteps                                     ║
║     • Exitosos: $successfulSteps                                         ║
║     • Fallidos: $failedSteps                                          ║
║     • Tasa de éxito: $([math]::Round(($successfulSteps / $totalSteps) * 100, 1))%                                    ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green
    
    if ($failedSteps -gt 0) {
        Write-Host "⚠️  Algunos pasos fallaron. Revise los logs para más detalles." -ForegroundColor Yellow
    }
    
    Write-Host "💡 Consejos finales:" -ForegroundColor Cyan
    Write-Host "   • Reinicie el sistema para aplicar todos los cambios" -ForegroundColor White
    Write-Host "   • Verifique Windows Update para actualizaciones pendientes" -ForegroundColor White
    Write-Host "   • Configure sus aplicaciones según sus preferencias" -ForegroundColor White
}

function Initialize-UIHelpersModule {
    <#
    .SYNOPSIS
        Inicializa el módulo de helpers de UI
    #>
    
    if ($script:HasLogging) {
        Write-Log "UI-Helpers v3.0 cargado correctamente" -Level "INFO" -Component "UI-Helpers"
    } else {
        Write-Host "[UI-Helpers] Módulo v3.0 cargado correctamente" -ForegroundColor Green
    }
    
    # Mostrar notificación de módulo cargado
    Show-ModernToastNotification -Title "WinAutoConfigure" -Message "Módulos de interfaz listos" -Type "Info"
    
    return $true
}

function Show-ProgressUpdate {
    param(
        [string]$Activity = "WinAutoConfigure",
        [string]$Status,
        [int]$PercentComplete,
        [int]$Id = 1
    )
    
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete -Id $Id
}

function Show-MenuSelection {
    param(
        [string]$Title,
        [array]$Options,
        [string]$Prompt = "Seleccione una opción"
    )
    
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  $($i + 1). $($Options[$i])" -ForegroundColor White
    }
    
    Write-Host ""
    do {
        $selection = Read-Host $Prompt
        $selectedIndex = [int]$selection - 1
    } while ($selectedIndex -lt 0 -or $selectedIndex -ge $Options.Count)
    
    return $selectedIndex
}

function Show-ConfigurationSummary {
    param(
        [hashtable]$Summary
    )
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║         RESUMEN DE CONFIGURACIÓN     ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    foreach ($item in $Summary.GetEnumerator()) {
        $status = if ($item.Value) { "✓" } else { "✗" }
        $color = if ($item.Value) { "Green" } else { "Red" }
        Write-Host "  $status $($item.Key)" -ForegroundColor $color
    }
    
    Write-Host ""
}
