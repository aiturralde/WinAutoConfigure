<#
.SYNOPSIS
    Módulo para configurar ajustes de red y seguridad en Windows 11
.DESCRIPTION
    Este módulo configura Windows Defender, Firewall, y ajustes de red
.NOTES
    Incluye configuraciones de seguridad y optimizaciones de red
#>

function Initialize-NetworkSecurityModule {
    [CmdletBinding()]
    param()
    
    Write-Log "Iniciando configuración de red y seguridad..."
    
    # Paso 1: Configurar Windows Defender
    Set-DefenderSettings
    
    # Paso 2: Configurar Firewall
    Set-FirewallSettings
    
    # Paso 3: Configurar DNS
    Set-DnsSettings
    
    # Paso 4: Configurar servicios de red
    Set-NetworkServices
    
    Write-Log "Configuración de red y seguridad completada"
    return $true
}

function Set-DefenderSettings {
    Write-Log "Configurando Windows Defender..."
    
    try {
        # Habilitar protección en tiempo real
        Set-MpPreference -DisableRealtimeMonitoring $false
        
        # Configurar exclusiones para desarrollo
        $devPaths = @(
            "$env:USERPROFILE\source",
            "$env:USERPROFILE\repos",
            "$env:USERPROFILE\projects"
        )
        
        foreach ($path in $devPaths) {
            if (Test-Path $path) {
                Add-MpPreference -ExclusionPath $path
                Write-Log "Exclusión agregada: $path"
            }
        }
        
        # Configurar escaneo rápido programado
        Set-MpPreference -ScanScheduleQuickScanTime "02:00:00"
        
        Write-Log "Windows Defender configurado"
    }
    catch {
        Write-Log "Error configurando Windows Defender: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Set-FirewallSettings {
    Write-Log "Configurando Windows Firewall..."
    
    try {
        # Habilitar firewall en todos los perfiles
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
        
        # Configurar reglas para desarrollo
        $devPorts = @(
            @{Name = "Node.js Development"; Port = 3000; Protocol = "TCP"},
            @{Name = "React Development"; Port = 3001; Protocol = "TCP"},
            @{Name = "Angular Development"; Port = 4200; Protocol = "TCP"},
            @{Name = "Vue.js Development"; Port = 8080; Protocol = "TCP"},
            @{Name = "ASP.NET Development"; Port = 5000; Protocol = "TCP"},
            @{Name = "ASP.NET HTTPS Development"; Port = 5001; Protocol = "TCP"}
        )
        
        foreach ($port in $devPorts) {
            $existingRule = Get-NetFirewallRule -DisplayName $port.Name -ErrorAction SilentlyContinue
            if (-not $existingRule) {
                New-NetFirewallRule -DisplayName $port.Name -Direction Inbound -LocalPort $port.Port -Protocol $port.Protocol -Action Allow
                Write-Log "Regla de firewall creada: $($port.Name)"
            }
        }
        
        Write-Log "Windows Firewall configurado"
    }
    catch {
        Write-Log "Error configurando Firewall: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Set-DnsSettings {
    Write-Log "Configurando DNS..."
    
    try {
        # Obtener adaptadores de red activos
        $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.MediaType -eq "802.3"}
        
        foreach ($adapter in $adapters) {
            # Configurar DNS seguros (Cloudflare)
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses @("1.1.1.1", "1.0.0.1")
            Write-Log "DNS configurado para adaptador: $($adapter.Name)"
        }
        
        # Limpiar caché DNS
        Clear-DnsClientCache
        
        Write-Log "DNS configurado correctamente"
    }
    catch {
        Write-Log "Error configurando DNS: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Set-NetworkServices {
    Write-Log "Configurando servicios de red..."
    
    try {
        # Servicios a deshabilitar para mejorar privacidad
        $servicesToDisable = @(
            "DiagTrack",           # Telemetría
            "dmwappushservice",    # Mensaje push WAP
            "WSearch",             # Windows Search (opcional)
            "WMPNetworkSvc"        # Servicio de uso compartido de red de Windows Media Player
        )
        
        foreach ($service in $servicesToDisable) {
            $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq "Running") {
                Stop-Service -Name $service -Force
                Set-Service -Name $service -StartupType Disabled
                Write-Log "Servicio deshabilitado: $service"
            }
        }
        
        # Servicios a optimizar
        $servicesToOptimize = @(
            @{Name = "Themes"; StartupType = "Automatic"},
            @{Name = "AudioSrv"; StartupType = "Automatic"},
            @{Name = "Spooler"; StartupType = "Automatic"}
        )
        
        foreach ($service in $servicesToOptimize) {
            Set-Service -Name $service.Name -StartupType $service.StartupType -ErrorAction SilentlyContinue
            Write-Log "Servicio optimizado: $($service.Name)"
        }
        
        Write-Log "Servicios de red configurados"
    }
    catch {
        Write-Log "Error configurando servicios: $($_.Exception.Message)" -Level "WARNING"
    }
}
