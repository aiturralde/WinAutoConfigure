<#
.SYNOPSIS
    Módulo para la instalación y configuración de Windows Terminal
.DESCRIPTION
    Este módulo instala Windows Terminal desde Microsoft Store y aplica configuraciones personalizadas
.NOTES
    Incluye instalación de fuentes y configuración de perfiles de PowerShell
#>

function Initialize-WindowsTerminalModule {
    [CmdletBinding()]
    param()
    
    Write-Log "Iniciando configuración de Windows Terminal..."
    
    # Paso 1: Instalar Windows Terminal
    Install-WindowsTerminal
    
    # Paso 2: Instalar fuentes necesarias
    Install-TerminalFonts
    
    # Paso 3: Configurar Windows Terminal
    Set-WindowsTerminalSettings
    
    # Paso 4: Configurar perfil de PowerShell
    Set-PowerShellProfile
    
    Write-Log "Configuración de Windows Terminal completada"
}

function Install-WindowsTerminal {
    Write-Log "Verificando instalación de Windows Terminal..."
    
    # Verificar si Windows Terminal ya está instalado
    $windowsTerminal = Get-AppxPackage -Name "Microsoft.WindowsTerminal" -ErrorAction SilentlyContinue
    
    if ($windowsTerminal) {
        Write-Log "Windows Terminal ya está instalado (Versión: $($windowsTerminal.Version))"
        return $true
    }
    
    Write-Log "Instalando Windows Terminal desde Microsoft Store..."
    
    try {
        # Verificar si winget está disponible
        $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
        
        if ($wingetPath) {
            Write-Log "Instalando Windows Terminal usando winget..."
            & winget install --id Microsoft.WindowsTerminal --source msstore --accept-package-agreements --accept-source-agreements | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Windows Terminal instalado correctamente usando winget"
                return $true
            }
        }
        
        # Método alternativo usando PowerShell
        Write-Log "Intentando instalación alternativa..."
        
        try {
            # Buscar en Microsoft Store
            Write-Log "Buscando Windows Terminal en Microsoft Store..."
            
            # Comando para abrir Microsoft Store en Windows Terminal
            Start-Process "ms-windows-store://pdp/?productid=9N0DX20HK701"
            
            Write-Log "Se ha abierto Microsoft Store. Por favor, instale Windows Terminal manualmente."
            Write-Log "Presione cualquier tecla cuando haya completado la instalación..."
            Read-Host
            
            # Verificar instalación
            $windowsTerminal = Get-AppxPackage -Name "Microsoft.WindowsTerminal" -ErrorAction SilentlyContinue
            if ($windowsTerminal) {
                Write-Log "Windows Terminal instalado correctamente"
                return $true
            } else {
                Write-Log "No se pudo verificar la instalación de Windows Terminal" -Level "WARNING"
                return $false
            }
        }
        catch {
            Write-Log "Error en instalación alternativa: $($_.Exception.Message)" -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Error instalando Windows Terminal: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Install-TerminalFonts {
    Write-Log "Instalando fuentes para Windows Terminal..."
    
    # Obtener la ruta del script principal (asumiendo que estamos en Modules/)
    $moduleScriptPath = $PSScriptRoot
    $projectRoot = Split-Path $moduleScriptPath -Parent
    $projectFontsPath = Join-Path $projectRoot "Fonts"
    
    # Verificar si existe la carpeta de fuentes
    if (-not (Test-Path $projectFontsPath)) {
        Write-Log "Carpeta 'Fonts' no encontrada en: $projectFontsPath" -Level "WARNING"
        Write-Log "Creando carpeta de fuentes vacía. Agregue archivos .ttf o .otf a esta carpeta." -Level "INFO"
        New-Item -Path $projectFontsPath -ItemType Directory -Force | Out-Null
        return $false
    }
    
    # Buscar archivos de fuentes en la carpeta
    $fontFiles = Get-ChildItem -Path $projectFontsPath -Recurse -Include "*.ttf", "*.otf" -ErrorAction SilentlyContinue
    
    if ($fontFiles.Count -eq 0) {
        Write-Log "No se encontraron archivos de fuentes (.ttf o .otf) en la carpeta: $projectFontsPath" -Level "WARNING"
        Write-Log "Agregue archivos de fuentes a la carpeta 'Fonts' para instalarlas automáticamente." -Level "INFO"
        return $false
    }
    
    Write-Log "Encontradas $($fontFiles.Count) fuentes para instalar"
    
    $installedCount = 0
    $skippedCount = 0
    
    foreach ($fontFile in $fontFiles) {
        try {
            Write-Log "Procesando fuente: $($fontFile.Name)"
            
            # Ruta de destino en la carpeta de fuentes del sistema
            $systemFontsPath = "$env:SystemRoot\Fonts"
            $targetPath = Join-Path $systemFontsPath $fontFile.Name
            
            # Verificar si la fuente ya está instalada
            if (Test-Path $targetPath) {
                Write-Log "Fuente ya instalada: $($fontFile.Name)" -Level "INFO"
                $skippedCount++
                continue
            }
            
            # Copiar fuente a la carpeta del sistema
            Copy-Item -Path $fontFile.FullName -Destination $targetPath -Force
            Write-Log "Fuente copiada: $($fontFile.Name)"
            
            # Registrar fuente en el registro de Windows
            $fontName = [System.IO.Path]::GetFileNameWithoutExtension($fontFile.Name)
            $fontExtension = $fontFile.Extension.ToLower()
            
            # Determinar el tipo de fuente para el registro
            $fontType = switch ($fontExtension) {
                ".ttf" { "(TrueType)" }
                ".otf" { "(OpenType)" }
                default { "(TrueType)" }
            }
            
            $registryKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
            $registryValueName = "$fontName $fontType"
            
            try {
                # Verificar si la entrada del registro ya existe
                $existingValue = Get-ItemProperty -Path $registryKey -Name $registryValueName -ErrorAction SilentlyContinue
                
                if (-not $existingValue) {
                    New-ItemProperty -Path $registryKey -Name $registryValueName -Value $fontFile.Name -PropertyType String -Force | Out-Null
                    Write-Log "Fuente registrada en el sistema: $registryValueName"
                } else {
                    Write-Log "Fuente ya registrada: $registryValueName" -Level "INFO"
                }
            }
            catch {
                Write-Log "Advertencia: No se pudo registrar la fuente en el registro: $($_.Exception.Message)" -Level "WARNING"
            }
            
            $installedCount++
        }
        catch {
            Write-Log "Error instalando fuente $($fontFile.Name): $($_.Exception.Message)" -Level "ERROR"
        }
    }
    
    # Resumen de instalación
    Write-Log "=== Resumen de Instalación de Fuentes ==="
    Write-Log "Fuentes instaladas: $installedCount"
    Write-Log "Fuentes omitidas (ya instaladas): $skippedCount"
    Write-Log "Total procesadas: $($fontFiles.Count)"
    
    if ($installedCount -gt 0) {
        Write-Log "Algunas fuentes pueden requerir reiniciar las aplicaciones para aparecer disponibles." -Level "INFO"
    }
    
    Write-Log "Instalación de fuentes completada"
    return $true
}

function Set-WindowsTerminalSettings {
    Write-Log "Configurando settings de Windows Terminal..."
    
    # Ruta del archivo de configuración
    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    
    # Verificar si existe el directorio
    $settingsDir = Split-Path $settingsPath -Parent
    if (-not (Test-Path $settingsDir)) {
        Write-Log "Directorio de configuración no encontrado. Asegúrese de que Windows Terminal esté instalado." -Level "WARNING"
        return $false
    }
    
    # Obtener la ruta del archivo de configuración del proyecto
    $moduleScriptPath = $PSScriptRoot
    $projectRoot = Split-Path $moduleScriptPath -Parent
    $configFilePath = Join-Path $projectRoot "Config\terminal-settings.json"
    
    # Verificar si existe el archivo de configuración
    if (-not (Test-Path $configFilePath)) {
        Write-Log "Archivo de configuración no encontrado: $configFilePath" -Level "ERROR"
        Write-Log "Usando configuración predeterminada..." -Level "WARNING"
        
        # Configuración predeterminada de respaldo
        $customSettings = @{
            '$help' = 'https://aka.ms/terminal-documentation'
            '$schema' = 'https://aka.ms/terminal-profiles-schema'
            'defaultProfile' = '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'
            'copyOnSelect' = $false
            'copyFormatting' = $false
            'profiles' = @{
                'defaults' = @{
                    'font' = @{
                        'face' = 'Cascadia Code'
                        'size' = 12
                    }
                    'cursorShape' = 'bar'
                    'colorScheme' = 'Campbell Powershell'
                }
                'list' = @(
                    @{
                        'guid' = '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'
                        'name' = 'Windows PowerShell'
                        'commandline' = 'powershell.exe'
                        'hidden' = $false
                        'startingDirectory' = '%USERPROFILE%'
                        'icon' = 'ms-appx:///ProfileIcons/{61c54bbd-c2c6-5271-96e7-009a87ff44bf}.png'
                    },
                    @{
                        'guid' = '{574e775e-4f2a-5b96-ac1e-a2962a402336}'
                        'name' = 'PowerShell Core'
                        'commandline' = 'pwsh.exe'
                        'hidden' = $false
                        'startingDirectory' = '%USERPROFILE%'
                        'icon' = 'ms-appx:///ProfileIcons/{574e775e-4f2a-5b96-ac1e-a2962a402336}.png'
                    }
                )
            }
        }
    }
    else {
        try {
            Write-Log "Cargando configuración desde: $configFilePath"
            $configContent = Get-Content -Path $configFilePath -Raw -Encoding UTF8
            $customSettings = $configContent | ConvertFrom-Json -AsHashtable
            Write-Log "Configuración cargada correctamente desde archivo"
        }
        catch {
            Write-Log "Error leyendo archivo de configuración: $($_.Exception.Message)" -Level "ERROR"
            Write-Log "Usando configuración predeterminada..." -Level "WARNING"
            
            # Configuración predeterminada de respaldo
            $customSettings = @{
                '$help' = 'https://aka.ms/terminal-documentation'
                '$schema' = 'https://aka.ms/terminal-profiles-schema'
                'defaultProfile' = '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'
                'copyOnSelect' = $false
                'copyFormatting' = $false
                'profiles' = @{
                    'defaults' = @{
                        'font' = @{
                            'face' = 'Cascadia Code'
                            'size' = 12
                        }
                        'cursorShape' = 'bar'
                        'colorScheme' = 'Campbell Powershell'
                    }
                    'list' = @(
                        @{
                            'guid' = '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'
                            'name' = 'Windows PowerShell'
                            'commandline' = 'powershell.exe'
                            'hidden' = $false
                            'startingDirectory' = '%USERPROFILE%'
                            'icon' = 'ms-appx:///ProfileIcons/{61c54bbd-c2c6-5271-96e7-009a87ff44bf}.png'
                        },
                        @{
                            'guid' = '{574e775e-4f2a-5b96-ac1e-a2962a402336}'
                            'name' = 'PowerShell Core'
                            'commandline' = 'pwsh.exe'
                            'hidden' = $false
                            'startingDirectory' = '%USERPROFILE%'
                            'icon' = 'ms-appx:///ProfileIcons/{574e775e-4f2a-5b96-ac1e-a2962a402336}.png'
                        }
                    )
                }
            }
        }
    }
    
    try {
        # Crear backup del archivo existente si existe
        if (Test-Path $settingsPath) {
            $backupPath = "$settingsPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item -Path $settingsPath -Destination $backupPath
            Write-Log "Backup creado: $backupPath"
        }
        
        # Escribir nueva configuración
        $customSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding UTF8
        Write-Log "Configuración de Windows Terminal aplicada correctamente"
        return $true
    }
    catch {
        Write-Log "Error configurando Windows Terminal: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Set-PowerShellProfile {
    Write-Log "Configurando perfil de PowerShell..."
    
    # Obtener la ruta del archivo de perfil del proyecto
    $moduleScriptPath = $PSScriptRoot
    $projectRoot = Split-Path $moduleScriptPath -Parent
    $sourceProfilePath = Join-Path $projectRoot "Config\Microsoft.PowerShell_profile.ps1"
    
    # Verificar si existe el archivo de perfil personalizado
    if (-not (Test-Path $sourceProfilePath)) {
        Write-Log "Archivo de perfil no encontrado: $sourceProfilePath" -Level "ERROR"
        Write-Log "Usando configuración predeterminada..." -Level "WARNING"
        
        # Contenido de perfil básico de respaldo
        $profileContent = @'
# Perfil básico de PowerShell para WinAutoConfigure
# Archivo de perfil personalizado no encontrado

# Configuración básica de colores
$Host.UI.RawUI.BackgroundColor = "DarkBlue"
$Host.UI.RawUI.ForegroundColor = "White"

# Mensaje de bienvenida
Write-Host "PowerShell configurado por WinAutoConfigure" -ForegroundColor Green
Write-Host "Para personalizar, edite: Config\Microsoft.PowerShell_profile.ps1" -ForegroundColor Yellow
Write-Host ""
'@
    }
    else {
        try {
            Write-Log "Cargando perfil desde: $sourceProfilePath"
            $profileContent = Get-Content -Path $sourceProfilePath -Raw -Encoding UTF8
            Write-Log "Perfil personalizado cargado correctamente"
        }
        catch {
            Write-Log "Error leyendo archivo de perfil: $($_.Exception.Message)" -Level "ERROR"
            Write-Log "Usando configuración predeterminada..." -Level "WARNING"
            
            # Contenido de perfil básico de respaldo
            $profileContent = @'
# Perfil básico de PowerShell para WinAutoConfigure
# Error al cargar archivo de perfil personalizado

# Configuración básica de colores
$Host.UI.RawUI.BackgroundColor = "DarkBlue"
$Host.UI.RawUI.ForegroundColor = "White"

# Mensaje de bienvenida
Write-Host "PowerShell configurado por WinAutoConfigure" -ForegroundColor Green
Write-Host "Error al cargar perfil personalizado" -ForegroundColor Red
Write-Host ""
'@
        }
    }
    
    # Crear perfil para Windows PowerShell
    $profilePath = $PROFILE.AllUsersAllHosts
    $profileDir = Split-Path $profilePath -Parent
    
    if (-not (Test-Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
    }
    
    try {
        Set-Content -Path $profilePath -Value $profileContent -Encoding UTF8
        Write-Log "Perfil de PowerShell configurado en: $profilePath"
        
        # También crear para PowerShell Core si está disponible
        if (Get-Command pwsh -ErrorAction SilentlyContinue) {
            $coreProfilePath = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
            $coreProfileDir = Split-Path $coreProfilePath -Parent
            
            if (-not (Test-Path $coreProfileDir)) {
                New-Item -Path $coreProfileDir -ItemType Directory -Force | Out-Null
            }
            
            Set-Content -Path $coreProfilePath -Value $profileContent -Encoding UTF8
            Write-Log "Perfil de PowerShell Core configurado en: $coreProfilePath"
        }
        
        return $true
    }
    catch {
        Write-Log "Error configurando perfil de PowerShell: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}
