# Firebat Pro

Replace the Firefox icon with a custom bat icon and enable multi-profile support.

## What It Does

Modifies your existing Firefox shortcut to:
- Use a custom bat-themed icon
- Launch a specific profile (`default-release` by default)
- Allow multiple Firefox profiles to run simultaneously

## Installation

1. Download or clone this repo
2. Open PowerShell in the project folder
3. Run:

```powershell
.\install.ps1
```

4. Search "Firefox" in Start Menu - it should show the bat icon
5. Pin to taskbar

### Custom Profile

To use a different profile:

```powershell
.\install.ps1 -ProfileName "your-profile-name"
```

## Uninstall

Restore Firefox shortcuts to defaults:

```powershell
.\uninstall.ps1
```

## Files

| File | Purpose |
|------|---------|
| `install.ps1` | Modifies Firefox shortcuts |
| `uninstall.ps1` | Restores default Firefox shortcuts |
| `firebatpro.ico` | Custom bat icon |
| `firebatpro.png` | Source image |

## Requirements

- Windows 10/11
- Firefox installed at `C:\Program Files\Mozilla Firefox\`
- Firefox shortcut in Start Menu or Desktop

## How It Works

The installer finds existing Firefox shortcuts and modifies their properties:

- **Arguments:** `-P "profile-name" --no-remote`
- **Icon:** `firebatpro.ico`

The `--no-remote` flag allows multiple Firefox profiles to run simultaneously.
