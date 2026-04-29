# Firebat Pro

Replace the Firefox icon with a custom bat icon and enable multi-profile support.

## What It Does

- Custom bat-themed Firefox icon
- Launches a specific profile (`default-release` by default)
- Allows multiple Firefox profiles to run simultaneously
- Persists through Firefox updates (via background watcher)

## Installation

```powershell
.\install.ps1
```

That's it. The script:
1. Modifies your Firefox shortcuts (icon + profile args)
2. Installs a background watcher that re-applies settings if Firefox updates reset them
3. Starts the watcher immediately

### Options

```powershell
# Use a different profile
.\install.ps1 -ProfileName "your-profile-name"

# Skip watcher (no persistence through updates)
.\install.ps1 -NoWatcher
```

## Uninstall

```powershell
.\uninstall.ps1
```

## Files

| File | Purpose |
|------|---------|
| `install.ps1` | Setup + watcher (all-in-one) |
| `uninstall.ps1` | Restores default Firefox shortcuts |
| `firebatpro.ico` | Custom bat icon |
| `firebatpro.png` | Source image |

## Requirements

- Windows 10/11
- Firefox installed at `C:\Program Files\Mozilla Firefox\`
- PowerShell
