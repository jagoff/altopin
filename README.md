# 📌 AltoPin

**AltoPin** es una aplicación ligera y elegante para macOS que permite mantener cualquier ventana siempre visible encima de todas las demás con un simple atajo de teclado.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## ⚡️ Inicio Rápido

```bash
git clone https://github.com/tu-usuario/altopin.git && cd altopin && bash build.sh && open build/AlwaysOnTop.app
```

Presiona **Control+Cmd+T** en cualquier ventana para pinnearla. ¡Así de simple!

## ✨ Características

- 🎯 **Pin instantáneo**: Mantén cualquier ventana siempre visible con Control+Cmd+T
- 📋 **Menú intuitivo**: Acceso rápido desde la barra de menú con lista de apps disponibles
- 🔄 **Toggle rápido**: Activa/desactiva el pin con el mismo atajo
- 👁️ **Siempre visible**: Las ventanas pinneadas permanecen encima incluso al cambiar de app
- 🎨 **Íconos visuales**: Interfaz clara con íconos de apps e indicadores de estado
- ⚡️ **Ultra rápido**: Timer de 50ms para mantener ventanas al frente de forma agresiva
- 🔐 **Seguro**: Usa APIs de accesibilidad de macOS de forma nativa

## 📋 Requisitos

- macOS 14.0 o superior
- Permisos de accesibilidad habilitados

## 🚀 Instalación

### Opción 1: Instalación Rápida (Recomendada)

```bash
# 1. Clona el repositorio
git clone https://github.com/tu-usuario/altopin.git
cd altopin

# 2. Compila e instala
bash build.sh
cp -r build/AlwaysOnTop.app /Applications/

# 3. Abre la aplicación
open /Applications/AlwaysOnTop.app
```

### Opción 2: Solo Probar (Sin Instalar)

```bash
# 1. Clona y compila
git clone https://github.com/tu-usuario/altopin.git
cd altopin
bash build.sh

# 2. Ejecuta directamente
open build/AlwaysOnTop.app
```

**Nota**: La primera vez que ejecutes la app, macOS te pedirá permisos de accesibilidad.

## 🔐 Permisos de Accesibilidad

La primera vez que ejecutes AltoPin, macOS te pedirá permisos de accesibilidad:

1. Ve a **Preferencias del Sistema** > **Seguridad y Privacidad** > **Privacidad** > **Accesibilidad**
2. Haz clic en el candado para hacer cambios
3. Agrega **AlwaysOnTop** a la lista
4. Marca la casilla para habilitar los permisos

## 📖 Uso

### Atajo de Teclado

- **Control+Cmd+T**: Toggle pin en la ventana activa

### Menú Bar

1. Haz clic en el ícono de pin (📌) en la barra de menú
2. Verás dos secciones:
   - **VENTANAS PINNEADAS**: Apps actualmente pinneadas (con ✓)
   - **APPS DISPONIBLES**: Apps que puedes pinnear (con ○)
3. Haz clic en cualquier app para pinnearla/despinnearla

### Indicadores Visuales

- 📌 **Pin vacío**: Sin ventanas pinneadas
- 📌 **Pin relleno + número**: Número de ventanas pinneadas
- ✓ **Check verde**: App está pinneada
- ○ **Círculo**: App disponible para pinnear

## 🛠️ Cómo Funciona

AltoPin utiliza varias técnicas para mantener las ventanas siempre visibles:

1. **AXUIElement API**: Manipula ventanas usando las APIs de accesibilidad de macOS
2. **Timer agresivo**: Verifica cada 50ms el estado de las ventanas pinneadas
3. **NSWorkspace Observer**: Detecta cambios de aplicación activa
4. **AXRaise + activate()**: Fuerza las ventanas al frente cuando es necesario

## 📁 Estructura del Proyecto

```
altopin/
├── main.swift              # Código principal de la aplicación (412 líneas)
├── Info.plist              # Configuración de la app
├── build.sh                # Script de compilación
├── README.md               # Este archivo
├── LICENSE                 # Licencia MIT
├── CHANGELOG.md            # Historial de cambios
└── .gitignore             # Archivos ignorados por git
```

## 🔧 Desarrollo

### Compilar

```bash
bash build.sh
```

### Ejecutar en modo debug

```bash
./build/AlwaysOnTop.app/Contents/MacOS/AlwaysOnTop
```

### Arquitectura

- **AppDelegate**: Clase principal que maneja la aplicación
- **GlobalHotKey**: Maneja los atajos de teclado globales
- **Key enum**: Mapeo de códigos de teclas

## 🤝 Contribuciones

Las contribuciones son bienvenidas! Si tienes ideas para mejorar AltoPin:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📝 Roadmap

- [ ] Persistencia de ventanas pinneadas entre reinicios
- [ ] Launch at login
- [ ] Temas personalizables (Light/Dark)
- [ ] Múltiples atajos de teclado configurables
- [ ] Soporte para múltiples displays

## 🐛 Problemas Conocidos

- En macOS 14+, el API `activateIgnoringOtherApps` está deprecado pero aún funcional
- Algunas apps con ventanas especiales pueden no ser compatibles

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 🙏 Agradecimientos

- Inspirado en [AlwaysOnTop](https://github.com/itsabhishekolkha/AlwaysOnTop)
- Gracias a la comunidad de macOS por las APIs de accesibilidad

## 📧 Contacto

Si tienes preguntas o sugerencias, abre un issue en GitHub.

---

**¡Hecho con ❤️ para la comunidad de macOS!**
