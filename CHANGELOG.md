# Changelog

All notable changes to AltoPin will be documented in this file.

## [1.1.0] - 2025-10-15

### Added
- **Timer adaptativo**: Cambia automáticamente entre 50ms (activo) y 200ms (estable) para optimizar CPU y batería
- **Animaciones suaves**: Transiciones fade in/out en el ícono del menu bar
- **Cache de AXUIElement**: Mejor performance al reutilizar elementos de accesibilidad
- **Detección de actividad**: Monitorea cambios de app para ajustar el timer dinámicamente
- **Homebrew Cask**: Fórmula para instalación via `brew install --cask altopin`

### Improved
- Reducción del 75% en uso de CPU cuando las ventanas están estables
- Mejor respuesta al cambiar entre apps
- Animaciones más profesionales en la UI

### Technical
- Nuevo sistema de timestamps para tracking de actividad
- Timer de dos velocidades (fast/slow) según contexto
- Optimización de llamadas a Accessibility API

## [1.0.0] - 2025-10-15

### Added
- Initial release of AltoPin
- Pin any window to stay always on top with Control+Cmd+T
- Menu bar integration with app list
- Visual indicators for pinned/available apps
- Aggressive 50ms timer to maintain windows on top
- NSWorkspace observer for app activation changes
- Clean and intuitive UI
- Support for multiple pinned windows simultaneously

### Features
- **Keyboard Shortcut**: Control+Cmd+T to toggle pin on active window
- **Menu Bar**: Click to see all running apps and pin/unpin directly
- **Visual Feedback**: Pin icon shows number of pinned windows
- **Smart Filtering**: Pinned apps don't appear in available apps list
- **Native macOS**: Built with Swift using Accessibility APIs

### Technical
- 412 lines of clean, optimized Swift code
- No external dependencies
- Uses AXUIElement for window manipulation
- Timer-based monitoring for persistent window positioning
