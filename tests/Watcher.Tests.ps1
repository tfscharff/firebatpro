#Requires -Version 5.1
#Requires -Modules Pester

Describe "Watcher Module" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot "..\modules\Watcher.psm1"
        Import-Module $ModulePath -Force
    }

    Context "Initialize-Watcher" {
        It "Stores configuration" {
            { Initialize-Watcher -IconPath "C:\test.ico" -ProfileName "test" `
                -FirefoxExe "C:\test.exe" -FirefoxDir "C:\test" `
                -DebounceMs 500 } | Should -Not -Throw
        }
    }

    Context "Start-ShortcutWatchers" {
        It "Throws when not initialized" {
            Remove-Module Watcher -Force -ErrorAction SilentlyContinue
            Import-Module $ModulePath -Force

            { Start-ShortcutWatchers -ShortcutLocations @() } | Should -Throw "*not initialized*"
        }

        It "Returns 0 for non-existent directories" {
            Initialize-Watcher -IconPath "C:\test.ico" -ProfileName "test" `
                -FirefoxExe "C:\test.exe" -FirefoxDir "C:\test"

            $result = Start-ShortcutWatchers -ShortcutLocations @("C:\nonexistent\path.lnk")
            $result | Should -Be 0
        }
    }

    Context "Stop-ShortcutWatchers" {
        It "Runs without error when no watchers" {
            { Stop-ShortcutWatchers } | Should -Not -Throw
        }
    }
}
