# Config.psm1 - Configuration loading with environment variable expansion

$script:Config = $null
$script:ScriptDir = $null

function Initialize-Config {
    param([string]$ScriptDirectory)

    $script:ScriptDir = $ScriptDirectory
    $configPath = Join-Path $ScriptDirectory "config.json"

    if (-not (Test-Path $configPath)) {
        throw "Configuration file not found: $configPath"
    }

    $raw = Get-Content $configPath -Raw | ConvertFrom-Json

    # Expand environment variables in shortcuts array
    $expandedShortcuts = @()
    foreach ($path in $raw.shortcuts) {
        $expandedShortcuts += [Environment]::ExpandEnvironmentVariables($path)
    }

    $script:Config = @{
        FirefoxExe = $raw.firefox.exePath
        FirefoxDir = $raw.firefox.directory
        ProfileName = $raw.profile.name
        ShortcutLocations = $expandedShortcuts
        DebounceMs = $raw.watcher.debounceMs
        LogMaxSizeMB = $raw.logging.maxSizeMB
        IconPath = Join-Path $ScriptDirectory "firebatpro.ico"
        ScriptDir = $ScriptDirectory
    }
}

function Get-Config {
    if (-not $script:Config) {
        throw "Config not initialized. Call Initialize-Config first."
    }
    return $script:Config
}

function Get-ScriptDir {
    return $script:ScriptDir
}

Export-ModuleMember -Function Initialize-Config, Get-Config, Get-ScriptDir
