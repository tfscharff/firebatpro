# Firebat Pro Uninstaller
# Restores Firefox shortcuts, stops watcher, removes generated files

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$firefoxExe = "C:\Program Files\Mozilla Firefox\firefox.exe"

# Same locations as install.ps1
$shortcutLocations = @(
    "$env:USERPROFILE\Desktop\Firefox.lnk",
    "$env:PUBLIC\Desktop\Firefox.lnk",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Firefox.lnk",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Firefox.lnk",
    "$env:USERPROFILE\Desktop\Mozilla Firefox.lnk",
    "$env:PUBLIC\Desktop\Mozilla Firefox.lnk"
)

$shell = New-Object -ComObject WScript.Shell

Write-Host "Firebat Pro Uninstaller" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Stop watcher
Write-Host "Stopping watcher..." -ForegroundColor Yellow
Get-Process powershell -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like "*-Watch*" } |
    Stop-Process -Force -ErrorAction SilentlyContinue
Write-Host "  Done." -ForegroundColor Green

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
$restored = 0

foreach ($path in $shortcutLocations) {
    if (Test-Path $path) {
        Write-Host "  Restoring: $path"
        $lnk = $shell.CreateShortcut($path)
        $lnk.TargetPath = $firefoxExe
        $lnk.Arguments = ""
        $lnk.IconLocation = "$firefoxExe,0"
        $lnk.WorkingDirectory = "C:\Program Files\Mozilla Firefox"
        $lnk.Save()
        $restored++
    }
}

if ($restored -eq 0) {
    Write-Host "  No Firefox shortcuts found." -ForegroundColor Gray
} else {
    Write-Host "  Restored $restored shortcut(s)." -ForegroundColor Green
}

Write-Host ""
Write-Host "Uninstall complete!" -ForegroundColor Green
