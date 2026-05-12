#Requires -Version 5.1
#Requires -Modules Pester

Describe "Logging Module" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot "..\modules\Logging.psm1"
        Import-Module $ModulePath -Force
    }

    Context "Initialize-Logging" {
        It "Creates log directory if needed" {
            Initialize-Logging -MaxSizeMB 1
            $logPath = Get-LogPath

            $logDir = Split-Path $logPath -Parent
            Test-Path $logDir | Should -Be $true
        }

        It "Sets log path in LocalAppData" {
            Initialize-Logging
            $logPath = Get-LogPath

            $logPath | Should -BeLike "*firebatpro*"
        }
    }

    Context "Write-Log" {
        BeforeAll {
            Initialize-Logging -MaxSizeMB 1
        }

        It "Writes INFO level by default" {
            Write-Log "Test message"
            $logPath = Get-LogPath

            Test-Path $logPath | Should -Be $true
            Get-Content $logPath -Tail 1 | Should -Match "\[INFO\]"
        }

        It "Writes with specified level" {
            Write-Log "Warning message" -Level WARN
            $logPath = Get-LogPath

            Get-Content $logPath -Tail 1 | Should -Match "\[WARN\]"
        }

        It "Includes timestamp" {
            Write-Log "Timestamp test"
            $logPath = Get-LogPath

            Get-Content $logPath -Tail 1 | Should -Match "\[\d{4}-\d{2}-\d{2}"
        }
    }
}
