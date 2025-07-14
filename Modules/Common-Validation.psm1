# ====================================================================================
# MODULO: Common-Validation
# AUTOR: WinAutoConfigure
# VERSION: 3.0
# DESCRIPCION: Funciones de validacion de sistema y configuracion
# ====================================================================================

# Variables globales del modulo
$script:ValidationInitialized = $false

function Initialize-ValidationModule {
    <#
    .SYNOPSIS
        Inicializa el modulo de validacion
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Inicializando modulo de validacion..." -Level "INFO"
        $script:ValidationInitialized = $true
        Write-Log "Modulo de validacion inicializado correctamente" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Error inicializando modulo de validacion: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Test-SystemRequirements {
    <#
    .SYNOPSIS
        Valida que el sistema cumple con los requisitos minimos
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
        Details = @{}
    }
    
    try {
        Write-Log "Iniciando validacion de requisitos del sistema..." -Level "INFO"
        
        # Validar version de Windows
        try {
            $osInfo = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop
            $osVersion = [Version]$osInfo.Version
            $requiredVersion = [Version]"10.0.10240"
            
            $results.WindowsVersion = $osVersion -ge $requiredVersion
            $results.Details.OSName = $osInfo.Caption
            $results.Details.OSVersion = $osInfo.Version
            $results.Details.OSBuild = $osInfo.BuildNumber
            
            if ($results.WindowsVersion) {
                Write-Log "Version de Windows: $($osInfo.Caption) ($($osInfo.Version)) - COMPATIBLE" -Level "SUCCESS"
            } else {
                Write-Log "Version de Windows: $($osInfo.Caption) ($($osInfo.Version)) - NO COMPATIBLE" -Level "ERROR"
                $results.Details.WindowsError = "Se requiere Windows 10 v1909 o superior"
            }
        }
        catch {
            Write-Log "Error obteniendo version de Windows: $($_.Exception.Message)" -Level "ERROR"
            $results.Details.WindowsError = $_.Exception.Message
        }
        
        # Validar version de PowerShell
        try {
            $psVersion = $PSVersionTable.PSVersion
            $results.PowerShellVersion = $psVersion.Major -ge 5
            $results.Details.PSVersion = $psVersion.ToString()
            
            if ($results.PowerShellVersion) {
                Write-Log "Version de PowerShell: $($psVersion) - COMPATIBLE" -Level "SUCCESS"
            } else {
                Write-Log "Version de PowerShell: $($psVersion) - NO COMPATIBLE" -Level "ERROR"
                $results.Details.PowerShellError = "Se requiere PowerShell 5.1 o superior"
            }
        }
        catch {
            Write-Log "Error obteniendo version de PowerShell: $($_.Exception.Message)" -Level "ERROR"
            $results.Details.PowerShellError = $_.Exception.Message
        }
        
        # Validar permisos de administrador
        try {
            $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
            $results.AdminRights = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
            $results.Details.CurrentUser = $currentUser.Name
            
            if ($results.AdminRights) {
                Write-Log "Permisos de administrador: VERIFICADOS" -Level "SUCCESS"
            } else {
                Write-Log "Permisos de administrador: NO DISPONIBLES" -Level "ERROR"
                $results.Details.AdminError = "Se requieren permisos de administrador para ejecutar este script"
            }
        }
        catch {
            Write-Log "Error verificando permisos: $($_.Exception.Message)" -Level "ERROR"
            $results.Details.AdminError = $_.Exception.Message
        }
        
        # Validar memoria disponible
        try {
            $computerSystem = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop
            $totalRAM = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
            $minMemory = 4
            
            $results.MemoryRequirement = $totalRAM -ge $minMemory
            $results.Details.TotalRAM = $totalRAM
            $results.Details.MinMemoryRequired = $minMemory
            
            Write-Log "Memoria total: $totalRAM GB (Minimo: $minMemory GB)" -Level "INFO"
            
            if ($results.MemoryRequirement) {
                Write-Log "Memoria suficiente disponible" -Level "SUCCESS"
            } else {
                Write-Log "Memoria insuficiente" -Level "WARNING"
            }
        }
        catch {
            Write-Log "Error obteniendo informacion de memoria: $($_.Exception.Message)" -Level "ERROR"
            $results.Details.MemoryError = $_.Exception.Message
            $results.MemoryRequirement = $true
        }
        
        # Validar espacio en disco
        try {
            $systemDrive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $env:SystemDrive }
            $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
            $totalSpaceGB = [math]::Round($systemDrive.Size / 1GB, 2)
            $minDiskSpace = 5
            
            Write-Log "Espacio en disco $($env:SystemDrive): $freeSpaceGB GB libres de $totalSpaceGB GB (Minimo: $minDiskSpace GB)" -Level "INFO"
            
            $results.DiskSpace = $freeSpaceGB -ge $minDiskSpace
            $results.Details.FreeSpace = $freeSpaceGB
            $results.Details.TotalSpace = $totalSpaceGB
            $results.Details.MinDiskRequired = $minDiskSpace
            
            if ($results.DiskSpace) {
                Write-Log "Espacio en disco suficiente" -Level "SUCCESS"
            } else {
                Write-Log "Poco espacio en disco disponible" -Level "WARNING"
                $results.DiskSpace = $true
            }
        }
        catch {
            Write-Log "Error obteniendo informacion de disco: $($_.Exception.Message)" -Level "ERROR"
            $results.Details.DiskError = $_.Exception.Message
            $results.DiskSpace = $true
        }
        
        # Resultado general
        $results.OverallStatus = $results.WindowsVersion -and $results.PowerShellVersion -and $results.AdminRights
        
        Write-Log "Resultado de validacion:" -Level "INFO"
        Write-Log "  - Windows: $($results.WindowsVersion)" -Level "INFO"
        Write-Log "  - PowerShell: $($results.PowerShellVersion)" -Level "INFO"
        Write-Log "  - Administrador: $($results.AdminRights)" -Level "INFO"
        Write-Log "  - Memoria: $($results.MemoryRequirement)" -Level "INFO"
        Write-Log "  - Disco: $($results.DiskSpace)" -Level "INFO"
        Write-Log "  - Estado general: $($results.OverallStatus)" -Level "INFO"
        
        return $results
    }
    catch {
        Write-Log "Error critico durante validacion de requisitos: $($_.Exception.Message)" -Level "ERROR"
        $results.Details.CriticalError = $_.Exception.Message
        return $results
    }
}

function Test-ConfigurationFiles {
    <#
    .SYNOPSIS
        Valida la integridad de todos los archivos de configuracion JSON
    #>
    [CmdletBinding()]
    param()
    
    $configPath = Join-Path $PSScriptRoot "..\Config"
    $configFiles = @(
        "applications.json",
        "common-settings.json",
        "gaming-config.json",
        "git-config.json",
        "master-config.json",
        "terminal-settings.json"
    )
    
    $results = @{
        ValidFiles = @()
        InvalidFiles = @()
        OverallStatus = $true
    }
    
    Write-Log "Validando archivos de configuracion..." -Level "INFO"
    
    foreach ($file in $configFiles) {
        $filePath = Join-Path $configPath $file
        
        try {
            if (Test-Path $filePath) {
                $content = Get-Content $filePath -Raw | ConvertFrom-Json -ErrorAction Stop
                $results.ValidFiles += $file
                Write-Log "Archivo ${file} VALIDO" -Level "SUCCESS"
            } else {
                $results.InvalidFiles += @{
                    File = $file
                    Error = "Archivo no encontrado"
                }
                Write-Log "Archivo ${file} NO ENCONTRADO" -Level "WARNING"
            }
        }
        catch {
            $results.InvalidFiles += @{
                File = $file
                Error = $_.Exception.Message
            }
            Write-Log "Archivo ${file} ERROR - $($_.Exception.Message)" -Level "ERROR"
            $results.OverallStatus = $false
        }
    }
    
    return $results
}

function Test-ModuleDependencies {
    <#
    .SYNOPSIS
        Verifica que todos los modulos requeridos esten disponibles
    #>
    [CmdletBinding()]
    param()
    
    $requiredModules = @(
        "Common-Logging.psm1",
        "Common-Cache.psm1",
        "Common-ProgressTracking.psm1"
    )
    
    $results = @{
        AvailableModules = @()
        MissingModules = @()
        OverallStatus = $true
    }
    
    Write-Log "Verificando dependencias de modulos..." -Level "INFO"
    
    foreach ($module in $requiredModules) {
        $modulePath = Join-Path $PSScriptRoot $module
        
        if (Test-Path $modulePath) {
            $results.AvailableModules += $module
            Write-Log "Modulo ${module} DISPONIBLE" -Level "SUCCESS"
        } else {
            $results.MissingModules += $module
            Write-Log "Modulo ${module} NO ENCONTRADO" -Level "ERROR"
            $results.OverallStatus = $false
        }
    }
    
    return $results
}

function Test-NetworkConnectivity {
    <#
    .SYNOPSIS
        Verifica la conectividad de red a sitios importantes
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
    
    Write-Log "Verificando conectividad de red..." -Level "INFO"
    
    foreach ($url in $testUrls) {
        try {
            $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                $results.SuccessfulConnections += $url
                Write-Log "Conectividad a ${url} EXITOSA" -Level "SUCCESS"
            } else {
                $results.FailedConnections += @{
                    Url = $url
                    StatusCode = $response.StatusCode
                }
                Write-Log "Conectividad a ${url} FALLO (Status: $($response.StatusCode))" -Level "WARNING"
            }
        }
        catch {
            $results.FailedConnections += @{
                Url = $url
                Error = $_.Exception.Message
            }
            Write-Log "Conectividad a ${url} ERROR - $($_.Exception.Message)" -Level "ERROR"
        }
    }
    
    $results.OverallStatus = $results.SuccessfulConnections.Count -gt 0
    
    return $results
}

function Invoke-CompleteValidation {
    <#
    .SYNOPSIS
        Ejecuta todas las validaciones disponibles
    #>
    [CmdletBinding()]
    param()
    
    Write-Log "Iniciando validacion completa del sistema..." -Level "INFO"
    
    $validationResults = @{
        SystemRequirements = Test-SystemRequirements
        ConfigurationFiles = Test-ConfigurationFiles
        ModuleDependencies = Test-ModuleDependencies
        NetworkConnectivity = Test-NetworkConnectivity
        OverallStatus = $false
    }
    
    # Determinar estado general
    $criticalTests = @(
        $validationResults.SystemRequirements.OverallStatus,
        $validationResults.ModuleDependencies.OverallStatus
    )
    
    $validationResults.OverallStatus = $criticalTests -notcontains $false
    
    Write-Log "Validacion completa finalizada. Estado general: $($validationResults.OverallStatus)" -Level "INFO"
    
    return $validationResults
}

# Exportar funciones del modulo
Export-ModuleMember -Function @(
    'Initialize-ValidationModule',
    'Test-SystemRequirements',
    'Test-ConfigurationFiles', 
    'Test-ModuleDependencies',
    'Test-NetworkConnectivity',
    'Invoke-CompleteValidation'
)