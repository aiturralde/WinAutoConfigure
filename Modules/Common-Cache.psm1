<#
.SYNOPSIS
    Módulo de cache inteligente para WinAutoConfigure
.DESCRIPTION
    Proporciona funciones de cache para evitar re-validaciones innecesarias
    y mejorar el rendimiento del sistema
.NOTES
    Módulo interno - Gestión automática de cache
#>

# Variables del módulo
$script:CachePath = ""
$script:CacheExpireHours = 24

function Initialize-CacheModule {
    [CmdletBinding()]
    param(
        [string]$CacheDirectory = "Cache",
        [int]$ExpireHours = 24
    )
    
    try {
        $script:CacheExpireHours = $ExpireHours
        $script:CachePath = Join-Path $PSScriptRoot "..\$CacheDirectory"
        
        if (-not (Test-Path $script:CachePath)) {
            New-Item -Path $script:CachePath -ItemType Directory -Force | Out-Null
        }
        
        Write-Verbose "Módulo de cache inicializado: $script:CachePath"
        return $true
    }
    catch {
        Write-Error "Error inicializando módulo de cache: $($_.Exception.Message)"
        return $false
    }
}

function Get-CacheKey {
    <#
    .SYNOPSIS
        Genera una clave de cache única basada en parámetros
    #>
    [CmdletBinding()]
    param(
        [string]$ModuleName,
        [string]$Operation,
        [hashtable]$Parameters = @{}
    )
    
    $keyData = @{
        Module = $ModuleName
        Operation = $Operation
        Parameters = $Parameters
        ComputerName = $env:COMPUTERNAME
    }
    
    $jsonString = $keyData | ConvertTo-Json -Compress
    $hash = Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($jsonString))) -Algorithm SHA256
    return $hash.Hash.Substring(0, 16)
}

function Test-CacheValid {
    <#
    .SYNOPSIS
        Verifica si un elemento del cache es válido (no expirado)
    #>
    [CmdletBinding()]
    param([string]$CacheKey)
    
    if (-not (Initialize-CacheModule)) {
        return $false
    }
    
    $cacheFile = Join-Path $script:CachePath "$CacheKey.json"
    
    if (-not (Test-Path $cacheFile)) {
        return $false
    }
    
    try {
        $cacheData = Get-Content $cacheFile -Raw | ConvertFrom-Json
        $cacheTime = [DateTime]$cacheData.Timestamp
        $expireTime = $cacheTime.AddHours($script:CacheExpireHours)
        
        return (Get-Date) -lt $expireTime
    }
    catch {
        # Si hay error leyendo el cache, considerarlo inválido
        return $false
    }
}

function Get-CachedData {
    <#
    .SYNOPSIS
        Obtiene datos del cache si están disponibles y son válidos
    #>
    [CmdletBinding()]
    param([string]$CacheKey)
    
    if (-not (Test-CacheValid -CacheKey $CacheKey)) {
        return $null
    }
    
    try {
        $cacheFile = Join-Path $script:CachePath "$CacheKey.json"
        $cacheData = Get-Content $cacheFile -Raw | ConvertFrom-Json
        return $cacheData.Data
    }
    catch {
        Write-Warning "Error leyendo cache para clave: $CacheKey"
        return $null
    }
}

function Set-CachedData {
    <#
    .SYNOPSIS
        Almacena datos en el cache con timestamp
    #>
    [CmdletBinding()]
    param(
        [string]$CacheKey,
        [object]$Data
    )
    
    if (-not (Initialize-CacheModule)) {
        return $false
    }
    
    try {
        $cacheData = @{
            Timestamp = Get-Date
            CacheKey = $CacheKey
            Data = $Data
        }
        
        $cacheFile = Join-Path $script:CachePath "$CacheKey.json"
        $cacheData | ConvertTo-Json -Depth 10 | Set-Content $cacheFile -Encoding UTF8
        
        Write-Verbose "Datos almacenados en cache: $CacheKey"
        return $true
    }
    catch {
        Write-Error "Error almacenando en cache: $($_.Exception.Message)"
        return $false
    }
}

function Clear-ModuleCache {
    <#
    .SYNOPSIS
        Limpia el cache de un módulo específico o todo el cache
    #>
    [CmdletBinding()]
    param(
        [string]$ModuleName = "*"
    )
    
    if (-not (Initialize-CacheModule)) {
        return $false
    }
    
    try {
        if ($ModuleName -eq "*") {
            # Limpiar todo el cache
            Get-ChildItem $script:CachePath -Filter "*.json" | Remove-Item -Force
            Write-Verbose "Cache completo limpiado"
        } else {
            # Limpiar cache específico del módulo
            $pattern = "*$ModuleName*"
            Get-ChildItem $script:CachePath -Filter "*.json" | 
                Where-Object { $_.Name -like $pattern } | 
                Remove-Item -Force
            Write-Verbose "Cache del módulo $ModuleName limpiado"
        }
        return $true
    }
    catch {
        Write-Error "Error limpiando cache: $($_.Exception.Message)"
        return $false
    }
}

function Get-CacheStatistics {
    <#
    .SYNOPSIS
        Obtiene estadísticas del cache actual
    #>
    [CmdletBinding()]
    param()
    
    if (-not (Initialize-CacheModule)) {
        return $null
    }
    
    try {
        $cacheFiles = Get-ChildItem $script:CachePath -Filter "*.json"
        $totalSize = ($cacheFiles | Measure-Object -Property Length -Sum).Sum
        $validCount = 0
        $expiredCount = 0
        
        foreach ($file in $cacheFiles) {
            $cacheKey = $file.BaseName
            if (Test-CacheValid -CacheKey $cacheKey) {
                $validCount++
            } else {
                $expiredCount++
            }
        }
        
        return @{
            TotalEntries = $cacheFiles.Count
            ValidEntries = $validCount
            ExpiredEntries = $expiredCount
            TotalSizeKB = [math]::Round($totalSize / 1KB, 2)
            CachePath = $script:CachePath
            ExpireHours = $script:CacheExpireHours
        }
    }
    catch {
        Write-Error "Error obteniendo estadísticas de cache: $($_.Exception.Message)"
        return $null
    }
}

function Invoke-CacheOperation {
    <#
    .SYNOPSIS
        Operación de cache inteligente con fallback
    #>
    [CmdletBinding()]
    param(
        [string]$ModuleName,
        [string]$Operation,
        [scriptblock]$ScriptBlock,
        [hashtable]$Parameters = @{},
        [switch]$ForceRefresh
    )
    
    $cacheKey = Get-CacheKey -ModuleName $ModuleName -Operation $Operation -Parameters $Parameters
    
    # Si no se fuerza refresh, intentar obtener del cache
    if (-not $ForceRefresh) {
        $cachedResult = Get-CachedData -CacheKey $cacheKey
        if ($null -ne $cachedResult) {
            Write-Verbose "Datos obtenidos del cache para $ModuleName.$Operation"
            return $cachedResult
        }
    }
    
    # Ejecutar operación y almacenar en cache
    try {
        Write-Verbose "Ejecutando operación $ModuleName.$Operation"
        $result = & $ScriptBlock
        
        # Almacenar resultado en cache
        Set-CachedData -CacheKey $cacheKey -Data $result | Out-Null
        
        return $result
    }
    catch {
        Write-Error "Error ejecutando operación $ModuleName.$Operation : $($_.Exception.Message)"
        throw
    }
}

function Optimize-Cache {
    <#
    .SYNOPSIS
        Optimiza el cache eliminando entradas expiradas
    #>
    [CmdletBinding()]
    param()
    
    if (-not (Initialize-CacheModule)) {
        return $false
    }
    
    try {
        $cacheFiles = Get-ChildItem $script:CachePath -Filter "*.json"
        $removedCount = 0
        
        foreach ($file in $cacheFiles) {
            $cacheKey = $file.BaseName
            if (-not (Test-CacheValid -CacheKey $cacheKey)) {
                Remove-Item $file.FullName -Force
                $removedCount++
            }
        }
        
        Write-Verbose "Cache optimizado: $removedCount entradas expiradas eliminadas"
        return $true
    }
    catch {
        Write-Error "Error optimizando cache: $($_.Exception.Message)"
        return $false
    }
}

# Exportar funciones principales
Export-ModuleMember -Function @(
    'Initialize-CacheModule',
    'Get-CachedData',
    'Set-CachedData',
    'Clear-ModuleCache',
    'Get-CacheStatistics',
    'Invoke-CacheOperation',
    'Optimize-Cache'
)
