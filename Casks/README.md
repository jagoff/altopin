# AltoPin Homebrew Cask

This directory contains the Homebrew Cask formula for AltoPin.

## Installation

### Option 1: From Homebrew (Coming Soon)
```bash
brew install --cask altopin
```

### Option 2: From This Repository
```bash
brew install --cask Casks/altopin.rb
```

## What Gets Installed

- **App Location**: `/Applications/AlwaysOnTop.app`
- **Version**: 1.2.0
- **Requirements**: macOS Monterey (12.0) or later

## Post-Installation

After installation, you need to grant Accessibility permissions:

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Click the **+** button
3. Navigate to `/Applications/AlwaysOnTop.app`
4. Enable the checkbox
5. Launch AltoPin

## Usage

- **Keyboard Shortcut**: `Control+Cmd+T` to pin/unpin active window
- **Menu Bar**: Click the pin icon to see all apps and pin/unpin from menu

## Features

- ⚡️ Ultra-aggressive 10ms timer (100 checks/second)
- 📌 Pin windows from menu bar or keyboard
- 🎨 Animated menu bar icon
- 🔢 Shows count of pinned windows
- 🪟 Support for multiple pinned windows

## Uninstallation

```bash
brew uninstall --cask altopin
```

To remove all data:
```bash
brew uninstall --zap altopin
```

This will remove:
- The app
- Preferences: `~/Library/Preferences/com.altopin.AlwaysOnTop.plist`
- Caches: `~/Library/Caches/com.altopin.AlwaysOnTop`
- App Support: `~/Library/Application Support/AlwaysOnTop`

## Development

To update the Cask after a new release:

1. Update version in `altopin.rb`
2. Run `../package.sh` to generate new SHA256
3. Update SHA256 in `altopin.rb`
4. Test installation:
   ```bash
   brew install --cask --force Casks/altopin.rb
   ```

## Links

- **Homepage**: https://github.com/jagoff/altopin
- **Releases**: https://github.com/jagoff/altopin/releases
- **Issues**: https://github.com/jagoff/altopin/issues
