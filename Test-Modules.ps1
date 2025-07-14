# Test script para validar la carga de módulos
param(
    [switch]$TestOnly = $false
)

Write-Host "Probando carga de módulos WinAutoConfigure..." -ForegroundColor Cyan

try {
    # Importar módulos necesarios
    $ModulesPath = Join-Path $PSScriptRoot "Modules"
    
    Write-Host "Cargando módulo Common-Logging..." -ForegroundColor Yellow
    Import-Module (Join-Path $ModulesPath "Common-Logging.psm1") -Force
    
    Write-Host "Cargando módulo Common-Cache..." -ForegroundColor Yellow
    Import-Module (Join-Path $ModulesPath "Common-Cache.psm1") -Force
    
    Write-Host "Cargando módulo Common-Validation..." -ForegroundColor Yellow
    Import-Module (Join-Path $ModulesPath "Common-Validation.psm1") -Force
    
    Write-Host "Cargando módulo Common-ProgressTracking..." -ForegroundColor Yellow
    Import-Module (Join-Path $ModulesPath "Common-ProgressTracking.psm1") -Force
    
    Write-Host ""
    Write-Host "Inicializando módulos..." -ForegroundColor Cyan
    
    # Inicializar módulos
    Write-Host "Inicializando Cache..." -ForegroundColor Yellow
    $cacheResult = Initialize-CacheModule
    if ($cacheResult) {
        Write-Host "Cache: OK" -ForegroundColor Green
    } else {
        Write-Host "Cache: ERROR" -ForegroundColor Red
    }
    
    Write-Host "Inicializando Validation..." -ForegroundColor Yellow
    $validationResult = Initialize-ValidationModule
    if ($validationResult) {
        Write-Host "Validation: OK" -ForegroundColor Green
    } else {
        Write-Host "Validation: ERROR" -ForegroundColor Red
    }
    
    Write-Host "Inicializando Progress..." -ForegroundColor Yellow
    $progressResult = Initialize-ProgressModule
    if ($progressResult) {
        Write-Host "Progress: OK" -ForegroundColor Green
    } else {
        Write-Host "Progress: ERROR" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Probando funciones básicas..." -ForegroundColor Cyan
    
    # Probar logging
    Write-Log "Mensaje de prueba" -Level "INFO"
    Write-Host "Logging: OK" -ForegroundColor Green
    
    # Probar progreso
    $currentStep = Get-CurrentStep
    Write-Host "Paso actual: $currentStep" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Todos los módulos cargados correctamente" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "Error cargando módulos:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
