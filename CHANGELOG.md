# Changelog

Todos los cambios notables de este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
y este proyecto adhiere al [Versionado Semántico](https://semver.org/spec/v2.0.0.html).

## [3.1.0] - 2025-07-19

### ✨ Agregado
- Instalación automática de Cloudflare WARP vía winget
- Configuración automática del cliente WARP (registro y conexión)
- Protección VPN integrada + DNS seguro (1.1.1.1)
- Protección automática contra malware y sitios maliciosos

### 🔄 Cambiado
- **BREAKING**: Paso 3 del módulo NetworkSecurity ahora instala Cloudflare WARP
- Reemplazada configuración DNS manual por solución VPN completa

### 🗑️ Removido
- Configuración manual de servidores DNS
- Función `Set-DnsSettings` del módulo Configure-NetworkSecurity
- Sección `"dns"` del archivo network-security-config.json

## [3.0.0] - 2025-07-14

### ✨ Agregado
- Arquitectura orientada a objetos completa con clases PowerShell
- Sistema de reinicio inteligente con preservación de progreso
- Cache avanzado que evita reejecutar configuraciones
- Módulo gaming completamente refactorizado (7 optimizaciones)
- Sistema de logging empresarial con rotación automática
- Validación multicapa robusta del sistema
- Nuevo módulo de seguridad de red con configuraciones empresariales

### 🔄 Cambiado
- Rediseño completo de arquitectura del proyecto
- Stack de desarrollo actualizado con herramientas modernas
- Lista de aplicaciones curada y actualizada
- Optimizaciones de Windows más granulares
- Performance general significativamente mejorada

### 🐛 Corregido
- Problemas de codificación de caracteres en módulos
- Gestión mejorada de rutas y archivos
- Manejo robusto de errores en instalaciones
- Optimización de tiempos de ejecución

## [2.x] - Versiones Anteriores

### Características Principales
- Configuración básica de Windows Terminal
- Instalación de aplicaciones esenciales vía Winget
- Configuraciones básicas de Windows y gaming
- Configuración manual de algunos componentes

---

## Enlaces

- [3.1.0]: https://github.com/aiturralde/WinAutoConfigure/compare/v3.0.0...v3.1.0
- [3.0.0]: https://github.com/aiturralde/WinAutoConfigure/releases/tag/v3.0.0
