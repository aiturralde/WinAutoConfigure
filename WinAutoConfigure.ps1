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
$ModulesPath = Join-Path $PSScriptRoot "modules"

# Cargar módulo de Logging
. (Join-Path $ModulesPath "Logging.ps1")

# Cargar módulo de Cache
. (Join-Path $ModulesPath "Cache.ps1")

# Cargar módulo de Progress Tracking
. (Join-Path $ModulesPath "ProgressTracking.ps1")

# Cargar módulo de System Validation
. (Join-Path $ModulesPath "SystemValidation.ps1")

# =====================================================================================
# CLASE PRINCIPAL
# =====================================================================================

class WinAutoConfiguration {
    [object]$Logger
    [object]$Cache
    [object]$ProgressTracker
    [object]$Validator
    [string]$ConfigPath
    [string]$ModulesPath
    [int]$CurrentStep

    # Constructor
    WinAutoConfiguration([string]$RootPath) {
        $this.ConfigPath = Join-Path $RootPath "config"
        $this.ModulesPath = Join-Path $RootPath "modules"
        $this.CurrentStep = 1
    }

    [bool] Initialize() {
        try {
            # Inicializar Logger
            $this.Logger = [Logger]::new((Join-Path $this.ConfigPath "logs"))
            $this.Logger.LogInfo("Inicializando WinAutoConfiguration v3.0")
            
            # Inicializar Cache
            $this.Cache = [CacheManager]::new((Join-Path $this.ConfigPath "cache"))
            
            # Inicializar Progress Tracker
            $this.ProgressTracker = [ProgressTracker]::new((Join-Path $this.ConfigPath "progress.json"))
            $this.CurrentStep = $this.ProgressTracker.GetCurrentStep()
            
            # Inicializar System Validator
            $this.Validator = [SystemValidator]::new()
            
            return $true
        }
        catch {
            Write-Error "Error durante inicialización: $($_.Exception.Message)"
            return $false
        }
    }

    [bool] ValidateEnvironment() {
        try {
            $this.Logger.LogInfo("Validando entorno del sistema...")
            
            # Verificar permisos de administrador
            if (-not $this.Validator.IsAdministrator()) {
                $this.Logger.LogError("Se requieren permisos de administrador")
                return $false
            }
            
            # Verificar versión de PowerShell
            if (-not $this.Validator.ValidatePowerShellVersion()) {
                $this.Logger.LogError("Se requiere PowerShell 5.1 o superior")
                return $false
            }
            
            # Verificar versión de Windows
            if (-not $this.Validator.ValidateWindowsVersion()) {
                $this.Logger.LogError("Se requiere Windows 10 v1909 o superior")
                return $false
            }
            
            # Verificar espacio en disco
            if (-not $this.Validator.ValidateDiskSpace()) {
                $this.Logger.LogWarning("Poco espacio en disco disponible")
            }
            
            return $true
        }
        catch {
            $this.Logger.LogError("Error durante validación: $($_.Exception.Message)")
            return $false
        }
    }

    [void] SetProgress([int]$StepNumber) {
        $this.CurrentStep = $StepNumber
        $this.ProgressTracker.SetCurrentStep($StepNumber)
        $this.Logger.LogInfo("Progreso actualizado: Paso $StepNumber")
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
        
        $currentIndex = if ($this.CurrentStep -eq 7 -or $this.CurrentStep -gt 6) { $steps.Count } else { $this.CurrentStep - 1 }
        $percentage = [math]::Round((($currentIndex) / $steps.Count) * 100, 1)
        
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
            if ($this.CurrentStep -eq 7 -or $this.CurrentStep -gt 6 -or $i -lt $currentIndex) {
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
            $this.Logger.LogError("Número de paso inválido: $StepNumber")
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
            $this.Logger.LogInfo("Ejecutando paso $StepNumber : $($stepInfo.Module)")
            
            if (-not (Test-Path $modulePath)) {
                $this.Logger.LogError("Módulo no encontrado: $modulePath")
                return $false
            }
            
            # Cargar y ejecutar módulo
            . $modulePath
            if (Get-Command $stepInfo.Function -ErrorAction SilentlyContinue) {
                $result = & $stepInfo.Function
                if ($result) {
                    $this.SetProgress($StepNumber + 1)
                    return $true
                } else {
                    return $false
                }
            } else {
                $this.Logger.LogError("Función no encontrada: $($stepInfo.Function)")
                return $false
            }
        }
        catch {
            $this.Logger.LogError("Error ejecutando paso $StepNumber : $($_.Exception.Message)")
            return $false
        }
    }
    
    [bool] ExecuteAllSteps() {
        $this.Logger.LogInfo("Iniciando ejecución completa de WinAutoConfigure")
        
        # Ejecutar desde el paso actual hasta el final
        for ($step = $this.CurrentStep; $step -le 6; $step++) {
            if (-not $this.ExecuteStep($step)) {
                $this.Logger.LogError("Ejecución detenida en el paso $step")
                return $false
            }
            
            # Pequeña pausa entre pasos
            Start-Sleep 2
        }
        
        # Cargar módulo auxiliar UI-Helpers
        $uiHelpersPath = Join-Path $this.ModulesPath "UI-Helpers.ps1"
        if (Test-Path $uiHelpersPath) {
            try {
                $this.Logger.LogInfo("Cargando módulos auxiliares...")
                . $uiHelpersPath
                if (Get-Command "Initialize-UIHelpersModule" -ErrorAction SilentlyContinue) {
                    Initialize-UIHelpersModule
                }
            }
            catch {
                $this.Logger.LogWarning("Error cargando UI-Helpers: $($_.Exception.Message)")
            }
        }
        
        $this.SetProgress(7)  # Marcar como completado
        $this.Logger.LogInfo("=== ¡Configuración completada exitosamente! ===")
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
    $winAutoConfig.Logger.LogInfo("Limpiando cache...")
    $winAutoConfig.Cache.Clear("*")
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
    $winAutoConfig.Logger.LogError("Error durante ejecucion: $($_.Exception.Message)")
    Write-Error "Error durante la ejecucion. Consulte los logs para mas detalles."
    exit 1
}
