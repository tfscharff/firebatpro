# Firebat Pro - Install/Watch script
# Custom Firefox icon with multi-profile support and persistence

param(
    [string]$ProfileName,
    [switch]$NoWatcher,
    [switch]$Watch,
    [switch]$Status
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = $MyInvocation.MyCommand.Path

# Import modules
Import-Module (Join-Path $scriptDir "modules\Config.psm1") -Force
Import-Module (Join-Path $scriptDir "modules\Logging.psm1") -Force
Import-Module (Join-Path $scriptDir "modules\Shortcuts.psm1") -Force
Import-Module (Join-Path $scriptDir "modules\Watcher.psm1") -Force

# Initialize config
Initialize-Config -ScriptDirectory $scriptDir
$config = Get-Config

# Override profile name if provided via parameter
if ($ProfileName) {
    $config.ProfileName = $ProfileName
}

# Initialize logging
Initialize-Logging -MaxSizeMB $config.LogMaxSizeMB

# ============================================================
# STATUS MODE
# ============================================================
if ($Status) {
    Write-Host "Firebat Pro Status" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    Write-Host ""

    # Check Firefox
    if (Test-Path $config.FirefoxExe) {
        Write-Host "Firefox: " -NoNewline
        Write-Host "Found" -ForegroundColor Green
    } else {
        Write-Host "Firefox: " -NoNewline
        Write-Host "Not found at $($config.FirefoxExe)" -ForegroundColor Red
    }

    # Check icon
    if (Test-Path $config.IconPath) {
        Write-Host "Icon: " -NoNewline
        Write-Host "Found" -ForegroundColor Green
    } else {
        Write-Host "Icon: " -NoNewline
        Write-Host "Not found" -ForegroundColor Red
    }

    # Check shortcuts
    Write-Host ""
    Write-Host "Shortcuts:" -ForegroundColor Yellow
    Initialize-Shortcuts
    foreach ($path in $config.ShortcutLocations) {
        if (Test-Path $path) {
            $isFirebat = Test-IsFirebatShortcut $path
            $status = if ($isFirebat) { "Firebat" } else { "Default" }
            $color = if ($isFirebat) { "Green" } else { "Gray" }
            Write-Host "  $path : " -NoNewline
            Write-Host $status -ForegroundColor $color
        }
    }

    # Check watcher
    Write-Host ""
    $watcherRunning = Get-Process powershell -ErrorAction SilentlyContinue |
        Where-Object { $_.Id -ne $PID -and $_.CommandLine -like "*-Watch*" }
    Write-Host "Watcher: " -NoNewline
    if ($watcherRunning) {
        Write-Host "Running" -ForegroundColor Green
    } else {
        Write-Host "Not running" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Profile: $($config.ProfileName)"
    Write-Host "Log: $(Get-LogPath)"

    exit 0
}

# ============================================================
# WATCHER MODE
# ============================================================
if ($Watch) {
    if (-not (Test-Path $config.IconPath)) {
        Write-Log "Icon not found, exiting watcher" -Level ERROR
        exit 1
    }

    Write-Log "Watcher starting for profile: $($config.ProfileName)"

    Initialize-Watcher -IconPath $config.IconPath -ProfileName $config.ProfileName `
        -FirefoxExe $config.FirefoxExe -FirefoxDir $config.FirefoxDir `
        -DebounceMs $config.DebounceMs

    $count = Start-ShortcutWatchers -ShortcutLocations $config.ShortcutLocations
    Write-Log "Watching $count shortcut location(s)"

    Wait-Forever
    exit 0
}

# ============================================================
# INSTALL MODE (default)
# ============================================================

if (-not (Test-Path $config.FirefoxExe)) {
    Write-Error "Firefox not found at $($config.FirefoxExe)"
    exit 1
}

if (-not (Test-Path $config.IconPath)) {
    Write-Error "Icon not found at $($config.IconPath)"
    exit 1
}

Write-Host "Firebat Pro Installer" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Profile: $($config.ProfileName)"
Write-Host ""

# Step 1: Modify Firefox shortcuts
Write-Host "Step 1: Modifying Firefox shortcuts..." -ForegroundColor Yellow
Initialize-Shortcuts

$updated = 0
foreach ($path in $config.ShortcutLocations) {
    if (Test-Path $path) {
        Write-Host "  Updating: $path"
        if (Set-FirebatShortcut -ShortcutPath $path -FirefoxExe $config.FirefoxExe `
            -FirefoxDir $config.FirefoxDir -ProfileName $config.ProfileName `
            -IconPath $config.IconPath) {
            $updated++
        }
    }
}

if ($updated -eq 0) {
    Write-Host "  No Firefox shortcuts found (or already configured)." -ForegroundColor Yellow
} else {
    Write-Host "  Updated $updated shortcut(s)." -ForegroundColor Green
    Write-Log "Updated $updated shortcut(s)"
}

# Step 2: Install watcher for persistence
if (-not $NoWatcher) {
    Write-Host ""
    Write-Host "Step 2: Installing watcher for persistence..." -ForegroundColor Yellow

    # Kill existing watcher first
    Get-Process powershell -ErrorAction SilentlyContinue |
        Where-Object { $_.Id -ne $PID -and $_.CommandLine -like "*-Watch*" } |
        Stop-Process -Force -ErrorAction SilentlyContinue

    # Create VBS wrapper to run PowerShell hidden
    $vbsPath = Join-Path $scriptDir "watcher-hidden.vbs"
    @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$scriptPath"" -Watch -ProfileName ""$($config.ProfileName)""", 0, False
"@ | Out-File -FilePath $vbsPath -Encoding ASCII

    # Create startup shortcut
    $startupShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Firebat Watcher.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $lnk = $shell.CreateShortcut($startupShortcut)
    $lnk.TargetPath = "wscript.exe"
    $lnk.Arguments = "`"$vbsPath`""
    $lnk.WorkingDirectory = $scriptDir
    $lnk.Description = "Firebat Pro - Firefox shortcut watcher"
    $lnk.Save()

    Write-Host "  Created startup shortcut." -ForegroundColor Green

    # Start watcher now
    Write-Host "  Starting watcher..."
    Start-Process "wscript.exe" -ArgumentList "`"$vbsPath`"" -WindowStyle Hidden
    Write-Host "  Watcher running." -ForegroundColor Green
    Write-Log "Watcher installed and started"
}

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Search 'Firefox' in Start Menu - should show bat icon"
Write-Host "  2. Pin to taskbar"
if (-not $NoWatcher) {
    Write-Host ""
    Write-Host "Watcher will keep your settings through Firefox updates."
}
