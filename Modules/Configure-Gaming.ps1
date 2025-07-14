#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Configuración optimizada para gaming en Windows 11
.DESCRIPTION
    Este módulo optimiza Windows 11 para obtener el máximo rendimiento en gaming,
    configurando Game Mode, DirectX, hardware acceleration y herramientas gaming.
.NOTES
    Autor: WinAutoConfigure
    Versión: 2.0
    Requiere: Windows 11, PowerShell 5.1+, Permisos de administrador
#>

param(
    [switch]$Verbose,
    [switch]$DisableGameBar,
    [switch]$MaxPerformance
)

# Importar módulo común de logging
Import-Module (Join-Path $PSScriptRoot "Common-Logging.psm1") -Force

# Importar UI-Helpers si está disponible
$UIHelpersPath = Join-Path $PSScriptRoot "UI-Helpers.ps1"
if (Test-Path $UIHelpersPath) {
    . $UIHelpersPath
}

function Set-GameMode {
    <#
    .SYNOPSIS
        Configura Windows Game Mode y optimizaciones gaming
    #>
    Write-Log "Configurando Windows Game Mode..." -Component "Gaming"
    
    Invoke-SafeRegistryOperation {
        # Habilitar Game Mode
        $gameModePath = "HKCU:\SOFTWARE\Microsoft\GameBar"
        if (-not (Test-Path $gameModePath)) {
            New-Item -Path $gameModePath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $gameModePath -Name "AllowAutoGameMode" -Value 1 -Type DWord
        Set-ItemProperty -Path $gameModePath -Name "AutoGameModeEnabled" -Value 1 -Type DWord
        
        # Game Mode en configuración del sistema
        $systemGameModePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
        if (-not (Test-Path $systemGameModePath)) {
            New-Item -Path $systemGameModePath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $systemGameModePath -Name "GameDVR_Enabled" -Value 0 -Type DWord
        Set-ItemProperty -Path $systemGameModePath -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord
        Set-ItemProperty -Path $systemGameModePath -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1 -Type DWord
        Set-ItemProperty -Path $systemGameModePath -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1 -Type DWord
        Set-ItemProperty -Path $systemGameModePath -Name "GameDVR_EFSEFeatureFlags" -Value 0 -Type DWord
    } -Description "Configurar Windows Game Mode" -Component "Gaming"
}

function Set-GameBar {
    <#
    .SYNOPSIS
        Configura Xbox Game Bar según preferencias
    #>
    if ($DisableGameBar) {
        Write-Log "Deshabilitando Xbox Game Bar..."
        
        try {
            # Deshabilitar Game Bar
            $gameBarPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
            Set-ItemProperty -Path $gameBarPath -Name "AppCaptureEnabled" -Value 0 -Type DWord
            
            $gameBarPath2 = "HKCU:\SOFTWARE\Microsoft\GameBar"
            Set-ItemProperty -Path $gameBarPath2 -Name "UseNexusForGameBarEnabled" -Value 0 -Type DWord
            
            # Deshabilitar notificaciones de Game Bar
            $notificationsPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Microsoft.XboxGamingOverlay_8wekyb3d8bbwe!App"
            if (-not (Test-Path $notificationsPath)) {
                New-Item -Path $notificationsPath -Force | Out-Null
            }
            Set-ItemProperty -Path $notificationsPath -Name "Enabled" -Value 0 -Type DWord
            
            Write-Log "Xbox Game Bar deshabilitado correctamente" -Level "INFO"
        }
        catch {
            Write-Log "Error deshabilitando Game Bar: $($_.Exception.Message)" -Level "ERROR"
        }
    }
    else {
        Write-Log "Optimizando Xbox Game Bar..."
        
        try {
            # Optimizar Game Bar (mantenerlo habilitado pero optimizado)
            $gameBarPath = "HKCU:\SOFTWARE\Microsoft\GameBar"
            Set-ItemProperty -Path $gameBarPath -Name "ShowStartupPanel" -Value 0 -Type DWord
            Set-ItemProperty -Path $gameBarPath -Name "GamePanelStartupTipIndex" -Value 3 -Type DWord
            Set-ItemProperty -Path $gameBarPath -Name "ShowGameModeNotifications" -Value 0 -Type DWord
            
            Write-Log "Xbox Game Bar optimizado correctamente" -Level "INFO"
        }
        catch {
            Write-Log "Error optimizando Game Bar: $($_.Exception.Message)" -Level "ERROR"
        }
    }
}

function Set-HardwareAcceleration {
    <#
    .SYNOPSIS
        Configura hardware acceleration y optimizaciones GPU
    #>
    Write-Log "Configurando hardware acceleration..."
    
    try {
        # Hardware-accelerated GPU scheduling (Windows 11)
        $gpuSchedulingPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        Set-ItemProperty -Path $gpuSchedulingPath -Name "HwSchMode" -Value 2 -Type DWord
        
        # DirectX optimizations
        $dxgiPath = "HKCU:\SOFTWARE\Microsoft\DirectX\UserGpuPreferences"
        if (-not (Test-Path $dxgiPath)) {
            New-Item -Path $dxgiPath -Force | Out-Null
        }
        
        # Variable Refresh Rate optimizations
        $dwmPath = "HKCU:\SOFTWARE\Microsoft\DirectX\GraphicsSettings"
        if (-not (Test-Path $dwmPath)) {
            New-Item -Path $dwmPath -Force | Out-Null
        }
        Set-ItemProperty -Path $dwmPath -Name "SwapEffectUpgradeEnable" -Value 1 -Type DWord
        
        Write-Log "Hardware acceleration configurado correctamente" -Level "INFO"
    }
    catch {
        Write-Log "Error configurando hardware acceleration: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Set-PerformanceOptimizations {
    <#
    .SYNOPSIS
        Aplica optimizaciones de rendimiento específicas para gaming
    #>
    Write-Log "Aplicando optimizaciones de rendimiento gaming..."
    
    try {
        # Deshabilitar Windows Search durante gaming
        $searchPath = "HKLM:\SOFTWARE\Microsoft\Windows Search\Gathering Manager"
        if (Test-Path $searchPath) {
            Set-ItemProperty -Path $searchPath -Name "DisableBackOff" -Value 1 -Type DWord
        }
        
        # Memory optimizations
        $memoryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        Set-ItemProperty -Path $memoryPath -Name "LargeSystemCache" -Value 0 -Type DWord
        Set-ItemProperty -Path $memoryPath -Name "DisablePagingExecutive" -Value 1 -Type DWord
        
        # Multimedia Class Scheduler Service optimizations
        $mmcssPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Set-ItemProperty -Path $mmcssPath -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord
        Set-ItemProperty -Path $mmcssPath -Name "SystemResponsiveness" -Value 0 -Type DWord
        
        # Gaming task priorities
        $gamesPath = "$mmcssPath\Tasks\Games"
        if (-not (Test-Path $gamesPath)) {
            New-Item -Path $gamesPath -Force | Out-Null
        }
        Set-ItemProperty -Path $gamesPath -Name "GPU Priority" -Value 8 -Type DWord
        Set-ItemProperty -Path $gamesPath -Name "Priority" -Value 6 -Type DWord
        Set-ItemProperty -Path $gamesPath -Name "Scheduling Category" -Value "High" -Type String
        Set-ItemProperty -Path $gamesPath -Name "SFIO Priority" -Value "High" -Type String
        
        Write-Log "Optimizaciones de rendimiento aplicadas correctamente" -Level "INFO"
    }
    catch {
        Write-Log "Error aplicando optimizaciones de rendimiento: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Set-NetworkOptimizations {
    <#
    .SYNOPSIS
        Optimiza configuraciones de red para gaming
    #>
    Write-Log "Optimizando configuraciones de red para gaming..."
    
    try {
        # TCP optimizations for gaming
        $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        Set-ItemProperty -Path $tcpPath -Name "TcpAckFrequency" -Value 1 -Type DWord
        Set-ItemProperty -Path $tcpPath -Name "TCPNoDelay" -Value 1 -Type DWord
        Set-ItemProperty -Path $tcpPath -Name "TcpDelAckTicks" -Value 0 -Type DWord
        
        # Network adapter optimizations
        $netPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
        Get-ChildItem $netPath | ForEach-Object {
            if (Get-ItemProperty -Path $_.PSPath -Name "DhcpIPAddress" -ErrorAction SilentlyContinue) {
                Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $_.PSPath -Name "TcpDelAckTicks" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            }
        }
        
        # Disable Nagle's algorithm for gaming
        $naglePath = "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters"
        if (Test-Path $naglePath) {
            Set-ItemProperty -Path $naglePath -Name "TCPNoDelay" -Value 1 -Type DWord
        }
        
        Write-Log "Optimizaciones de red aplicadas correctamente" -Level "INFO"
    }
    catch {
        Write-Log "Error optimizando configuraciones de red: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Set-PowerOptimizations {
    <#
    .SYNOPSIS
        Configura el plan de energía para máximo rendimiento gaming
    #>
    Write-Log "Configurando plan de energía para gaming..."
    
    try {
        # Crear plan de energía personalizado para gaming si no existe
        $gamingPlan = powercfg /list | Select-String "Gaming Performance"
        
        if (-not $gamingPlan) {
            # Duplicar plan de alto rendimiento
            $highPerfGuid = (powercfg /list | Select-String "Alto rendimiento|High performance").ToString().Split()[3]
            if ($highPerfGuid) {
                $result = powercfg /duplicatescheme $highPerfGuid
                $newGuid = ($result | Select-String "GUID").ToString().Split()[-1]
                powercfg /changename $newGuid "Gaming Performance" "Optimized for maximum gaming performance"
                powercfg /setactive $newGuid
                
                # Configuraciones específicas para gaming
                powercfg /change disk-timeout-ac 0
                powercfg /change disk-timeout-dc 0
                powercfg /change standby-timeout-ac 0
                powercfg /change standby-timeout-dc 0
                powercfg /change hibernate-timeout-ac 0
                powercfg /change hibernate-timeout-dc 0
                
                Write-Log "Plan de energía Gaming Performance creado y activado" -Level "INFO"
            }
        }
        else {
            Write-Log "Plan de energía Gaming Performance ya existe" -Level "INFO"
        }
        
        # Deshabilitar USB selective suspend
        $usbPath = "HKLM:\SYSTEM\CurrentControlSet\Services\USB"
        Set-ItemProperty -Path $usbPath -Name "DisableSelectiveSuspend" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        
    }
    catch {
        Write-Log "Error configurando plan de energía: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Set-GameCompatibility {
    <#
    .SYNOPSIS
        Configura compatibilidad para juegos legacy y modernos
    #>
    Write-Log "Configurando compatibilidad de juegos..."
    
    try {
        # DirectPlay (para juegos legacy)
        Enable-WindowsOptionalFeature -Online -FeatureName "DirectPlay" -All -NoRestart -ErrorAction SilentlyContinue
        
        # .NET Framework 3.5 (para juegos que lo requieren)
        Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" -All -NoRestart -ErrorAction SilentlyContinue
        
        # Legacy DirectX
        $dxPath = "HKLM:\SOFTWARE\Microsoft\DirectX"
        if (-not (Test-Path $dxPath)) {
            New-Item -Path $dxPath -Force | Out-Null
        }
        
        # Configurar Windows Defender exclusions para gaming
        $gamingFolders = @(
            "$env:ProgramFiles\Steam",
            "$env:ProgramFiles(x86)\Steam",
            "$env:ProgramFiles\Epic Games",
            "$env:LOCALAPPDATA\Programs\Epic Games",
            "$env:ProgramFiles\Origin Games",
            "$env:ProgramFiles(x86)\Origin Games"
        )
        
        foreach ($folder in $gamingFolders) {
            if (Test-Path $folder) {
                try {
                    Add-MpPreference -ExclusionPath $folder -ErrorAction SilentlyContinue
                    Write-Log "Exclusión agregada para: $folder" -Level "INFO"
                }
                catch {
                    Write-Log "No se pudo agregar exclusión para: $folder" -Level "WARNING"
                }
            }
        }
        
        Write-Log "Compatibilidad de juegos configurada correctamente" -Level "INFO"
    }
    catch {
        Write-Log "Error configurando compatibilidad: $($_.Exception.Message)" -Level "ERROR"
    }
}

# ==========================================
# FUNCIÓN PRINCIPAL
# ==========================================

function Start-GamingConfiguration {
    <#
    .SYNOPSIS
        Función principal que ejecuta toda la configuración gaming
    #>
    
    Write-LogSection "CONFIGURACIÓN GAMING" -Component "Gaming"
    Write-Log "Optimizando Windows 11 para máximo rendimiento gaming..." -Component "Gaming"
    
    try {
        # Verificar permisos de administrador
        if (-not (Test-AdminRights)) {
            throw "Se requieren permisos de administrador para ejecutar este módulo"
        }
        
        # Verificar versión de Windows
        $osInfo = Test-WindowsVersion
        if (-not $osInfo.IsWindows11) {
            Write-Log "Este módulo está optimizado para Windows 11 (detectado: $($osInfo.VersionString))" -Level "WARNING" -Component "Gaming"
        }
        
        # Ejecutar configuraciones
        Set-GameMode
        Set-GameBar
        Set-HardwareAcceleration
        Set-PerformanceOptimizations
        Set-NetworkOptimizations
        Set-PowerOptimizations
        Set-GameCompatibility
        
        Write-LogSection "CONFIGURACIÓN GAMING COMPLETADA" -Component "Gaming"
        Write-Log "Algunas configuraciones requieren reinicio para tomar efecto completo" -Level "WARNING" -Component "Gaming"
        
        return $true
    }
    catch {
        Write-Log "Error en configuración gaming: $($_.Exception.Message)" -Level "ERROR" -Component "Gaming"
        return $false
    }
}

# ==========================================
# EJECUCIÓN
# ==========================================

if ($MyInvocation.InvocationName -ne '.') {
    Start-GamingConfiguration
}
