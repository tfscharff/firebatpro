# Firebat Pro

Custom Firefox icon with multi-profile support and persistence.

## Architecture

### Modular Structure (v2.0)

```
firebatpro/
├── install.ps1              # Main entry point (install/watch/status)
├── uninstall.ps1            # Cleanup script
├── config.json              # Configuration file
├── firebatpro.ico           # Multi-size icon (16-256px)
├── firebatpro.png           # Source image
├── modules/
│   ├── Config.psm1          # Configuration loading
│   ├── Logging.psm1         # Log file management
│   ├── Shortcuts.psm1       # Shortcut manipulation
│   └── Watcher.psm1         # FileSystemWatcher management
└── tests/
    ├── Run-Tests.ps1        # Test runner
    ├── syntax-check.ps1     # Quick syntax validation
    ├── Config.Tests.ps1
    ├── Logging.Tests.ps1
    ├── Shortcuts.Tests.ps1
    └── Watcher.Tests.ps1
```

### Module Responsibilities

- **Config.psm1**: Loads `config.json`, expands environment variables, caches config
- **Logging.psm1**: Timestamped logging with rotation (1MB default)
- **Shortcuts.psm1**: WScript.Shell wrapper for .lnk manipulation
- **Watcher.psm1**: FileSystemWatcher for monitoring shortcut changes

### Key Features

- **Configuration file**: All settings in `config.json` (no code editing)
- **Status command**: `-Status` flag shows current state at a glance
- **Logging**: Operations logged to `%LOCALAPPDATA%\firebatpro\firebatpro.log`
- **Log rotation**: Automatic rotation at 1MB

## Commands

```powershell
# Install (applies icon, starts watcher)
.\install.ps1

# Install with specific profile
.\install.ps1 -ProfileName "work-profile"

# Install without persistence watcher
.\install.ps1 -NoWatcher

# Show status
.\install.ps1 -Status

# Uninstall
.\uninstall.ps1
```

## Configuration

Edit `config.json` to customize:

```json
{
  "firefox": {
    "exePath": "C:\\Program Files\\Mozilla Firefox\\firefox.exe",
    "directory": "C:\\Program Files\\Mozilla Firefox"
  },
  "profile": {
    "name": "default-release"
  },
  "shortcuts": [
    "%USERPROFILE%\\Desktop\\Firefox.lnk",
    ...
  ]
}
```

## Testing

```powershell
# Quick syntax check
.\tests\syntax-check.ps1

# Full test suite (requires Pester 5+)
.\tests\Run-Tests.ps1

# With coverage
.\tests\Run-Tests.ps1 -Coverage
```

## Technical Details

- Target: PowerShell 5.1+ (Windows 10/11 built-in)
- No external dependencies (uses Windows built-ins)
- VBS wrapper runs watcher hidden (generated at install, gitignored)
- Kills existing watcher before reinstall to avoid duplicates
- Shortcut locations defined in config, watch paths derived automatically

## Releasing

A release is a version bump and a tag. There is no package: the tool runs from this folder.
Release after a change to the scripts, modules or `config.json`. A change to docs or tests alone
needs no release.

1. Run the checks in "Testing"; do not release if any fails.
2. Pick the new version by Semantic Versioning 2.0.0: a fix is a patch, a new feature or option
   is a minor, and a change that breaks an existing `config.json` or command is a major.
3. Set `$Script:FirebatProVersion` in `install.ps1` to it. That line is the only place the version is written.
4. Commit that one file as `chore(release): vX.Y.Z`.
5. Tag the commit with an annotated tag: `git tag -a vX.Y.Z -m "Firebat Pro X.Y.Z"`.
6. Push the commit and the tag together: `git push --follow-tags`.
7. Check `.\install.ps1 -Version` prints the new version.

A running watcher keeps the code it loaded at start. After a release, the new code takes effect
when the user runs `.\install.ps1` again, which replaces the watcher; say so and leave that to
them.
