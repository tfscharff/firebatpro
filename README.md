# Firebat Pro

Custom icon for Firefox with profile targeting. External links open in your running profile. Persists through Firefox updates.

## Requirements

- Windows 10/11
- Firefox at `C:\Program Files\Mozilla Firefox\`

## Install

```powershell
.\install.ps1
```

This modifies your Firefox shortcuts, sets up a background watcher to persist settings through updates, and starts the watcher.

**Options:**
```powershell
.\install.ps1 -ProfileName "your-profile"  # Use a different profile
.\install.ps1 -NoWatcher                   # Skip persistence (one-time setup)
.\install.ps1 -Status                      # Show current status
```

After installing, search "Firefox" in Start Menu and pin to taskbar.

## Uninstall

```powershell
.\uninstall.ps1
```

Stops watcher, removes startup shortcut, restores Firefox shortcuts to defaults.

## Configuration

Edit `config.json` to customize settings:

```json
{
  "firefox": {
    "exePath": "C:\\Program Files\\Mozilla Firefox\\firefox.exe",
    "directory": "C:\\Program Files\\Mozilla Firefox"
  },
  "profile": {
    "name": "default-release"
  }
}
```

## Features

- **Zero dependencies** - Uses only Windows built-ins
- **Profile targeting** - Opens Firefox with your specified profile
- **External link handling** - Links from other apps open in your running profile
- **Auto-persistence** - Survives Firefox updates via FileSystemWatcher
- **Status command** - Check current state with `-Status`
- **Log rotation** - Automatic log file rotation at 1MB
- **Modular design** - Separate modules for easy maintenance

## Architecture

```
firebatpro/
├── install.ps1        # Main script
├── uninstall.ps1      # Cleanup script
├── config.json        # Configuration
├── modules/           # PowerShell modules
│   ├── Config.psm1
│   ├── Logging.psm1
│   ├── Shortcuts.psm1
│   └── Watcher.psm1
└── tests/             # Pester tests
```

## Logs

`%LOCALAPPDATA%\firebatpro\firebatpro.log`

## Testing

```powershell
# Syntax check
.\tests\syntax-check.ps1

# Full tests (requires Pester 5+)
.\tests\Run-Tests.ps1
```

## License

MIT
