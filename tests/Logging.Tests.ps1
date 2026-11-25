#Requires -Version 5.1
#Requires -Modules Pester

Describe "Logging Module" {
    BeforeAll {
        # Point the module at a throwaway LOCALAPPDATA so tests never write to the live log
        $script:OriginalLocalAppData = $env:LOCALAPPDATA
        $env:LOCALAPPDATA = Join-Path $TestDrive "LocalAppData"

        $ModulePath = Join-Path $PSScriptRoot "..\modules\Logging.psm1"
        Import-Module $ModulePath -Force
    }

    AfterAll {
        $env:LOCALAPPDATA = $script:OriginalLocalAppData
        Remove-Module Logging -Force -ErrorAction SilentlyContinue
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
            $logPath | Should -Be (Join-Path $env:LOCALAPPDATA "firebatpro\firebatpro.log")
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

        It "Rejects an unknown level" {
            { Write-Log "Bad level" -Level DEBUG } | Should -Throw
        }
    }

    Context "Write-Log without Initialize-Logging" {
        It "Initializes itself on first write" {
            Remove-Module Logging -Force -ErrorAction SilentlyContinue
            Import-Module $ModulePath -Force

            Get-LogPath | Should -BeNullOrEmpty
            Write-Log "Self-initialized"

            Get-LogPath | Should -Be (Join-Path $env:LOCALAPPDATA "firebatpro\firebatpro.log")
            Get-Content (Get-LogPath) -Tail 1 | Should -Match "Self-initialized"
        }
    }

    Context "Log rotation" {
        BeforeEach {
            Initialize-Logging -MaxSizeMB 1
            $script:LogPath = Get-LogPath
            $script:Backup = "$script:LogPath.old"
            Remove-Item $script:LogPath, $script:Backup -Force -ErrorAction SilentlyContinue
        }

        It "Does not rotate a log of exactly the size limit" {
            [System.IO.File]::WriteAllBytes($script:LogPath, (New-Object byte[] (1MB)))

            Write-Log "At limit"

            Test-Path $script:Backup | Should -Be $false
            (Get-Item $script:LogPath).Length | Should -BeGreaterThan 1MB
        }

        It "Rotates a log over the size limit to .old and starts a fresh log" {
            [System.IO.File]::WriteAllBytes($script:LogPath, (New-Object byte[] (1MB + 1)))

            Write-Log "After rotation"

            Test-Path $script:Backup | Should -Be $true
            (Get-Item $script:Backup).Length | Should -Be (1MB + 1)
            @(Get-Content $script:LogPath).Count | Should -Be 1
            Get-Content $script:LogPath | Should -Match "After rotation"
        }

        It "Replaces an existing .old backup when rotating" {
            Set-Content -Path $script:Backup -Value "previous backup"
            [System.IO.File]::WriteAllBytes($script:LogPath, (New-Object byte[] (1MB + 1)))

            Write-Log "Second rotation"

            (Get-Item $script:Backup).Length | Should -Be (1MB + 1)
            Get-Content $script:LogPath | Should -Match "Second rotation"
        }

        It "Honours a larger MaxSizeMB" {
            Initialize-Logging -MaxSizeMB 2
            [System.IO.File]::WriteAllBytes($script:LogPath, (New-Object byte[] (1MB + 1)))

            Write-Log "Under 2MB"

            Test-Path $script:Backup | Should -Be $false
        }

        It "Rotates on every write when MaxSizeMB is 0" {
            # CURRENT BEHAVIOUR (suspected bug): config.json without a logging.maxSizeMB value
            # reaches Initialize-Logging as $null, which becomes 0, so every write after the
            # first rotates and the log never holds more than one line.
            Initialize-Logging -MaxSizeMB 0

            Write-Log "First"
            Write-Log "Second"
            Write-Log "Third"

            @(Get-Content $script:LogPath).Count | Should -Be 1
            Get-Content $script:LogPath | Should -Match "Third"
            Get-Content $script:Backup | Should -Match "Second"
        }
    }
}
