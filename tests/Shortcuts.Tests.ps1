#Requires -Version 5.1
#Requires -Modules Pester

Describe "Shortcuts Module" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot "..\modules\Shortcuts.psm1"
        Import-Module $ModulePath -Force
    }

    Context "Initialize-Shortcuts" {
        It "Creates WScript.Shell object" {
            { Initialize-Shortcuts } | Should -Not -Throw
        }
    }

    Context "Test-IsFirebatShortcut" {
        It "Returns false for non-existent path" {
            Test-IsFirebatShortcut "C:\nonexistent\path.lnk" | Should -Be $false
        }
    }

    Context "Set-FirebatShortcut" {
        It "Returns false for non-existent path" {
            Initialize-Shortcuts
            $result = Set-FirebatShortcut -ShortcutPath "C:\nonexistent.lnk" `
                -FirefoxExe "C:\test.exe" -FirefoxDir "C:\test" `
                -ProfileName "test" -IconPath "C:\test.ico"

            $result | Should -Be $false
        }
    }

    Context "Reset-FirefoxShortcut" {
        It "Returns false for non-existent path" {
            Initialize-Shortcuts
            $result = Reset-FirefoxShortcut -ShortcutPath "C:\nonexistent.lnk" `
                -FirefoxExe "C:\test.exe" -FirefoxDir "C:\test"

            $result | Should -Be $false
        }
    }

    Context "Update-AllShortcuts" {
        It "Returns 0 when no shortcuts exist" {
            Initialize-Shortcuts
            $result = Update-AllShortcuts -ShortcutLocations @("C:\nonexistent1.lnk", "C:\nonexistent2.lnk") `
                -FirefoxExe "C:\test.exe" -FirefoxDir "C:\test" `
                -ProfileName "test" -IconPath "C:\test.ico"

            $result | Should -Be 0
        }
    }
}
