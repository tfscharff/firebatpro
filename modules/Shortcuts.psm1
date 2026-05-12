# Shortcuts.psm1 - Firefox shortcut manipulation

$script:Shell = $null

function Initialize-Shortcuts {
    $script:Shell = New-Object -ComObject WScript.Shell
}

function Get-ShellObject {
    if (-not $script:Shell) {
        Initialize-Shortcuts
    }
    return $script:Shell
}

function Test-IsFirebatShortcut {
    param([string]$ShortcutPath)

    if (-not (Test-Path $ShortcutPath)) {
        return $false
    }

    $shell = Get-ShellObject
    $lnk = $shell.CreateShortcut($ShortcutPath)
    return $lnk.IconLocation -like "*firebatpro*"
}

function Set-FirebatShortcut {
    param(
        [string]$ShortcutPath,
        [string]$FirefoxExe,
        [string]$FirefoxDir,
        [string]$ProfileName,
        [string]$IconPath
    )

    if (-not (Test-Path $ShortcutPath)) {
        return $false
    }

    # Skip if already configured
    if (Test-IsFirebatShortcut $ShortcutPath) {
        return $false
    }

    $shell = Get-ShellObject
    $lnk = $shell.CreateShortcut($ShortcutPath)
    $lnk.TargetPath = $FirefoxExe
    $lnk.Arguments = "-P `"$ProfileName`" --no-remote"
    $lnk.IconLocation = "$IconPath,0"
    $lnk.WorkingDirectory = $FirefoxDir
    $lnk.Save()

    return $true
}

function Reset-FirefoxShortcut {
    param(
        [string]$ShortcutPath,
        [string]$FirefoxExe,
        [string]$FirefoxDir
    )

    if (-not (Test-Path $ShortcutPath)) {
        return $false
    }

    $shell = Get-ShellObject
    $lnk = $shell.CreateShortcut($ShortcutPath)
    $lnk.TargetPath = $FirefoxExe
    $lnk.Arguments = ""
    $lnk.IconLocation = "$FirefoxExe,0"
    $lnk.WorkingDirectory = $FirefoxDir
    $lnk.Save()

    return $true
}

function Update-AllShortcuts {
    param(
        [string[]]$ShortcutLocations,
        [string]$FirefoxExe,
        [string]$FirefoxDir,
        [string]$ProfileName,
        [string]$IconPath
    )

    $updated = 0
    foreach ($path in $ShortcutLocations) {
        if (Set-FirebatShortcut -ShortcutPath $path -FirefoxExe $FirefoxExe -FirefoxDir $FirefoxDir -ProfileName $ProfileName -IconPath $IconPath) {
            $updated++
        }
    }
    return $updated
}

function Reset-AllShortcuts {
    param(
        [string[]]$ShortcutLocations,
        [string]$FirefoxExe,
        [string]$FirefoxDir
    )

    $restored = 0
    foreach ($path in $ShortcutLocations) {
        if (Reset-FirefoxShortcut -ShortcutPath $path -FirefoxExe $FirefoxExe -FirefoxDir $FirefoxDir) {
            $restored++
        }
    }
    return $restored
}

Export-ModuleMember -Function Initialize-Shortcuts, Test-IsFirebatShortcut, Set-FirebatShortcut, Reset-FirefoxShortcut, Update-AllShortcuts, Reset-AllShortcuts
