<#
.SYNOPSIS
    Configuración optimizada para gaming en Windows 11
.DESCRIPTION
    Este módulo optimiza Windows 11 para obtener el máximo rendimiento en gaming usando manejo estandarizado de errores
.NOTES
    Versión: 3.0 - Refactorizado con Common-ErrorHandling y Common-Configuration
    Autor: WinAutoConfigure Team
    Requiere: Windows 11, PowerShell 5.1+, Permisos de administrador
#>

# Importar módulos necesarios usando rutas absolutas
$ModulesPath = Split-Path $PSScriptRoot -Parent | Join-Path -ChildPath "Modules"
Import-Module (Join-Path $ModulesPath "Common-ErrorHandling.psm1") -Force -Global
Import-Module (Join-Path $ModulesPath "Common-Configuration.psm1") -Force -Global

# Asegurar que el enum ErrorSeverity esté disponible
if (-not ([System.Management.Automation.PSTypeName]'ErrorSeverity').Type) {
    Add-Type -TypeDefinition @"
        public enum ErrorSeverity {
            Low = 1,
            Medium = 2,
            High = 3,
            Critical = 4
        }
"@
}

function Initialize-GamingModule {
    <#
    .SYNOPSIS
        Inicializa el módulo de configuración gaming
    #>
    [CmdletBinding()]
    param()
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Iniciando configuración gaming optimizada..." -Component "Gaming"
        
        # Inicializar Configuration Manager
        $ConfigPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Config"
        Initialize-ConfigurationManager -ConfigRootPath $ConfigPath
        
        # Cargar configuración para validar
        $Config = Get-ConfigurationSafe -ConfigName "gaming-config"
        if (-not $Config) {
            throw "No se pudo cargar la configuración gaming"
        }
        
        # Validaciones previas
        if ($Config.settings.validate_admin_rights) {
            if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
                throw "Se requieren permisos de administrador para ejecutar este módulo"
            }
        }
        
        if ($Config.settings.validate_windows_version) {
            $osInfo = Get-WmiObject -Class Win32_OperatingSystem
            $version = [Version]$osInfo.Version
            if ($version.Major -lt 10 -or ($version.Major -eq 10 -and $version.Build -lt 22000)) {
                Write-Log "Este módulo está optimizado para Windows 11 (detectado: $($osInfo.Caption))" -Level "WARNING" -Component "Gaming"
            }
        }
        
        Write-Log "Módulo de gaming inicializado correctamente" -Component "Gaming" -Level "SUCCESS"
        return $true
        
    } -Operation "Inicializar configuración gaming" -Component "Gaming" -Severity ([ErrorSeverity]::High)
}

function Set-GameMode {
    <#
    .SYNOPSIS
        Configura Windows Game Mode y optimizaciones gaming
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Configurando Windows Game Mode..." -Component "GameMode"
        
        $configuredItems = 0
        
        # Habilitar Game Mode si está configurado
        if ($Config.auto_game_mode) {
            $gameModePath = "HKCU:\SOFTWARE\Microsoft\GameBar"
            if (-not (Test-Path $gameModePath)) {
                New-Item -Path $gameModePath -Force | Out-Null
            }
            
            Set-ItemProperty -Path $gameModePath -Name "AllowAutoGameMode" -Value 1 -Type DWord
            Set-ItemProperty -Path $gameModePath -Name "AutoGameModeEnabled" -Value 1 -Type DWord
            Write-Log "Auto Game Mode habilitado" -Component "GameMode"
            $configuredItems++
        }
        
        # Configurar Game DVR
        if ($Config.disable_game_dvr) {
            $systemGameModePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
            if (-not (Test-Path $systemGameModePath)) {
                New-Item -Path $systemGameModePath -Force | Out-Null
            }
            
            Set-ItemProperty -Path $systemGameModePath -Name "GameDVR_Enabled" -Value 0 -Type DWord
            Set-ItemProperty -Path $systemGameModePath -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord
            Set-ItemProperty -Path $systemGameModePath -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1 -Type DWord
            Set-ItemProperty -Path $systemGameModePath -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1 -Type DWord
            Set-ItemProperty -Path $systemGameModePath -Name "GameDVR_EFSEFeatureFlags" -Value 0 -Type DWord
            Write-Log "Game DVR deshabilitado para mejor rendimiento" -Component "GameMode"
            $configuredItems++
        }
        
        # Optimizaciones fullscreen
        if ($Config.fullscreen_optimizations) {
            $fullscreenPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
            Set-ItemProperty -Path $fullscreenPath -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord -ErrorAction SilentlyContinue
            Write-Log "Optimizaciones fullscreen configuradas" -Component "GameMode"
            $configuredItems++
        }
        
        Write-Log "Windows Game Mode configurado exitosamente ($configuredItems configuraciones aplicadas)" -Component "GameMode" -Level "SUCCESS"
        return $true
        
    } -Operation "Configurar Windows Game Mode" -Component "GameMode" -Severity ([ErrorSeverity]::Medium)
}

function Set-GameBar {
    <#
    .SYNOPSIS
        Configura Xbox Game Bar según preferencias
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Configurando Xbox Game Bar..." -Component "GameBar"
        
        $configuredItems = 0
        
        if ($Config.disable_completely) {
            # Deshabilitar Game Bar completamente
            $gameBarPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
            Set-ItemProperty -Path $gameBarPath -Name "AppCaptureEnabled" -Value 0 -Type DWord
            
            $gameBarPath2 = "HKCU:\SOFTWARE\Microsoft\GameBar"
            Set-ItemProperty -Path $gameBarPath2 -Name "UseNexusForGameBarEnabled" -Value 0 -Type DWord
            
            Write-Log "Xbox Game Bar deshabilitado completamente" -Component "GameBar"
            $configuredItems++
        } else {
            # Optimizar Game Bar (mantenerlo habilitado pero optimizado)
            $gameBarPath = "HKCU:\SOFTWARE\Microsoft\GameBar"
            
            if ($Config.disable_startup_panel) {
                Set-ItemProperty -Path $gameBarPath -Name "ShowStartupPanel" -Value 0 -Type DWord
                Write-Log "Panel de inicio de Game Bar deshabilitado" -Component "GameBar"
                $configuredItems++
            }
            
            if ($Config.disable_notifications) {
                Set-ItemProperty -Path $gameBarPath -Name "ShowGameModeNotifications" -Value 0 -Type DWord
                Write-Log "Notificaciones de Game Bar deshabilitadas" -Component "GameBar"
                $configuredItems++
            }
            
            if ($Config.disable_tips) {
                Set-ItemProperty -Path $gameBarPath -Name "GamePanelStartupTipIndex" -Value 3 -Type DWord
                Write-Log "Tips de Game Bar deshabilitados" -Component "GameBar"
                $configuredItems++
            }
        }
        
        # Deshabilitar notificaciones específicas
        if ($Config.disable_notifications) {
            $notificationsPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Microsoft.XboxGamingOverlay_8wekyb3d8bbwe!App"
            if (-not (Test-Path $notificationsPath)) {
                New-Item -Path $notificationsPath -Force | Out-Null
            }
            Set-ItemProperty -Path $notificationsPath -Name "Enabled" -Value 0 -Type DWord
            $configuredItems++
        }
        
        Write-Log "Xbox Game Bar configurado exitosamente ($configuredItems configuraciones aplicadas)" -Component "GameBar" -Level "SUCCESS"
        return $true
        
    } -Operation "Configurar Xbox Game Bar" -Component "GameBar" -Severity ([ErrorSeverity]::Low)
}

function Set-HardwareAcceleration {
    <#
    .SYNOPSIS
        Configura aceleración de hardware para optimizar rendimiento de juegos
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Configurando aceleración de hardware..." -Component "HardwareAcceleration"
        
        $configuredItems = 0
        
        # Configurar aceleración de GPU
        if ($Config.enable_gpu_scheduling) {
            $schedulingPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
            Set-ItemProperty -Path $schedulingPath -Name "HwSchMode" -Value 2 -Type DWord
            Write-Log "Hardware-accelerated GPU scheduling habilitado" -Component "HardwareAcceleration"
            $configuredItems++
        }
        
        # Configurar DirectX optimizations
        if ($Config.enable_directx_optimizations) {
            $directXPath = "HKCU:\SOFTWARE\Microsoft\DirectX\UserGpuPreferences"
            if (-not (Test-Path $directXPath)) {
                New-Item -Path $directXPath -Force | Out-Null
            }
            
            # Configurar preferencia de GPU de alto rendimiento por defecto
            $appsPath = "HKCU:\SOFTWARE\Microsoft\DirectX\UserGpuPreferences"
            Set-ItemProperty -Path $appsPath -Name "DirectXUserGlobalSettings" -Value "GpuPreference=2;" -Type String
            Write-Log "Optimizaciones DirectX configuradas" -Component "HardwareAcceleration"
            $configuredItems++
        }
        
        # Configurar optimizaciones de VRAM
        if ($Config.optimize_vram_usage) {
            $vramPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
            Set-ItemProperty -Path $vramPath -Name "TdrLevel" -Value 0 -Type DWord
            Set-ItemProperty -Path $vramPath -Name "TdrDelay" -Value 60 -Type DWord
            Write-Log "Optimizaciones de VRAM configuradas" -Component "HardwareAcceleration"
            $configuredItems++
        }
        
        # Configurar optimizaciones de CPU
        if ($Config.enable_cpu_optimizations) {
            $cpuPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
            Set-ItemProperty -Path $cpuPath -Name "Win32PrioritySeparation" -Value 38 -Type DWord
            Write-Log "Optimizaciones de CPU para juegos configuradas" -Component "HardwareAcceleration"
            $configuredItems++
        }
        
        # Configurar optimizaciones de memoria
        if ($Config.optimize_memory_management) {
            $memoryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
            Set-ItemProperty -Path $memoryPath -Name "LargeSystemCache" -Value 0 -Type DWord
            Set-ItemProperty -Path $memoryPath -Name "DisablePagingExecutive" -Value 1 -Type DWord
            Write-Log "Gestión de memoria optimizada para juegos" -Component "HardwareAcceleration"
            $configuredItems++
        }
        
        Write-Log "Aceleración de hardware configurada exitosamente ($configuredItems optimizaciones aplicadas)" -Component "HardwareAcceleration" -Level "SUCCESS"
        return $true
        
    } -Operation "Configurar aceleración de hardware" -Component "HardwareAcceleration" -Severity ([ErrorSeverity]::Medium)
}

function Set-PerformanceOptimizations {
    <#
    .SYNOPSIS
        Aplica optimizaciones de rendimiento específicas para gaming
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Aplicando optimizaciones de rendimiento gaming..." -Component "PerformanceOptimizations"
        
        $configuredItems = 0
        
        # Optimizaciones de búsqueda de Windows
        if ($Config.disable_windows_search_during_gaming) {
            $searchPath = "HKLM:\SOFTWARE\Microsoft\Windows Search\Gathering Manager"
            if (Test-Path $searchPath) {
                Set-ItemProperty -Path $searchPath -Name "DisableBackOff" -Value 1 -Type DWord
                Write-Log "Windows Search optimizado para gaming" -Component "PerformanceOptimizations"
                $configuredItems++
            }
        }
        
        # Optimizaciones de memoria
        if ($Config.optimize_memory_settings) {
            $memoryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
            Set-ItemProperty -Path $memoryPath -Name "LargeSystemCache" -Value 0 -Type DWord
            Set-ItemProperty -Path $memoryPath -Name "DisablePagingExecutive" -Value 1 -Type DWord
            Write-Log "Configuración de memoria optimizada" -Component "PerformanceOptimizations"
            $configuredItems++
        }
        
        # Optimizaciones del Multimedia Class Scheduler Service
        if ($Config.optimize_mmcss) {
            $mmcssPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
            Set-ItemProperty -Path $mmcssPath -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord
            Set-ItemProperty -Path $mmcssPath -Name "SystemResponsiveness" -Value 0 -Type DWord
            Write-Log "MMCSS optimizado para gaming" -Component "PerformanceOptimizations"
            $configuredItems++
        }
        
        # Prioridades de tareas de gaming
        if ($Config.set_gaming_task_priorities) {
            $mmcssPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
            $gamesPath = "$mmcssPath\Tasks\Games"
            if (-not (Test-Path $gamesPath)) {
                New-Item -Path $gamesPath -Force | Out-Null
            }
            Set-ItemProperty -Path $gamesPath -Name "GPU Priority" -Value 8 -Type DWord
            Set-ItemProperty -Path $gamesPath -Name "Priority" -Value 6 -Type DWord
            Set-ItemProperty -Path $gamesPath -Name "Scheduling Category" -Value "High" -Type String
            Set-ItemProperty -Path $gamesPath -Name "SFIO Priority" -Value "High" -Type String
            Write-Log "Prioridades de tareas de gaming configuradas" -Component "PerformanceOptimizations"
            $configuredItems++
        }
        
        # Optimizaciones de servicios
        if ($Config.optimize_services) {
            # Deshabilitar servicios innecesarios durante gaming
            $servicesToOptimize = @(
                @{Name = "Fax"; StartupType = "Disabled"},
                @{Name = "Spooler"; StartupType = "Manual"},
                @{Name = "TabletInputService"; StartupType = "Manual"}
            )
            
            foreach ($service in $servicesToOptimize) {
                try {
                    Set-Service -Name $service.Name -StartupType $service.StartupType -ErrorAction SilentlyContinue
                    Write-Log "Servicio $($service.Name) configurado como $($service.StartupType)" -Component "PerformanceOptimizations"
                } catch {
                    Write-Log "No se pudo configurar el servicio $($service.Name)" -Component "PerformanceOptimizations" -Level "WARNING"
                }
            }
            $configuredItems++
        }
        
        Write-Log "Optimizaciones de rendimiento aplicadas exitosamente ($configuredItems optimizaciones aplicadas)" -Component "PerformanceOptimizations" -Level "SUCCESS"
        return $true
        
    } -Operation "Aplicar optimizaciones de rendimiento" -Component "PerformanceOptimizations" -Severity ([ErrorSeverity]::Low)
}

function Set-NetworkOptimizations {
    <#
    .SYNOPSIS
        Optimiza configuraciones de red para gaming
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Optimizando configuraciones de red para gaming..." -Component "NetworkOptimizations"
        
        $configuredItems = 0
        
        # Optimizaciones TCP para gaming
        if ($Config.optimize_tcp_settings) {
            $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            Set-ItemProperty -Path $tcpPath -Name "TcpAckFrequency" -Value 1 -Type DWord
            Set-ItemProperty -Path $tcpPath -Name "TCPNoDelay" -Value 1 -Type DWord
            Set-ItemProperty -Path $tcpPath -Name "TcpDelAckTicks" -Value 0 -Type DWord
            Write-Log "Configuraciones TCP optimizadas para gaming" -Component "NetworkOptimizations"
            $configuredItems++
        }
        
        # Optimizaciones de adaptadores de red
        if ($Config.optimize_network_adapters) {
            $netPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
            $adaptorsOptimized = 0
            Get-ChildItem $netPath | ForEach-Object {
                if (Get-ItemProperty -Path $_.PSPath -Name "DhcpIPAddress" -ErrorAction SilentlyContinue) {
                    Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $_.PSPath -Name "TcpDelAckTicks" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                    $adaptorsOptimized++
                }
            }
            Write-Log "Adaptadores de red optimizados ($adaptorsOptimized adaptadores)" -Component "NetworkOptimizations"
            $configuredItems++
        }
        
        # Deshabilitar algoritmo de Nagle para gaming
        if ($Config.disable_nagle_algorithm) {
            $naglePath = "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters"
            if (Test-Path $naglePath) {
                Set-ItemProperty -Path $naglePath -Name "TCPNoDelay" -Value 1 -Type DWord
                Write-Log "Algoritmo de Nagle deshabilitado para gaming" -Component "NetworkOptimizations"
                $configuredItems++
            }
        }
        
        # Optimizaciones de QoS
        if ($Config.optimize_qos_settings) {
            $qosPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
            if (-not (Test-Path $qosPath)) {
                New-Item -Path $qosPath -Force | Out-Null
            }
            Set-ItemProperty -Path $qosPath -Name "NonBestEffortLimit" -Value 0 -Type DWord
            Write-Log "Configuraciones QoS optimizadas" -Component "NetworkOptimizations"
            $configuredItems++
        }
        
        # Optimizaciones de latencia de red
        if ($Config.reduce_network_latency) {
            $latencyPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
            Set-ItemProperty -Path $latencyPath -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord
            Write-Log "Configuraciones de latencia de red optimizadas" -Component "NetworkOptimizations"
            $configuredItems++
        }
        
        Write-Log "Optimizaciones de red aplicadas exitosamente ($configuredItems optimizaciones aplicadas)" -Component "NetworkOptimizations" -Level "SUCCESS"
        return $true
        
    } -Operation "Optimizar configuraciones de red" -Component "NetworkOptimizations" -Severity ([ErrorSeverity]::Low)
}

function Set-PowerOptimizations {
    <#
    .SYNOPSIS
        Configura el plan de energía para máximo rendimiento gaming
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Configurando plan de energía para gaming..." -Component "PowerOptimizations"
        
        $configuredItems = 0
        
        # Crear y configurar plan de energía para gaming
        if ($Config.create_gaming_power_plan) {
            $gamingPlan = powercfg /list | Select-String "Gaming Performance"
            
            if (-not $gamingPlan) {
                # Duplicar plan de alto rendimiento
                $highPerfLine = powercfg /list | Select-String "Alto rendimiento|High performance"
                if ($highPerfLine) {
                    $highPerfGuid = $highPerfLine.ToString().Split()[3]
                    if ($highPerfGuid) {
                        try {
                            $result = powercfg /duplicatescheme $highPerfGuid
                            $newGuidLine = $result | Select-String "GUID"
                            if ($newGuidLine) {
                                $newGuid = $newGuidLine.ToString().Split()[-1]
                                powercfg /changename $newGuid "Gaming Performance" "Optimized for maximum gaming performance"
                                
                                if ($Config.activate_gaming_plan) {
                                    powercfg /setactive $newGuid
                                }
                                
                                Write-Log "Plan de energía Gaming Performance creado" -Component "PowerOptimizations"
                                $configuredItems++
                            } else {
                                Write-Log "No se pudo obtener GUID del nuevo plan de energía" -Component "PowerOptimizations" -Level "WARNING"
                            }
                        } catch {
                            Write-Log "Error creando plan de energía personalizado: $($_.Exception.Message)" -Component "PowerOptimizations" -Level "WARNING"
                        }
                    } else {
                        Write-Log "No se pudo obtener GUID del plan de alto rendimiento" -Component "PowerOptimizations" -Level "WARNING"
                    }
                } else {
                    Write-Log "Plan de alto rendimiento no encontrado" -Component "PowerOptimizations" -Level "WARNING"
                }
            } else {
                Write-Log "Plan de energía Gaming Performance ya existe" -Component "PowerOptimizations"
                $configuredItems++
            }
        }
        
        # Configuraciones específicas de energía
        if ($Config.disable_power_throttling) {
            # Deshabilitar limitación de energía
            powercfg /change disk-timeout-ac 0
            powercfg /change disk-timeout-dc 0
            powercfg /change standby-timeout-ac 0
            powercfg /change standby-timeout-dc 0
            powercfg /change hibernate-timeout-ac 0
            powercfg /change hibernate-timeout-dc 0
            Write-Log "Limitación de energía deshabilitada" -Component "PowerOptimizations"
            $configuredItems++
        }
        
        # Optimizaciones de USB
        if ($Config.disable_usb_selective_suspend) {
            $usbPath = "HKLM:\SYSTEM\CurrentControlSet\Services\USB"
            Set-ItemProperty -Path $usbPath -Name "DisableSelectiveSuspend" -Value 1 -Type DWord -ErrorAction SilentlyContinue
            Write-Log "Suspensión selectiva USB deshabilitada" -Component "PowerOptimizations"
            $configuredItems++
        }
        
        # Configurar procesador para máximo rendimiento
        if ($Config.set_maximum_processor_state) {
            # Configurar estado mínimo y máximo del procesador al 100%
            powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100
            powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100
            powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100
            powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100
            Write-Log "Procesador configurado para máximo rendimiento" -Component "PowerOptimizations"
            $configuredItems++
        }
        
        Write-Log "Optimizaciones de energía aplicadas exitosamente ($configuredItems optimizaciones aplicadas)" -Component "PowerOptimizations" -Level "SUCCESS"
        return $true
        
    } -Operation "Configurar optimizaciones de energía" -Component "PowerOptimizations" -Severity ([ErrorSeverity]::Low)
}

function Set-GameCompatibility {
    <#
    .SYNOPSIS
        Configura compatibilidad para juegos legacy y modernos
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Configurando compatibilidad de juegos..." -Component "GameCompatibility"
        
        $configuredItems = 0
        
        # Habilitar DirectPlay para juegos legacy
        if ($Config.enable_directplay) {
            Enable-WindowsOptionalFeature -Online -FeatureName "DirectPlay" -All -NoRestart -ErrorAction SilentlyContinue
            Write-Log "DirectPlay habilitado para juegos legacy" -Component "GameCompatibility"
            $configuredItems++
        }
        
        # Habilitar .NET Framework 3.5
        if ($Config.enable_netfx3) {
            Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" -All -NoRestart -ErrorAction SilentlyContinue
            Write-Log ".NET Framework 3.5 habilitado" -Component "GameCompatibility"
            $configuredItems++
        }
        
        # Configurar DirectX legacy
        if ($Config.configure_legacy_directx) {
            $dxPath = "HKLM:\SOFTWARE\Microsoft\DirectX"
            if (-not (Test-Path $dxPath)) {
                New-Item -Path $dxPath -Force | Out-Null
            }
            Set-ItemProperty -Path $dxPath -Name "DisableAGPSupport" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Write-Log "DirectX legacy configurado" -Component "GameCompatibility"
            $configuredItems++
        }
        
        # Configurar exclusiones de Windows Defender para gaming
        if ($Config.configure_defender_exclusions) {
            $gamingFolders = @(
                "$env:ProgramFiles\Steam",
                "$env:ProgramFiles(x86)\Steam",
                "$env:ProgramFiles\Epic Games",
                "$env:LOCALAPPDATA\Programs\Epic Games",
                "$env:ProgramFiles\Origin Games",
                "$env:ProgramFiles(x86)\Origin Games",
                "$env:ProgramFiles\Ubisoft",
                "$env:ProgramFiles(x86)\Ubisoft"
            )
            
            $exclusionsAdded = 0
            foreach ($folder in $gamingFolders) {
                if (Test-Path $folder) {
                    try {
                        Add-MpPreference -ExclusionPath $folder -ErrorAction SilentlyContinue
                        Write-Log "Exclusión agregada para: $folder" -Component "GameCompatibility"
                        $exclusionsAdded++
                    }
                    catch {
                        Write-Log "No se pudo agregar exclusión para: $folder" -Component "GameCompatibility" -Level "WARNING"
                    }
                }
            }
            
            if ($exclusionsAdded -gt 0) {
                Write-Log "Configuradas $exclusionsAdded exclusiones de Defender para gaming" -Component "GameCompatibility"
                $configuredItems++
            }
        }
        
        # Configurar compatibilidad con juegos de 32 bits
        if ($Config.enable_32bit_compatibility) {
            $wow64Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
            # Configuraciones específicas para mejorar compatibilidad con juegos de 32 bits
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\SubSystems" -Name "Optional" -Value "Posix" -Type String -ErrorAction SilentlyContinue
            Write-Log "Compatibilidad con aplicaciones de 32 bits optimizada" -Component "GameCompatibility"
            $configuredItems++
        }
        
        Write-Log "Compatibilidad de juegos configurada exitosamente ($configuredItems configuraciones aplicadas)" -Component "GameCompatibility" -Level "SUCCESS"
        return $true
        
    } -Operation "Configurar compatibilidad de juegos" -Component "GameCompatibility" -Severity ([ErrorSeverity]::Low)
}

# ==========================================
# FUNCIÓN PRINCIPAL
# ==========================================

function Start-GamingConfiguration {
    <#
    .SYNOPSIS
        Función principal que ejecuta toda la configuración gaming
    #>
    
    # Inicializar configuración
    $initResult = Initialize-GamingModule
    if (-not $initResult) {
        Write-Log "Error inicializando módulo de gaming" -Level "ERROR" -Component "Gaming"
        return $false
    }
    
    return Invoke-WithErrorHandling -Action {
        Write-LogSection "CONFIGURACIÓN GAMING" -Component "Gaming"
        Write-Log "Optimizando Windows 11 para máximo rendimiento gaming..." -Component "Gaming"
        
        # Obtener configuración
        $config = Get-ConfigurationSafe -ConfigName "gaming-config"
        if (-not $config) {
            throw "No se pudo cargar la configuración de gaming"
        }
        
        $results = @{
            GameMode = $false
            GameBar = $false
            HardwareAcceleration = $false
            PerformanceOptimizations = $false
            NetworkOptimizations = $false
            PowerOptimizations = $false
            GameCompatibility = $false
        }
        
        # Ejecutar configuraciones según esté habilitado en config
        if ($config.game_mode.enabled) {
            Write-Log "Ejecutando configuración: Game Mode" -Component "Gaming"
            $results.GameMode = Set-GameMode -Config $config.game_mode
        } else {
            Write-Log "Configuración Game Mode omitida (deshabilitada en configuración)" -Component "Gaming"
            $results.GameMode = $true
        }
        
        if ($config.game_bar.enabled) {
            Write-Log "Ejecutando configuración: Game Bar" -Component "Gaming"
            $results.GameBar = Set-GameBar -Config $config.game_bar
        } else {
            Write-Log "Configuración Game Bar omitida (deshabilitada en configuración)" -Component "Gaming"
            $results.GameBar = $true
        }
        
        if ($config.hardware_acceleration.enabled) {
            Write-Log "Ejecutando configuración: Hardware Acceleration" -Component "Gaming"
            $results.HardwareAcceleration = Set-HardwareAcceleration -Config $config.hardware_acceleration
        } else {
            Write-Log "Configuración Hardware Acceleration omitida (deshabilitada en configuración)" -Component "Gaming"
            $results.HardwareAcceleration = $true
        }
        
        if ($config.performance_optimizations.enabled) {
            Write-Log "Ejecutando configuración: Performance Optimizations" -Component "Gaming"
            $results.PerformanceOptimizations = Set-PerformanceOptimizations -Config $config.performance_optimizations
        } else {
            Write-Log "Optimizaciones de rendimiento omitidas (deshabilitadas en configuración)" -Component "Gaming"
            $results.PerformanceOptimizations = $true
        }
        
        if ($config.network_optimizations.enabled) {
            Write-Log "Ejecutando configuración: Network Optimizations" -Component "Gaming"
            $results.NetworkOptimizations = Set-NetworkOptimizations -Config $config.network_optimizations
        } else {
            Write-Log "Optimizaciones de red omitidas (deshabilitadas en configuración)" -Component "Gaming"
            $results.NetworkOptimizations = $true
        }
        
        if ($config.power_optimizations.enabled) {
            Write-Log "Ejecutando configuración: Power Optimizations" -Component "Gaming"
            $results.PowerOptimizations = Set-PowerOptimizations -Config $config.power_optimizations
        } else {
            Write-Log "Optimizaciones de energía omitidas (deshabilitadas en configuración)" -Component "Gaming"
            $results.PowerOptimizations = $true
        }
        
        if ($config.game_compatibility.enabled) {
            Write-Log "Ejecutando configuración: Game Compatibility" -Component "Gaming"
            $results.GameCompatibility = Set-GameCompatibility -Config $config.game_compatibility
        } else {
            Write-Log "Configuración de compatibilidad omitida (deshabilitada en configuración)" -Component "Gaming"
            $results.GameCompatibility = $true
        }
        
        # Validar resultados
        $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
        $totalCount = $results.Count
        $failedCount = $totalCount - $successCount
        
        # Resumen final
        Write-LogSection "CONFIGURACIÓN GAMING COMPLETADA" -Component "Gaming"
        Write-Log "Configuraciones ejecutadas exitosamente: $successCount/$totalCount" -Component "Gaming" -Level "SUCCESS"
        
        if ($failedCount -gt 0) {
            Write-Log "Configuraciones fallidas: $failedCount" -Component "Gaming" -Level "WARNING"
        }
        
        if ($config.settings.require_restart_notification) {
            Write-Log "Algunas configuraciones requieren reinicio para tomar efecto completo" -Level "WARNING" -Component "Gaming"
        }
        
        return $successCount -eq $totalCount
        
    } -Operation "Configuración completa de gaming" -Component "Gaming" -Severity ([ErrorSeverity]::High)
}
