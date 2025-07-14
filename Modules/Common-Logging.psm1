#Requires -Version 5.1

<#
.SYNOPSIS
    Módulo común de logging para WinAutoConfigure (INTERNO)
.DESCRIPTION
    Este módulo proporciona funciones de logging reutilizables para todos los módulos del proyecto.
    NOTA: Este es un módulo interno - no debe ser documentado o expuesto al usuario final.
    Incluye funciones de logging, utilidades de archivos y validaciones comunes.
.NOTES
    Autor: WinAutoConfigure
    Versión: 2.0
    Tipo: Módulo interno
    Requiere: PowerShell 5.1+
#>

# Variables del módulo de logging
$Script:LoggingModulePath = $PSScriptRoot
$Script:ProjectRoot = Split-Path $Script:LoggingModulePath -Parent
$Script:LogPath = Join-Path $Script:ProjectRoot "Logs"
$Script:ConfigPath = Join-Path $Script:ProjectRoot "Config"

# Asegurar que el directorio de logs existe
function Initialize-LoggingPaths {
    <#
    .SYNOPSIS
        Inicializa las rutas necesarias para el logging
    #>
    if (-not (Test-Path $Script:LogPath)) {
        New-Item -ItemType Directory -Path $Script:LogPath -Force | Out-Null
    }
    if (-not (Test-Path $Script:ConfigPath)) {
        New-Item -ItemType Directory -Path $Script:ConfigPath -Force | Out-Null
    }
}

# Inicializar rutas al cargar el módulo
Initialize-LoggingPaths

function Write-Log {
    <#
    .SYNOPSIS
        Función de logging centralizada para todo el proyecto
    .DESCRIPTION
        Escribe mensajes de log con timestamp, nivel y contexto al archivo de log diario
        y los muestra en pantalla con colores apropiados.
    .PARAMETER Message
        El mensaje a escribir en el log
    .PARAMETER Level
        El nivel del mensaje: INFO, WARNING, ERROR
    .PARAMETER Component
        El componente o módulo que genera el log (se detecta automáticamente)
    .PARAMETER LogFile
        Archivo de log específico (opcional, por defecto usa el log diario)
    .EXAMPLE
        Write-Log "Iniciando configuración" -Level "INFO"
    .EXAMPLE
        Write-Log "Error de conexión" -Level "ERROR" -Component "Network"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS', 'DEBUG')]
        [string]$Level = 'INFO',
        
        [string]$Component = "",
        
        [string]$LogFile = ""
    )
    
    # Detectar componente automáticamente si no se especifica
    if ([string]::IsNullOrEmpty($Component)) {
        $callStack = Get-PSCallStack
        if ($callStack.Count -gt 1 -and $callStack[1].ScriptName) {
            $callerFile = Split-Path -Leaf $callStack[1].ScriptName
            $Component = $callerFile -replace '\.ps1$', ''
        }
        else {
            $Component = "WinAutoConfigure"
        }
    }
    
    # Usar archivo de log por defecto si no se especifica
    if ([string]::IsNullOrEmpty($LogFile)) {
        $LogFile = Join-Path $Script:LogPath "WinAutoConfigure_$(Get-Date -Format 'yyyyMMdd').log"
    }
    
    # Crear timestamp
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    
    # Determinar color según el nivel
    $color = switch ($Level) {
        'INFO' { 'White' }
        'SUCCESS' { 'Green' }
        'WARNING' { 'Yellow' }
        'ERROR' { 'Red' }
        'DEBUG' { 'Cyan' }
        default { 'White' }
    }
    
    # Mostrar en pantalla con color
    Write-Host $logEntry -ForegroundColor $color
    
    # Escribir al archivo de log
    try {
        Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "No se pudo escribir al archivo de log: $LogFile"
    }
}

function Write-LogSection {
    <#
    .SYNOPSIS
        Escribe una sección destacada en el log
    .DESCRIPTION
        Crea una entrada de log con formato de sección para separar visualmente
        las diferentes fases de ejecución.
    .PARAMETER Title
        El título de la sección
    .PARAMETER Component
        El componente que inicia la sección
    .EXAMPLE
        Write-LogSection "CONFIGURACIÓN GAMING"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        
        [string]$Component = ""
    )
    
    $separator = "=" * ($Title.Length + 6)
    Write-Log $separator -Level "INFO" -Component $Component
    Write-Log "=== $Title ===" -Level "INFO" -Component $Component
    Write-Log $separator -Level "INFO" -Component $Component
}

function Test-AdminRights {
    <#
    .SYNOPSIS
        Verifica si el script se está ejecutando con permisos de administrador
    .DESCRIPTION
        Función común para verificar permisos administrativos en todos los módulos
    .OUTPUTS
        [bool] True si tiene permisos de administrador, False en caso contrario
    .EXAMPLE
        if (-not (Test-AdminRights)) { throw "Se requieren permisos de administrador" }
    #>
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        Write-Log "Error verificando permisos de administrador: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Test-WindowsVersion {
    <#
    .SYNOPSIS
        Verifica la versión de Windows
    .DESCRIPTION
        Función común para verificar la versión de Windows en todos los módulos
    .PARAMETER MinimumBuild
        Build mínimo requerido (por defecto 22000 para Windows 11)
    .OUTPUTS
        [PSCustomObject] Objeto con información de la versión de Windows
    .EXAMPLE
        $osInfo = Test-WindowsVersion
        if (-not $osInfo.IsWindows11) { Write-Log "Optimizado para Windows 11" -Level "WARNING" }
    #>
    param(
        [int]$MinimumBuild = 22000
    )
    
    try {
        $osVersion = [System.Environment]::OSVersion.Version
        $buildNumber = $osVersion.Build
        
        $result = [PSCustomObject]@{
            Major = $osVersion.Major
            Minor = $osVersion.Minor
            Build = $buildNumber
            IsWindows10 = ($osVersion.Major -eq 10 -and $buildNumber -lt 22000)
            IsWindows11 = ($osVersion.Major -eq 10 -and $buildNumber -ge 22000)
            MeetsMinimumRequirement = ($buildNumber -ge $MinimumBuild)
            VersionString = "$($osVersion.Major).$($osVersion.Minor).$buildNumber"
        }
        
        Write-Log "Windows detectado: $($result.VersionString)" -Level "INFO" -Component "System"
        
        return $result
    }
    catch {
        Write-Log "Error detectando versión de Windows: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Invoke-SafeRegistryOperation {
    <#
    .SYNOPSIS
        Ejecuta operaciones de registro de forma segura
    .DESCRIPTION
        Wrapper seguro para operaciones de registro con logging automático y manejo de errores
    .PARAMETER ScriptBlock
        El bloque de código a ejecutar
    .PARAMETER Description
        Descripción de la operación para el log
    .PARAMETER Component
        Componente que ejecuta la operación
    .OUTPUTS
        [bool] True si la operación fue exitosa, False en caso contrario
    .EXAMPLE
        Invoke-SafeRegistryOperation {
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Test" -Name "Value" -Value 1
        } -Description "Configurar valor de prueba"
    #>
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory)]
        [string]$Description,
        
        [string]$Component = ""
    )
    
    try {
        Write-Log "Ejecutando: $Description" -Level "INFO" -Component $Component
        & $ScriptBlock
        Write-Log "$Description - Completado" -Level "SUCCESS" -Component $Component
        return $true
    }
    catch {
        Write-Log "Error en $Description`: $($_.Exception.Message)" -Level "ERROR" -Component $Component
        return $false
    }
}

function Get-LogFilePath {
    <#
    .SYNOPSIS
        Obtiene la ruta del archivo de log para la fecha actual
    .DESCRIPTION
        Función helper para obtener la ruta del archivo de log diario
    .PARAMETER Date
        Fecha para el archivo de log (por defecto la fecha actual)
    .OUTPUTS
        [string] Ruta completa del archivo de log
    .EXAMPLE
        $logFile = Get-LogFilePath
        $yesterdayLog = Get-LogFilePath -Date (Get-Date).AddDays(-1)
    #>
    param(
        [DateTime]$Date = (Get-Date)
    )
    
    return Join-Path $Script:LogPath "WinAutoConfigure_$($Date.ToString('yyyyMMdd')).log"
}

function Get-RecentLogEntries {
    <#
    .SYNOPSIS
        Obtiene las entradas de log más recientes
    .DESCRIPTION
        Función helper para obtener las últimas entradas del log para debugging
    .PARAMETER Count
        Número de entradas a obtener (por defecto 20)
    .PARAMETER Level
        Filtrar por nivel específico (opcional)
    .OUTPUTS
        [string[]] Array de entradas de log
    .EXAMPLE
        Get-RecentLogEntries -Count 10
        Get-RecentLogEntries -Level "ERROR"
    #>
    param(
        [int]$Count = 20,
        [string]$Level = ""
    )
    
    try {
        $logFile = Get-LogFilePath
        if (-not (Test-Path $logFile)) {
            Write-Log "Archivo de log no encontrado: $logFile" -Level "WARNING"
            return @()
        }
        
        $entries = Get-Content $logFile | Select-Object -Last ($Count * 2)
        
        if (-not [string]::IsNullOrEmpty($Level)) {
            $entries = $entries | Where-Object { $_ -match "\[$Level\]" }
        }
        
        return $entries | Select-Object -Last $Count
    }
    catch {
        Write-Log "Error obteniendo entradas de log: $($_.Exception.Message)" -Level "ERROR"
        return @()
    }
}

function Export-LogsForDiagnostics {
    <#
    .SYNOPSIS
        Exporta logs para diagnósticos
    .DESCRIPTION
        Crea un archivo ZIP con los logs para envío de diagnósticos
    .PARAMETER OutputPath
        Ruta donde crear el archivo ZIP (opcional)
    .PARAMETER Days
        Número de días de logs a incluir (por defecto 7)
    .OUTPUTS
        [string] Ruta del archivo ZIP creado
    .EXAMPLE
        Export-LogsForDiagnostics -Days 3
    #>
    param(
        [string]$OutputPath = "",
        [int]$Days = 7
    )
    
    try {
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = Join-Path $Script:ProjectRoot "WinAutoConfigure_Logs_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
        }
        
        $tempFolder = Join-Path $env:TEMP "WinAutoConfigureLogs_$(Get-Date -Format 'HHmmss')"
        New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null
        
        # Copiar logs de los últimos N días
        $startDate = (Get-Date).AddDays(-$Days)
        Get-ChildItem $Script:LogPath -Filter "*.log" | Where-Object {
            $_.LastWriteTime -gt $startDate
        } | ForEach-Object {
            Copy-Item $_.FullName -Destination $tempFolder
        }
        
        # Comprimir
        if (Get-Command Compress-Archive -ErrorAction SilentlyContinue) {
            Compress-Archive -Path "$tempFolder\*" -DestinationPath $OutputPath -Force
            Write-Log "Logs exportados a: $OutputPath" -Level "SUCCESS"
        }
        else {
            Write-Log "Compress-Archive no disponible. Logs copiados a: $tempFolder" -Level "WARNING"
            $OutputPath = $tempFolder
        }
        
        # Limpiar carpeta temporal si se creó ZIP
        if ($OutputPath -ne $tempFolder -and (Test-Path $tempFolder)) {
            Remove-Item $tempFolder -Recurse -Force
        }
        
        return $OutputPath
    }
    catch {
        Write-Log "Error exportando logs: $($_.Exception.Message)" -Level "ERROR"
        return ""
    }
}

# Exportar funciones del módulo
Export-ModuleMember -Function @(
    'Write-Log',
    'Write-LogSection',
    'Test-AdminRights',
    'Test-WindowsVersion',
    'Invoke-SafeRegistryOperation',
    'Get-LogFilePath',
    'Get-RecentLogEntries',
    'Export-LogsForDiagnostics'
)
