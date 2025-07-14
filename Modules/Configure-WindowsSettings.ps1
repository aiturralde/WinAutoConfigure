<#
.SYNOPSIS
    Módulo para configurar ajustes básicos de Windows 11
.DESCRIPTION
    Este módulo configura ajustes comunes de Windows 11 como configuración regional, privacidad, y optimizaciones
.NOTES
    Incluye configuraciones de rendimiento, privacidad y personalización
#>

function Initialize-WindowsSettingsModule {
    [CmdletBinding()]
    param()
    
    Write-Log "Iniciando configuración de ajustes de Windows 11..."
    
    # Paso 1: Configurar ajustes regionales
    Set-RegionalSettings
    
    # Paso 2: Configurar privacidad
    Set-PrivacySettings
    
    # Paso 3: Optimizar rendimiento
    Set-PerformanceSettings
    
    # Paso 4: Configurar Explorer
    Set-ExplorerSettings
    
    # Paso 5: Configurar actualizaciones
    Set-UpdateSettings
    
    Write-Log "Configuración de Windows 11 completada"
}

function Set-RegionalSettings {
    Write-Log "Configurando ajustes regionales para Chile..."
    
    try {
        # Configurar zona horaria para Chile (Santiago)
        Set-TimeZone -Id "Pacific SA Standard Time" -ErrorAction SilentlyContinue
        
        # Configurar formato regional para Chile
        Set-Culture -CultureInfo "es-CL"
        
        # Nota: Mantenemos el idioma del sistema como en-US para compatibilidad
        # Si deseas cambiar también el idioma del sistema, descomenta la siguiente línea:
        # Set-WinSystemLocale -SystemLocale "es-CL"
        
        Write-Log "Ajustes regionales configurados para Chile (es-CL)"
    }
    catch {
        Write-Log "Error configurando ajustes regionales: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Set-PrivacySettings {
    Write-Log "Configurando ajustes de privacidad..."
    
    try {
        # Deshabilitar telemetría
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord
        
        # Deshabilitar publicidad personalizada
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord
        
        # Deshabilitar sugerencias de inicio
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord
        
        Write-Log "Ajustes de privacidad configurados"
    }
    catch {
        Write-Log "Error configurando privacidad: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Set-PerformanceSettings {
    Write-Log "Optimizando configuración de rendimiento para máximo performance..."
    
    try {
        # Configurar plan de energía a alto rendimiento
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        
        # Configurar suspensión del sistema (nunca)
        powercfg /change standby-timeout-ac 0
        powercfg /change standby-timeout-dc 0
        
        # Configurar suspensión del monitor (1 hora)
        powercfg /change monitor-timeout-ac 60
        powercfg /change monitor-timeout-dc 60
        
        # Configurar suspensión del disco duro (nunca)
        powercfg /change disk-timeout-ac 0
        powercfg /change disk-timeout-dc 0
        
        # Mantener todos los efectos visuales habilitados para mejor experiencia visual
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 1 -Type DWord
        
        # Configurar archivos de paginación automático
        $cs = Get-WmiObject -Class Win32_ComputerSystem
        if (-not $cs.AutomaticManagedPagefile) {
            $cs.AutomaticManagedPagefile = $true
            $cs.Put()
        }
        
        Write-Log "Optimizaciones de máximo rendimiento aplicadas (PC de altas prestaciones)"
    }
    catch {
        Write-Log "Error optimizando rendimiento: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Set-ExplorerSettings {
    Write-Log "Configurando Windows Explorer..."
    
    try {
        # Mostrar extensiones de archivo
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord
        
        # No mostrar archivos ocultos
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 2 -Type DWord
        
        # Abrir en Este Equipo por defecto
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1 -Type DWord
        
        # Deshabilitar acceso rápido
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowFrequent" -Value 0 -Type DWord
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecent" -Value 0 -Type DWord
        
        Write-Log "Windows Explorer configurado"
    }
    catch {
        Write-Log "Error configurando Explorer: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Set-UpdateSettings {
    Write-Log "Configurando Windows Update..."
    
    try {
        # Configurar actualizaciones para descargar e instalar automáticamente
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "AUOptions" -Value 4 -Type DWord
        
        # Deshabilitar reinicio automático
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord
        
        Write-Log "Windows Update configurado"
    }
    catch {
        Write-Log "Error configurando Windows Update: $($_.Exception.Message)" -Level "WARNING"
    }
}
