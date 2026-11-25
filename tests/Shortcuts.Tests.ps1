#Requires -Version 5.1
#Requires -Modules Pester

Describe "Shortcuts Module" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot "..\modules\Shortcuts.psm1"
        Import-Module $ModulePath -Force

        # Fake WScript.Shell: CreateShortcut returns one stored object per path, Save() counts calls.
        # Shortcut paths are empty placeholder files in TestDrive, so Test-Path sees them but no
        # real .lnk is read or written.
        function New-FakeShell {
            $shell = [pscustomobject]@{ Links = @{} }
            $shell | Add-Member -MemberType ScriptMethod -Name CreateShortcut -Value {
                param($Path)
                if (-not $this.Links.ContainsKey($Path)) {
                    $lnk = [pscustomobject]@{
                        TargetPath = ""
                        Arguments = ""
                        IconLocation = ""
                        WorkingDirectory = ""
                        SaveCount = 0
                    }
                    $lnk | Add-Member -MemberType ScriptMethod -Name Save -Value { $this.SaveCount++ }
                    $this.Links[$Path] = $lnk
                }
                return $this.Links[$Path]
            }
            return $shell
        }

        function New-PlaceholderShortcut {
            param([string]$Name)
            $path = Join-Path $TestDrive $Name
            Set-Content -Path $path -Value ""
            return $path
        }
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

    Context "Shortcut changes with a mocked shell" {
        BeforeEach {
            $script:FakeShell = New-FakeShell
            Mock Get-ShellObject -ModuleName Shortcuts { $script:FakeShell }
        }

        It "Recognises a shortcut whose icon is firebatpro" {
            $path = New-PlaceholderShortcut "IsFirebat.lnk"
            $script:FakeShell.CreateShortcut($path).IconLocation = "C:\tools\firebatpro.ico,0"

            Test-IsFirebatShortcut $path | Should -Be $true
        }

        It "Does not recognise a shortcut with the Firefox icon" {
            $path = New-PlaceholderShortcut "IsDefault.lnk"
            $script:FakeShell.CreateShortcut($path).IconLocation = "C:\FF\firefox.exe,0"

            Test-IsFirebatShortcut $path | Should -Be $false
        }

        It "Sets target, profile argument, icon and working directory, then saves" {
            $path = New-PlaceholderShortcut "Set.lnk"

            $result = Set-FirebatShortcut -ShortcutPath $path -FirefoxExe "C:\FF\firefox.exe" `
                -FirefoxDir "C:\FF" -ProfileName "work profile" -IconPath "C:\tools\firebatpro.ico"

            $result | Should -Be $true
            $lnk = $script:FakeShell.CreateShortcut($path)
            $lnk.TargetPath | Should -Be "C:\FF\firefox.exe"
            $lnk.Arguments | Should -Be '-P "work profile"'
            $lnk.IconLocation | Should -Be "C:\tools\firebatpro.ico,0"
            $lnk.WorkingDirectory | Should -Be "C:\FF"
            $lnk.SaveCount | Should -Be 1
        }

        It "Skips a shortcut that is already configured" {
            $path = New-PlaceholderShortcut "Already.lnk"
            $lnk = $script:FakeShell.CreateShortcut($path)
            $lnk.IconLocation = "C:\tools\firebatpro.ico,0"
            $lnk.Arguments = '-P "old"'

            $result = Set-FirebatShortcut -ShortcutPath $path -FirefoxExe "C:\FF\firefox.exe" `
                -FirefoxDir "C:\FF" -ProfileName "new" -IconPath "C:\tools\firebatpro.ico"

            $result | Should -Be $false
            $lnk.Arguments | Should -Be '-P "old"'
            $lnk.SaveCount | Should -Be 0
        }

        It "Resets a shortcut to plain Firefox and saves" {
            $path = New-PlaceholderShortcut "Reset.lnk"
            $lnk = $script:FakeShell.CreateShortcut($path)
            $lnk.IconLocation = "C:\tools\firebatpro.ico,0"
            $lnk.Arguments = '-P "work"'

            $result = Reset-FirefoxShortcut -ShortcutPath $path -FirefoxExe "C:\FF\firefox.exe" -FirefoxDir "C:\FF"

            $result | Should -Be $true
            $lnk.TargetPath | Should -Be "C:\FF\firefox.exe"
            $lnk.Arguments | Should -Be ""
            $lnk.IconLocation | Should -Be "C:\FF\firefox.exe,0"
            $lnk.WorkingDirectory | Should -Be "C:\FF"
            $lnk.SaveCount | Should -Be 1
        }

        It "Update-AllShortcuts counts only shortcuts it changed" {
            $new = New-PlaceholderShortcut "UpdNew.lnk"
            $done = New-PlaceholderShortcut "UpdDone.lnk"
            $script:FakeShell.CreateShortcut($done).IconLocation = "C:\tools\firebatpro.ico,0"
            $missing = Join-Path $TestDrive "UpdMissing.lnk"

            $result = Update-AllShortcuts -ShortcutLocations @($new, $done, $missing) `
                -FirefoxExe "C:\FF\firefox.exe" -FirefoxDir "C:\FF" `
                -ProfileName "work" -IconPath "C:\tools\firebatpro.ico"

            $result | Should -Be 1
            $script:FakeShell.CreateShortcut($new).SaveCount | Should -Be 1
            $script:FakeShell.CreateShortcut($done).SaveCount | Should -Be 0
        }

        It "Reset-AllShortcuts counts every existing shortcut" {
            $a = New-PlaceholderShortcut "RstA.lnk"
            $b = New-PlaceholderShortcut "RstB.lnk"
            $missing = Join-Path $TestDrive "RstMissing.lnk"

            $result = Reset-AllShortcuts -ShortcutLocations @($a, $missing, $b) `
                -FirefoxExe "C:\FF\firefox.exe" -FirefoxDir "C:\FF"

            $result | Should -Be 2
            $script:FakeShell.CreateShortcut($a).IconLocation | Should -Be "C:\FF\firefox.exe,0"
            $script:FakeShell.CreateShortcut($b).IconLocation | Should -Be "C:\FF\firefox.exe,0"
        }
    }
}
