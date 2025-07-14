<#
.SYNOPSIS
    Módulo para configurar herramientas de desarrollo
.DESCRIPTION
    Este módulo configura entornos de desarrollo, instala SDKs y configura herramientas
.NOTES
    Incluye configuración de Git, Node.js, Python, .NET y herramientas de desarrollo
#>

function Initialize-DevelopmentToolsModule {
    [CmdletBinding()]
    param()
    
    Write-Log "Iniciando configuración de herramientas de desarrollo..."
    
    # Paso 1: Configurar Git globalmente
    Set-GitConfiguration
    
    # Paso 2: Configurar Node.js y npm
    Set-NodeJsConfiguration
    
    # Paso 3: Configurar Python
    Set-PythonConfiguration
    
    # Paso 4: Configurar .NET
    Set-DotNetConfiguration
    
    # Paso 5: Instalar extensiones de VS Code
    Install-VSCodeExtensions
    
    Write-Log "Configuración de herramientas de desarrollo completada"
    return $true
}

function Set-GitConfiguration {
    Write-Log "Configurando Git..."
    
    try {
        # Verificar si Git está instalado
        $gitPath = Get-Command git -ErrorAction SilentlyContinue
        if (-not $gitPath) {
            Write-Log "Git no está instalado. Instálelo primero mediante winget." -Level "WARNING"
            return
        }
        
        # Obtener la ruta del proyecto
        $moduleScriptPath = $PSCommandPath
        $projectRoot = Split-Path (Split-Path $moduleScriptPath -Parent) -Parent
        
        # Configuración básica de Git (el usuario puede personalizar después)
        $configFile = Join-Path $projectRoot "Config\git-config.json"
        
        if (Test-Path $configFile) {
            $gitConfig = Get-Content -Path $configFile -Raw | ConvertFrom-Json
            
            & git config --global user.name $gitConfig.userName
            & git config --global user.email $gitConfig.userEmail
            & git config --global init.defaultBranch $gitConfig.defaultBranch
            
            Write-Log "Git configurado con: $($gitConfig.userName) <$($gitConfig.userEmail)>"
        } else {
            # Configuración predeterminada
            & git config --global init.defaultBranch "main"
            & git config --global core.autocrlf true
            & git config --global core.editor "code --wait"
            & git config --global merge.tool "vscode"
            & git config --global mergetool.vscode.cmd 'code --wait $MERGED'
            & git config --global diff.tool "vscode"
            & git config --global difftool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'
            
            Write-Log "Git configurado con ajustes predeterminados"
        }
        
    }
    catch {
        Write-Log "Error configurando Git: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Set-NodeJsConfiguration {
    Write-Log "Configurando Node.js y npm..."
    
    try {
        $nodePath = Get-Command node -ErrorAction SilentlyContinue
        if (-not $nodePath) {
            Write-Log "Node.js no está instalado. Instálelo primero mediante winget." -Level "WARNING"
            return
        }
        
        # Configurar npm
        & npm config set init-author-name "Usuario"
        & npm config set init-license "MIT"
        & npm config set save-exact true
        
        # Instalar paquetes globales útiles
        $globalPackages = @(
            "npm@latest",
            "yarn",
            "pnpm",
            "typescript",
            "@typescript-eslint/eslint-plugin",
            "eslint",
            "prettier",
            "nodemon",
            "http-server",
            "live-server"
        )
        
        foreach ($package in $globalPackages) {
            Write-Log "Instalando paquete global: $package"
            & npm install -g $package --silent
        }
        
        Write-Log "Node.js y npm configurados"
    }
    catch {
        Write-Log "Error configurando Node.js: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Set-PythonConfiguration {
    Write-Log "Configurando Python..."
    
    try {
        $pythonPath = Get-Command python -ErrorAction SilentlyContinue
        if (-not $pythonPath) {
            Write-Log "Python no está instalado. Instálelo primero mediante winget." -Level "WARNING"
            return
        }
        
        # Actualizar pip
        & python -m pip install --upgrade pip --quiet
        
        # Instalar paquetes útiles
        $pythonPackages = @(
            "virtualenv",
            "pipenv",
            "poetry",
            "black",
            "flake8",
            "pylint",
            "autopep8",
            "requests",
            "flask",
            "django",
            "fastapi",
            "jupyter",
            "pandas",
            "numpy"
        )
        
        foreach ($package in $pythonPackages) {
            Write-Log "Instalando paquete Python: $package"
            & python -m pip install $package --quiet
        }
        
        Write-Log "Python configurado"
    }
    catch {
        Write-Log "Error configurando Python: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Set-DotNetConfiguration {
    Write-Log "Configurando .NET..."
    
    try {
        $dotnetPath = Get-Command dotnet -ErrorAction SilentlyContinue
        if (-not $dotnetPath) {
            Write-Log ".NET no está instalado. Instálelo primero." -Level "WARNING"
            return
        }
        
        # Instalar herramientas globales de .NET
        $dotnetTools = @(
            "dotnet-ef",
            "dotnet-aspnet-codegenerator",
            "dotnet-dev-certs",
            "dotnet-format",
            "dotnet-reportgenerator-globaltool"
        )
        
        foreach ($tool in $dotnetTools) {
            Write-Log "Instalando herramienta .NET: $tool"
            & dotnet tool install --global $tool --verbosity quiet
        }
        
        # Configurar certificados de desarrollo HTTPS
        & dotnet dev-certs https --trust
        
        Write-Log ".NET configurado"
    }
    catch {
        Write-Log "Error configurando .NET: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Install-VSCodeExtensions {
    Write-Log "Instalando extensiones de VS Code..."
    
    try {
        $codePath = Get-Command code -ErrorAction SilentlyContinue
        if (-not $codePath) {
            Write-Log "VS Code no está instalado. Instálelo primero mediante winget." -Level "WARNING"
            return
        }
        
        # Lista de extensiones útiles
        $extensions = @(
            "ms-vscode.powershell",
            "ms-python.python",
            "ms-dotnettools.csharp",
            "ms-vscode.vscode-typescript-next",
            "bradlc.vscode-tailwindcss",
            "esbenp.prettier-vscode",
            "formulahendry.auto-rename-tag",
            "christian-kohler.path-intellisense",
            "ms-vscode.vscode-json",
            "redhat.vscode-yaml",
            "eamodio.gitlens",
            "github.copilot",
            "ms-vscode-remote.remote-containers",
            "ms-vscode-remote.remote-ssh",
            "pkief.material-icon-theme",
            "zhuangtongfa.material-theme"
        )
        
        foreach ($extension in $extensions) {
            Write-Log "Instalando extensión: $extension"
            & code --install-extension $extension --force
        }
        
        Write-Log "Extensiones de VS Code instaladas"
    }
    catch {
        Write-Log "Error instalando extensiones de VS Code: $($_.Exception.Message)" -Level "WARNING"
    }
}

# Función para crear archivo de configuración de Git
function New-GitConfigTemplate {
    # Obtener la ruta del proyecto
    $moduleScriptPath = $PSCommandPath
    $projectRoot = Split-Path (Split-Path $moduleScriptPath -Parent) -Parent
    $gitConfigPath = Join-Path $projectRoot "Config\git-config.json"
    
    if (-not (Test-Path $gitConfigPath)) {
        $gitConfigTemplate = @{
            userName = "Tu Nombre"
            userEmail = "tu.email@ejemplo.com"
            defaultBranch = "main"
        }
        
        $gitConfigTemplate | ConvertTo-Json -Depth 2 | Set-Content -Path $gitConfigPath -Encoding UTF8
        Write-Log "Plantilla de configuración Git creada: $gitConfigPath"
        Write-Log "Edite este archivo con su información personal antes de ejecutar el módulo de desarrollo"
    }
}
