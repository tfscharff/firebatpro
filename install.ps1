# Firebat Pro
# Custom Firefox icon with multi-profile support and persistence

param(
    [string]$ProfileName = "default-release",
    [switch]$NoWatcher,
    [switch]$Watch  # Internal: runs watcher mode
)

$ErrorActionPreference = "Stop"

# Resolve paths relative to script location
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = $MyInvocation.MyCommand.Path
$iconPath = Join-Path $scriptDir "firebatpro.ico"

# Firefox default install location
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

$shell = New-Object -ComObject WScript.Shell

function Apply-FirebatSettings {
    param([string]$ShortcutPath)

    if (Test-Path $ShortcutPath) {
        $lnk = $shell.CreateShortcut($ShortcutPath)

        # Skip if already has our settings
        if ($lnk.IconLocation -like "*firebatpro*") {
            return $false
        }

        $lnk.TargetPath = $firefoxExe
        $lnk.Arguments = "-P `"$ProfileName`" --no-remote"
        $lnk.IconLocation = "$iconPath,0"
        $lnk.WorkingDirectory = "C:\Program Files\Mozilla Firefox"
        $lnk.Save()
        return $true
    }
    return $false
}

# ============================================================
# WATCHER MODE
# ============================================================
if ($Watch) {
    # Verify icon exists
    if (-not (Test-Path $iconPath)) {
        exit 1
    }

    # Shortcut directories to monitor
    $watchPaths = @(
        @{ Dir = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"; File = "Firefox.lnk" },
        @{ Dir = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"; File = "Firefox.lnk" },
        @{ Dir = "$env:PUBLIC\Desktop"; File = "Firefox.lnk" },
        @{ Dir = "$env:USERPROFILE\Desktop"; File = "Firefox.lnk" },
        @{ Dir = "$env:PUBLIC\Desktop"; File = "Mozilla Firefox.lnk" },
        @{ Dir = "$env:USERPROFILE\Desktop"; File = "Mozilla Firefox.lnk" }
    )

    # Create file system watchers
    $watchers = @()

    foreach ($watchPath in $watchPaths) {
        if (Test-Path $watchPath.Dir) {
            $watcher = New-Object System.IO.FileSystemWatcher
            $watcher.Path = $watchPath.Dir
            $watcher.Filter = $watchPath.File
            $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::FileName
            $watcher.EnableRaisingEvents = $true

            $eventData = @{
                IconPath = $iconPath
                ProfileName = $ProfileName
                FirefoxExe = $firefoxExe
            }

            Register-ObjectEvent -InputObject $watcher -EventName Changed -Action {
                Start-Sleep -Milliseconds 500
                $shortcutPath = $Event.SourceEventArgs.FullPath
                $shell = New-Object -ComObject WScript.Shell
                $data = $Event.MessageData

                if (Test-Path $shortcutPath) {
                    $lnk = $shell.CreateShortcut($shortcutPath)
                    if ($lnk.IconLocation -notlike "*firebatpro*") {
                        $lnk.TargetPath = $data.FirefoxExe
                        $lnk.Arguments = "-P `"$($data.ProfileName)`" --no-remote"
                        $lnk.IconLocation = "$($data.IconPath),0"
                        $lnk.WorkingDirectory = "C:\Program Files\Mozilla Firefox"
                        $lnk.Save()
                    }
                }
            } -MessageData $eventData | Out-Null

            Register-ObjectEvent -InputObject $watcher -EventName Created -Action {
                Start-Sleep -Milliseconds 500
                $shortcutPath = $Event.SourceEventArgs.FullPath
                $shell = New-Object -ComObject WScript.Shell
                $data = $Event.MessageData

                if (Test-Path $shortcutPath) {
                    $lnk = $shell.CreateShortcut($shortcutPath)
                    $lnk.TargetPath = $data.FirefoxExe
                    $lnk.Arguments = "-P `"$($data.ProfileName)`" --no-remote"
                    $lnk.IconLocation = "$($data.IconPath),0"
                    $lnk.WorkingDirectory = "C:\Program Files\Mozilla Firefox"
                    $lnk.Save()
                }
            } -MessageData $eventData | Out-Null

            $watchers += $watcher
        }
    }

    # Keep running
    try {
        while ($true) { Start-Sleep -Seconds 1 }
    } finally {
        foreach ($watcher in $watchers) {
            $watcher.EnableRaisingEvents = $false
            $watcher.Dispose()
        }
        Get-EventSubscriber | Unregister-Event
    }

    exit
}

# ============================================================
# INSTALL MODE (default)
# ============================================================

# Verify Firefox exists
if (-not (Test-Path $firefoxExe)) {
    Write-Error "Firefox not found at $firefoxExe"
    exit 1
}

# Verify icon exists
if (-not (Test-Path $iconPath)) {
    Write-Error "Icon not found at $iconPath"
    exit 1
}

Write-Host "Firebat Pro Installer" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Profile: $ProfileName"
Write-Host ""

# Step 1: Modify Firefox shortcuts
Write-Host "Step 1: Modifying Firefox shortcuts..." -ForegroundColor Yellow
$updated = 0

foreach ($path in $shortcutLocations) {
    if (Test-Path $path) {
        Write-Host "  Updating: $path"
        Apply-FirebatSettings $path | Out-Null
        $updated++
    }
}

if ($updated -eq 0) {
    Write-Host "  No Firefox shortcuts found." -ForegroundColor Yellow
} else {
    Write-Host "  Updated $updated shortcut(s)." -ForegroundColor Green
}

# Step 2: Install watcher for persistence
if (-not $NoWatcher) {
    Write-Host ""
    Write-Host "Step 2: Installing watcher for persistence..." -ForegroundColor Yellow

    # Create VBS wrapper to run PowerShell hidden
    $vbsPath = Join-Path $scriptDir "watcher-hidden.vbs"
    $vbsContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$scriptPath"" -Watch -ProfileName ""$ProfileName""", 0, False
"@
    $vbsContent | Out-File -FilePath $vbsPath -Encoding ASCII

    # Create startup shortcut
    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $startupShortcut = Join-Path $startupFolder "Firebat Watcher.lnk"

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
