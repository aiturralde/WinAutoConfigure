# WinAutoConfigure v3.0 - Script Principal
# Configuración automática para Windows 11 con arquitectura orientada a objetos

param(
    [Parameter(Mandatory=$false)]
    [int]$Step = 0,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowStatus = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ValidateOnly = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ForceRefresh = $false
)

# =====================================================================================
# IMPORTS Y DEPENDENCIAS
# =====================================================================================

# Importar módulos necesarios
$ModulesPath = Join-Path $PSScriptRoot "Modules"

# Cargar módulos comunes
Import-Module (Join-Path $ModulesPath "Common-Logging.psm1") -Force
Import-Module (Join-Path $ModulesPath "Common-Cache.psm1") -Force
Import-Module (Join-Path $ModulesPath "Common-Validation.psm1") -Force
Import-Module (Join-Path $ModulesPath "Common-ProgressTracking.psm1") -Force

# Inicializar módulos
Initialize-CacheModule
Initialize-ValidationModule
Initialize-ProgressModule

# =====================================================================================
# CLASE PRINCIPAL
# =====================================================================================

class WinAutoConfiguration {
    [string]$ConfigPath
    [string]$ModulesPath
    [int]$CurrentStep

    # Constructor
    WinAutoConfiguration([string]$RootPath) {
        $this.ConfigPath = Join-Path $RootPath "Config"
        $this.ModulesPath = Join-Path $RootPath "Modules"
        $this.CurrentStep = 1
    }

    [bool] Initialize() {
        try {
            # Inicializar logging
            Write-Log "Inicializando WinAutoConfiguration v3.0" -Level "INFO"
            
            # Obtener paso actual desde el módulo de progreso
            $this.CurrentStep = Get-CurrentStep
            
            return $true
        }
        catch {
            Write-Error "Error durante inicialización: $($_.Exception.Message)"
            return $false
        }
    }

    [bool] ValidateEnvironment() {
        try {
            Write-Log "Validando entorno del sistema..." -Level "INFO"
            
            # Usar las funciones del módulo de validación
            $requirements = Test-SystemRequirements
            
            if (-not $requirements.AdminRights) {
                Write-Log "Se requieren permisos de administrador" -Level "ERROR"
                return $false
            }
            
            if (-not $requirements.PowerShellVersion) {
                Write-Log "Se requiere PowerShell 5.1 o superior" -Level "ERROR"
                return $false
            }
            
            if (-not $requirements.WindowsVersion) {
                Write-Log "Se requiere Windows 10 v1909 o superior" -Level "ERROR"
                return $false
            }
            
            if (-not $requirements.DiskSpace) {
                Write-Log "Poco espacio en disco disponible" -Level "WARNING"
            }
            
            return $requirements.OverallStatus
        }
        catch {
            Write-Log "Error durante validación: $($_.Exception.Message)" -Level "ERROR"
            return $false
        }
    }

    [void] SetProgress([int]$StepNumber) {
        $this.CurrentStep = $StepNumber
        Set-CurrentStep -StepNumber $StepNumber
        Write-Log "Progreso actualizado: Paso $StepNumber" -Level "INFO"
    }

    [void] ShowProgressStatus() {
        $steps = @(
            "1. Configuracion de Windows Terminal",
            "2. Instalacion de Aplicaciones y Caracteristicas",
            "3. Configuracion de Windows",
            "4. Configuracion de Seguridad de Red", 
            "5. Configuracion de Herramientas de Desarrollo",
            "6. Configuracion Gaming (Optimizaciones)"
        )
        
        $progressSummary = Get-ProgressSummary
        $currentIndex = if ($this.CurrentStep -eq 7 -or $this.CurrentStep -gt 6) { $steps.Count } else { $this.CurrentStep - 1 }
        $percentage = $progressSummary.PercentageComplete
        
        Write-Host "`n" -ForegroundColor Green
        Write-Host "===============================================================" -ForegroundColor Green
        Write-Host "                 WINAUTOCONFIGURE v3.0                        " -ForegroundColor Green
        Write-Host "===============================================================" -ForegroundColor Green
        
        if ($this.CurrentStep -eq 7 -or $this.CurrentStep -gt 6) {
            Write-Host " Estado: COMPLETADO (100%)                                 " -ForegroundColor Green
        } else {
            Write-Host " Paso actual: $($this.CurrentStep)/6 ($percentage%)                                     " -ForegroundColor Green
        }
        
        for ($i = 0; $i -lt $steps.Count; $i++) {
            $stepCompleted = Test-StepCompleted -StepNumber ($i + 1)
            if ($this.CurrentStep -eq 7 -or $this.CurrentStep -gt 6 -or $stepCompleted) {
                $status = "[X]"
                $color = "Green"
            } elseif ($i -eq $currentIndex -and $this.CurrentStep -ne 7) {
                $status = "[>]"
                $color = "Yellow"
            } else {
                $status = "[ ]"
                $color = "Gray"
            }
            Write-Host " $status $($steps[$i])" -ForegroundColor $color
        }
        
        Write-Host "===============================================================" -ForegroundColor Green
        Write-Host "`n"
    }

    [bool] ExecuteStep([int]$StepNumber) {
        if ($StepNumber -lt 1 -or $StepNumber -gt 6) {
            Write-Log "Número de paso inválido: $StepNumber" -Level "ERROR"
            return $false
        }
        
        $stepMapping = @{
            1 = @{ Module = "Setup-WindowsTerminal.ps1"; Function = "Initialize-WindowsTerminalModule" }
            2 = @{ Module = "Install-Applications.ps1"; Function = "Install-ApplicationsModule" }
            3 = @{ Module = "Configure-WindowsSettings.ps1"; Function = "Initialize-WindowsSettingsModule" }
            4 = @{ Module = "Configure-NetworkSecurity.ps1"; Function = "Initialize-NetworkSecurityModule" }
            5 = @{ Module = "Configure-DevelopmentTools.ps1"; Function = "Initialize-DevelopmentToolsModule" }
            6 = @{ Module = "Configure-Gaming.ps1"; Function = "Start-GamingConfiguration" }
        }
        
        $stepInfo = $stepMapping[$StepNumber]
        $modulePath = Join-Path $this.ModulesPath $stepInfo.Module
        
        try {
            Write-Log "Ejecutando paso $StepNumber : $($stepInfo.Module)" -Level "INFO"
            
            if (-not (Test-Path $modulePath)) {
                Write-Log "Módulo no encontrado: $modulePath" -Level "ERROR"
                return $false
            }
            
            # Cargar y ejecutar módulo
            . $modulePath
            if (Get-Command $stepInfo.Function -ErrorAction SilentlyContinue) {
                $result = & $stepInfo.Function
                if ($result) {
                    Add-CompletedStep -StepNumber $StepNumber
                    $this.SetProgress($StepNumber + 1)
                    return $true
                } else {
                    Add-ErrorCount
                    return $false
                }
            } else {
                Write-Log "Función no encontrada: $($stepInfo.Function)" -Level "ERROR"
                return $false
            }
        }
        catch {
            Write-Log "Error ejecutando paso $StepNumber : $($_.Exception.Message)" -Level "ERROR"
            Add-ErrorCount
            return $false
        }
    }
    
    [bool] ExecuteAllSteps() {
        Write-Log "Iniciando ejecución completa de WinAutoConfigure" -Level "INFO"
        
        # Ejecutar desde el paso actual hasta el final
        for ($step = $this.CurrentStep; $step -le 6; $step++) {
            if (-not $this.ExecuteStep($step)) {
                Write-Log "Ejecución detenida en el paso $step" -Level "ERROR"
                return $false
            }
            
            # Pequeña pausa entre pasos
            Start-Sleep 2
        }
        
        # Cargar módulo auxiliar UI-Helpers
        $uiHelpersPath = Join-Path $this.ModulesPath "UI-Helpers.ps1"
        if (Test-Path $uiHelpersPath) {
            try {
                Write-Log "Cargando módulos auxiliares..." -Level "INFO"
                . $uiHelpersPath
                if (Get-Command "Initialize-UIHelpersModule" -ErrorAction SilentlyContinue) {
                    Initialize-UIHelpersModule
                }
            }
            catch {
                Write-Log "Error cargando UI-Helpers: $($_.Exception.Message)" -Level "WARNING"
            }
        }
        
        $this.SetProgress(7)  # Marcar como completado
        Write-Log "=== ¡Configuración completada exitosamente! ===" -Level "INFO"
        return $true
    }
}

# =====================================================================================
# FUNCIONES AUXILIARES
# =====================================================================================

function Show-WelcomeMessage {
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host "                                                               " -ForegroundColor Cyan
    Write-Host "               WINAUTOCONFIGURE v3.0                          " -ForegroundColor Cyan
    Write-Host "                                                               " -ForegroundColor Cyan
    Write-Host "          Configuracion Automatica para Windows 11            " -ForegroundColor Cyan
    Write-Host "                                                               " -ForegroundColor Cyan
    Write-Host "  Nueva arquitectura orientada a objetos                      " -ForegroundColor Cyan
    Write-Host "  Cache inteligente para mejor rendimiento                    " -ForegroundColor Cyan
    Write-Host "  Validaciones robustas del sistema                          " -ForegroundColor Cyan
    Write-Host "  Monitoreo avanzado de progreso                             " -ForegroundColor Cyan
    Write-Host "                                                               " -ForegroundColor Cyan
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Test-Prerequisites {
    # Verificación básica antes de inicializar la clase principal
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "Este script debe ejecutarse como administrador"
        return $false
    }
    
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Error "PowerShell 5.1 o superior es requerido"
        return $false
    }
    
    return $true
}

# =====================================================================================
# EJECUCIÓN PRINCIPAL
# =====================================================================================

# Verificar prerrequisitos básicos
if (-not (Test-Prerequisites)) {
    exit 1
}

# Mostrar mensaje de bienvenida si no es solo status
if (-not $ShowStatus) {
    Show-WelcomeMessage
}

# Inicializar configuración principal
$winAutoConfig = [WinAutoConfiguration]::new($PSScriptRoot)

if (-not $winAutoConfig.Initialize()) {
    Write-Error "Error inicializando WinAutoConfigure"
    exit 1
}

# Manejar parámetros
if ($ShowStatus) {
    $winAutoConfig.ShowProgressStatus()
    exit 0
}

if ($ValidateOnly) {
    Write-Host "Ejecutando validacion completa del sistema..." -ForegroundColor Cyan
    $isValid = $winAutoConfig.ValidateEnvironment()
    
    if ($isValid) {
        Write-Host "Sistema validado correctamente" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "Errores de validacion detectados" -ForegroundColor Red
        exit 1
    }
}

# Validar entorno antes de continuar
if (-not $winAutoConfig.ValidateEnvironment()) {
    Write-Error "El sistema no cumple con los requisitos mínimos"
    exit 1
}

# Limpiar cache si se solicita
if ($ForceRefresh) {
    Write-Log "Limpiando cache..." -Level "INFO"
    Clear-ModuleCache -ModuleName "*"
}

# Ejecutar paso específico o todos los pasos
try {
    if ($Step -gt 0) {
        # Ejecutar paso específico
        $success = $winAutoConfig.ExecuteStep($Step)
        if (-not $success) {
            exit 1
        }
    } else {
        # Ejecutar todos los pasos desde el actual
        $success = $winAutoConfig.ExecuteAllSteps()
        if (-not $success) {
            exit 1
        }
    }
    
    # Mostrar estado final
    $winAutoConfig.ShowProgressStatus()
    
    Write-Host "WinAutoConfigure completado exitosamente!" -ForegroundColor Green
    Write-Host "Para ver el estado: .\WinAutoConfigure.ps1 -ShowStatus" -ForegroundColor Cyan
    
} catch {
    Write-Log "Error durante ejecucion: $($_.Exception.Message)" -Level "ERROR"
    Add-ErrorCount
    Write-Error "Error durante la ejecucion. Consulte los logs para mas detalles."
    exit 1
}
