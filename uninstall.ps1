# Firebat Pro Uninstaller
# Restores Firefox shortcuts, stops watcher, removes generated files

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import modules
Import-Module (Join-Path $scriptDir "modules\Config.psm1") -Force
Import-Module (Join-Path $scriptDir "modules\Logging.psm1") -Force
Import-Module (Join-Path $scriptDir "modules\Shortcuts.psm1") -Force

# Initialize
Initialize-Config -ScriptDirectory $scriptDir
$config = Get-Config
Initialize-Logging -MaxSizeMB $config.LogMaxSizeMB

Write-Host "Firebat Pro Uninstaller" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Stop watcher
Write-Host "Stopping watcher..." -ForegroundColor Yellow
Get-Process powershell -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like "*-Watch*" } |
    Stop-Process -Force -ErrorAction SilentlyContinue
Write-Host "  Done." -ForegroundColor Green
Write-Log "Watcher stopped"

# Step 2: Remove startup shortcut
Write-Host "Removing startup shortcut..." -ForegroundColor Yellow
$startupShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Firebat Watcher.lnk"
if (Test-Path $startupShortcut) {
    Remove-Item $startupShortcut -Force
    Write-Host "  Removed." -ForegroundColor Green
} else {
    Write-Host "  Not found (already removed)." -ForegroundColor Gray
}

# Step 3: Remove generated VBS
Write-Host "Removing generated files..." -ForegroundColor Yellow
$vbsPath = Join-Path $scriptDir "watcher-hidden.vbs"
if (Test-Path $vbsPath) {
    Remove-Item $vbsPath -Force
    Write-Host "  Removed watcher-hidden.vbs" -ForegroundColor Green
} else {
    Write-Host "  No generated files found." -ForegroundColor Gray
}

# Step 4: Restore Firefox shortcuts
Write-Host "Restoring Firefox shortcuts..." -ForegroundColor Yellow
Initialize-Shortcuts
$restored = Reset-AllShortcuts -ShortcutLocations $config.ShortcutLocations `
    -FirefoxExe $config.FirefoxExe -FirefoxDir $config.FirefoxDir

if ($restored -eq 0) {
    Write-Host "  No Firefox shortcuts found." -ForegroundColor Gray
} else {
    Write-Host "  Restored $restored shortcut(s)." -ForegroundColor Green
    Write-Log "Restored $restored shortcut(s)"
}

Write-Host ""
Write-Host "Uninstall complete!" -ForegroundColor Green
Write-Log "Uninstall complete"
