<#
.SYNOPSIS
    Suite de tests para módulos de WinAutoConfigure
.DESCRIPTION
    Ejecuta tests automatizados para validar el funcionamiento
    de todos los módulos del sistema
.NOTES
    Ejecutar antes de deployment en producción
#>

param(
    [string]$ModuleName = "*",
    [switch]$Detailed,
    [switch]$ExportResults
)

# Importar módulos necesarios
$ModulesPath = Join-Path $PSScriptRoot "..\Modules"
Import-Module (Join-Path $ModulesPath "Common-Logging.psm1") -Force
Import-Module (Join-Path $ModulesPath "Common-Validation.psm1") -Force

function Test-ModuleStructure {
    <#
    .SYNOPSIS
        Verifica la estructura correcta de los módulos
    #>
    param([string]$ModulePath)
    
    $results = @{
        ModuleName = Split-Path $ModulePath -Leaf
        HasValidSyntax = $false
        HasRequiredFunctions = $false
        HasDocumentation = $false
        Issues = @()
    }
    
    try {
        # Test 1: Sintaxis válida
        $syntaxErrors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $ModulePath -Raw), [ref]$syntaxErrors)
        
        if ($syntaxErrors.Count -eq 0) {
            $results.HasValidSyntax = $true
        } else {
            $results.Issues += "Errores de sintaxis: $($syntaxErrors.Count)"
        }
        
        # Test 2: Funciones requeridas
        $content = Get-Content $ModulePath -Raw
        $requiredPatterns = @(
            'function\s+\w+',  # Al menos una función
            '\.SYNOPSIS',      # Documentación
            'param\s*\('       # Parámetros
        )
        
        $hasRequired = $true
        foreach ($pattern in $requiredPatterns) {
            if ($content -notmatch $pattern) {
                $hasRequired = $false
                $results.Issues += "Falta patrón requerido: $pattern"
            }
        }
        $results.HasRequiredFunctions = $hasRequired
        
        # Test 3: Documentación
        if ($content -match '\.SYNOPSIS' -and $content -match '\.DESCRIPTION') {
            $results.HasDocumentation = $true
        } else {
            $results.Issues += "Documentación incompleta"
        }
        
    } catch {
        $results.Issues += "Error analizando módulo: $($_.Exception.Message)"
    }
    
    return $results
}

function Test-ConfigurationFiles {
    <#
    .SYNOPSIS
        Verifica la integridad de archivos de configuración
    #>
    
    $configPath = Join-Path $PSScriptRoot "..\Config"
    $results = @{
        TestName = "ConfigurationFiles"
        TotalFiles = 0
        ValidFiles = 0
        InvalidFiles = @()
        Success = $false
    }
    
    $configFiles = Get-ChildItem $configPath -Filter "*.json"
    $results.TotalFiles = $configFiles.Count
    
    foreach ($file in $configFiles) {
        try {
            $null = Get-Content $file.FullName -Raw | ConvertFrom-Json
            $results.ValidFiles++
        } catch {
            $results.InvalidFiles += @{
                File = $file.Name
                Error = $_.Exception.Message
            }
        }
    }
    
    $results.Success = ($results.InvalidFiles.Count -eq 0) -and ($results.ValidFiles -gt 0)
    return $results
}

function Test-SystemCompatibility {
    <#
    .SYNOPSIS
        Verifica compatibilidad con el sistema actual
    #>
    
    $results = @{
        TestName = "SystemCompatibility"
        WindowsVersion = $false
        PowerShellVersion = $false
        AdminRights = $false
        RequiredModules = $false
        Success = $false
    }
    
    try {
        # Verificar Windows 11
        $osVersion = [Environment]::OSVersion.Version
        $results.WindowsVersion = $osVersion.Major -eq 10 -and $osVersion.Build -ge 22000
        
        # Verificar PowerShell 5.1+
        $results.PowerShellVersion = $PSVersionTable.PSVersion.Major -ge 5
        
        # Verificar permisos de administrador
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $results.AdminRights = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        # Verificar módulos requeridos
        $requiredModules = @("Microsoft.PowerShell.Utility", "Microsoft.PowerShell.Management")
        $availableModules = Get-Module -ListAvailable | Select-Object -ExpandProperty Name
        $results.RequiredModules = ($requiredModules | Where-Object { $_ -in $availableModules }).Count -eq $requiredModules.Count
        
        $results.Success = $results.WindowsVersion -and $results.PowerShellVersion -and 
                          $results.AdminRights -and $results.RequiredModules
        
    } catch {
        Write-Error "Error en test de compatibilidad: $($_.Exception.Message)"
    }
    
    return $results
}

function Test-NetworkConnectivity {
    <#
    .SYNOPSIS
        Verifica conectividad de red para descargas
    #>
    
    $results = @{
        TestName = "NetworkConnectivity"
        TestedUrls = @()
        SuccessfulConnections = 0
        FailedConnections = 0
        Success = $false
    }
    
    $testUrls = @(
        "https://github.com",
        "https://api.github.com", 
        "https://raw.githubusercontent.com",
        "https://www.microsoft.com"
    )
    
    foreach ($url in $testUrls) {
        $testResult = @{
            Url = $url
            Success = $false
            ResponseTime = 0
            Error = $null
        }
        
        try {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -UseBasicParsing
            $stopwatch.Stop()
            
            if ($response.StatusCode -eq 200) {
                $testResult.Success = $true
                $testResult.ResponseTime = $stopwatch.ElapsedMilliseconds
                $results.SuccessfulConnections++
            } else {
                $testResult.Error = "Status Code: $($response.StatusCode)"
                $results.FailedConnections++
            }
        } catch {
            $testResult.Error = $_.Exception.Message
            $results.FailedConnections++
        }
        
        $results.TestedUrls += $testResult
    }
    
    $results.Success = $results.FailedConnections -eq 0
    return $results
}

function Invoke-AllTests {
    <#
    .SYNOPSIS
        Ejecuta todos los tests del sistema
    #>
    param(
        [string]$FilterModule = "*"
    )
    
    Write-Log "=== Iniciando Suite de Tests WinAutoConfigure ===" -Level "INFO"
    
    $testResults = @{
        StartTime = Get-Date
        TestResults = @()
        OverallSuccess = $false
        Summary = @{
            Total = 0
            Passed = 0
            Failed = 0
        }
    }
    
    # Test 1: Compatibilidad del sistema
    Write-Host "Ejecutando test de compatibilidad del sistema..." -ForegroundColor Cyan
    $systemTest = Test-SystemCompatibility
    $testResults.TestResults += $systemTest
    
    # Test 2: Archivos de configuración
    Write-Host "Ejecutando test de archivos de configuración..." -ForegroundColor Cyan
    $configTest = Test-ConfigurationFiles
    $testResults.TestResults += $configTest
    
    # Test 3: Conectividad de red
    Write-Host "Ejecutando test de conectividad de red..." -ForegroundColor Cyan
    $networkTest = Test-NetworkConnectivity
    $testResults.TestResults += $networkTest
    
    # Test 4: Estructura de módulos (excluyendo UI-Helpers por ser módulo interno)
    Write-Host "Ejecutando test de estructura de módulos..." -ForegroundColor Cyan
    $modulesPath = Join-Path $PSScriptRoot "..\Modules"
    $moduleFiles = Get-ChildItem $modulesPath -Filter "*.ps1" | Where-Object { 
        $_.Name -like "*$FilterModule*" -and $_.Name -ne "UI-Helpers.ps1" 
    }
    
    foreach ($moduleFile in $moduleFiles) {
        $moduleTest = Test-ModuleStructure -ModulePath $moduleFile.FullName
        $moduleTest.TestName = "ModuleStructure_$($moduleFile.BaseName)"
        $moduleTest.Success = $moduleTest.HasValidSyntax -and $moduleTest.HasRequiredFunctions
        $testResults.TestResults += $moduleTest
    }
    
    # Calcular resumen
    $testResults.Summary.Total = $testResults.TestResults.Count
    $testResults.Summary.Passed = ($testResults.TestResults | Where-Object { $_.Success }).Count
    $testResults.Summary.Failed = $testResults.Summary.Total - $testResults.Summary.Passed
    $testResults.OverallSuccess = $testResults.Summary.Failed -eq 0
    
    $testResults.EndTime = Get-Date
    $testResults.Duration = $testResults.EndTime - $testResults.StartTime
    
    return $testResults
}

function Show-TestResults {
    <#
    .SYNOPSIS
        Muestra los resultados de tests de forma legible
    #>
    param([hashtable]$Results, [switch]$Detailed)
    
    Write-Host "`n" -ForegroundColor Green
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                  RESULTADOS DE TESTS                     ║" -ForegroundColor Green
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Green
    
    $statusColor = if ($Results.OverallSuccess) { "Green" } else { "Red" }
    $statusText = if ($Results.OverallSuccess) { "ÉXITO" } else { "FALLOS DETECTADOS" }
    
    Write-Host "║ Estado General: $statusText" -ForegroundColor $statusColor
    Write-Host "║ Tests Ejecutados: $($Results.Summary.Total)" -ForegroundColor White
    Write-Host "║ Tests Exitosos: $($Results.Summary.Passed)" -ForegroundColor Green
    Write-Host "║ Tests Fallidos: $($Results.Summary.Failed)" -ForegroundColor $(if($Results.Summary.Failed -gt 0){"Red"}else{"Green"})
    Write-Host "║ Duración: $($Results.Duration.TotalSeconds.ToString('F2')) segundos" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    if ($Detailed) {
        Write-Host "`nDetalles por Test:" -ForegroundColor Cyan
        
        foreach ($test in $Results.TestResults) {
            $icon = if ($test.Success) { "✓" } else { "✗" }
            $color = if ($test.Success) { "Green" } else { "Red" }
            
            Write-Host "$icon $($test.TestName)" -ForegroundColor $color
            
            if (-not $test.Success -and $test.PSObject.Properties.Name -contains "Issues") {
                foreach ($issue in $test.Issues) {
                    Write-Host "  - $issue" -ForegroundColor Yellow
                }
            }
        }
    }
}

# Ejecución principal
if ($MyInvocation.InvocationName -ne '.') {
    $testResults = Invoke-AllTests -FilterModule $ModuleName
    Show-TestResults -Results $testResults -Detailed:$Detailed
    
    if ($ExportResults) {
        $exportPath = Join-Path $PSScriptRoot "test_results_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $testResults | ConvertTo-Json -Depth 10 | Set-Content $exportPath -Encoding UTF8
        Write-Host "Resultados exportados a: $exportPath" -ForegroundColor Green
    }
    
    # Retornar código de salida apropiado
    if (-not $testResults.OverallSuccess) {
        exit 1
    }
}
