<#
.SYNOPSIS
    Módulo simplificado para gestión centralizada de configuraciones
.DESCRIPTION
    Proporciona funciones para cargar y validar configuraciones de manera consistente
.NOTES
    Versión: 1.0 - Refactorización conservadora
#>

# Variable para almacenar la ruta de configuraciones
$script:ConfigPath = ""

function Initialize-ConfigurationManager {
    param([string]$ConfigRootPath)
    
    $script:ConfigPath = $ConfigRootPath
    Write-Log "Configuration Manager inicializado con ruta: $ConfigRootPath" -Component "ConfigManager"
}

function Get-ConfigurationSafe {
    <#
    .SYNOPSIS
        Carga configuración JSON de manera segura con validación
    .PARAMETER ConfigName
        Nombre del archivo de configuración (sin extensión .json)
    .PARAMETER RequiredKeys
        Claves que deben estar presentes en la configuración
    .PARAMETER DefaultValues
        Valores por defecto para claves faltantes
    .EXAMPLE
        $appConfig = Get-ConfigurationSafe -ConfigName "applications" -RequiredKeys @("applications") -DefaultValues @{applications = @{}}
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigName,
        
        [Parameter(Mandatory = $false)]
        [string[]]$RequiredKeys = @(),
        
        [Parameter(Mandatory = $false)]
        [hashtable]$DefaultValues = @{}
    )
    
    $configFile = Join-Path $script:ConfigPath "$ConfigName.json"
    
    try {
        Write-Log "Cargando configuración: $ConfigName" -Component "ConfigManager"
        
        if (-not (Test-Path $configFile)) {
            Write-Log "Archivo de configuración no encontrado: $configFile" -Level "WARNING" -Component "ConfigManager"
            return $DefaultValues
        }
        
        $content = Get-Content $configFile -Raw -ErrorAction Stop
        $config = $content | ConvertFrom-Json -AsHashtable -ErrorAction Stop
        
        # Validar claves requeridas
        if ($RequiredKeys.Count -gt 0) {
            $missing = @()
            foreach ($key in $RequiredKeys) {
                if (-not $config.ContainsKey($key)) {
                    $missing += $key
                }
            }
            
            if ($missing.Count -gt 0) {
                Write-Log "Configuración '$ConfigName' falta claves requeridas: $($missing -join ', ')" -Level "WARNING" -Component "ConfigManager"
                
                # Aplicar valores por defecto
                foreach ($key in $missing) {
                    if ($DefaultValues.ContainsKey($key)) {
                        $config[$key] = $DefaultValues[$key]
                        Write-Log "Aplicando valor por defecto para '$key'" -Level "INFO" -Component "ConfigManager"
                    }
                }
            }
        }
        
        Write-Log "Configuración '$ConfigName' cargada exitosamente" -Component "ConfigManager"
        return $config
    }
    catch {
        Write-Log "Error cargando configuración '$ConfigName': $($_.Exception.Message)" -Level "ERROR" -Component "ConfigManager"
        return $DefaultValues
    }
}

function Test-ConfigurationValid {
    <#
    .SYNOPSIS
        Valida que una configuración tenga estructura válida
    .PARAMETER ConfigName
        Nombre de la configuración a validar
    .PARAMETER RequiredStructure
        Hashtable con la estructura requerida
    .EXAMPLE
        Test-ConfigurationValid -ConfigName "applications" -RequiredStructure @{applications = @{}}
    #>
    param(
        [string]$ConfigName,
        [hashtable]$RequiredStructure
    )
    
    $config = Get-ConfigurationSafe -ConfigName $ConfigName
    
    foreach ($key in $RequiredStructure.Keys) {
        if (-not $config.ContainsKey($key)) {
            Write-Log "Estructura inválida en '$ConfigName': falta clave '$key'" -Level "ERROR" -Component "ConfigManager"
            return $false
        }
    }
    
    Write-Log "Configuración '$ConfigName' tiene estructura válida" -Component "ConfigManager"
    return $true
}

Export-ModuleMember -Function @(
    'Initialize-ConfigurationManager',
    'Get-ConfigurationSafe', 
    'Test-ConfigurationValid'
)
