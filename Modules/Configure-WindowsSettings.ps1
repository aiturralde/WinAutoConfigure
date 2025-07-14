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
    
    # Paso 0: Instalar módulos de PowerShell necesarios
    Install-PowerShellModules
    
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
    return $true
}

function Install-PowerShellModules {
    Write-Log "Instalando módulos de PowerShell necesarios..."
    
    try {
        # Paso 1: Actualizar PowerShellGet para evitar problemas de instalación
        Write-Log "Verificando y actualizando PowerShellGet..."
        $PowerShellGetVersion = Get-Module -ListAvailable -Name PowerShellGet | Sort-Object Version -Descending | Select-Object -First 1
        Write-Log "PowerShellGet actual: $($PowerShellGetVersion.Version)"
        
        try {
            # Intentar actualizar PowerShellGet si es necesario
            $LatestPSGet = Find-Module -Name PowerShellGet -ErrorAction SilentlyContinue
            if ($LatestPSGet -and $LatestPSGet.Version -gt $PowerShellGetVersion.Version) {
                Write-Log "Actualizando PowerShellGet a versión $($LatestPSGet.Version)..."
                Install-Module -Name PowerShellGet -Force -AllowClobber -Scope CurrentUser -ErrorAction SilentlyContinue
                Write-Log "PowerShellGet actualizado correctamente"
            }
        }
        catch {
            Write-Log "No se pudo actualizar PowerShellGet, continuando con versión actual: $($_.Exception.Message)" -Level "WARNING"
        }
        
        # Paso 2: Verificar y configurar repositorio PSGallery
        Write-Log "Verificando repositorio PSGallery..."
        try {
            $PSGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
            if (-not $PSGallery) {
                Write-Log "Registrando repositorio PSGallery..."
                Register-PSRepository -Default -ErrorAction Stop
                Write-Log "Repositorio PSGallery registrado correctamente"
            } else {
                Write-Log "Repositorio PSGallery ya está registrado"
                if ($PSGallery.InstallationPolicy -ne "Trusted") {
                    Write-Log "Configurando PSGallery como repositorio confiable..."
                    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
                }
            }
        }
        catch {
            Write-Log "Error configurando PSGallery: $($_.Exception.Message)" -Level "WARNING"
            Write-Log "Continuando con configuración estándar de repositorios..."
        }
        
        # Paso 3: Lista de módulos requeridos por el perfil de PowerShell
        $RequiredModules = @(
            "Terminal-Icons",
            "PSReadLine"
        )
        
        foreach ($Module in $RequiredModules) {
            Write-Log "Verificando módulo: $Module"
            
            # Verificar si el módulo ya está instalado
            $InstalledModule = Get-Module -ListAvailable -Name $Module
            
            if (-not $InstalledModule) {
                Write-Log "Instalando módulo: $Module"
                
                # Intentar instalación con reintentos
                $MaxRetries = 3
                $RetryCount = 0
                $InstallSuccess = $false
                
                while ($RetryCount -lt $MaxRetries -and -not $InstallSuccess) {
                    try {
                        $RetryCount++
                        Write-Log "Intento $RetryCount de $MaxRetries para instalar $Module"
                        
                        # Intentar instalación con diferentes estrategias
                        if ($Module -eq "Terminal-Icons") {
                            # Primero intentar con PSGallery explícito
                            try {
                                Write-Log "Intentando instalar $Module desde PSGallery..."
                                Install-Module -Name $Module -Repository PSGallery -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
                            }
                            catch {
                                Write-Log "Fallo instalación desde PSGallery, intentando instalación estándar: $($_.Exception.Message)" -Level "WARNING"
                                Install-Module -Name $Module -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
                            }
                        } else {
                            Install-Module -Name $Module -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
                        }
                        
                        # Verificar que se instaló correctamente
                        $VerifyModule = Get-Module -ListAvailable -Name $Module
                        if ($VerifyModule) {
                            Write-Log "Módulo $Module instalado correctamente (Versión: $($VerifyModule.Version))"
                            $InstallSuccess = $true
                        }
                    }
                    catch {
                        Write-Log "Error en intento $RetryCount para $Module : $($_.Exception.Message)" -Level "WARNING"
                        if ($RetryCount -lt $MaxRetries) {
                            Write-Log "Reintentando en 2 segundos..."
                            Start-Sleep -Seconds 2
                        }
                    }
                }
                
                if (-not $InstallSuccess) {
                    Write-Log "No se pudo instalar el módulo $Module después de $MaxRetries intentos" -Level "ERROR"
                    throw "Error crítico: No se pudo instalar $Module"
                }
            } else {
                Write-Log "Módulo $Module ya está instalado (Versión: $($InstalledModule.Version))"
            }
        }
        
        # Verificar oh-my-posh (se instala como aplicación, no como módulo)
        $OhMyPoshPath = "$env:LOCALAPPDATA\Programs\oh-my-posh\oh-my-posh.exe"
        if (-not (Test-Path $OhMyPoshPath)) {
            Write-Log "oh-my-posh no encontrado. Se instalará con las aplicaciones en el paso correspondiente."
        } else {
            Write-Log "oh-my-posh ya está instalado"
        }
        
        Write-Log "Instalación de módulos de PowerShell completada"
    }
    catch {
        Write-Log "Error al instalar módulos de PowerShell: $_" -Level "ERROR"
        throw
    }
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
        try {
            $cs = Get-WmiObject -Class Win32_ComputerSystem
            if (-not $cs.AutomaticManagedPagefile) {
                $cs.AutomaticManagedPagefile = $true
                $cs.Put()
                Write-Log "Archivo de paginación configurado a automático"
            } else {
                Write-Log "Archivo de paginación ya está configurado como automático"
            }
        }
        catch {
            Write-Log "No se pudo configurar el archivo de paginación automático: $($_.Exception.Message)" -Level "WARNING"
            Write-Log "Esta configuración se puede ajustar manualmente en Configuración del sistema > Rendimiento > Memoria virtual" -Level "INFO"
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
