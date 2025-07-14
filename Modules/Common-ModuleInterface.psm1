<#
.SYNOPSIS
    Interfaz base para módulos de configuración de WinAutoConfigure
.DESCRIPTION
    Define la estructura estándar que deben seguir todos los módulos
    de configuración para garantizar consistencia y interoperabilidad
.NOTES
    Clase base - Implementar en todos los módulos de configuración
.VERSION
    3.0 - Refactorizado con arquitectura orientada a objetos
#>

# Definición de la interfaz base para módulos
class ConfigurationModuleBase {
    [string]$ModuleName
    [string]$Version
    [hashtable]$Config
    [bool]$IsInitialized
    [hashtable]$Status
    
    # Constructor
    ConfigurationModuleBase([string]$Name, [string]$Ver) {
        $this.ModuleName = $Name
        $this.Version = $Ver
        $this.IsInitialized = $false
        $this.Config = @{}
        $this.Status = @{
            LastRun = $null
            Success = $false
            Errors = @()
            Warnings = @()
        }
    }
    
    # Métodos que deben ser implementados por cada módulo
    [bool] ValidatePrerequisites() {
        throw "ValidatePrerequisites() debe ser implementado por la clase derivada"
    }
    
    [bool] Initialize() {
        throw "Initialize() debe ser implementado por la clase derivada"
    }
    
    [bool] Execute() {
        throw "Execute() debe ser implementado por la clase derivada"
    }
    
    [hashtable] GetStatus() {
        return $this.Status
    }
    
    [string] GetModuleName() {
        return $this.ModuleName
    }
    
    [string] GetVersion() {
        return $this.Version
    }
    
    # Métodos auxiliares comunes
    [void] LogInfo([string]$Message) {
        if (Get-Module "Common-Logging" -ErrorAction SilentlyContinue) {
            Write-Log $Message -Level "INFO" -Component $this.ModuleName
        } else {
            Write-Host "[$($this.ModuleName)] INFO: $Message" -ForegroundColor Green
        }
    }
    
    [void] LogWarning([string]$Message) {
        $this.Status.Warnings += $Message
        if (Get-Module "Common-Logging" -ErrorAction SilentlyContinue) {
            Write-Log $Message -Level "WARNING" -Component $this.ModuleName
        } else {
            Write-Host "[$($this.ModuleName)] WARNING: $Message" -ForegroundColor Yellow
        }
    }
    
    [void] LogError([string]$Message) {
        $this.Status.Errors += $Message
        if (Get-Module "Common-Logging" -ErrorAction SilentlyContinue) {
            Write-Log $Message -Level "ERROR" -Component $this.ModuleName
        } else {
            Write-Host "[$($this.ModuleName)] ERROR: $Message" -ForegroundColor Red
        }
    }
    
    [bool] LoadConfiguration([string]$ConfigPath) {
        try {
            if (Test-Path $ConfigPath) {
                $configContent = Get-Content $ConfigPath -Raw | ConvertFrom-Json
                $this.Config = @{}
                
                # Convertir PSCustomObject a Hashtable
                $configContent.PSObject.Properties | ForEach-Object {
                    $this.Config[$_.Name] = $_.Value
                }
                
                $this.LogInfo("Configuración cargada desde: $ConfigPath")
                return $true
            } else {
                $this.LogWarning("Archivo de configuración no encontrado: $ConfigPath")
                return $false
            }
        }
        catch {
            $this.LogError("Error cargando configuración: $($_.Exception.Message)")
            return $false
        }
    }
    
    [void] UpdateStatus([bool]$Success, [string]$Message) {
        $this.Status.LastRun = Get-Date
        $this.Status.Success = $Success
        if ($Message) {
            if ($Success) {
                $this.LogInfo($Message)
            } else {
                $this.LogError($Message)
            }
        }
    }
}

# Enumeración de estados de módulo
enum ModuleExecutionState {
    NotStarted
    Initializing
    ValidatingPrerequisites
    Executing
    Completed
    Failed
    Skipped
}

# Clase para gestión de módulos
class ModuleManager {
    [hashtable]$RegisteredModules
    [hashtable]$ExecutionOrder
    [string]$ConfigPath
    
    ModuleManager([string]$ConfigurationPath) {
        $this.RegisteredModules = @{}
        $this.ExecutionOrder = @{}
        $this.ConfigPath = $ConfigurationPath
    }
    
    [bool] RegisterModule([ConfigurationModuleBase]$Module, [int]$ExecutionOrder) {
        try {
            $this.RegisteredModules[$Module.GetModuleName()] = $Module
            $this.ExecutionOrder[$ExecutionOrder] = $Module.GetModuleName()
            Write-Verbose "Módulo registrado: $($Module.GetModuleName()) en orden $ExecutionOrder"
            return $true
        }
        catch {
            Write-Error "Error registrando módulo: $($_.Exception.Message)"
            return $false
        }
    }

    [ConfigurationModuleBase] GetModule([string]$ModuleName) {
        if ($this.RegisteredModules.ContainsKey($ModuleName)) {
            return $this.RegisteredModules[$ModuleName]
        }
        return $null
    }
    
    [string[]] GetExecutionOrder() {
        $orderedKeys = $this.ExecutionOrder.Keys | Sort-Object
        return $orderedKeys | ForEach-Object { $this.ExecutionOrder[$_] }
    }
    
    [bool] ExecuteModule([string]$ModuleName) {
        $module = $this.GetModule($ModuleName)
        if ($null -eq $module) {
            Write-Error "Módulo no encontrado: $ModuleName"
            return $false
        }
        
        try {
            # Validar prerrequisitos
            if (-not $module.ValidatePrerequisites()) {
                $module.UpdateStatus($false, "Prerrequisitos no cumplidos")
                return $false
            }
            
            # Inicializar módulo
            if (-not $module.Initialize()) {
                $module.UpdateStatus($false, "Fallo en inicialización")
                return $false
            }
            
            # Ejecutar módulo
            $result = $module.Execute()
            if ($result) {
                $message = "Ejecutado correctamente"
            } else {
                $message = "Fallo en ejecución"
            }
            $module.UpdateStatus($result, $message)
            
            return $result
        }
        catch {
            $module.LogError("Error ejecutando módulo: $($_.Exception.Message)")
            $module.UpdateStatus($false, "Excepción durante ejecución")
            return $false
        }
    }
    
    [bool] ExecuteAllModules() {
        $success = $true
        $orderKeys = $this.ExecutionOrder.Keys | Sort-Object
        
        foreach ($order in $orderKeys) {
            $moduleName = $this.ExecutionOrder[$order]
            Write-Host "Ejecutando módulo: $moduleName" -ForegroundColor Cyan
            
            if (-not $this.ExecuteModule($moduleName)) {
                Write-Warning "Módulo $moduleName falló"
                $success = $false
                
                # Decidir si continuar basado en configuración
                $module = $this.GetModule($moduleName)
                if ($module.Config.ContainsKey("stop_on_error") -and $module.Config.stop_on_error) {
                    Write-Error "Deteniendo ejecución debido a error en $moduleName"
                    break
                }
            }
        }
        
        return $success
    }
    
    [hashtable] GetOverallStatus() {
        $status = @{
            TotalModules = $this.RegisteredModules.Count
            SuccessfulModules = 0
            FailedModules = 0
            ModuleDetails = @{}
        }
        
        foreach ($moduleName in $this.RegisteredModules.Keys) {
            $module = $this.RegisteredModules[$moduleName]
            $moduleStatus = $module.GetStatus()
            
            $status.ModuleDetails[$moduleName] = $moduleStatus
            
            if ($moduleStatus.Success) {
                $status.SuccessfulModules++
            } else {
                $status.FailedModules++
            }
        }
        
        return $status
    }
}

# Función auxiliar para crear instancias de módulos simplificada
function New-ConfigurationModule {
    <#
    .SYNOPSIS
        Crea una nueva instancia de módulo de configuración
    .DESCRIPTION
        Función simplificada para crear módulos básicos que heredan
        de ConfigurationModuleBase con funcionalidad predefinida
    .PARAMETER ModuleName
        Nombre del módulo a crear
    .PARAMETER Version
        Versión del módulo (por defecto 1.0)
    .EXAMPLE
        $module = New-ConfigurationModule -ModuleName "TestModule" -Version "1.0"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,
        [string]$Version = "1.0"
    )
    
    try {
        # Crear una instancia básica del módulo
        return [ConfigurationModuleBase]::new($ModuleName, $Version)
    }
    catch {
        Write-Error "Error creando módulo $ModuleName`: $($_.Exception.Message)"
        return $null
    }
}

# Función auxiliar para crear un manager de módulos
function New-ModuleManager {
    <#
    .SYNOPSIS
        Crea una nueva instancia de ModuleManager
    .PARAMETER ConfigPath
        Ruta al archivo de configuración
    #>
    [CmdletBinding()]
    param(
        [string]$ConfigPath = ""
    )
    
    return [ModuleManager]::new($ConfigPath)
}

# Exportar funciones públicas
Export-ModuleMember -Function @(
    'New-ConfigurationModule',
    'New-ModuleManager'
)
