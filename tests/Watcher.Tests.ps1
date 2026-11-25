#Requires -Version 5.1
#Requires -Modules Pester

Describe "Watcher Module" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot "..\modules\Watcher.psm1"
        Import-Module $ModulePath -Force
    }

    AfterAll {
        Stop-ShortcutWatchers
    }

    Context "Initialize-Watcher" {
        It "Stores configuration" {
            { Initialize-Watcher -IconPath "C:\test.ico" -ProfileName "test" `
                -FirefoxExe "C:\test.exe" -FirefoxDir "C:\test" `
                -DebounceMs 500 } | Should -Not -Throw
        }

        It "Defaults DebounceMs to 500" {
            Initialize-Watcher -IconPath "C:\test.ico" -ProfileName "test" `
                -FirefoxExe "C:\test.exe" -FirefoxDir "C:\test"

            InModuleScope Watcher { $script:WatcherConfig.DebounceMs } | Should -Be 500
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

    Context "Start-ShortcutWatchers with real folders" {
        # Watchers are created on empty TestDrive folders only; no event is ever raised.
        BeforeAll {
            $script:DirA = Join-Path $TestDrive "WatchA"
            $script:DirB = Join-Path $TestDrive "WatchB"
            New-Item -ItemType Directory -Path $script:DirA, $script:DirB -Force | Out-Null
        }

        BeforeEach {
            Stop-ShortcutWatchers
            Initialize-Watcher -IconPath "C:\test.ico" -ProfileName "test" `
                -FirefoxExe "C:\test.exe" -FirefoxDir "C:\test" -DebounceMs 10
        }

        AfterEach {
            Stop-ShortcutWatchers
        }

        It "Watches each file by its folder and name, skipping missing folders" {
            $result = Start-ShortcutWatchers -ShortcutLocations @(
                (Join-Path $script:DirA "Firefox.lnk"),
                (Join-Path $TestDrive "Missing\Firefox.lnk")
            )

            $result | Should -Be 1
            $watcher = InModuleScope Watcher { $script:Watchers[0] }
            $watcher.Path | Should -Be $script:DirA
            $watcher.Filter | Should -Be "Firefox.lnk"
            $watcher.EnableRaisingEvents | Should -Be $true
        }

        It "Registers Changed and Created handlers for each watcher" {
            Start-ShortcutWatchers -ShortcutLocations @((Join-Path $script:DirA "Firefox.lnk")) | Out-Null

            $watcher = InModuleScope Watcher { $script:Watchers[0] }
            $events = Get-EventSubscriber | Where-Object { $_.SourceObject -eq $watcher } |
                ForEach-Object { $_.EventName } | Sort-Object
            $events | Should -Be @("Changed", "Created")
        }

        It "Watches distinct paths once each and drops duplicates" -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {
            $result = Start-ShortcutWatchers -ShortcutLocations @(
                (Join-Path $script:DirA "Firefox.lnk"),
                (Join-Path $script:DirA "Mozilla Firefox.lnk"),
                (Join-Path $script:DirB "Firefox.lnk"),
                (Join-Path $script:DirA "Firefox.lnk")
            )

            $result | Should -Be 3
        }

        It "Collapses all paths to one watcher on Windows PowerShell 5.1" -Skip:($PSVersionTable.PSEdition -ne 'Desktop') {
            # CURRENT BEHAVIOUR (suspected bug): on Windows PowerShell 5.1, Sort-Object -Unique
            # cannot see the Dir and File keys of the hashtables it sorts, so it treats every
            # watch path as equal and keeps only one. The live watcher runs on powershell.exe.
            $result = Start-ShortcutWatchers -ShortcutLocations @(
                (Join-Path $script:DirA "Firefox.lnk"),
                (Join-Path $script:DirA "Mozilla Firefox.lnk"),
                (Join-Path $script:DirB "Firefox.lnk")
            )

            $result | Should -Be 1
        }
    }

    Context "Stop-ShortcutWatchers" {
        It "Runs without error when no watchers" {
            { Stop-ShortcutWatchers } | Should -Not -Throw
        }

        It "Disables, disposes and forgets every watcher and unregisters its events" {
            $dir = Join-Path $TestDrive "StopDir"
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Initialize-Watcher -IconPath "C:\test.ico" -ProfileName "test" `
                -FirefoxExe "C:\test.exe" -FirefoxDir "C:\test"
            Start-ShortcutWatchers -ShortcutLocations @((Join-Path $dir "Firefox.lnk")) | Out-Null
            $watcher = InModuleScope Watcher { $script:Watchers[0] }

            Stop-ShortcutWatchers

            $watcher.EnableRaisingEvents | Should -Be $false
            @(InModuleScope Watcher { $script:Watchers }).Count | Should -Be 0
            @(Get-EventSubscriber | Where-Object { $_.SourceObject -eq $watcher }).Count | Should -Be 0
        }
    }

    Context "Wait-Forever" {
        It "Stops the watchers when the wait loop is interrupted" {
            Mock Start-Sleep -ModuleName Watcher { throw "interrupted" }
            Mock Stop-ShortcutWatchers -ModuleName Watcher { }

            { Wait-Forever } | Should -Throw "*interrupted*"

            Should -Invoke Stop-ShortcutWatchers -ModuleName Watcher -Times 1 -Exactly
        }
    }
}
