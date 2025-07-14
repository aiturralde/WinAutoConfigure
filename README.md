# WinAutoConfigure v3.0

[![GitHub Release](https://img.shields.io/github/v/release/aiturralde/WinAutoConfigure?style=for-the-badge)](https://github.com/aiturralde/WinAutoConfigure/releases)
[![PowerShell Version](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207%2B-blue?style=for-the-badge&logo=powershell)](https://github.com/PowerShell/PowerShell)
[![Windows Support](https://img.shields.io/badge/Windows-10%20%7C%2011-0078d4?style=for-the-badge&logo=windows)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/github/license/aiturralde/WinAutoConfigure?style=for-the-badge)](LICENSE)

🚀 **Configuración automática y optimización completa para Windows**

WinAutoConfigure es una herramienta de configuración automática de última generación que transforma tu instalación de Windows en un sistema completamente optimizado para productividad, desarrollo y gaming con un solo comando. Diseñada con arquitectura moderna y características empresariales.

## ✨ ¿Qué hace WinAutoConfigure?

**WinAutoConfigure v3.0** es la solución que uso para la configuración automática de Windows, incorporando:

### 🏗️ **Arquitectura Empresarial**
- **Orientada a Objetos**: Diseño modular con clases PowerShell
- **Cache Inteligente**: Sistema de persistencia que evita reejecutar configuraciones
- **Logging Avanzado**: Trazabilidad completa con rotación automática de logs
- **Validación Robusta**: Verificaciones de sistema multicapa antes de cada operación
- **Recuperación Automática**: Continúa desde el punto de falla sin perder progreso

### 🎯 **Configuraciones Automatizadas**
- **🖥️ Terminal Moderno**: Windows Terminal con perfiles optimizados y fuentes Nerd
- **📦 Aplicaciones Esenciales**: Instalación vía Winget de 40+ herramientas curadas
- **⚙️ Optimización del Sistema**: Configuraciones de rendimiento y personalización avanzada
- **🛡️ Seguridad de Red**: Configuración de firewall Windows Defender y protecciones
- **💻 Entorno de Desarrollo**: Stack completo para múltiples lenguajes y frameworks
- **🎮 Optimización Gaming**: Configuraciones específicas para máximo rendimiento en juegos

## 🎯 Características Principales

### 🔄 **Ejecución Inteligente**
- **Progreso Resumible**: Sistema de checkpoint que continúa desde donde se detuvo
- **Validación Previa**: Verificaciones de compatibilidad sin hacer cambios (`-ValidateOnly`)
- **Ejecución Selectiva**: Ejecuta pasos individuales según necesidades (`-Step 1-6`)
- **Forzar Actualización**: Bypassa cache para reconfiguración completa (`-ForceRefresh`)
- **Estado Visual**: Monitor de progreso con indicadores claros (`-ShowStatus`)

### 📊 **Monitoreo y Observabilidad**
- **Logs Estructurados**: Formato consistente con niveles de severidad
- **Cache Transparente**: Tracking de configuraciones aplicadas vs estado actual
- **Métricas de Performance**: Tiempos de ejecución y uso de recursos
- **Debugging Avanzado**: Trazas detalladas para diagnóstico de problemas

## 🚀 Inicio Rápido

### 📋 Requisitos del Sistema
- **Sistema Operativo**: Windows 10 v1909+ o Windows 11 (cualquier edición)
- **PowerShell**: 5.1+ (incluido en Windows) o PowerShell 7.x
- **Permisos**: Cuenta de administrador local
- **Conectividad**: Acceso a Internet para descargas
- **Espacio**: ~2GB libres para aplicaciones y cache

### ⚡ Instalación y Ejecución

#### Método 1: Descarga Directa
```powershell
# Descargar desde GitHub Releases
# https://github.com/aiturralde/WinAutoConfigure/releases/latest

# Extraer y ejecutar
.\Install.ps1 -RunImmediately
```

#### Método 2: Clonado del Repositorio
```powershell
# Clonar repositorio
git clone https://github.com/aiturralde/WinAutoConfigure.git
cd WinAutoConfigure

# Ejecutar con privilegios de administrador
.\WinAutoConfigure.ps1
```

### 🎮 Comandos Básicos

```powershell
# 🚀 Configuración completa automática
.\WinAutoConfigure.ps1

# 📊 Ver estado actual y progreso
.\WinAutoConfigure.ps1 -ShowStatus

# 🔍 Solo validar sistema (sin cambios)
.\WinAutoConfigure.ps1 -ValidateOnly

# 🔄 Reconfiguración completa (ignorar cache)
.\WinAutoConfigure.ps1 -ForceRefresh
```

### 🎯 Ejecución Avanzada

```powershell
# 🎯 Ejecutar paso específico (1-6)
.\WinAutoConfigure.ps1 -Step 3

# 🔄 Forzar actualización de un paso específico
.\WinAutoConfigure.ps1 -Step 2 -ForceRefresh

# 🔍 Validación de paso específico
.\WinAutoConfigure.ps1 -Step 5 -ValidateOnly

# 📊 Estado detallado con métricas
.\WinAutoConfigure.ps1 -ShowStatus -Verbose
```

## 📋 Sistema de Configuración Modular

WinAutoConfigure ejecuta **6 pasos modulares** que pueden ejecutarse independientemente:

| Paso | 🎯 Configuración | 📦 Incluye | ⏱️ Tiempo Est. |
|------|------------------|-------------|----------------|
| **1** | **🖥️ Windows Terminal** | Perfiles personalizados, fuentes Nerd Font, temas, PowerShell profile | ~3 min |
| **2** | **📦 Aplicaciones** | 40+ herramientas vía Winget: VS Code, Git, Docker, etc. | ~15 min |
| **3** | **⚙️ Sistema Windows** | Optimizaciones de rendimiento, Explorer, taskbar, privacidad | ~5 min |
| **4** | **🛡️ Seguridad de Red** | Windows Defender, firewall, protecciones avanzadas | ~3 min |
| **5** | **💻 Desarrollo** | SDKs, runtimes, herramientas CLI, configuraciones IDE | ~10 min |
| **6** | **🎮 Gaming** | Optimizaciones GPU, Xbox Game Bar, configuraciones de alto rendimiento | ~2 min |

### 🔧 Detalles de Configuración

#### **Paso 1: Windows Terminal** 🖥️
- **PowerShell 7**: Perfiles optimizados con autocompletado avanzado
- **Command Prompt**: Configuración mejorada con UTF-8
- **Git Bash**: Integración nativa si Git está instalado
- **Fuentes**: CascadiaCode y Caskaydia Cove Nerd Font
- **Temas**: Dark+ compatible con VS Code

#### **Paso 2: Aplicaciones Esenciales** 📦
```powershell
# Productividad
Microsoft.PowerToys, Notepad++, 7zip.7zip, Adobe.Acrobat.Reader.64-bit

# Desarrollo
Microsoft.VisualStudioCode, Git.Git, Microsoft.WindowsTerminal, 
Docker.DockerDesktop, Postman.Postman, Microsoft.PowerShell

# Multimedia
VideoLAN.VLC, OBSProject.OBSStudio, GIMP.GIMP

# Navegadores
Google.Chrome, Mozilla.Firefox, Microsoft.Edge.Dev

# Y muchas más...
```

#### **Paso 3: Optimizaciones del Sistema** ⚙️
- **Rendimiento**: Configuraciones de energía y CPU optimizadas
- **Explorer**: Extensiones de archivo, elementos ocultos, navegación mejorada
- **Taskbar**: Agrupación inteligente, ubicación optimizada
- **Privacidad**: Desactivación de telemetría innecesaria
- **Startup**: Gestión automática de programas de inicio

#### **Paso 4: Seguridad de Red** 🛡️
- **Windows Defender**: Configuración óptima de antivirus
- **Firewall**: Reglas personalizadas para desarrollo
- **SmartScreen**: Configuración balanceada seguridad/usabilidad
- **Network Protection**: Protección contra amenazas de red

#### **Paso 5: Herramientas de Desarrollo** 💻
- **Runtimes**: .NET, Node.js, Python, Java
- **Containers**: Docker Desktop con WSL2
- **CLI Tools**: Azure CLI, AWS CLI, kubectl, helm
- **IDEs**: VS Code con extensiones esenciales
- **Git**: Configuración global optimizada

#### **Paso 6: Optimización Gaming** 🎮
- **Game Mode**: Activación de modo juego de Windows
- **Xbox Game Bar**: Configuración optimizada
- **Graphics**: Configuraciones de alto rendimiento para GPU
- **Audio**: Optimizaciones de latencia para gaming
- **Background Apps**: Restricción de apps innecesarias durante juegos

## 🎛️ Parámetros y Opciones

| Parámetro | Tipo | Descripción | Ejemplo |
|-----------|------|-------------|---------|
| `-Step` | `[Int]` | Ejecuta paso específico (1-6) | `-Step 3` |
| `-ShowStatus` | `[Switch]` | Muestra progreso actual sin ejecutar | `-ShowStatus` |
| `-ValidateOnly` | `[Switch]` | Valida sistema sin hacer cambios | `-ValidateOnly` |
| `-ForceRefresh` | `[Switch]` | Ignora cache, reejecuta configuraciones | `-ForceRefresh` |
| `-Verbose` | `[Switch]` | Output detallado para debugging | `-Verbose` |

### 🎮 Ejemplos de Uso por Escenario

#### **Primera Instalación Completa**
```powershell
# Configuración desde cero
.\WinAutoConfigure.ps1

# Con logging detallado
.\WinAutoConfigure.ps1 -Verbose
```

#### **Mantenimiento y Actualizaciones**
```powershell
# Ver estado actual del sistema
.\WinAutoConfigure.ps1 -ShowStatus

# Actualizar solo aplicaciones (ignorar cache)
.\WinAutoConfigure.ps1 -Step 2 -ForceRefresh

# Reconfigurar terminal después de cambios manuales
.\WinAutoConfigure.ps1 -Step 1 -ForceRefresh
```

#### **Configuración Específica por Rol**
```powershell
# Setup solo para desarrollo
.\WinAutoConfigure.ps1 -Step 1  # Terminal
.\WinAutoConfigure.ps1 -Step 5  # Dev tools

# Setup para gaming
.\WinAutoConfigure.ps1 -Step 1  # Terminal
.\WinAutoConfigure.ps1 -Step 6  # Gaming optimizations

# Setup para uso general/oficina
.\WinAutoConfigure.ps1 -Step 1  # Terminal
.\WinAutoConfigure.ps1 -Step 2  # Applications
.\WinAutoConfigure.ps1 -Step 3  # Windows settings
```

#### **Debugging y Diagnóstico**
```powershell
# Verificar qué falla sin hacer cambios
.\WinAutoConfigure.ps1 -ValidateOnly -Verbose

# Verificar paso específico
.\WinAutoConfigure.ps1 -Step 4 -ValidateOnly

# Información de sistema después de cambios manuales
.\WinAutoConfigure.ps1 -ShowStatus -Verbose
```

## 🛡️ Seguridad y Validaciones Robustas

WinAutoConfigure implementa **validaciones multicapa** para garantizar ejecución segura:

### ✅ **Validaciones de Sistema**
- **Permisos de Administrador**: Verificación automática antes de cualquier operación
- **Compatibilidad de Windows**: Detección de versión y edición soportada
- **PowerShell Version**: Verificación de 5.1+ con fallback automático
- **Espacio en Disco**: Cálculo dinámico de espacio requerido vs disponible
- **Estado del Sistema**: Verificación de que Windows no está en modo de mantenimiento

### 🔒 **Validaciones de Seguridad**
- **Integridad de Archivos**: Verificación de checksums para archivos críticos
- **Conectividad Segura**: Validación de certificados SSL para descargas
- **Scanning de Malware**: Integración con Windows Defender para archivos descargados
- **Rollback Automático**: Reversión de cambios en caso de falla crítica
- **Sandbox Testing**: Validación de comandos críticos antes de ejecución

### 📊 **Sistema de Auditoría**
- **Logging Completo**: Registro de todas las operaciones con timestamps
- **Tracking de Cambios**: Monitoreo de configuraciones aplicadas vs estado actual
- **Métricas de Performance**: Tiempos de ejecución y uso de recursos
- **Reporting de Errores**: Información detallada para troubleshooting

## 📊 Monitoreo de Progreso y Logging Avanzado

### 🎯 **Monitor de Estado en Tiempo Real**

El comando `-ShowStatus` proporciona una vista completa del progreso:

```powershell
.\WinAutoConfigure.ps1 -ShowStatus
```

**Output de ejemplo:**
```
===============================================================
                 WINAUTOCONFIGURE v3.0                        
===============================================================
 🎯 Progreso General: 4/6 pasos completados (67%)            
 ⏱️  Tiempo total ejecutado: 18 min 32 seg                   
 💾 Cache: 15 configuraciones aplicadas                      
 
 ✅ [COMPLETADO] 1. Windows Terminal (2m 45s)
 ✅ [COMPLETADO] 2. Aplicaciones (14m 12s)  
 ✅ [COMPLETADO] 3. Sistema Windows (1m 23s)
 ✅ [COMPLETADO] 4. Seguridad de Red (48s)
 🔄 [PENDIENTE ] 5. Herramientas de Desarrollo
 ⏭️  [PENDIENTE ] 6. Optimización Gaming
===============================================================
 📊 Sistema: Windows 11 Pro 22H2 | PowerShell 7.4.0
 💿 Espacio libre: 125.4 GB | Memoria: 16 GB DDR4
 🌐 Conectividad: ✅ | Windows Update: ✅
===============================================================
```

### 📝 **Sistema de Logging Empresarial**

#### **Ubicación de Logs**
```
WinAutoConfigure/
├── Config/
│   ├── applications.json                 # Lista de aplicaciones a instalar
│   ├── terminal-settings.json           # Configuración de Windows Terminal
│   ├── common-settings.json             # Configuraciones generales del sistema
│   ├── gaming-config.json              # Configuraciones específicas para gaming
│   ├── git-config.json                 # Configuración global de Git
│   ├── master-config.json              # Configuración maestra del sistema
│   └── Microsoft.PowerShell_profile.ps1 # Perfil personalizado de PowerShell
├── Logs/
├── Cache/
```

#### **Formato de Log Estructurado**
```
[2025-07-14 15:30:45] [INFO] [STEP-2] Starting application installation
[2025-07-14 15:30:46] [DEBUG] [WINGET] Checking winget availability
[2025-07-14 15:30:47] [SUCCESS] [INSTALL] Microsoft.VisualStudioCode installed (v1.85.2)
[2025-07-14 15:30:52] [WARNING] [INSTALL] Docker.DockerDesktop requires restart
[2025-07-14 15:30:53] [ERROR] [INSTALL] Failed to install: Adobe.CreativeCloud (network timeout)
```
#### **Optimización de Performance**
```powershell
# Ver estadísticas de cache
.\WinAutoConfigure.ps1 -ShowStatus -Verbose

# Cache Stats Example:
# 📊 Cache Statistics:
#    - Configurations cached: 42
#    - Cache hits: 38 (90.5%)
#    - Cache misses: 4 (9.5%)
#    - Time saved: ~12 minutes
```

## 🔄 Continuación Automática y Recuperación

### 🎯 **Sistema de Checkpoint Inteligente**

WinAutoConfigure implementa un sistema de checkpoint robusto que garantiza:

1. **🚀 Primera Ejecución**: Comienza sistemáticamente desde el paso 1
2. **🔄 Ejecuciones Posteriores**: Detecta automáticamente el último paso completado
3. **⚠️ Recuperación de Errores**: Reinicia inteligentemente desde el punto de falla
4. **🔧 Modo Manual**: Permite override con `-ForceRefresh` para reconfiguración completa
5. **🎯 Ejecución Selectiva**: Soporte para pasos individuales sin afectar el progreso general

### ⚡ **Optimización de Performance**

#### **Cache Inteligente**
- **🔍 Detección de Cambios**: Compara estado actual vs configuraciones aplicadas
- **⚡ Skip Inteligente**: Evita reejecutar configuraciones ya aplicadas y válidas
- **🔄 Invalidación Automática**: Detecta cambios manuales y reconfigura según necesidad
- **🎛️ Control Manual**: Forzar actualización con `-ForceRefresh` cuando sea necesario

#### **Ejecución Optimizada**
- **✅ Validaciones Rápidas**: Checks de prerequisitos antes de cada paso (< 5 segundos)
- **📦 Descarga Paralela**: Downloads concurrentes de múltiples aplicaciones cuando es seguro
- **🔙 Rollback Automático**: Reversión inmediata en caso de errores críticos del sistema
- **🎯 Ejecución Selectiva**: Permite configurar solo los componentes necesarios

### 🛠️ **Modos de Ejecución Avanzados**

```powershell
# 🔄 Continuación inteligente (modo por defecto)
.\WinAutoConfigure.ps1

# 🎯 Ejecución paso específico manteniendo progreso
.\WinAutoConfigure.ps1 -Step 3

# 🔧 Reconfiguración completa (ignorar todo el cache)
.\WinAutoConfigure.ps1 -ForceRefresh

# 🔍 Modo diagnóstico (sin cambios)
.\WinAutoConfigure.ps1 -ValidateOnly

# 📊 Solo mostrar estado actual
.\WinAutoConfigure.ps1 -ShowStatus
```

## 🆘 Solución de Problemas y Soporte

### 🔧 **Problemas Comunes y Soluciones**

#### **🚫 "Error de permisos de administrador"**
```powershell
# ✅ Solución: Ejecutar PowerShell como administrador
# 1. Click derecho en PowerShell
# 2. Seleccionar "Ejecutar como administrador"
# 3. Confirmar UAC prompt

# Verificar permisos actuales:
[Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
```

#### **⚠️ "El sistema no cumple requisitos mínimos"**
```powershell
# 🔍 Diagnóstico específico de compatibilidad
.\WinAutoConfigure.ps1 -ValidateOnly -Verbose

# Verificaciones comunes:
# - Windows 10 v1909+ o Windows 11
# - PowerShell 5.1+ 
# - 2GB+ espacio libre
# - Conectividad a Internet
```

#### **⏸️ "Configuración incompleta o interrumpida"**
```powershell
# 📊 Ver progreso actual y punto de falla
.\WinAutoConfigure.ps1 -ShowStatus -Verbose

# 🔄 Continuar desde donde se detuvo
.\WinAutoConfigure.ps1

# 🔧 Si hay problemas persistentes, reiniciar paso específico:
.\WinAutoConfigure.ps1 -Step [NUMERO] -ForceRefresh
```

#### **🔄 "Necesito reinstalar/reconfigurar todo"**
```powershell
# 🔧 Reconfiguración completa (borra cache)
.\WinAutoConfigure.ps1 -ForceRefresh

# 🎯 Reconfigurar paso específico:
.\WinAutoConfigure.ps1 -Step 2 -ForceRefresh

# 🗑️ Limpiar cache manualmente:
Remove-Item ".\Cache\*" -Recurse -Force
```

#### **🌐 "Problemas de conectividad/descarga"**
```powershell
# ✅ Verificar conectividad básica
Test-NetConnection -ComputerName "github.com" -Port 443
Test-NetConnection -ComputerName "winget.azureedge.net" -Port 443

# 🔧 Configurar proxy si es necesario (empresas):
$env:HTTP_PROXY = "http://proxy.empresa.com:8080"
$env:HTTPS_PROXY = "http://proxy.empresa.com:8080"
```

#### **💻 "PowerShell Core vs Windows PowerShell"**
```powershell
# Verificar versión actual:
$PSVersionTable.PSVersion

# Windows PowerShell (5.1) - Incluido en Windows:
powershell.exe -ExecutionPolicy Bypass -File ".\WinAutoConfigure.ps1"

# PowerShell Core (7.x) - Si está instalado:
pwsh.exe -ExecutionPolicy Bypass -File ".\WinAutoConfigure.ps1"
```

### 📋 **Diagnostics y Debugging**

#### **🔍 Modo Verbose para Debugging**
```powershell
# Información detallada de ejecución
.\WinAutoConfigure.ps1 -Verbose

# Combinar con otros parámetros:
.\WinAutoConfigure.ps1 -Step 2 -ValidateOnly -Verbose
```

#### **📊 Información del Sistema**
```powershell
# Mostrar información completa del entorno
.\WinAutoConfigure.ps1 -ShowStatus -Verbose

# Output incluye:
# - Versión de Windows y PowerShell
# - Espacio en disco y memoria
# - Estado de conectividad
# - Configuraciones aplicadas
# - Estadísticas de cache
```

### 📞 **Canales de Soporte**

#### **🐛 Reportar Bugs**
1. **📋 Usar Bug Report Template**: [Crear Issue](https://github.com/aiturralde/WinAutoConfigure/issues/new?template=bug_report.yml)
2. **📁 Incluir Logs**: Adjuntar archivos de `Logs/WinAutoConfigure_YYYY-MM-DD.log`
3. **💻 Información del Sistema**: Output de `.\WinAutoConfigure.ps1 -ShowStatus -Verbose`
4. **⚡ Comando Exacto**: El comando exacto que causó el problema

#### **✨ Solicitar Features**
1. **💡 Feature Request Template**: [Solicitar Feature](https://github.com/aiturralde/WinAutoConfigure/issues/new?template=feature_request.yml)
2. **🎯 Describir Caso de Uso**: Explicar claramente el problema que resuelve
3. **📋 Detalles de Implementación**: Si tienes ideas sobre cómo implementarlo

#### **� Discussiones Generales**
- **🗣️ GitHub Discussions**: Para preguntas generales y discusiones
- **📚 Wiki**: Documentación adicional y guías avanzadas
- **🔒 Security Issues**: Reportar vulnerabilidades vía email privado

### 📋 **Checklist de Información para Soporte**

Cuando reportes un problema, incluye siempre:

- [ ] **Sistema**: Versión de Windows (ej: Windows 11 Pro 22H2)
- [ ] **PowerShell**: Versión de PowerShell (`$PSVersionTable.PSVersion`)
- [ ] **Comando**: Comando exacto ejecutado
- [ ] **Error**: Mensaje de error completo (copia/pega)
- [ ] **Logs**: Archivo de log más reciente de `Logs/`
- [ ] **Estado**: Output de `.\WinAutoConfigure.ps1 -ShowStatus`
- [ ] **Reproducibilidad**: Si el error es consistente o esporádico

### 🛠️ **Auto-Diagnóstico**

```powershell
# 🔍 Script de diagnóstico rápido
.\WinAutoConfigure.ps1 -ValidateOnly -Verbose 2>&1 | Tee-Object -FilePath "diagnostic.txt"

# Este comando:
# ✅ Valida todos los prerequisitos
# 📊 Genera output detallado
# 💾 Guarda la información en archivo para soporte
```

## 🎨 Personalización y Configuración Avanzada

### 🔧 **Configuración Modular por Casos de Uso**

#### **👨‍💻 Desarrollador Full-Stack**
```powershell
# Setup mínimo para desarrollo
.\WinAutoConfigure.ps1 -Step 1  # Terminal optimizado
.\WinAutoConfigure.ps1 -Step 5  # Herramientas de desarrollo
.\WinAutoConfigure.ps1 -Step 2  # Aplicaciones esenciales
```

#### **🎮 Gaming Enthusiast**
```powershell
# Configuración optimizada para gaming
.\WinAutoConfigure.ps1 -Step 1  # Terminal para gestión
.\WinAutoConfigure.ps1 -Step 6  # Optimizaciones gaming
.\WinAutoConfigure.ps1 -Step 3  # Optimizaciones sistema
```

#### **💼 Productividad Empresarial**
```powershell
# Setup para oficina/trabajo remoto
.\WinAutoConfigure.ps1 -Step 1  # Terminal profesional
.\WinAutoConfigure.ps1 -Step 2  # Apps productividad
.\WinAutoConfigure.ps1 -Step 3  # Configuraciones sistema
.\WinAutoConfigure.ps1 -Step 4  # Seguridad de red
```

#### **🔒 Estación de Trabajo Segura**
```powershell
# Máxima seguridad y compliance
.\WinAutoConfigure.ps1 -Step 4  # Seguridad primero
.\WinAutoConfigure.ps1 -Step 1  # Terminal seguro
.\WinAutoConfigure.ps1 -Step 3  # Configuraciones endurecidas
```

### ⚙️ **Configuración Personalizada**

#### **Modificar Lista de Aplicaciones**
```json
# Editar: Config/applications.json
{
  "applications": {
    "Microsoft.VisualStudioCode": true,
    "Git.Git": true,
    "Google.Chrome": true,
    "Docker.DockerDesktop": true,
    "Postman.Postman": true
    // Habilitar/deshabilitar aplicaciones según necesidad (true/false)
  }
}
```

#### **Personalizar Windows Terminal**
```json
# Editar: Config/terminal-settings.json
{
  "profiles": {
    "defaults": {
      "colorScheme": "Campbell Powershell",  // Cambiar tema
      "fontSize": 12,                        // Ajustar tamaño fuente
      "fontFace": "CascadiaCode NF"         // Cambiar fuente
    }
  }
}
```

#### **Respaldo y Restauración**
```powershell
# 💾 Crear respaldo completo de configuraciones
Copy-Item "Config\" -Destination "Backup\Config_$(Get-Date -Format 'yyyy-MM-dd')" -Recurse
Copy-Item "Cache\" -Destination "Backup\Cache_$(Get-Date -Format 'yyyy-MM-dd')" -Recurse

# 🔄 Restaurar desde respaldo  
Remove-Item "Config\*" -Recurse -Force
Remove-Item "Cache\*" -Recurse -Force
Copy-Item "Backup\Config_2025-07-14\*" -Destination "Config\" -Recurse
Copy-Item "Backup\Cache_2025-07-14\*" -Destination "Cache\" -Recurse
```

## 🚀 Contribución y Desarrollo

#### **🧪 Testing y Validación**
```powershell
# Validar sintaxis PowerShell
foreach ($file in Get-ChildItem -Filter "*.ps1" -Recurse) {
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$errors)
    if ($errors) { Write-Error "Errors in $($file.Name): $errors" }
}

# Test manual de módulos
Import-Module ".\Modules\Common-Logging.psm1" -Force
Import-Module ".\Modules\Common-Cache.psm1" -Force
```

#### **🎯 Versionado Semántico**
- **Major (v3.0.0)**: Cambios breaking, nueva arquitectura
- **Minor (v3.1.0)**: Nuevas características, sin breaking changes
- **Patch (v3.1.1)**: Bug fixes, mejoras menores

---

**WinAutoConfigure v3.0**
🔗 **[Releases](https://github.com/aiturralde/WinAutoConfigure/releases)** | 🐛 **[Issues](https://github.com/aiturralde/WinAutoConfigure/issues)** 