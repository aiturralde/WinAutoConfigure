<#
.SYNOPSIS
    Módulo para configurar herramientas de desarrollo
.DESCRIPTION
    Este módulo configura entornos de desarrollo, instala SDKs y configura herramientas usando manejo estandarizado de errores
.NOTES
    Versión: 2.0 - Refactorizado con Common-ErrorHandling y Common-Configuration
    Incluye configuración de Git, Node.js, Python, .NET y herramientas de desarrollo
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

function Initialize-DevelopmentToolsModule {
    [CmdletBinding()]
    param()
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Iniciando configuración de herramientas de desarrollo..." -Component "DevelopmentTools"
        
        # Inicializar Configuration Manager
        $ConfigPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Config"
        Initialize-ConfigurationManager -ConfigRootPath $ConfigPath
        
        # Cargar configuración
        $Config = Get-ConfigurationSafe -ConfigName "development-tools-config"
        if (-not $Config) {
            throw "No se pudo cargar la configuración de herramientas de desarrollo"
        }
        
        $results = @{
            Git = $false
            NodeJS = $false
            Python = $false
            DotNet = $false
            VSCode = $false
        }
        
        # Crear plantilla de Git config si está habilitado
        if ($Config.settings.create_git_config_template) {
            New-GitConfigTemplate
        }
        
        # Paso 1: Configurar Git globalmente
        if ($Config.git.enabled) {
            $results.Git = Set-GitConfiguration -Config $Config.git -Settings $Config.settings
        } else {
            Write-Log "Configuración de Git omitida (deshabilitada en configuración)" -Component "DevelopmentTools"
            $results.Git = $true
        }
        
        # Paso 2: Configurar Node.js y npm
        if ($Config.nodejs.enabled) {
            $results.NodeJS = Set-NodeJsConfiguration -Config $Config.nodejs -Settings $Config.settings
        } else {
            Write-Log "Configuración de Node.js omitida (deshabilitada en configuración)" -Component "DevelopmentTools"
            $results.NodeJS = $true
        }
        
        # Paso 3: Configurar Python
        if ($Config.python.enabled) {
            $results.Python = Set-PythonConfiguration -Config $Config.python -Settings $Config.settings
        } else {
            Write-Log "Configuración de Python omitida (deshabilitada en configuración)" -Component "DevelopmentTools"
            $results.Python = $true
        }
        
        # Paso 4: Configurar .NET
        if ($Config.dotnet.enabled) {
            $results.DotNet = Set-DotNetConfiguration -Config $Config.dotnet -Settings $Config.settings
        } else {
            Write-Log "Configuración de .NET omitida (deshabilitada en configuración)" -Component "DevelopmentTools"
            $results.DotNet = $true
        }
        
        # Paso 5: Instalar extensiones de VS Code
        if ($Config.vscode.enabled) {
            $results.VSCode = Install-VSCodeExtensions -Config $Config.vscode -Settings $Config.settings
        } else {
            Write-Log "Instalación de extensiones VS Code omitida (deshabilitada en configuración)" -Component "DevelopmentTools"
            $results.VSCode = $true
        }
        
        # Validar resultados
        $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
        $totalCount = $results.Count
        
        Write-Log "Configuración de herramientas de desarrollo completada: $successCount/$totalCount exitosas" -Component "DevelopmentTools"
        
        if ($successCount -eq $totalCount) {
            Write-Log "✅ Todas las herramientas de desarrollo configuradas exitosamente" -Component "DevelopmentTools" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "⚠️ Algunas configuraciones fallaron - Revisar logs para detalles" -Component "DevelopmentTools" -Level "WARNING"
            return $Config.settings.skip_on_error
        }
        
    } -Operation "Inicializar configuración de herramientas de desarrollo" -Component "DevelopmentTools" -Severity ([ErrorSeverity]::High)
}

function Set-GitConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
    )
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Configurando Git..." -Component "GitConfig"
        
        # Verificar si Git está instalado
        $gitPath = Get-Command git -ErrorAction SilentlyContinue
        if (-not $gitPath) {
            if ($Settings.continue_on_tool_missing) {
                Write-Log "Git no está instalado - Omitiendo configuración" -Component "GitConfig" -Level "WARNING"
                return $true
            } else {
                throw "Git no está instalado. Instálelo primero mediante winget."
            }
        }
        
        $configuredItems = 0
        
        # Configurar desde archivo git-config.json si está habilitado
        if ($Config.config_from_file) {
            $ConfigPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Config"
            $gitConfigFile = Join-Path $ConfigPath "git-config.json"
            
            if (Test-Path $gitConfigFile) {
                try {
                    $gitConfig = Get-Content -Path $gitConfigFile -Raw | ConvertFrom-Json -AsHashtable
                    
                    if ($gitConfig.userName -and $gitConfig.userEmail) {
                        & git config --global user.name $gitConfig.userName
                        & git config --global user.email $gitConfig.userEmail
                        Write-Log "Git configurado con: $($gitConfig.userName) <$($gitConfig.userEmail)>" -Component "GitConfig"
                        $configuredItems++
                    }
                    
                    if ($gitConfig.defaultBranch) {
                        & git config --global init.defaultBranch $gitConfig.defaultBranch
                        $configuredItems++
                    }
                    
                } catch {
                    Write-Log "Error leyendo configuración Git desde archivo: $($_.Exception.Message)" -Component "GitConfig" -Level "WARNING"
                }
            } else {
                Write-Log "Archivo git-config.json no encontrado, usando configuración por defecto" -Component "GitConfig" -Level "INFO"
            }
        }
        
        # Aplicar configuración por defecto
        foreach ($configKey in $Config.default_config.GetEnumerator()) {
            try {
                & git config --global $configKey.Key $configKey.Value
                Write-Log "Git config: $($configKey.Key) = $($configKey.Value)" -Component "GitConfig"
                $configuredItems++
            }
            catch {
                Write-Log "Error configurando '$($configKey.Key)': $($_.Exception.Message)" -Component "GitConfig" -Level "WARNING"
            }
        }
        
        Write-Log "Git configurado exitosamente ($configuredItems configuraciones aplicadas)" -Component "GitConfig" -Level "SUCCESS"
        return $true
        
    } -Operation "Configurar Git" -Component "GitConfig" -Severity ([ErrorSeverity]::Low)
}

function Set-NodeJsConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
    )
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Configurando Node.js y npm..." -Component "NodeJSConfig"
        
        # Verificar si Node.js está instalado
        $nodePath = Get-Command node -ErrorAction SilentlyContinue
        if (-not $nodePath) {
            if ($Settings.continue_on_tool_missing) {
                Write-Log "Node.js no está instalado - Omitiendo configuración" -Component "NodeJSConfig" -Level "WARNING"
                return $true
            } else {
                throw "Node.js no está instalado. Instálelo primero mediante winget."
            }
        }
        
        $configuredItems = 0
        $installedPackages = 0
        
        # Configurar npm
        foreach ($configItem in $Config.npm_config.GetEnumerator()) {
            try {
                & npm config set $configItem.Key $configItem.Value
                Write-Log "npm config: $($configItem.Key) = $($configItem.Value)" -Component "NodeJSConfig"
                $configuredItems++
            }
            catch {
                Write-Log "Error configurando npm '$($configItem.Key)': $($_.Exception.Message)" -Component "NodeJSConfig" -Level "WARNING"
            }
        }
        
        # Instalar paquetes globales
        foreach ($package in $Config.global_packages) {
            try {
                Write-Log "Instalando paquete global: $package" -Component "NodeJSConfig"
                & npm install -g $package --silent
                $installedPackages++
            }
            catch {
                Write-Log "Error instalando paquete '$package': $($_.Exception.Message)" -Component "NodeJSConfig" -Level "WARNING"
            }
        }
        
        Write-Log "Node.js configurado exitosamente ($configuredItems configuraciones, $installedPackages paquetes instalados)" -Component "NodeJSConfig" -Level "SUCCESS"
        return $true
        
    } -Operation "Configurar Node.js" -Component "NodeJSConfig" -Severity ([ErrorSeverity]::Low)
}

function Set-PythonConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
    )
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Configurando Python..." -Component "PythonConfig"
        
        # Verificar si Python está instalado
        $pythonPath = Get-Command python -ErrorAction SilentlyContinue
        if (-not $pythonPath) {
            if ($Settings.continue_on_tool_missing) {
                Write-Log "Python no está instalado - Omitiendo configuración" -Component "PythonConfig" -Level "WARNING"
                return $true
            } else {
                throw "Python no está instalado. Instálelo primero mediante winget."
            }
        }
        
        $installedPackages = 0
        
        # Actualizar pip si está habilitado
        if ($Config.upgrade_pip) {
            try {
                Write-Log "Actualizando pip..." -Component "PythonConfig"
                & python -m pip install --upgrade pip --quiet
                Write-Log "pip actualizado exitosamente" -Component "PythonConfig"
            }
            catch {
                Write-Log "Error actualizando pip: $($_.Exception.Message)" -Component "PythonConfig" -Level "WARNING"
            }
        }
        
        # Instalar paquetes Python
        foreach ($package in $Config.packages) {
            try {
                Write-Log "Instalando paquete Python: $package" -Component "PythonConfig"
                & python -m pip install $package --quiet
                $installedPackages++
            }
            catch {
                Write-Log "Error instalando paquete '$package': $($_.Exception.Message)" -Component "PythonConfig" -Level "WARNING"
            }
        }
        
        Write-Log "Python configurado exitosamente ($installedPackages paquetes instalados)" -Component "PythonConfig" -Level "SUCCESS"
        return $true
        
    } -Operation "Configurar Python" -Component "PythonConfig" -Severity ([ErrorSeverity]::Low)
}

function Set-DotNetConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
    )
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Configurando .NET..." -Component "DotNetConfig"
        
        # Verificar si .NET está instalado
        $dotnetPath = Get-Command dotnet -ErrorAction SilentlyContinue
        if (-not $dotnetPath) {
            if ($Settings.continue_on_tool_missing) {
                Write-Log ".NET no está instalado - Omitiendo configuración" -Component "DotNetConfig" -Level "WARNING"
                return $true
            } else {
                throw ".NET no está instalado. Instálelo primero."
            }
        }
        
        $installedTools = 0
        
        # Instalar herramientas globales de .NET
        foreach ($tool in $Config.global_tools) {
            try {
                Write-Log "Instalando herramienta .NET: $tool" -Component "DotNetConfig"
                & dotnet tool install --global $tool --verbosity quiet
                $installedTools++
            }
            catch {
                # Si ya está instalado, intentar actualizar
                try {
                    Write-Log "Herramienta ya instalada, intentando actualizar: $tool" -Component "DotNetConfig"
                    & dotnet tool update --global $tool --verbosity quiet
                    $installedTools++
                }
                catch {
                    Write-Log "Error instalando/actualizando herramienta '$tool': $($_.Exception.Message)" -Component "DotNetConfig" -Level "WARNING"
                }
            }
        }
        
        # Configurar certificados de desarrollo HTTPS si está habilitado
        if ($Config.trust_dev_certs) {
            try {
                Write-Log "Configurando certificados de desarrollo HTTPS..." -Component "DotNetConfig"
                & dotnet dev-certs https --trust
                Write-Log "Certificados HTTPS configurados" -Component "DotNetConfig"
            }
            catch {
                Write-Log "Error configurando certificados HTTPS: $($_.Exception.Message)" -Component "DotNetConfig" -Level "WARNING"
            }
        }
        
        Write-Log ".NET configurado exitosamente ($installedTools herramientas procesadas)" -Component "DotNetConfig" -Level "SUCCESS"
        return $true
        
    } -Operation "Configurar .NET" -Component "DotNetConfig" -Severity ([ErrorSeverity]::Low)
}

function Install-VSCodeExtensions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
    )
    
    return Invoke-WithErrorHandling -Action {
        Write-Log "Instalando extensiones de VS Code..." -Component "VSCodeConfig"
        
        # Verificar si VS Code está instalado
        $codePath = Get-Command code -ErrorAction SilentlyContinue
        if (-not $codePath) {
            if ($Settings.continue_on_tool_missing) {
                Write-Log "VS Code no está instalado - Omitiendo instalación de extensiones" -Component "VSCodeConfig" -Level "WARNING"
                return $true
            } else {
                throw "VS Code no está instalado. Instálelo primero mediante winget."
            }
        }
        
        $installedExtensions = 0
        
        # Instalar extensiones
        foreach ($extension in $Config.extensions) {
            try {
                Write-Log "Instalando extensión: $extension" -Component "VSCodeConfig"
                & code --install-extension $extension --force
                $installedExtensions++
            }
            catch {
                Write-Log "Error instalando extensión '$extension': $($_.Exception.Message)" -Component "VSCodeConfig" -Level "WARNING"
            }
        }
        
        Write-Log "Extensiones de VS Code procesadas exitosamente ($installedExtensions extensiones instaladas)" -Component "VSCodeConfig" -Level "SUCCESS"
        return $true
        
    } -Operation "Instalar extensiones de VS Code" -Component "VSCodeConfig" -Severity ([ErrorSeverity]::Low)
}

# Función para crear archivo de configuración de Git
function New-GitConfigTemplate {
    return Invoke-WithErrorHandling -Action {
        # Obtener la ruta del proyecto
        $ConfigPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Config"
        $gitConfigPath = Join-Path $ConfigPath "git-config.json"
        
        if (-not (Test-Path $gitConfigPath)) {
            $gitConfigTemplate = @{
                userName = "Tu Nombre"
                userEmail = "tu.email@ejemplo.com"
                defaultBranch = "main"
            }
            
            $gitConfigTemplate | ConvertTo-Json -Depth 2 | Set-Content -Path $gitConfigPath -Encoding UTF8
            Write-Log "Plantilla de configuración Git creada: $gitConfigPath" -Component "GitConfig"
            Write-Log "Edite este archivo con su información personal antes de ejecutar el módulo de desarrollo" -Component "GitConfig" -Level "INFO"
        } else {
            Write-Log "Archivo git-config.json ya existe: $gitConfigPath" -Component "GitConfig" -Level "INFO"
        }
        
        return $true
        
    } -Operation "Crear plantilla Git config" -Component "GitConfig" -Severity ([ErrorSeverity]::Low) -Silent
}
