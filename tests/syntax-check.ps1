$files = @(
    'install.ps1',
    'uninstall.ps1',
    'modules/Config.psm1',
    'modules/Logging.psm1',
    'modules/Shortcuts.psm1',
    'modules/Watcher.psm1'
)

$scriptDir = Split-Path -Parent $PSScriptRoot
$allPassed = $true

foreach ($f in $files) {
    $path = Join-Path $scriptDir $f
    try {
        [scriptblock]::Create((Get-Content $path -Raw)) | Out-Null
        Write-Host "OK: $f" -ForegroundColor Green
    } catch {
        Write-Host "FAIL: $f - $_" -ForegroundColor Red
        $allPassed = $false
    }
}

if ($allPassed) {
    Write-Host "`nAll syntax checks passed" -ForegroundColor Cyan
    exit 0
} else {
    exit 1
}
