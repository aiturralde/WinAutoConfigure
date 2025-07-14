<#
.SYNOPSIS
    Módulo de validación central para WinAutoConfigure
.DESCRIPTION
    Proporciona funciones de validación centralizadas para configuraciones,
    requisitos del sistema y dependencias de módulos
.NOTES
    Módulo interno - No exponer funciones innecesarias
#>

# Importar configuraciones comunes
$script:CommonSettings = $null
$script:MasterConfig = $null

function Initialize-ValidationModule {
    [CmdletBinding()]
    param()
    
    try {
        $configPath = Join-Path $PSScriptRoot "..\Config"
        $commonSettingsPath = Join-Path $configPath "common-settings.json"
        $masterConfigPath = Join-Path $configPath "master-config.json"
        
        if (Test-Path $commonSettingsPath) {
            $script:CommonSettings = Get-Content $commonSettingsPath -Raw | ConvertFrom-Json
        } else {
            Write-Warning "Archivo common-settings.json no encontrado, usando configuración por defecto"
            $script:CommonSettings = @{}
        }
        
        if (Test-Path $masterConfigPath) {
            $script:MasterConfig = Get-Content $masterConfigPath -Raw | ConvertFrom-Json
        } else {
            Write-Warning "Archivo master-config.json no encontrado, usando configuración por defecto"
            $script:MasterConfig = @{}
        }
        
        Write-Verbose "Módulo de validación inicializado correctamente"
        return $true
    }
    catch {
        Write-Warning "Error inicializando módulo de validación: $($_.Exception.Message)"
        # Inicializar con valores por defecto
        $script:CommonSettings = @{}
        $script:MasterConfig = @{}
        return $true  # No fallar completamente
    }
}

function Test-SystemRequirements {
    <#
    .SYNOPSIS
        Valida que el sistema cumpla con los requisitos mínimos
    #>
    [CmdletBinding()]
    param()
    
    $results = @{
        WindowsVersion = $false
        PowerShellVersion = $false
        AdminRights = $false
        MemoryRequirement = $false
        DiskSpace = $false
        OverallStatus = $false
    }
    
    try {
        # Validar versión de Windows
        $osVersion = (Get-WmiObject -Class Win32_OperatingSystem).Version
        $isWindows11 = [Version]$osVersion -ge [Version]"10.0.22000"
        $results.WindowsVersion = $isWindows11
        
        # Validar versión de PowerShell
        $psVersion = $PSVersionTable.PSVersion
        $validPSVersion = $psVersion.Major -ge 5
        $results.PowerShellVersion = $validPSVersion
        
        # Validar permisos de administrador
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $results.AdminRights = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        # Validar memoria RAM
        $totalRAM = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB
        $results.MemoryRequirement = $totalRAM -ge $script:CommonSettings.system_requirements.minimum_ram_gb
        
        # Validar espacio en disco
        $systemDrive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $env:SystemDrive }
        $freeSpaceGB = $systemDrive.FreeSpace / 1GB
        $results.DiskSpace = $freeSpaceGB -ge $script:CommonSettings.system_requirements.minimum_disk_space_gb
        
        # Resultado general
        $results.OverallStatus = $results.WindowsVersion -and $results.PowerShellVersion -and 
                                $results.AdminRights -and $results.MemoryRequirement -and $results.DiskSpace
        
        return $results
    }
    catch {
        Write-Error "Error validando requisitos del sistema: $($_.Exception.Message)"
        return $results
    }
}

function Test-ConfigurationFiles {
    <#
    .SYNOPSIS
        Valida la integridad de todos los archivos de configuración JSON
    #>
    [CmdletBinding()]
    param()
    
    $configPath = Join-Path $PSScriptRoot "..\Config"
    $results = @{
        ValidFiles = @()
        InvalidFiles = @()
        MissingFiles = @()
        OverallStatus = $false
    }
    
    # Lista de archivos de configuración críticos
    $criticalConfigs = @(
        "common-settings.json",
        "master-config.json",
        "applications.json",
        "terminal-settings.json"
    )
    
    foreach ($configFile in $criticalConfigs) {
        $filePath = Join-Path $configPath $configFile
        
        if (-not (Test-Path $filePath)) {
            $results.MissingFiles += $configFile
            continue
        }
        
        try {
            $null = Get-Content $filePath -Raw | ConvertFrom-Json
            $results.ValidFiles += $configFile
        }
        catch {
            $results.InvalidFiles += @{
                File = $configFile
                Error = $_.Exception.Message
            }
        }
    }
    
    $results.OverallStatus = ($results.InvalidFiles.Count -eq 0) -and ($results.MissingFiles.Count -eq 0)
    return $results
}

function Test-ModuleDependencies {
    <#
    .SYNOPSIS
        Verifica que todos los módulos requeridos estén disponibles
    #>
    [CmdletBinding()]
    param()
    
    $modulesPath = Join-Path $PSScriptRoot ".."
    $results = @{
        AvailableModules = @()
        MissingModules = @()
        OverallStatus = $false
    }
    
    # Obtener lista de módulos desde la configuración maestra
    foreach ($moduleInfo in $script:MasterConfig.modules.PSObject.Properties) {
        $moduleName = $moduleInfo.Value.name
        $modulePath = Join-Path $modulesPath "Modules\$moduleName.ps1"
        
        if (Test-Path $modulePath) {
            $results.AvailableModules += $moduleName
        } else {
            $results.MissingModules += $moduleName
        }
    }
    
    # Verificar dependencias globales
    foreach ($dependency in $script:MasterConfig.global_dependencies) {
        $depPath = Join-Path $modulesPath "Modules\$dependency"
        
        if (-not (Test-Path $depPath)) {
            $results.MissingModules += $dependency
        }
    }
    
    $results.OverallStatus = $results.MissingModules.Count -eq 0
    return $results
}

function Test-WindowsFeatureAvailability {
    <#
    .SYNOPSIS
        Verifica la disponibilidad de características de Windows opcionales
    #>
    [CmdletBinding()]
    param([string[]]$FeatureNames)
    
    $results = @{}
    
    foreach ($feature in $FeatureNames) {
        try {
            $featureInfo = Get-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction SilentlyContinue
            $results[$feature] = @{
                Available = $null -ne $featureInfo
                Enabled = $featureInfo.State -eq "Enabled"
                CanBeEnabled = $featureInfo.State -eq "Disabled"
            }
        }
        catch {
            $results[$feature] = @{
                Available = $false
                Enabled = $false
                CanBeEnabled = $false
                Error = $_.Exception.Message
            }
        }
    }
    
    return $results
}

function Test-NetworkConnectivity {
    <#
    .SYNOPSIS
        Verifica la conectividad de red necesaria para descargas
    #>
    [CmdletBinding()]
    param()
    
    $testUrls = @(
        "https://github.com",
        "https://raw.githubusercontent.com",
        "https://www.microsoft.com",
        "https://api.github.com"
    )
    
    $results = @{
        SuccessfulConnections = @()
        FailedConnections = @()
        OverallStatus = $false
    }
    
    foreach ($url in $testUrls) {
        try {
            $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                $results.SuccessfulConnections += $url
            } else {
                $results.FailedConnections += @{
                    Url = $url
                    StatusCode = $response.StatusCode
                }
            }
        }
        catch {
            $results.FailedConnections += @{
                Url = $url
                Error = $_.Exception.Message
            }
        }
    }
    
    $results.OverallStatus = $results.FailedConnections.Count -eq 0
    return $results
}

function Invoke-CompleteValidation {
    <#
    .SYNOPSIS
        Ejecuta todas las validaciones y retorna un reporte completo
    #>
    [CmdletBinding()]
    param()
    
    if (-not (Initialize-ValidationModule)) {
        return $false
    }
    
    $report = @{
        Timestamp = Get-Date
        SystemRequirements = Test-SystemRequirements
        ConfigurationFiles = Test-ConfigurationFiles
        ModuleDependencies = Test-ModuleDependencies
        NetworkConnectivity = Test-NetworkConnectivity
        OverallStatus = $false
    }
    
    # Determinar estado general
    $report.OverallStatus = $report.SystemRequirements.OverallStatus -and
                           $report.ConfigurationFiles.OverallStatus -and
                           $report.ModuleDependencies.OverallStatus -and
                           $report.NetworkConnectivity.OverallStatus
    
    return $report
}

# Exportar funciones principales
Export-ModuleMember -Function @(
    'Initialize-ValidationModule',
    'Test-SystemRequirements',
    'Test-ConfigurationFiles', 
    'Test-ModuleDependencies',
    'Test-WindowsFeatureAvailability',
    'Test-NetworkConnectivity',
    'Invoke-CompleteValidation'
)
