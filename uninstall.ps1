# Firebat Pro Uninstaller
# Restores Firefox shortcuts to default settings

$ErrorActionPreference = "Stop"

$firefoxExe = "C:\Program Files\Mozilla Firefox\firefox.exe"
$desktopShortcut = "$env:USERPROFILE\Desktop\Firefox.lnk"
$startMenuShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Firefox.lnk"
$publicDesktop = "$env:PUBLIC\Desktop\Firefox.lnk"

$shell = New-Object -ComObject WScript.Shell

function Restore-Shortcut {
    param([string]$Path)

    if (Test-Path $Path) {
        Write-Host "Restoring: $Path"
        $lnk = $shell.CreateShortcut($Path)
        $lnk.TargetPath = $firefoxExe
        $lnk.Arguments = ""
        $lnk.IconLocation = "$firefoxExe,0"
        $lnk.WorkingDirectory = "C:\Program Files\Mozilla Firefox"
        $lnk.Save()
        Write-Host "  Done!" -ForegroundColor Green
        return $true
    }
    return $false
}

Write-Host "Firebat Pro Uninstaller" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host ""

Restore-Shortcut $desktopShortcut
Restore-Shortcut $startMenuShortcut
Restore-Shortcut $publicDesktop

Write-Host ""
Write-Host "Firefox shortcuts restored to defaults." -ForegroundColor Green
