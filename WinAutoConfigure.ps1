# WinAutoConfigure v3.1 - Script Principal
# Configuración automática para Windows 11 con arquitectura orientada a objetos

param(
    [Parameter(Mandatory=$false)]
    [int]$Step = 0,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowStatus = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ValidateOnly = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ForceRefresh = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DiagnosticReport = $false
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
Initialize-ProgressModule

# Verificar que Initialize-ValidationModule esté disponible
if (Get-Command Initialize-ValidationModule -ErrorAction SilentlyContinue) {
    Initialize-ValidationModule
} else {
    Write-Log "Initialize-ValidationModule no disponible, continuando..." -Level "WARNING"
}

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
            Write-Log "Inicializando WinAutoConfiguration v3.1" -Level "INFO"
            
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
            
            # Mostrar información detallada de la validación
            if ($requirements.Details) {
                Write-Log "=== INFORMACION DEL SISTEMA ===" -Level "INFO"
                
                if ($requirements.Details.OSName) {
                    Write-Log "Sistema Operativo: $($requirements.Details.OSName)" -Level "INFO"
                }
                if ($requirements.Details.OSVersion) {
                    Write-Log "Versión del SO: $($requirements.Details.OSVersion)" -Level "INFO"
                }
                if ($requirements.Details.BuildNumber) {
                    Write-Log "Build Number: $($requirements.Details.BuildNumber)" -Level "INFO"
                }
                if ($requirements.Details.PSVersion) {
                    Write-Log "PowerShell: v$($requirements.Details.PSVersion)" -Level "INFO"
                }
                if ($requirements.Details.CurrentUser) {
                    Write-Log "Usuario actual: $($requirements.Details.CurrentUser)" -Level "INFO"
                }
                if ($requirements.Details.TotalRAM) {
                    Write-Log "Memoria RAM: $($requirements.Details.TotalRAM) GB" -Level "INFO"
                }
                if ($requirements.Details.FreeSpace -and $requirements.Details.TotalSpace) {
                    Write-Log "Espacio en disco: $($requirements.Details.FreeSpace) GB libres de $($requirements.Details.TotalSpace) GB" -Level "INFO"
                }
                
                Write-Log "=== RESULTADOS DE VALIDACION ===" -Level "INFO"
            }
            
            # Verificar cada requisito y proporcionar mensajes específicos
            $validationPassed = $true
            
            if (-not $requirements.AdminRights) {
                Write-Log "❌ FALLA: Se requieren permisos de administrador" -Level "ERROR"
                Write-Log "   Solución: Ejecute el script desde una ventana de PowerShell como administrador" -Level "ERROR"
                $validationPassed = $false
            } else {
                Write-Log "✅ Permisos de administrador: OK" -Level "SUCCESS"
            }
            
            if (-not $requirements.PowerShellVersion) {
                Write-Log "❌ FALLA: Se requiere PowerShell 5.1 o superior" -Level "ERROR"
                if ($requirements.Details.PSVersion) {
                    Write-Log "   Versión actual: $($requirements.Details.PSVersion)" -Level "ERROR"
                }
                Write-Log "   Solución: Actualice PowerShell a la versión 5.1 o superior" -Level "ERROR"
                $validationPassed = $false
            } else {
                Write-Log "✅ Versión de PowerShell: OK" -Level "SUCCESS"
            }
            
            if (-not $requirements.WindowsVersion) {
                Write-Log "❌ FALLA: Se requiere Windows 10 v1909 o superior" -Level "ERROR"
                if ($requirements.Details.OSName) {
                    Write-Log "   Sistema actual: $($requirements.Details.OSName)" -Level "ERROR"
                }
                if ($requirements.Details.OSVersion) {
                    Write-Log "   Versión actual: $($requirements.Details.OSVersion)" -Level "ERROR"
                }
                Write-Log "   Solución: Actualice a una versión compatible de Windows" -Level "ERROR"
                $validationPassed = $false
            } else {
                Write-Log "✅ Versión de Windows: OK" -Level "SUCCESS"
            }
            
            if (-not $requirements.DiskSpace) {
                Write-Log "⚠️  ADVERTENCIA: Poco espacio en disco disponible" -Level "WARNING"
                if ($requirements.Details.FreeSpace) {
                    Write-Log "   Espacio libre: $($requirements.Details.FreeSpace) GB" -Level "WARNING"
                }
                Write-Log "   Recomendación: Libere espacio en disco antes de continuar" -Level "WARNING"
                # No fallar por espacio en disco, solo advertir
            } else {
                Write-Log "✅ Espacio en disco: OK" -Level "SUCCESS"
            }
            
            if (-not $requirements.MemoryRequirement) {
                Write-Log "⚠️  ADVERTENCIA: Memoria RAM limitada" -Level "WARNING"
                if ($requirements.Details.TotalRAM) {
                    Write-Log "   RAM disponible: $($requirements.Details.TotalRAM) GB" -Level "WARNING"
                }
                Write-Log "   Recomendación: El rendimiento puede verse afectado" -Level "WARNING"
                # No fallar por RAM limitada, solo advertir
            } else {
                Write-Log "✅ Memoria RAM: OK" -Level "SUCCESS"
            }
            
            # Mostrar errores específicos si los hay
            if ($requirements.Details.OSError) {
                Write-Log "Error obteniendo información del SO: $($requirements.Details.OSError)" -Level "ERROR"
            }
            if ($requirements.Details.PSError) {
                Write-Log "Error obteniendo información de PowerShell: $($requirements.Details.PSError)" -Level "ERROR"
            }
            if ($requirements.Details.AdminError) {
                Write-Log "Error validando permisos: $($requirements.Details.AdminError)" -Level "ERROR"
            }
            if ($requirements.Details.CriticalError) {
                Write-Log "Error crítico durante validación: $($requirements.Details.CriticalError)" -Level "ERROR"
                $validationPassed = $false
            }
            
            if ($validationPassed) {
                Write-Log "✅ Todas las validaciones críticas pasaron correctamente" -Level "SUCCESS"
            } else {
                Write-Log "❌ Una o más validaciones críticas fallaron" -Level "ERROR"
                Write-Log "   Consulte los mensajes anteriores para soluciones específicas" -Level "ERROR"
            }
            
            return $validationPassed
            
        }
        catch {
            Write-Log "Error crítico durante validación: $($_.Exception.Message)" -Level "ERROR"
            Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level "ERROR"
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
        Write-Host "                 WINAUTOCONFIGURE v3.1                        " -ForegroundColor Green
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
        
        # Mostrar información especial si está en el paso 5 (después del reinicio requerido)
        if ($this.CurrentStep -eq 5 -and (Test-StepCompleted -StepNumber 4)) {
            Write-Host ""
            Write-Host " 💾 PROGRESO RESTAURADO DESDE CACHE" -ForegroundColor Cyan
            Write-Host " 🔄 Continuando desde donde se quedó..." -ForegroundColor Cyan
        }
        
        # Mostrar próximos pasos si no está completado
        if ($this.CurrentStep -le 6 -and $this.CurrentStep -ne 7) {
            Write-Host ""
            Write-Host " ▶️  SIGUIENTE: Ejecute .\WinAutoConfigure.ps1 -Step $($this.CurrentStep)" -ForegroundColor Cyan
        }
        
        Write-Host "===============================================================" -ForegroundColor Green
        Write-Host "`n"
    }

    [void] ShowRestartMessage([int]$CompletedStep) {
        $nextStep = $CompletedStep + 1
        
        Write-Host ""
        Write-Host "===============================================================" -ForegroundColor Yellow
        Write-Host "                    REINICIO REQUERIDO                        " -ForegroundColor Yellow
        Write-Host "===============================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "✅ PASO $CompletedStep COMPLETADO EXITOSAMENTE" -ForegroundColor Green
        Write-Host ""
        Write-Host "🔄 ACCIÓN REQUERIDA:" -ForegroundColor Yellow
        Write-Host "   Las configuraciones aplicadas requieren reiniciar" -ForegroundColor White
        Write-Host "   la sesión de PowerShell para tomar efecto." -ForegroundColor White
        Write-Host ""
        Write-Host "📋 INSTRUCCIONES:" -ForegroundColor Cyan
        Write-Host "   1. Cierre esta ventana de PowerShell" -ForegroundColor White
        Write-Host "   2. Abra una nueva ventana de PowerShell como Administrador" -ForegroundColor White
        Write-Host "   3. Navegue al directorio:" -ForegroundColor White
        Write-Host "      cd '$PSScriptRoot'" -ForegroundColor Gray
        Write-Host "   4. Ejecute el siguiente comando para continuar:" -ForegroundColor White
        Write-Host "      .\WinAutoConfigure.ps1 -Step $nextStep" -ForegroundColor Green
        Write-Host ""
        Write-Host "💾 EL PROGRESO SE HA GUARDADO AUTOMÁTICAMENTE" -ForegroundColor Green
        Write-Host "   Su progreso actual: $CompletedStep/6 pasos completados" -ForegroundColor Green
        Write-Host ""
        Write-Host "ℹ️  NOTA: El cache inteligente recordará su progreso" -ForegroundColor Cyan
        Write-Host "   No es necesario repetir los pasos anteriores" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "===============================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Log "Usuario debe reiniciar PowerShell después del paso $CompletedStep para continuar con paso $nextStep" -Level "INFO"
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
            4 = @{ Module = "Configure-NetworkSecurity.ps1"; Function = "Initialize-NetworkSecurityModule"; RequiresRestart = $true }
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
                    
                    # Manejar paso especial que requiere reinicio de PowerShell
                    if ($stepInfo.RequiresRestart) {
                        $this.ShowRestartMessage($StepNumber)
                        return $true
                    }
                    
                    return $true
                } else {
                    Write-Log "El módulo $($stepInfo.Module) retornó false" -Level "ERROR"
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
            Write-Log "Detalles del error: $($_.ScriptStackTrace)" -Level "ERROR"
            Add-ErrorCount
            return $false
        }
    }
    
    [bool] ExecuteAllSteps() {
        Write-Log "Iniciando ejecución completa de WinAutoConfigure" -Level "INFO"
        
        # Mapeo de pasos que requieren reinicio
        $restartRequiredSteps = @(4)
        
        # Ejecutar desde el paso actual hasta el final
        for ($step = $this.CurrentStep; $step -le 6; $step++) {
            if (-not $this.ExecuteStep($step)) {
                Write-Log "Ejecución detenida en el paso $step" -Level "ERROR"
                return $false
            }
            
            # Si este paso requiere reinicio, detener la ejecución aquí
            if ($restartRequiredSteps -contains $step) {
                Write-Log "Ejecución pausada después del paso $step (reinicio requerido)" -Level "INFO"
                return $true  # Retorna true porque el paso se completó exitosamente
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
    Write-Host "               WINAUTOCONFIGURE v3.1                          " -ForegroundColor Cyan
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

function New-DiagnosticReport {
    Write-Host "=== REPORTE DE DIAGNOSTICO WINAUTOCONFIGURE ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Sistema operativo
    Write-Host "SISTEMA OPERATIVO:" -ForegroundColor Green
    $osInfo = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($osInfo) {
        Write-Host "  Nombre: $($osInfo.Caption)" -ForegroundColor White
        Write-Host "  Version: $($osInfo.Version)" -ForegroundColor White
        $isCompatible = [Version]$osInfo.Version -ge [Version]"10.0.10240"
        $status = if ($isCompatible) { "Compatible" } else { "No Compatible" }
        Write-Host "  Estado: $status" -ForegroundColor $(if ($isCompatible) { "Green" } else { "Red" })
    }
    
    Write-Host ""
    
    # PowerShell
    Write-Host "POWERSHELL:" -ForegroundColor Green
    Write-Host "  Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
    $isPSCompatible = $PSVersionTable.PSVersion.Major -ge 5
    $status = if ($isPSCompatible) { "Compatible" } else { "No Compatible" }
    Write-Host "  Estado: $status" -ForegroundColor $(if ($isPSCompatible) { "Green" } else { "Red" })
    
    Write-Host ""
    
    # Permisos
    Write-Host "PERMISOS:" -ForegroundColor Green
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    
    Write-Host "  Usuario: $($currentUser.Name)" -ForegroundColor White
    $status = if ($isAdmin) { "Administrador" } else { "Usuario Estandar" }
    Write-Host "  Estado: $status" -ForegroundColor $(if ($isAdmin) { "Green" } else { "Red" })
    
    if (-not $isAdmin) {
        Write-Host "  SOLUCION: Ejecute PowerShell como Administrador" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "RESUMEN:" -ForegroundColor Green
    if ($isPSCompatible -and $isAdmin) {
        Write-Host "Su sistema cumple con todos los requisitos" -ForegroundColor Green
        Write-Host "   Ejecute: .\WinAutoConfigure.ps1" -ForegroundColor Cyan
    } else {
        Write-Host "Su sistema requiere atencion:" -ForegroundColor Red
        if (-not $isPSCompatible) {
            Write-Host "   • Actualice PowerShell a v5.1 o superior" -ForegroundColor Yellow
        }
        if (-not $isAdmin) {
            Write-Host "   • Ejecute PowerShell como Administrador" -ForegroundColor Yellow
        }
    }
    
    return $true
}

# =====================================================================================
# EJECUCION PRINCIPAL
# =====================================================================================

# Manejar reporte de diagnostico sin requerir permisos de administrador
if ($DiagnosticReport) {
    $reportResult = New-DiagnosticReport
    exit $(if ($reportResult) { 0 } else { 1 })
}

# Verificar prerrequisitos básicos
if (-not (Test-Prerequisites)) {
    Write-Host ""
    Write-Host "AYUDA: Para obtener un reporte de diagnóstico detallado, ejecute:" -ForegroundColor Cyan
    Write-Host ".\WinAutoConfigure.ps1 -DiagnosticReport" -ForegroundColor Cyan
    Write-Host ""
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
