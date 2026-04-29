# Install Firebat Watcher as a startup task
# Runs the watcher automatically when you log in

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$watcherPath = Join-Path $scriptDir "watcher.ps1"
$taskName = "FirebatProWatcher"

# Create a VBS wrapper to run PowerShell hidden (no window)
$vbsPath = Join-Path $scriptDir "watcher-hidden.vbs"
$vbsContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$watcherPath""", 0, False
"@
$vbsContent | Out-File -FilePath $vbsPath -Encoding ASCII

# Create startup shortcut
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = Join-Path $startupFolder "Firebat Watcher.lnk"

$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut($shortcutPath)
$lnk.TargetPath = "wscript.exe"
$lnk.Arguments = "`"$vbsPath`""
$lnk.WorkingDirectory = $scriptDir
$lnk.Description = "Firebat Pro - Firefox shortcut watcher"
$lnk.Save()

Write-Host "Firebat Watcher Installer" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Created startup shortcut: $shortcutPath" -ForegroundColor Green
Write-Host ""
Write-Host "The watcher will start automatically at login."
Write-Host "To start it now, run: .\watcher.ps1"
Write-Host ""
Write-Host "To uninstall, delete:" -ForegroundColor Yellow
Write-Host "  - $shortcutPath"
Write-Host "  - $vbsPath"
