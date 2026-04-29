# Firebat Pro

PowerShell scripts to customize Firefox shortcuts with a bat icon and multi-profile support.

## Files

- `install.ps1` - All-in-one setup (modifies shortcuts + installs watcher)
- `uninstall.ps1` - Restores Firefox shortcuts to defaults
- `watcher.ps1` - FileSystemWatcher that monitors shortcuts and re-applies settings
- `firebatpro.ico` - Multi-size ICO (256, 128, 64, 48, 32, 16px)
- `firebatpro.png` - Source PNG with transparency
- `.gitignore` - Excludes generated `watcher-hidden.vbs`

## Technical Notes

- All paths resolved relative to script location (no hardcoded user paths)
- Firefox expected at `C:\Program Files\Mozilla Firefox\firefox.exe`
- Watcher runs hidden via VBS wrapper (generated at install time)
- Uses WScript.Shell COM object to modify .lnk files
- `--no-remote` flag enables multiple simultaneous Firefox profiles
