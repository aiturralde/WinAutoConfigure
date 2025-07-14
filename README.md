# WinAutoConfigure v3.0

🚀 **Configuración automática y optimización completa para Windows 11**

WinAutoConfigure es una herramienta de configuración automática que transforma tu instalación de Windows 11 en un sistema optimizado para productividad, desarrollo y gaming con un solo comando.

## ✨ ¿Qué hace WinAutoConfigure?

WinAutoConfigure automatiza la configuración completa de Windows 11, incluyendo:

- **Terminal Moderno**: Configuración de Windows Terminal con perfiles optimizados
- **Aplicaciones Esenciales**: Instalación automática de herramientas de productividad y desarrollo
- **Optimización del Sistema**: Configuraciones de rendimiento y personalización
- **Seguridad de Red**: Configuración de firewall y protecciones de red
- **Herramientas de Desarrollo**: Entorno completo para programadores
- **Optimización Gaming**: Configuraciones específicas para mejor rendimiento en juegos

## 🎯 Características Principales

### Arquitectura Moderna
- **Orientada a Objetos**: Diseño modular y mantenible
- **Cache Inteligente**: Evita reejecutar pasos ya completados
- **Logging Avanzado**: Seguimiento detallado de todas las operaciones
- **Validación Robusta**: Verificaciones de sistema antes de cada operación

### Ejecución Flexible
- **Progreso Resumible**: Continúa desde donde se detuvo la última ejecución
- **Pasos Individuales**: Ejecuta solo las configuraciones que necesites
- **Validación Previa**: Verifica compatibilidad sin hacer cambios
- **Forzar Actualización**: Refresca configuraciones cuando sea necesario

## 🚀 Inicio Rápido

### Requisitos Previos
- Windows 10 v1909 o Windows 11
- PowerShell 5.1 o superior
- Permisos de administrador
- Conexión a Internet

### Ejecución Básica

```powershell
# Configuración completa automática
.\WinAutoConfigure.ps1

# Ver estado actual
.\WinAutoConfigure.ps1 -ShowStatus

# Solo validar el sistema (sin cambios)
.\WinAutoConfigure.ps1 -ValidateOnly
```

### Ejecución Avanzada

```powershell
# Ejecutar un paso específico (1-6)
.\WinAutoConfigure.ps1 -Step 3

# Forzar actualización (ignorar cache)
.\WinAutoConfigure.ps1 -ForceRefresh

# Combinación de parámetros
.\WinAutoConfigure.ps1 -Step 2 -ForceRefresh
```

## 📋 Pasos de Configuración

WinAutoConfigure ejecuta 6 pasos principales:

| Paso | Descripción | Incluye |
|------|-------------|---------|
| **1** | **Windows Terminal** | Configuración de perfiles, temas y fuentes |
| **2** | **Aplicaciones** | Instalación de herramientas esenciales |
| **3** | **Sistema Windows** | Optimizaciones de rendimiento y personalización |
| **4** | **Seguridad de Red** | Configuración de firewall y protecciones |
| **5** | **Desarrollo** | Entorno completo para programadores |
| **6** | **Gaming** | Optimizaciones específicas para juegos |

## 🔧 Parámetros Disponibles

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `-Step` | Int | Ejecuta un paso específico (1-6) |
| `-ShowStatus` | Switch | Muestra el progreso actual sin ejecutar |
| `-ValidateOnly` | Switch | Valida el sistema sin hacer cambios |
| `-ForceRefresh` | Switch | Ignora cache y reejecuta configuraciones |

## 💡 Ejemplos de Uso

### Configuración Primera Vez
```powershell
# Ejecutar configuración completa
.\WinAutoConfigure.ps1
```

### Mantenimiento del Sistema
```powershell
# Ver qué se ha configurado
.\WinAutoConfigure.ps1 -ShowStatus

# Actualizar solo aplicaciones
.\WinAutoConfigure.ps1 -Step 2 -ForceRefresh
```

### Configuración Específica
```powershell
# Solo configurar herramientas de desarrollo
.\WinAutoConfigure.ps1 -Step 5

# Solo optimizaciones gaming
.\WinAutoConfigure.ps1 -Step 6
```

### Validación del Sistema
```powershell
# Verificar compatibilidad antes de ejecutar
.\WinAutoConfigure.ps1 -ValidateOnly

# Ver estado después de cambios manuales
.\WinAutoConfigure.ps1 -ShowStatus
```

## 🛡️ Seguridad y Validaciones

WinAutoConfigure incluye múltiples validaciones de seguridad:

- ✅ **Verificación de Permisos**: Confirma permisos de administrador
- ✅ **Compatibilidad de Sistema**: Valida versión de Windows y PowerShell
- ✅ **Espacio en Disco**: Verifica espacio disponible antes de instalar
- ✅ **Estado del Sistema**: Comprueba que el sistema esté en estado estable

## 📊 Progreso y Logging

### Ver Progreso
El comando `-ShowStatus` muestra el estado actual:
```
===============================================================
                 WINAUTOCONFIGURE v3.0                        
===============================================================
 Paso actual: 3/6 (50%)                                      

 [X] 1. Configuracion de Windows Terminal
 [X] 2. Instalacion de Aplicaciones y Caracteristicas
 [>] 3. Configuracion de Windows
 [ ] 4. Configuracion de Seguridad de Red
 [ ] 5. Configuracion de Herramientas de Desarrollo
 [ ] 6. Configuracion Gaming (Optimizaciones)
===============================================================
```

### Logs del Sistema
Los logs detallados se almacenan en:
- `config/logs/`: Logs de ejecución y errores
- `config/cache/`: Cache de configuraciones aplicadas
- `config/progress.json`: Estado actual del progreso

## 🔄 Continuación Automática

WinAutoConfigure recuerda automáticamente dónde se quedó:

1. **Primera Ejecución**: Comienza desde el paso 1
2. **Ejecuciones Posteriores**: Continúa desde el último paso completado
3. **Después de Errores**: Reinicia desde el paso que falló
4. **Con -ForceRefresh**: Reejecuta todo ignorando el progreso previo

## ⚡ Optimización de Rendimiento

### Cache Inteligente
- Evita reejecutar configuraciones ya aplicadas
- Detecta cambios en el sistema automáticamente
- Permite forzar actualización cuando sea necesario

### Ejecución Eficiente
- Validaciones rápidas antes de cada paso
- Descarga paralela de recursos cuando es posible
- Rollback automático en caso de errores críticos

## 🆘 Solución de Problemas

### Problemas Comunes

**"Error de permisos"**
```powershell
# Ejecutar PowerShell como administrador
# Hacer clic derecho > "Ejecutar como administrador"
```

**"El sistema no cumple requisitos"**
```powershell
# Verificar específicamente qué falla
.\WinAutoConfigure.ps1 -ValidateOnly
```

**"Configuración incompleta"**
```powershell
# Ver el progreso actual
.\WinAutoConfigure.ps1 -ShowStatus

# Continuar desde donde se detuvo
.\WinAutoConfigure.ps1
```

**"Reinstalar configuración"**
```powershell
# Forzar reconfiguración completa
.\WinAutoConfigure.ps1 -ForceRefresh
```

### Logs de Error
Si encuentras problemas, revisa los logs en:
- `config/logs/WinAutoConfigure_YYYY-MM-DD.log`

## 🎨 Personalización

### Configuración Modular
Cada paso puede ejecutarse independientemente según tus necesidades:

- **Solo Terminal**: `-Step 1`
- **Solo Aplicaciones**: `-Step 2`
- **Solo Gaming**: `-Step 6`

### Configuración Persistente
Las configuraciones se almacenan y persisten entre reinicios del sistema.

## 📞 Soporte

Para reportar problemas o solicitar características:

1. **Logs**: Incluye siempre los logs de `config/logs/`
2. **Sistema**: Especifica versión de Windows y PowerShell
3. **Comando**: Indica el comando exacto que ejecutaste
4. **Error**: Copia el mensaje de error completo

---

**WinAutoConfigure v3.0** 