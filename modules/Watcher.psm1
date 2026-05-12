# Watcher.psm1 - FileSystemWatcher management for shortcut persistence

$script:Watchers = @()
$script:WatcherConfig = $null

function Initialize-Watcher {
    param(
        [string]$IconPath,
        [string]$ProfileName,
        [string]$FirefoxExe,
        [string]$FirefoxDir,
        [int]$DebounceMs = 500
    )

    $script:WatcherConfig = @{
        IconPath = $IconPath
        ProfileName = $ProfileName
        FirefoxExe = $FirefoxExe
        FirefoxDir = $FirefoxDir
        DebounceMs = $DebounceMs
    }
}

function Start-ShortcutWatchers {
    param([string[]]$ShortcutLocations)

    if (-not $script:WatcherConfig) {
        throw "Watcher not initialized. Call Initialize-Watcher first."
    }

    # Derive unique watch paths
    $watchPaths = $ShortcutLocations | ForEach-Object {
        @{ Dir = Split-Path -Parent $_; File = Split-Path -Leaf $_ }
    } | Sort-Object -Property Dir, File -Unique

    foreach ($watchPath in $watchPaths) {
        if (-not (Test-Path $watchPath.Dir)) {
            continue
        }

        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $watchPath.Dir
        $watcher.Filter = $watchPath.File
        $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::FileName
        $watcher.EnableRaisingEvents = $true

        $eventData = $script:WatcherConfig.Clone()

        $handler = {
            Start-Sleep -Milliseconds $Event.MessageData.DebounceMs
            $shortcutPath = $Event.SourceEventArgs.FullPath
            $data = $Event.MessageData

            if (Test-Path $shortcutPath) {
                $shell = New-Object -ComObject WScript.Shell
                $lnk = $shell.CreateShortcut($shortcutPath)
                if ($lnk.IconLocation -notlike "*firebatpro*") {
                    $lnk.TargetPath = $data.FirefoxExe
                    $lnk.Arguments = "-P `"$($data.ProfileName)`" --no-remote"
                    $lnk.IconLocation = "$($data.IconPath),0"
                    $lnk.WorkingDirectory = $data.FirefoxDir
                    $lnk.Save()
                }
            }
        }

        Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $handler -MessageData $eventData | Out-Null
        Register-ObjectEvent -InputObject $watcher -EventName Created -Action $handler -MessageData $eventData | Out-Null

        $script:Watchers += $watcher
    }

    return $script:Watchers.Count
}

function Stop-ShortcutWatchers {
    foreach ($watcher in $script:Watchers) {
        $watcher.EnableRaisingEvents = $false
        $watcher.Dispose()
    }
    Get-EventSubscriber | Unregister-Event -ErrorAction SilentlyContinue
    $script:Watchers = @()
}

function Wait-Forever {
    try {
        while ($true) { Start-Sleep -Seconds 1 }
    } finally {
        Stop-ShortcutWatchers
    }
}

Export-ModuleMember -Function Initialize-Watcher, Start-ShortcutWatchers, Stop-ShortcutWatchers, Wait-Forever
