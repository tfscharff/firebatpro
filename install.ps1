# Firebat Pro Installer
# Modifies the regular Firefox shortcut to use custom icon and profile arguments

param(
    [string]$ProfileName = "default-release",
    [string]$IconPath = ""
)

$ErrorActionPreference = "Stop"

# Get script directory and resolve icon path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $IconPath) {
    $IconPath = Join-Path $scriptDir "firebatpro.ico"
}
$IconPath = (Resolve-Path $IconPath).Path

# Firefox paths
$firefoxExe = "C:\Program Files\Mozilla Firefox\firefox.exe"

# Common Firefox shortcut locations
$shortcutLocations = @(
    "$env:USERPROFILE\Desktop\Firefox.lnk",
    "$env:PUBLIC\Desktop\Firefox.lnk",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Firefox.lnk",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Firefox.lnk",
    "$env:USERPROFILE\Desktop\Mozilla Firefox.lnk",
    "$env:PUBLIC\Desktop\Mozilla Firefox.lnk"
)

# Verify Firefox exists
if (-not (Test-Path $firefoxExe)) {
    Write-Error "Firefox not found at $firefoxExe"
    exit 1
}

# Verify icon exists
if (-not (Test-Path $IconPath)) {
    Write-Error "Icon not found at $IconPath"
    exit 1
}

$shell = New-Object -ComObject WScript.Shell

Write-Host "Firebat Pro Installer" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Profile: $ProfileName"
Write-Host "Icon: $IconPath"
Write-Host ""

$updated = 0

foreach ($path in $shortcutLocations) {
    if (Test-Path $path) {
        Write-Host "Updating: $path"
        $lnk = $shell.CreateShortcut($path)
        $lnk.TargetPath = $firefoxExe
        $lnk.Arguments = "-P `"$ProfileName`" --no-remote"
        $lnk.IconLocation = "$IconPath,0"
        $lnk.WorkingDirectory = "C:\Program Files\Mozilla Firefox"
        $lnk.Save()
        Write-Host "  Done!" -ForegroundColor Green
        $updated++
    }
}

Write-Host ""
if ($updated -gt 0) {
    Write-Host "Updated $updated Firefox shortcut(s)!" -ForegroundColor Green
    Write-Host "Pin the shortcut to your taskbar for the full Firebat experience."
} else {
    Write-Host "No Firefox shortcuts found to update." -ForegroundColor Yellow
    Write-Host "Expected locations:"
    foreach ($path in $shortcutLocations) {
        Write-Host "  - $path"
    }
}
