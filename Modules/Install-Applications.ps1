<#
.SYNOPSIS
    Módulo para la instalación de aplicaciones usando Winget
.DESCRIPTION
    Este módulo lee una lista de aplicaciones desde un archivo JSON y las instala usando Winget
.NOTES
    Requiere Windows Package Manager (winget) instalado
#>

function Install-ApplicationsModule {
    [CmdletBinding()]
    param()
    
    Write-Log "Iniciando instalación de aplicaciones con Winget..."
    
    # Verificar que winget esté disponible
    if (-not (Test-WingetAvailability)) {
        Write-Log "Winget no está disponible. Intentando instalar..." -Level "WARNING"
        if (-not (Install-Winget)) {
            Write-Log "No se pudo instalar winget. Abortando instalación de aplicaciones." -Level "ERROR"
            return $false
        }
    }
    
    # Obtener la ruta del proyecto
    $moduleScriptPath = $PSCommandPath
    $projectRoot = Split-Path (Split-Path $moduleScriptPath -Parent) -Parent
    
    # Cargar lista de aplicaciones
    $applicationsFile = Join-Path $projectRoot "Config\applications.json"
    if (-not (Test-Path $applicationsFile)) {
        Write-Log "Archivo de aplicaciones no encontrado. Creando archivo ejemplo: $applicationsFile"
        New-ApplicationsJsonTemplate -Path $applicationsFile
        Write-Log "Se ha creado un archivo de ejemplo. Modifique la lista de aplicaciones según sus necesidades."
        return $false
    }
    
    # Leer y validar JSON
    try {
        $applicationsConfig = Get-Content -Path $applicationsFile -Raw | ConvertFrom-Json
    }
    catch {
        Write-Log "Error leyendo archivo de aplicaciones: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
    
    # Instalar características de Windows si están configuradas
    if ($applicationsConfig.PSObject.Properties.Name -contains "windows_features" -and 
        $applicationsConfig.settings.PSObject.Properties.Name -contains "install_windows_features" -and
        $applicationsConfig.settings.install_windows_features) {
        Install-WindowsFeaturesFromConfig -Config $applicationsConfig -ProjectRoot $projectRoot
    }
    
    # Instalar aplicaciones
    Install-ApplicationsFromConfig -Config $applicationsConfig -ProjectRoot $projectRoot
    
    Write-Log "Instalación de aplicaciones completada"
    return $true
}

function Test-WingetAvailability {
    try {
        $wingetVersion = & winget --version 2>$null
        if ($wingetVersion) {
            Write-Log "Winget disponible - Versión: $wingetVersion"
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

function Install-Winget {
    Write-Log "Instalando Windows Package Manager (winget)..."
    
    try {
        # Verificar si App Installer está instalado (incluye winget)
        $appInstaller = Get-AppxPackage -Name "Microsoft.DesktopAppInstaller" -ErrorAction SilentlyContinue
        
        if (-not $appInstaller) {
            Write-Log "Instalando App Installer desde Microsoft Store..."
            
            # Intentar instalar usando PowerShell
            try {
                # Descargar e instalar App Installer
                $appInstallerUrl = "https://aka.ms/getwinget"
                $tempPath = Join-Path $env:TEMP "AppInstaller.msixbundle"
                
                Invoke-WebRequest -Uri $appInstallerUrl -OutFile $tempPath -UseBasicParsing
                Add-AppxPackage -Path $tempPath
                
                Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
                Write-Log "App Installer instalado correctamente"
            }
            catch {
                Write-Log "Error instalando App Installer: $($_.Exception.Message)" -Level "ERROR"
                
                # Abrir Microsoft Store como alternativa
                Write-Log "Abriendo Microsoft Store para instalación manual..."
                Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
                
                Write-Log "Por favor, instale 'App Installer' desde Microsoft Store y presione cualquier tecla para continuar..."
                Read-Host
            }
        }
        
        # Verificar instalación
        Start-Sleep 5
        return Test-WingetAvailability
    }
    catch {
        Write-Log "Error instalando winget: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function New-ApplicationsJsonTemplate {
    param([string]$Path)
    
    $template = @{
        applications = @{
            "Google.Chrome" = $true
            "Mozilla.Firefox" = $false
            "7zip.7zip" = $true
            "Microsoft.VisualStudioCode" = $true
            "Git.Git" = $true
            "Microsoft.PowerShell" = $true
            "Docker.DockerDesktop" = $false
            "VideoLAN.VLC" = $false
            "Notepad++.Notepad++" = $false
            "Adobe.Acrobat.Reader.64-bit" = $true
            "Microsoft.PowerToys" = $true
        }
        windows_features = @{
            "Microsoft-Hyper-V-All" = $false
            "VirtualMachinePlatform" = $false
            "Microsoft-Windows-Subsystem-Linux" = $false
            "Containers" = $false
        }
        settings = @{
            continue_on_error = $true
            create_restore_point = $true
            log_installations = $true
            install_windows_features = $true
        }
    }
    
    try {
        $template | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
        Write-Log "Archivo de configuración de aplicaciones creado: $Path"
        return $true
    }
    catch {
        Write-Log "Error creando archivo de configuración: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Install-ApplicationsFromConfig {
    param(
        [PSCustomObject]$Config,
        [string]$ProjectRoot
    )
    
    Write-Log "Procesando configuración de aplicaciones..."
    
    # Crear punto de restauración si está habilitado
    if ($Config.settings.create_restore_point) {
        New-SystemRestorePoint
    }
    
    $totalInstalled = 0
    $totalFailed = 0
    $installResults = @()
    
    # Procesar cada aplicación
    foreach ($appProperty in $Config.applications.PSObject.Properties) {
        $appId = $appProperty.Name
        $shouldInstall = $appProperty.Value
        
        # Si el valor es false, omitir la aplicación
        if (-not $shouldInstall) {
            Write-Log "Omitiendo $appId (marcada como no requerida)" -Level "INFO"
            continue
        }
        
        # Verificar si la aplicación ya está instalada
        if (Test-ApplicationInstalled -AppId $appId) {
            Write-Log "$appId ya está instalada" -Level "INFO"
            continue
        }
        
        Write-Log "Instalando: $appId"
        
        $installResult = Install-SingleApplication -AppId $appId
        $installResults += $installResult
        
        if ($installResult.Success) {
            $totalInstalled++
            Write-Log "$appId instalada correctamente" -Level "INFO"
        } else {
            $totalFailed++
            Write-Log "Error instalando $appId : $($installResult.ErrorMessage)" -Level "ERROR"
            
            if (-not $Config.settings.continue_on_error) {
                Write-Log "Abortando instalación debido a error (continue_on_error = false)" -Level "ERROR"
                break
            }
        }
        
        # Pequeña pausa entre instalaciones
        Start-Sleep 2
    }
    
    # Resumen de instalación
    Write-Log "=== Resumen de Instalación ==="
    Write-Log "Aplicaciones instaladas: $totalInstalled"
    Write-Log "Aplicaciones fallidas: $totalFailed"
    Write-Log "Total procesadas: $($totalInstalled + $totalFailed)"
    
    # Guardar log detallado si está habilitado
    if ($Config.settings.log_installations) {
        $logPath = Join-Path $ProjectRoot "Logs"
        if (-not (Test-Path $logPath)) {
            New-Item -ItemType Directory -Path $logPath -Force | Out-Null
        }
        $logFile = Join-Path $logPath "installations_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $installResults | ConvertTo-Json -Depth 5 | Set-Content -Path $logFile -Encoding UTF8
        Write-Log "Log detallado guardado en: $logFile"
    }
}

function Install-SingleApplication {
    param([string]$AppId)
    
    $result = @{
        Id = $AppId
        Success = $false
        ErrorMessage = ""
        InstallTime = Get-Date
    }
    
    try {
        # Construir comando de instalación
        $installArgs = @(
            "install",
            "--id", $AppId,
            "--accept-package-agreements",
            "--accept-source-agreements",
            "--silent"
        )
        
        # Ejecutar instalación
        $installOutput = & winget @installArgs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $result.Success = $true
        } else {
            $result.ErrorMessage = "Exit code: $LASTEXITCODE. Output: $($installOutput -join ' ')"
        }
    }
    catch {
        $result.ErrorMessage = $_.Exception.Message
    }
    
    return $result
}

function Test-ApplicationInstalled {
    param([string]$AppId)
    
    try {
        $listOutput = & winget list --id $AppId 2>$null
        return ($LASTEXITCODE -eq 0 -and $listOutput -match $AppId)
    }
    catch {
        return $false
    }
}

function New-SystemRestorePoint {
    try {
        Write-Log "Creando punto de restauración del sistema..."
        
        # Habilitar la creación de puntos de restauración si no está habilitada
        $restoreStatus = Get-WmiObject -Class Win32_SystemRestore
        if (-not $restoreStatus) {
            Enable-ComputerRestore -Drive "$env:SystemDrive"
        }
        
        # Crear punto de restauración
        $restorePoint = "WinAutoConfigure - Antes de instalación de aplicaciones"
        Checkpoint-Computer -Description $restorePoint -RestorePointType "MODIFY_SETTINGS"
        
        Write-Log "Punto de restauración creado: $restorePoint"
    }
    catch {
        Write-Log "Error creando punto de restauración: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Install-WindowsFeaturesFromConfig {
    param(
        [PSCustomObject]$Config,
        [string]$ProjectRoot
    )
    
    Write-Log "Procesando características de Windows..."
    
    if (-not $Config.PSObject.Properties.Name -contains "windows_features") {
        Write-Log "No se encontraron características de Windows en la configuración" -Level "INFO"
        return
    }
    
    $totalInstalled = 0
    $totalFailed = 0
    $featureResults = @()
    
    # Verificar si hay características habilitadas
    $enabledFeatures = $Config.windows_features.PSObject.Properties | Where-Object { $_.Value -eq $true }
    
    if ($enabledFeatures.Count -eq 0) {
        Write-Log "No hay características de Windows habilitadas para instalar" -Level "INFO"
        return
    }
    
    Write-Log "Encontradas $($enabledFeatures.Count) características de Windows para instalar"
    
    # Procesar cada característica habilitada
    foreach ($featureProperty in $enabledFeatures) {
        $featureName = $featureProperty.Name
        
        Write-Log "Instalando característica de Windows: $featureName"
        
        $installResult = Install-SingleWindowsFeature -FeatureName $featureName
        $featureResults += $installResult
        
        if ($installResult.Success) {
            $totalInstalled++
            Write-Log "$featureName instalada correctamente" -Level "INFO"
        } else {
            $totalFailed++
            Write-Log "Error instalando $featureName : $($installResult.ErrorMessage)" -Level "ERROR"
            
            if (-not $Config.settings.continue_on_error) {
                Write-Log "Abortando instalación debido a error (continue_on_error = false)" -Level "ERROR"
                break
            }
        }
        
        # Pequeña pausa entre instalaciones
        Start-Sleep 2
    }
    
    # Resumen de instalación de características
    Write-Log "=== Resumen de Características de Windows ==="
    Write-Log "Características instaladas: $totalInstalled"
    Write-Log "Características fallidas: $totalFailed"
    Write-Log "Total procesadas: $($totalInstalled + $totalFailed)"
    
    # Verificar si se necesita reinicio
    if ($totalInstalled -gt 0) {
        Write-Log "IMPORTANTE: Algunas características de Windows pueden requerir reinicio para funcionar correctamente" -Level "WARNING"
    }
    
    # Guardar log detallado si está habilitado
    if ($Config.settings.log_installations) {
        $logPath = Join-Path $ProjectRoot "Logs"
        if (-not (Test-Path $logPath)) {
            New-Item -ItemType Directory -Path $logPath -Force | Out-Null
        }
        $logFile = Join-Path $logPath "windows_features_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $featureResults | ConvertTo-Json -Depth 5 | Set-Content -Path $logFile -Encoding UTF8
        Write-Log "Log detallado de características guardado en: $logFile"
    }
}

function Install-SingleWindowsFeature {
    param([string]$FeatureName)
    
    $result = @{
        FeatureName = $FeatureName
        Success = $false
        ErrorMessage = ""
        InstallTime = Get-Date
        AlreadyInstalled = $false
    }
    
    try {
        # Verificar si la característica ya está habilitada
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction SilentlyContinue
        
        if ($feature -and $feature.State -eq "Enabled") {
            Write-Log "$FeatureName ya está habilitada" -Level "INFO"
            $result.Success = $true
            $result.AlreadyInstalled = $true
            return $result
        }
        
        if (-not $feature) {
            $result.ErrorMessage = "Característica no encontrada en el sistema"
            return $result
        }
        
        # Instalar la característica
        Write-Log "Habilitando característica: $FeatureName"
        $enableResult = Enable-WindowsOptionalFeature -Online -FeatureName $FeatureName -All -NoRestart
        
        if ($enableResult.RestartNeeded) {
            Write-Log "$FeatureName habilitada correctamente (requiere reinicio)" -Level "INFO"
        } else {
            Write-Log "$FeatureName habilitada correctamente" -Level "INFO"
        }
        
        $result.Success = $true
        $result.RestartNeeded = $enableResult.RestartNeeded
    }
    catch {
        $result.ErrorMessage = $_.Exception.Message
        Write-Log "Error habilitando $FeatureName : $($_.Exception.Message)" -Level "ERROR"
    }
    
    return $result
}

function Test-WindowsFeatureInstalled {
    param([string]$FeatureName)
    
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction SilentlyContinue
        return ($feature -and $feature.State -eq "Enabled")
    }
    catch {
        return $false
    }
}

function Get-AvailableWindowsFeatures {
    <#
    .SYNOPSIS
        Obtiene una lista de características de Windows disponibles
    .DESCRIPTION
        Lista las características opcionales de Windows que se pueden habilitar
    #>
    try {
        $features = Get-WindowsOptionalFeature -Online | Select-Object FeatureName, State, Description
        return $features
    }
    catch {
        Write-Log "Error obteniendo características de Windows: $($_.Exception.Message)" -Level "ERROR"
        return @()
    }
}
