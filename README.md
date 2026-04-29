# Firebat Pro

Custom bat icon for Firefox. Allows multiple profiles to run simultaneously. Persists through Firefox updates.

## Install

```powershell
.\install.ps1
```

This modifies your Firefox shortcuts, sets up a background watcher to persist settings through updates, and starts the watcher.

**Options:**
```powershell
.\install.ps1 -ProfileName "your-profile"  # Use a different profile
.\install.ps1 -NoWatcher                   # Skip persistence (one-time setup)
```

After installing, search "Firefox" in Start Menu and pin to taskbar.

## Uninstall

```powershell
.\uninstall.ps1
```

Stops watcher, removes startup shortcut, restores Firefox shortcuts to defaults.

## Requirements

- Windows 10/11
- Firefox at `C:\Program Files\Mozilla Firefox\`
