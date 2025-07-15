<#
.SYNOPSIS
    Módulo para manejo estandarizado de errores en WinAutoConfigure
.DESCRIPTION
    Proporciona funciones centralizadas para manejo consistente de errores, logging y recuperación
.NOTES
    Versión: 1.0
    Autor: WinAutoConfigure Team
#>

# Definir enum de severidad usando Add-Type para compatibilidad
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

# Clase para manejo estandarizado de errores
class ErrorHandler {
    static [bool] HandleError([System.Management.Automation.ErrorRecord]$ErrorRecord, [string]$Operation, [string]$Component, [ErrorSeverity]$Severity) {
        $errorMessage = $ErrorRecord.Exception.Message
        $errorDetails = @{
            Operation = $Operation
            Component = $Component
            Severity = $Severity.ToString()
            Message = $errorMessage
            ScriptLineNumber = $ErrorRecord.InvocationInfo.ScriptLineNumber
            PositionMessage = $ErrorRecord.InvocationInfo.PositionMessage
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        # Log del error con formato estándar
        $logLevel = [ErrorHandler]::GetLogLevel($Severity)
        Write-Log "[$($errorDetails.Component)] Error en '$($errorDetails.Operation)': $($errorDetails.Message)" -Level $logLevel
        
        # Log adicional para errores críticos
        if ($Severity -eq [ErrorSeverity]::Critical) {
            Write-Log "CRÍTICO - Línea $($errorDetails.ScriptLineNumber): $($errorDetails.PositionMessage)" -Level "ERROR"
        }
        
        # Determinar si continuar o detener ejecución
        return [ErrorHandler]::ShouldContinue($Severity)
    }
    
    static [string] GetLogLevel([ErrorSeverity]$Severity) {
        switch ($Severity) {
            ([ErrorSeverity]::Low) { return "WARNING" }
            ([ErrorSeverity]::Medium) { return "WARNING" }
            ([ErrorSeverity]::High) { return "ERROR" }
            ([ErrorSeverity]::Critical) { return "ERROR" }
        }
        return "WARNING"  # Default fallback
    }
    
    static [bool] ShouldContinue([ErrorSeverity]$Severity) {
        # Solo detener en errores críticos
        return $Severity -ne [ErrorSeverity]::Critical
    }
}

function Invoke-WithErrorHandling {
    <#
    .SYNOPSIS
        Ejecuta una operación con manejo estandarizado de errores
    .DESCRIPTION
        Wrapper para ejecutar operaciones con manejo consistente de errores y logging
    .PARAMETER Action
        ScriptBlock a ejecutar
    .PARAMETER Operation
        Nombre descriptivo de la operación
    .PARAMETER Component
        Componente que ejecuta la operación
    .PARAMETER Severity
        Severidad del error si ocurre (por defecto Medium)
    .PARAMETER ThrowOnError
        Si debe lanzar excepción en caso de error
    .EXAMPLE
        Invoke-WithErrorHandling -Action { Get-Process } -Operation "Listar procesos" -Component "SystemInfo"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$Action,
        
        [Parameter(Mandatory = $true)]
        [string]$Operation,
        
        [Parameter(Mandatory = $true)]
        [string]$Component,
        
        [Parameter(Mandatory = $false)]
        [ErrorSeverity]$Severity = [ErrorSeverity]::Medium,
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnError,
        
        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )
    
    try {
        if (-not $Silent) {
            Write-Log "Iniciando: $Operation" -Component $Component
        }
        
        $result = & $Action
        
        if (-not $Silent) {
            Write-Log "Completado exitosamente: $Operation" -Component $Component
        }
        
        return $result
    }
    catch {
        $shouldContinue = [ErrorHandler]::HandleError($_, $Operation, $Component, $Severity)
        
        if ($ThrowOnError -or -not $shouldContinue) {
            throw
        }
        
        return $false
    }
}

function Test-WithErrorHandling {
    <#
    .SYNOPSIS
        Ejecuta una validación con manejo estandarizado de errores
    .DESCRIPTION
        Wrapper específico para validaciones que retorna true/false
    .PARAMETER TestAction
        ScriptBlock que contiene la validación
    .PARAMETER TestName
        Nombre descriptivo de la validación
    .PARAMETER Component
        Componente que ejecuta la validación
    .EXAMPLE
        Test-WithErrorHandling -TestAction { Test-Path "C:\Windows" } -TestName "Verificar directorio Windows" -Component "Validation"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$TestAction,
        
        [Parameter(Mandatory = $true)]
        [string]$TestName,
        
        [Parameter(Mandatory = $true)]
        [string]$Component
    )
    
    try {
        $result = & $TestAction
        
        if ($result) {
            Write-Log "EXITOSO: $TestName" -Component $Component
        } else {
            Write-Log "FALLIDO: $TestName" -Component $Component -Level "WARNING"
        }
        
        return [bool]$result
    }
    catch {
        [ErrorHandler]::HandleError($_, $TestName, $Component, [ErrorSeverity]::Low)
        Write-Log "ERROR: $TestName" -Component $Component -Level "ERROR"
        return $false
    }
}

# Función para migración gradual - mantiene compatibilidad con código existente
function Write-ErrorLog {
    <#
    .SYNOPSIS
        Función de compatibilidad para el logging existente
    .DESCRIPTION
        Mantiene compatibilidad mientras migramos al nuevo sistema
    #>
    [CmdletBinding()]
    param(
        [string]$Message,
        [string]$Component = "Legacy",
        [string]$Level = "ERROR"
    )
    
    Write-Log $Message -Level $Level -Component $Component
}

# Exportar funciones públicas y tipos
Export-ModuleMember -Function @(
    'Invoke-WithErrorHandling',
    'Test-WithErrorHandling', 
    'Write-ErrorLog'
) -Cmdlet @()

# Hacer el enum disponible globalmente
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
