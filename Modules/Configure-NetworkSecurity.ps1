<#
.SYNOPSIS
    Módulo para configurar ajustes de red y seguridad en Windows 11
.DESCRIPTION
    Este módulo configura Windows Defender, Firewall, y ajustes de red usando manejo estandarizado de errores
.NOTES
    Versión: 2.0 - Refactorizado con Common-ErrorHandling y Common-Configuration
    Incluye configuraciones de seguridad y optimizaciones de red
#>

# Importar módulos necesarios usando rutas absolutas
$ModulesPath = Split-Path $PSScriptRoot -Parent | Join-Path -ChildPath "Modules"
Import-Module (Join-Path $ModulesPath "Common-ErrorHandling.psm1") -Force -Global
Import-Module (Join-Path $ModulesPath "Common-Configuration.psm1") -Force -Global

# Asegurar que el enum ErrorSeverity esté disponible
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

function Initialize-NetworkSecurityModule {
    [CmdletBinding()]
    param()
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Iniciando configuración de red y seguridad..." -Component "NetworkSecurity"
        
        # Inicializar Configuration Manager
        $ConfigPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Config"
        Initialize-ConfigurationManager -ConfigRootPath $ConfigPath
        
        # Cargar configuración
        $Config = Get-ConfigurationSafe -ConfigName "network-security-config"
        if (-not $Config) {
            throw "No se pudo cargar la configuración de seguridad de red"
        }
        
        $results = @{
            Defender = $false
            Firewall = $false
            DNS = $false
            NetworkServices = $false
        }
        
        # Paso 1: Configurar Windows Defender
        if ($Config.defender.enabled) {
            $results.Defender = Set-DefenderSettings -Config $Config.defender
        } else {
            Write-Log "Configuración de Windows Defender omitida (deshabilitada en configuración)" -Component "NetworkSecurity"
            $results.Defender = $true
        }
        
        # Paso 2: Configurar Firewall
        if ($Config.firewall.enabled) {
            $results.Firewall = Set-FirewallSettings -Config $Config.firewall
        } else {
            Write-Log "Configuración de Firewall omitida (deshabilitada en configuración)" -Component "NetworkSecurity"
            $results.Firewall = $true
        }
        
        # Paso 3: Configurar DNS
        if ($Config.dns.enabled) {
            $results.DNS = Set-DnsSettings -Config $Config.dns
        } else {
            Write-Log "Configuración de DNS omitida (deshabilitada en configuración)" -Component "NetworkSecurity"
            $results.DNS = $true
        }
        
        # Paso 4: Configurar servicios de red
        if ($Config.network_services.enabled) {
            $results.NetworkServices = Set-NetworkServices -Config $Config.network_services
        } else {
            Write-Log "Configuración de servicios de red omitida (deshabilitada en configuración)" -Component "NetworkSecurity"
            $results.NetworkServices = $true
        }
        
        # Validar resultados
        $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
        $totalCount = $results.Count
        
        Write-Log "Configuración de red y seguridad completada: $successCount/$totalCount exitosas" -Component "NetworkSecurity"
        
        if ($successCount -eq $totalCount) {
            Write-Log "✅ Todas las configuraciones de seguridad aplicadas exitosamente" -Component "NetworkSecurity" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "⚠️ Algunas configuraciones fallaron - Revisar logs para detalles" -Component "NetworkSecurity" -Level "WARNING" 
            return $Config.settings.skip_on_error
        }
        
    } -Operation "Inicializar configuración de red y seguridad" -Component "NetworkSecurity" -Severity ([ErrorSeverity]::High)
}

function Set-DefenderSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Configurando Windows Defender..." -Component "DefenderConfig"
        
        # Configurar protección en tiempo real
        if ($Config.real_time_protection) {
            Set-MpPreference -DisableRealtimeMonitoring $false
            Write-Log "Protección en tiempo real habilitada" -Component "DefenderConfig"
        }
        
        # Configurar exclusiones para desarrollo
        $successfulExclusions = 0
        foreach ($pathTemplate in $Config.exclusion_paths) {
            $expandedPath = $pathTemplate -replace '\{USERPROFILE\}', $env:USERPROFILE
            
            if (Test-Path $expandedPath -ErrorAction SilentlyContinue) {
                try {
                    Add-MpPreference -ExclusionPath $expandedPath -ErrorAction Stop
                    Write-Log "Exclusión agregada: $expandedPath" -Component "DefenderConfig"
                    $successfulExclusions++
                }
                catch {
                    Write-Log "Error agregando exclusión '$expandedPath': $($_.Exception.Message)" -Component "DefenderConfig" -Level "WARNING"
                }
            } else {
                Write-Log "Ruta no existe, omitiendo exclusión: $expandedPath" -Component "DefenderConfig" -Level "INFO"
            }
        }
        
        # Configurar escaneo programado
        if ($Config.scheduled_scan_time) {
            Set-MpPreference -ScanScheduleQuickScanTime $Config.scheduled_scan_time
            Write-Log "Escaneo rápido programado a las $($Config.scheduled_scan_time)" -Component "DefenderConfig"
        }
        
        Write-Log "Windows Defender configurado exitosamente ($successfulExclusions exclusiones aplicadas)" -Component "DefenderConfig" -Level "SUCCESS"
        return $true
        
    } -Operation "Configurar Windows Defender" -Component "DefenderConfig" -Severity ([ErrorSeverity]::Medium)
}

function Set-FirewallSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Configurando Windows Firewall..." -Component "FirewallConfig"
        
        # Habilitar firewall en todos los perfiles
        if ($Config.enable_all_profiles) {
            Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
            Write-Log "Firewall habilitado en todos los perfiles" -Component "FirewallConfig"
        }
        
        # Configurar reglas para desarrollo
        $successfulRules = 0
        foreach ($portConfig in $Config.development_ports) {
            try {
                $existingRule = Get-NetFirewallRule -DisplayName $portConfig.name -ErrorAction SilentlyContinue
                if (-not $existingRule) {
                    New-NetFirewallRule -DisplayName $portConfig.name -Direction Inbound -LocalPort $portConfig.port -Protocol $portConfig.protocol -Action Allow -ErrorAction Stop
                    Write-Log "Regla de firewall creada: $($portConfig.name) (Puerto $($portConfig.port))" -Component "FirewallConfig"
                    $successfulRules++
                } else {
                    Write-Log "Regla ya existe: $($portConfig.name)" -Component "FirewallConfig" -Level "INFO"
                    $successfulRules++
                }
            }
            catch {
                Write-Log "Error creando regla '$($portConfig.name)': $($_.Exception.Message)" -Component "FirewallConfig" -Level "WARNING"
            }
        }
        
        Write-Log "Windows Firewall configurado exitosamente ($successfulRules reglas procesadas)" -Component "FirewallConfig" -Level "SUCCESS"
        return $true
        
    } -Operation "Configurar Windows Firewall" -Component "FirewallConfig" -Severity ([ErrorSeverity]::Medium)
}

function Set-DnsSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Configurando DNS..." -Component "DNSConfig"
        
        # Preparar servidores DNS
        $dnsServers = @($Config.primary_dns, $Config.secondary_dns) | Where-Object { $_ }
        
        if ($dnsServers.Count -eq 0) {
            throw "No se especificaron servidores DNS válidos"
        }
        
        # Obtener adaptadores de red según configuración
        $adapterFilter = if ($Config.apply_to_ethernet_only) {
            { $_.Status -eq "Up" -and $_.MediaType -eq "802.3" }
        } else {
            { $_.Status -eq "Up" }
        }
        
        $adapters = Get-NetAdapter | Where-Object $adapterFilter
        
        if ($adapters.Count -eq 0) {
            Write-Log "No se encontraron adaptadores de red activos" -Component "DNSConfig" -Level "WARNING"
            return $false
        }
        
        # Configurar DNS en adaptadores
        $successfulAdapters = 0
        foreach ($adapter in $adapters) {
            try {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $dnsServers -ErrorAction Stop
                Write-Log "DNS configurado para adaptador: $($adapter.Name) ($($dnsServers -join ', '))" -Component "DNSConfig"
                $successfulAdapters++
            }
            catch {
                Write-Log "Error configurando DNS en adaptador '$($adapter.Name)': $($_.Exception.Message)" -Component "DNSConfig" -Level "WARNING"
            }
        }
        
        # Limpiar caché DNS si está habilitado
        if ($Config.clear_cache) {
            try {
                Clear-DnsClientCache
                Write-Log "Caché DNS limpiado" -Component "DNSConfig"
            }
            catch {
                Write-Log "Error limpiando caché DNS: $($_.Exception.Message)" -Component "DNSConfig" -Level "WARNING"
            }
        }
        
        Write-Log "DNS configurado exitosamente ($successfulAdapters adaptadores configurados)" -Component "DNSConfig" -Level "SUCCESS"
        return $successfulAdapters -gt 0
        
    } -Operation "Configurar DNS" -Component "DNSConfig" -Severity ([ErrorSeverity]::Medium)
}

function Set-NetworkServices {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Configurando servicios de red..." -Component "NetworkServices"
        
        $disabledCount = 0
        $optimizedCount = 0
        
        # Deshabilitar servicios especificados
        foreach ($serviceConfig in $Config.services_to_disable) {
            try {
                $svc = Get-Service -Name $serviceConfig.name -ErrorAction SilentlyContinue
                if ($svc) {
                    if ($svc.Status -eq "Running") {
                        Stop-Service -Name $serviceConfig.name -Force -ErrorAction Stop
                        Write-Log "Servicio detenido: $($serviceConfig.name)" -Component "NetworkServices"
                    }
                    Set-Service -Name $serviceConfig.name -StartupType Disabled -ErrorAction Stop
                    Write-Log "Servicio deshabilitado: $($serviceConfig.name) - $($serviceConfig.description)" -Component "NetworkServices"
                    $disabledCount++
                } else {
                    Write-Log "Servicio no encontrado (omitiendo): $($serviceConfig.name)" -Component "NetworkServices" -Level "INFO"
                }
            }
            catch {
                Write-Log "Error deshabilitando servicio '$($serviceConfig.name)': $($_.Exception.Message)" -Component "NetworkServices" -Level "WARNING"
            }
        }
        
        # Optimizar servicios especificados
        foreach ($serviceConfig in $Config.services_to_optimize) {
            try {
                $svc = Get-Service -Name $serviceConfig.name -ErrorAction SilentlyContinue
                if ($svc) {
                    Set-Service -Name $serviceConfig.name -StartupType $serviceConfig.startup_type -ErrorAction Stop
                    Write-Log "Servicio optimizado: $($serviceConfig.name) → $($serviceConfig.startup_type) - $($serviceConfig.description)" -Component "NetworkServices"
                    $optimizedCount++
                } else {
                    Write-Log "Servicio no encontrado para optimización: $($serviceConfig.name)" -Component "NetworkServices" -Level "WARNING"
                }
            }
            catch {
                Write-Log "Error optimizando servicio '$($serviceConfig.name)': $($_.Exception.Message)" -Component "NetworkServices" -Level "WARNING"
            }
        }
        
        Write-Log "Servicios de red configurados exitosamente ($disabledCount deshabilitados, $optimizedCount optimizados)" -Component "NetworkServices" -Level "SUCCESS"
        return $true
        
    } -Operation "Configurar servicios de red" -Component "NetworkServices" -Severity ([ErrorSeverity]::Medium)
}