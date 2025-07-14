<#
.SYNOPSIS
    Módulo de seguimiento de progreso para WinAutoConfigure
.DESCRIPTION
    Proporciona funciones para rastrear y persistir el progreso de configuración
.NOTES
    Módulo interno - Gestión de estado de progreso
#>

# Variables del módulo
$script:ProgressFile = ""
$script:CurrentProgress = @{}

function Initialize-ProgressModule {
    [CmdletBinding()]
    param(
        [string]$ProgressDirectory = "Cache"
    )
    
    try {
        $progressDir = Join-Path $PSScriptRoot "..\$ProgressDirectory"
        $script:ProgressFile = Join-Path $progressDir "progress.json"
        
        if (-not (Test-Path $progressDir)) {
            New-Item -Path $progressDir -ItemType Directory -Force | Out-Null
        }
        
        # Cargar progreso existente o crear nuevo
        if (Test-Path $script:ProgressFile) {
            $progressData = Get-Content $script:ProgressFile -Raw | ConvertFrom-Json
            $script:CurrentProgress = @{
                CurrentStep = $progressData.CurrentStep
                LastExecution = $progressData.LastExecution
                CompletedSteps = $progressData.CompletedSteps
                ErrorCount = $progressData.ErrorCount
            }
        } else {
            $script:CurrentProgress = @{
                CurrentStep = 1
                LastExecution = Get-Date
                CompletedSteps = @()
                ErrorCount = 0
            }
            Save-Progress
        }
        
        Write-Verbose "Módulo de progreso inicializado: $script:ProgressFile"
        return $true
    }
    catch {
        Write-Error "Error inicializando módulo de progreso: $($_.Exception.Message)"
        return $false
    }
}

function Get-CurrentStep {
    <#
    .SYNOPSIS
        Obtiene el paso actual de configuración
    #>
    [CmdletBinding()]
    param()
    
    return $script:CurrentProgress.CurrentStep
}

function Set-CurrentStep {
    <#
    .SYNOPSIS
        Establece el paso actual de configuración
    #>
    [CmdletBinding()]
    param(
        [int]$StepNumber
    )
    
    try {
        $script:CurrentProgress.CurrentStep = $StepNumber
        $script:CurrentProgress.LastExecution = Get-Date
        
        if ($StepNumber -notin $script:CurrentProgress.CompletedSteps) {
            $script:CurrentProgress.CompletedSteps += ($StepNumber - 1)
        }
        
        Save-Progress
        Write-Verbose "Paso actual actualizado a: $StepNumber"
        return $true
    }
    catch {
        Write-Error "Error actualizando paso: $($_.Exception.Message)"
        return $false
    }
}

function Add-CompletedStep {
    <#
    .SYNOPSIS
        Marca un paso como completado
    #>
    [CmdletBinding()]
    param(
        [int]$StepNumber
    )
    
    try {
        if ($StepNumber -notin $script:CurrentProgress.CompletedSteps) {
            $script:CurrentProgress.CompletedSteps += $StepNumber
        }
        Save-Progress
        return $true
    }
    catch {
        Write-Error "Error marcando paso como completado: $($_.Exception.Message)"
        return $false
    }
}

function Test-StepCompleted {
    <#
    .SYNOPSIS
        Verifica si un paso ha sido completado
    #>
    [CmdletBinding()]
    param(
        [int]$StepNumber
    )
    
    return $StepNumber -in $script:CurrentProgress.CompletedSteps
}

function Reset-Progress {
    <#
    .SYNOPSIS
        Reinicia el progreso de configuración
    #>
    [CmdletBinding()]
    param()
    
    try {
        $script:CurrentProgress = @{
            CurrentStep = 1
            LastExecution = Get-Date
            CompletedSteps = @()
            ErrorCount = 0
        }
        Save-Progress
        Write-Verbose "Progreso reiniciado"
        return $true
    }
    catch {
        Write-Error "Error reiniciando progreso: $($_.Exception.Message)"
        return $false
    }
}

function Add-ErrorCount {
    <#
    .SYNOPSIS
        Incrementa el contador de errores
    #>
    [CmdletBinding()]
    param()
    
    $script:CurrentProgress.ErrorCount++
    Save-Progress
}

function Get-ProgressSummary {
    <#
    .SYNOPSIS
        Obtiene un resumen del progreso actual
    #>
    [CmdletBinding()]
    param()
    
    return [PSCustomObject]@{
        CurrentStep = $script:CurrentProgress.CurrentStep
        CompletedSteps = $script:CurrentProgress.CompletedSteps
        TotalSteps = 6
        PercentageComplete = [math]::Round(($script:CurrentProgress.CompletedSteps.Count / 6) * 100, 1)
        LastExecution = $script:CurrentProgress.LastExecution
        ErrorCount = $script:CurrentProgress.ErrorCount
    }
}

function Save-Progress {
    <#
    .SYNOPSIS
        Guarda el progreso actual en el archivo JSON
    #>
    [CmdletBinding()]
    param()
    
    try {
        $script:CurrentProgress | ConvertTo-Json -Depth 3 | Set-Content $script:ProgressFile -Encoding UTF8
    }
    catch {
        Write-Warning "Error guardando progreso: $($_.Exception.Message)"
    }
}

# Exportar funciones públicas
Export-ModuleMember -Function @(
    'Initialize-ProgressModule',
    'Get-CurrentStep',
    'Set-CurrentStep',
    'Add-CompletedStep',
    'Test-StepCompleted',
    'Reset-Progress',
    'Add-ErrorCount',
    'Get-ProgressSummary'
)
