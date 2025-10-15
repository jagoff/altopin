# Changelog

All notable changes to AltoPin will be documented in this file.

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
