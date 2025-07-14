# Carpeta de Fuentes - WinAutoConfigure

Esta carpeta contiene las fuentes que se instalarán automáticamente durante la configuración de Windows Terminal.

## 📁 Uso

1. **Agregar fuentes**: Coloque archivos de fuentes (`.ttf` o `.otf`) en esta carpeta
2. **Estructura**: Las fuentes pueden estar en subcarpetas, el script las encontrará automáticamente
3. **Instalación**: Las fuentes se instalarán automáticamente cuando se ejecute el módulo de Windows Terminal

## 🔤 Fuentes Recomendadas para Terminal

### **Fuentes con Ligaduras (Recomendadas para programación):**
- **Cascadia Code** - Fuente oficial de Microsoft para terminales
- **Fira Code** - Popular fuente con ligaduras para programación
- **JetBrains Mono** - Fuente de JetBrains con excelente legibilidad
- **Source Code Pro** - Fuente de Adobe, muy legible
- **Hack** - Fuente diseñada específicamente para código fuente

### **Fuentes Clásicas:**
- **Consolas** - Fuente clásica de Microsoft (ya incluida en Windows)
- **Monaco** - Fuente popular en Mac
- **Menlo** - Otra fuente popular para terminales

## 📥 Donde Descargar Fuentes

### **Cascadia Code (Recomendada)**
```
https://github.com/microsoft/cascadia-code/releases
```
Descarga: `CascadiaCode-*.zip` y extrae los archivos `.ttf`

### **Fira Code**
```
https://github.com/tonsky/FiraCode/releases
```
Descarga: `Fira_Code_v*.zip` y extrae los archivos `.ttf`

### **JetBrains Mono**
```
https://www.jetbrains.com/lp/mono/
```

### **Nerd Fonts (Fuentes con iconos)**
```
https://www.nerdfonts.com/font-downloads
```
Incluye versiones parcheadas con iconos adicionales.

## 🛠️ Estructura de Ejemplo

```
Fonts/
├── README.md                    # Este archivo
├── CascadiaCode/
│   ├── CascadiaCode-Regular.ttf
│   ├── CascadiaCode-Bold.ttf
│   └── CascadiaCode-Italic.ttf
├── FiraCode/
│   ├── FiraCode-Regular.ttf
│   ├── FiraCode-Bold.ttf
│   └── FiraCode-Light.ttf
└── JetBrainsMono/
    ├── JetBrainsMono-Regular.ttf
    └── JetBrainsMono-Bold.ttf
```

## ⚙️ Configuración en Windows Terminal

Después de instalar las fuentes, se configurará automáticamente en Windows Terminal:

```json
{
    "fontFace": "Cascadia Code",
    "fontSize": 12
}
```

## 📝 Notas Importantes

1. **Permisos**: Se requieren permisos de administrador para instalar fuentes del sistema
2. **Registro**: Las fuentes se registran automáticamente en el registro de Windows
3. **Duplicados**: El script omite fuentes que ya están instaladas
4. **Formatos**: Soporta archivos `.ttf` (TrueType) y `.otf` (OpenType)
5. **Reinicio**: Algunas aplicaciones pueden requerir reinicio para mostrar las nuevas fuentes

## 🔍 Verificación

Para verificar que las fuentes se instalaron correctamente:

1. Abrir Windows Terminal
2. Ir a Configuración (Ctrl + ,)
3. Buscar la fuente en la lista de "Familia de fuentes"
4. O usar PowerShell: `Get-ChildItem "$env:SystemRoot\Fonts" | Where-Object Name -like "*CascadiaCode*"`

## 🚨 Solución de Problemas

### **La fuente no aparece en Windows Terminal:**
- Reiniciar Windows Terminal
- Verificar que el archivo se copió a `C:\Windows\Fonts`
- Comprobar que se registró en el registro de Windows

### **Error de permisos:**
- Ejecutar el script como administrador
- Verificar que la carpeta Fonts tiene los archivos correctos

### **Fuente corrupta:**
- Verificar que el archivo de fuente no esté dañado
- Descargar nuevamente la fuente desde la fuente oficial
