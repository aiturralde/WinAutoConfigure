<#
.SYNOPSIS
    Script de utilidades para WinAutoConfigure
.DESCRIPTION
    Proporciona funciones útiles para gestionar y mantener el proyecto WinAutoConfigure
.NOTES
    Incluye funciones para reset, verificación, y limpieza
#>

param(
    [Parameter()]
    [ValidateSet("Reset", "Check", "Clean", "Backup", "Restore", "Help")]
    [string]$Action = "Help"
)

$ScriptPath = $PSScriptRoot
$MainScript = Join-Path $ScriptPath "WinAutoConfigure.ps1"
$LogPath = Join-Path $ScriptPath "Logs"
$ConfigPath = Join-Path $ScriptPath "Config"
$ProgressFile = Join-Path $ScriptPath "progress.txt"

function Show-Help {
    Write-Host "=== WinAutoConfigure - Utilidades ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Uso: .\Utils.ps1 -Action <Acción>" -ForegroundColor Green
    Write-Host ""
    Write-Host "Acciones disponibles:" -ForegroundColor Yellow
    Write-Host "  Reset   - Reinicia el progreso del script principal"
    Write-Host "  Check   - Verifica el estado del sistema y configuración"
    Write-Host "  Clean   - Limpia logs y archivos temporales"
    Write-Host "  Backup  - Crea respaldo de la configuración"
    Write-Host "  Restore - Restaura configuración desde respaldo"
    Write-Host "  Help    - Muestra esta ayuda"
    Write-Host ""
    Write-Host "Ejemplos:" -ForegroundColor Magenta
    Write-Host "  .\Utils.ps1 -Action Reset"
    Write-Host "  .\Utils.ps1 -Action Check"
    Write-Host "  .\Utils.ps1 -Action Clean"
    Write-Host ""
}

function Reset-WinAutoConfigure {
    Write-Host "Reiniciando WinAutoConfigure..." -ForegroundColor Yellow
    
    # Eliminar archivo de progreso
    if (Test-Path $ProgressFile) {
        Remove-Item $ProgressFile -Force
        Write-Host "✓ Archivo de progreso eliminado" -ForegroundColor Green
    }
    
    # Eliminar tarea programada si existe
    $taskName = "WinAutoConfigureContinuation"
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "✓ Tarea programada eliminada" -ForegroundColor Green
    }
    
    Write-Host "WinAutoConfigure reiniciado. Puede ejecutar el script principal nuevamente." -ForegroundColor Cyan
}

function Test-SystemConfiguration {
    Write-Host "=== Verificación del Sistema ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Verificar permisos de administrador
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    Write-Host "Permisos de Administrador: " -NoNewline
    if ($isAdmin) {
        Write-Host "✓ SÍ" -ForegroundColor Green
    } else {
        Write-Host "✗ NO" -ForegroundColor Red
    }
    
    # Verificar versión de PowerShell
    Write-Host "Versión de PowerShell: " -NoNewline
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -ge 5) {
        Write-Host "✓ $psVersion" -ForegroundColor Green
    } else {
        Write-Host "✗ $psVersion (Se requiere 5.1+)" -ForegroundColor Red
    }
    
    # Verificar versión de Windows
    $osInfo = Get-WmiObject -Class Win32_OperatingSystem
    Write-Host "Sistema Operativo: " -NoNewline
    if ($osInfo.Caption -match "Windows 11|Windows 10") {
        Write-Host "✓ $($osInfo.Caption)" -ForegroundColor Green
    } else {
        Write-Host "✗ $($osInfo.Caption) (No soportado)" -ForegroundColor Red
    }
    
    # Verificar Hyper-V
    Write-Host "Estado de Hyper-V: " -NoNewline
    try {
        $hyperVFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
        if ($hyperVFeature.State -eq "Enabled") {
            Write-Host "✓ Instalado" -ForegroundColor Green
        } else {
            Write-Host "✗ No instalado" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ Error verificando" -ForegroundColor Red
    }
    
    # Verificar Windows Terminal
    Write-Host "Windows Terminal: " -NoNewline
    $windowsTerminal = Get-AppxPackage -Name "Microsoft.WindowsTerminal" -ErrorAction SilentlyContinue
    if ($windowsTerminal) {
        Write-Host "✓ Instalado (v$($windowsTerminal.Version))" -ForegroundColor Green
    } else {
        Write-Host "✗ No instalado" -ForegroundColor Yellow
    }
    
    # Verificar winget
    Write-Host "Windows Package Manager (winget): " -NoNewline
    try {
        $wingetVersion = & winget --version 2>$null
        if ($wingetVersion) {
            Write-Host "✓ Disponible ($wingetVersion)" -ForegroundColor Green
        } else {
            Write-Host "✗ No disponible" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ No disponible" -ForegroundColor Yellow
    }
    
    # Verificar archivos del proyecto
    Write-Host ""
    Write-Host "=== Archivos del Proyecto ===" -ForegroundColor Cyan
    
    $projectFiles = @(
        @{ Path = $MainScript; Name = "Script Principal" },
        @{ Path = (Join-Path $ScriptPath "Modules\Setup-WindowsTerminal.ps1"); Name = "Módulo Terminal" },
        @{ Path = (Join-Path $ScriptPath "Modules\Install-Applications.ps1"); Name = "Módulo Aplicaciones" },
        @{ Path = (Join-Path $ScriptPath "Modules\Configure-WindowsSettings.ps1"); Name = "Módulo Configuración Windows" },
        @{ Path = (Join-Path $ScriptPath "Modules\Configure-Gaming.ps1"); Name = "Módulo Gaming" },
        @{ Path = (Join-Path $ScriptPath "Modules\Common-Logging.psm1"); Name = "Módulo Logging" }
    )
    
    foreach ($file in $projectFiles) {
        Write-Host "$($file.Name): " -NoNewline
        if (Test-Path $file.Path) {
            Write-Host "✓ Existe" -ForegroundColor Green
        } else {
            Write-Host "✗ Falta" -ForegroundColor Red
        }
    }
    
    # Verificar progreso actual
    Write-Host ""
    Write-Host "=== Estado Actual ===" -ForegroundColor Cyan
    if (Test-Path $ProgressFile) {
        $currentStep = Get-Content $ProgressFile
        Write-Host "Paso actual: $currentStep" -ForegroundColor Yellow
        
        $taskName = "WinAutoConfigureContinuation"
        if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
            Write-Host "Tarea de continuación: ✓ Configurada" -ForegroundColor Green
        } else {
            Write-Host "Tarea de continuación: ✗ No configurada" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Estado: No iniciado" -ForegroundColor Gray
    }
}

function Clear-ProjectFiles {
    Write-Host "Limpiando archivos temporales..." -ForegroundColor Yellow
    
    $itemsToClean = 0
    
    # Limpiar logs antiguos (más de 30 días)
    if (Test-Path $LogPath) {
        $oldLogs = Get-ChildItem -Path $LogPath -Filter "*.log" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
        if ($oldLogs) {
            $oldLogs | Remove-Item -Force
            $itemsToClean += $oldLogs.Count
            Write-Host "✓ $($oldLogs.Count) logs antiguos eliminados" -ForegroundColor Green
        }
    }
    
    # Limpiar archivos temporales de fuentes
    $tempFontsPath = Join-Path $env:TEMP "TerminalFonts"
    if (Test-Path $tempFontsPath) {
        Remove-Item -Path $tempFontsPath -Recurse -Force -ErrorAction SilentlyContinue
        $itemsToClean++
        Write-Host "✓ Archivos temporales de fuentes eliminados" -ForegroundColor Green
    }
    
    # Limpiar backups antiguos de configuración (más de 7 días)
    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
    if (Test-Path $settingsPath) {
        $oldBackups = Get-ChildItem -Path $settingsPath -Filter "settings.json.backup_*" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
        if ($oldBackups) {
            $oldBackups | Remove-Item -Force
            $itemsToClean += $oldBackups.Count
            Write-Host "✓ $($oldBackups.Count) backups antiguos de terminal eliminados" -ForegroundColor Green
        }
    }
    
    if ($itemsToClean -eq 0) {
        Write-Host "✓ No hay archivos para limpiar" -ForegroundColor Gray
    } else {
        Write-Host "✓ Limpieza completada ($itemsToClean elementos)" -ForegroundColor Cyan
    }
}

function New-ConfigurationBackup {
    Write-Host "Creando respaldo de configuración..." -ForegroundColor Yellow
    
    $backupPath = Join-Path $ScriptPath "Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
    
    # Respaldar archivos de configuración
    if (Test-Path $ConfigPath) {
        Copy-Item -Path $ConfigPath -Destination (Join-Path $backupPath "Config") -Recurse -Force
        Write-Host "✓ Configuración respaldada" -ForegroundColor Green
    }
    
    # Respaldar configuración de Windows Terminal si existe
    $terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path $terminalSettingsPath) {
        $terminalBackupDir = Join-Path $backupPath "Terminal"
        New-Item -Path $terminalBackupDir -ItemType Directory -Force | Out-Null
        Copy-Item -Path $terminalSettingsPath -Destination (Join-Path $terminalBackupDir "settings.json") -Force
        Write-Host "✓ Configuración de Terminal respaldada" -ForegroundColor Green
    }
    
    # Respaldar perfil de PowerShell si existe
    $profilePath = $PROFILE.AllUsersAllHosts
    if (Test-Path $profilePath) {
        $profileBackupDir = Join-Path $backupPath "PowerShell"
        New-Item -Path $profileBackupDir -ItemType Directory -Force | Out-Null
        Copy-Item -Path $profilePath -Destination (Join-Path $profileBackupDir "Microsoft.PowerShell_profile.ps1") -Force
        Write-Host "✓ Perfil de PowerShell respaldado" -ForegroundColor Green
    }
    
    Write-Host "✓ Respaldo completado en: $backupPath" -ForegroundColor Cyan
}

function Restore-ConfigurationBackup {
    Write-Host "Restaurando configuración desde respaldo..." -ForegroundColor Yellow
    
    # Buscar carpetas de respaldo
    $backupFolders = Get-ChildItem -Path $ScriptPath -Filter "Backup_*" -Directory | Sort-Object Name -Descending
    
    if (-not $backupFolders) {
        Write-Host "✗ No se encontraron respaldos" -ForegroundColor Red
        return
    }
    
    Write-Host "Respaldos disponibles:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $backupFolders.Count; $i++) {
        Write-Host "  $($i + 1). $($backupFolders[$i].Name)" -ForegroundColor White
    }
    
    $selection = Read-Host "Seleccione el número de respaldo a restaurar (1-$($backupFolders.Count))"
    
    try {
        $selectedIndex = [int]$selection - 1
        if ($selectedIndex -lt 0 -or $selectedIndex -ge $backupFolders.Count) {
            Write-Host "✗ Selección inválida" -ForegroundColor Red
            return
        }
        
        $backupToRestore = $backupFolders[$selectedIndex]
        Write-Host "Restaurando desde: $($backupToRestore.Name)" -ForegroundColor Yellow
        
        # Restaurar configuración
        $configBackup = Join-Path $backupToRestore.FullName "Config"
        if (Test-Path $configBackup) {
            if (Test-Path $ConfigPath) {
                Remove-Item -Path $ConfigPath -Recurse -Force
            }
            Copy-Item -Path $configBackup -Destination $ConfigPath -Recurse -Force
            Write-Host "✓ Configuración restaurada" -ForegroundColor Green
        }
        
        Write-Host "✓ Restauración completada" -ForegroundColor Cyan
    }
    catch {
        Write-Host "✗ Error en la selección: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Ejecutar acción seleccionada
switch ($Action) {
    "Reset" { Reset-WinAutoConfigure }
    "Check" { Test-SystemConfiguration }
    "Clean" { Clear-ProjectFiles }
    "Backup" { New-ConfigurationBackup }
    "Restore" { Restore-ConfigurationBackup }
    "Help" { Show-Help }
    default { Show-Help }
}
