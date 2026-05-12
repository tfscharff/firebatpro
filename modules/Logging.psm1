# Logging.psm1 - Log file management with rotation

$script:LogPath = $null
$script:MaxSizeBytes = 1MB

function Initialize-Logging {
    param(
        [int]$MaxSizeMB = 1
    )

    $logDir = Join-Path $env:LOCALAPPDATA "firebatpro"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $script:LogPath = Join-Path $logDir "firebatpro.log"
    $script:MaxSizeBytes = $MaxSizeMB * 1MB
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )

    if (-not $script:LogPath) {
        Initialize-Logging
    }

    # Rotate if needed
    if ((Test-Path $script:LogPath) -and (Get-Item $script:LogPath).Length -gt $script:MaxSizeBytes) {
        $backup = "$script:LogPath.old"
        if (Test-Path $backup) { Remove-Item $backup -Force }
        Rename-Item $script:LogPath $backup
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"

    Add-Content -Path $script:LogPath -Value $entry
}

function Get-LogPath {
    return $script:LogPath
}

Export-ModuleMember -Function Initialize-Logging, Write-Log, Get-LogPath
