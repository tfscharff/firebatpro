# Firebat Pro

Single PowerShell script to customize Firefox with a bat icon and multi-profile support.

## Files

- `install.ps1` - All-in-one: setup + background watcher (use `-Watch` flag for watcher mode)
- `uninstall.ps1` - Restores Firefox shortcuts to defaults
- `firebatpro.ico` - Multi-size ICO (256, 128, 64, 48, 32, 16px)
- `firebatpro.png` - Source PNG with transparency

## Technical Notes

- Single script handles both install and watcher modes via `-Watch` flag
- Watcher runs hidden via VBS wrapper (generated at install time, gitignored)
- Uses FileSystemWatcher to detect shortcut changes
- All paths resolved relative to script location
