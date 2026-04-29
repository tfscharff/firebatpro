# Firebat Pro

Custom Firefox icon with multi-profile support and persistence.

## Files

- `install.ps1` - Setup + watcher mode (use `-Watch` flag internally)
- `uninstall.ps1` - Full cleanup (stops watcher, removes files, restores shortcuts)
- `firebatpro.ico` - Multi-size icon (16-256px)
- `firebatpro.png` - Source image with transparency

## Technical Details

- Shortcut locations defined once, watcher paths derived from them
- FileSystemWatcher monitors for shortcut changes
- VBS wrapper runs watcher hidden (generated at install, gitignored)
- Kills existing watcher before reinstall to avoid duplicates
