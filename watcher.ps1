# Firebat Pro Watcher
# Monitors Firefox shortcuts and re-applies custom settings when they change

param(
    [string]$ProfileName = "default-release",
    [string]$IconPath = ""
)

# Get script directory and resolve icon path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $IconPath) {
    $IconPath = Join-Path $scriptDir "firebatpro.ico"
}

$firefoxExe = "C:\Program Files\Mozilla Firefox\firefox.exe"

# Shortcut locations to monitor
$watchPaths = @(
    @{ Dir = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"; File = "Firefox.lnk" },
    @{ Dir = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"; File = "Firefox.lnk" },
    @{ Dir = "$env:PUBLIC\Desktop"; File = "Firefox.lnk" },
    @{ Dir = "$env:USERPROFILE\Desktop"; File = "Firefox.lnk" },
    @{ Dir = "$env:PUBLIC\Desktop"; File = "Mozilla Firefox.lnk" },
    @{ Dir = "$env:USERPROFILE\Desktop"; File = "Mozilla Firefox.lnk" }
)

$shell = New-Object -ComObject WScript.Shell

function Apply-FirebatSettings {
    param([string]$ShortcutPath)

    if (Test-Path $ShortcutPath) {
        $lnk = $shell.CreateShortcut($ShortcutPath)

        # Check if already has our settings
        if ($lnk.IconLocation -like "*firebatpro*") {
            return $false
        }

        Write-Host "$(Get-Date -Format 'HH:mm:ss') Applying Firebat settings to: $ShortcutPath"
        $lnk.TargetPath = $firefoxExe
        $lnk.Arguments = "-P `"$ProfileName`" --no-remote"
        $lnk.IconLocation = "$IconPath,0"
        $lnk.WorkingDirectory = "C:\Program Files\Mozilla Firefox"
        $lnk.Save()
        return $true
    }
    return $false
}

Write-Host "Firebat Pro Watcher" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "Profile: $ProfileName"
Write-Host "Icon: $IconPath"
Write-Host ""
Write-Host "Monitoring Firefox shortcuts for changes..."
Write-Host "Press Ctrl+C to stop."
Write-Host ""

# Create file system watchers
$watchers = @()

foreach ($watchPath in $watchPaths) {
    if (Test-Path $watchPath.Dir) {
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $watchPath.Dir
        $watcher.Filter = $watchPath.File
        $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::FileName
        $watcher.EnableRaisingEvents = $true

        $fullPath = Join-Path $watchPath.Dir $watchPath.File

        # Register event handler
        $action = {
            Start-Sleep -Milliseconds 500  # Wait for file to be fully written
            $path = $Event.SourceEventArgs.FullPath
            & $global:ApplySettings $path
        }

        Register-ObjectEvent -InputObject $watcher -EventName Changed -Action {
            Start-Sleep -Milliseconds 500
            $shortcutPath = $Event.SourceEventArgs.FullPath
            $shell = New-Object -ComObject WScript.Shell
            $firefoxExe = "C:\Program Files\Mozilla Firefox\firefox.exe"
            $iconPath = $Event.MessageData.IconPath
            $profileName = $Event.MessageData.ProfileName

            if (Test-Path $shortcutPath) {
                $lnk = $shell.CreateShortcut($shortcutPath)
                if ($lnk.IconLocation -notlike "*firebatpro*") {
                    Write-Host "$(Get-Date -Format 'HH:mm:ss') Firefox shortcut changed, re-applying Firebat settings..."
                    $lnk.TargetPath = $firefoxExe
                    $lnk.Arguments = "-P `"$profileName`" --no-remote"
                    $lnk.IconLocation = "$iconPath,0"
                    $lnk.WorkingDirectory = "C:\Program Files\Mozilla Firefox"
                    $lnk.Save()
                    Write-Host "$(Get-Date -Format 'HH:mm:ss') Done!"
                }
            }
        } -MessageData @{ IconPath = $IconPath; ProfileName = $ProfileName } | Out-Null

        Register-ObjectEvent -InputObject $watcher -EventName Created -Action {
            Start-Sleep -Milliseconds 500
            $shortcutPath = $Event.SourceEventArgs.FullPath
            $shell = New-Object -ComObject WScript.Shell
            $firefoxExe = "C:\Program Files\Mozilla Firefox\firefox.exe"
            $iconPath = $Event.MessageData.IconPath
            $profileName = $Event.MessageData.ProfileName

            if (Test-Path $shortcutPath) {
                Write-Host "$(Get-Date -Format 'HH:mm:ss') Firefox shortcut created, applying Firebat settings..."
                $lnk = $shell.CreateShortcut($shortcutPath)
                $lnk.TargetPath = $firefoxExe
                $lnk.Arguments = "-P `"$profileName`" --no-remote"
                $lnk.IconLocation = "$iconPath,0"
                $lnk.WorkingDirectory = "C:\Program Files\Mozilla Firefox"
                $lnk.Save()
                Write-Host "$(Get-Date -Format 'HH:mm:ss') Done!"
            }
        } -MessageData @{ IconPath = $IconPath; ProfileName = $ProfileName } | Out-Null

        $watchers += $watcher
        Write-Host "Watching: $fullPath"
    }
}

if ($watchers.Count -eq 0) {
    Write-Host "No Firefox shortcut directories found to watch." -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Keep script running
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    # Cleanup watchers
    foreach ($watcher in $watchers) {
        $watcher.EnableRaisingEvents = $false
        $watcher.Dispose()
    }
    Get-EventSubscriber | Unregister-Event
}
