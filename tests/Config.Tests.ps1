#Requires -Version 5.1
#Requires -Modules Pester

Describe "Config Module" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot "..\modules\Config.psm1"
        Import-Module $ModulePath -Force
        $TestDir = Split-Path $PSScriptRoot -Parent

        # Writes a config.json into a fresh folder under TestDrive and returns the folder
        function New-TestConfigDir {
            param([string]$Name, [string]$Json, [switch]$NoFile)
            $dir = Join-Path $TestDrive $Name
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            if (-not $NoFile) {
                Set-Content -Path (Join-Path $dir "config.json") -Value $Json
            }
            return $dir
        }
    }

    Context "Initialize-Config" {
        It "Loads configuration from config.json" {
            Initialize-Config -ScriptDirectory $TestDir
            $config = Get-Config

            $config | Should -Not -BeNullOrEmpty
            $config.FirefoxExe | Should -Not -BeNullOrEmpty
            $config.ProfileName | Should -Not -BeNullOrEmpty
        }

        It "Expands environment variables in shortcuts" {
            Initialize-Config -ScriptDirectory $TestDir
            $config = Get-Config

            $config.ShortcutLocations | Should -Not -BeNullOrEmpty
            $config.ShortcutLocations[0] | Should -Not -Match '%'
        }

        It "Sets IconPath relative to script directory" {
            Initialize-Config -ScriptDirectory $TestDir
            $config = Get-Config

            $config.IconPath | Should -BeLike "*firebatpro.ico"
        }
    }

    Context "Initialize-Config with a test config.json" {
        BeforeAll {
            $env:FIREBAT_TEST_VAR = "C:\FirebatTestRoot"
        }

        AfterAll {
            Remove-Item Env:\FIREBAT_TEST_VAR -ErrorAction SilentlyContinue
        }

        It "Maps every field of a full config" {
            $json = @'
{
  "firefox": { "exePath": "C:\\FF\\firefox.exe", "directory": "C:\\FF" },
  "profile": { "name": "work" },
  "shortcuts": [ "%FIREBAT_TEST_VAR%\\One.lnk", "C:\\Plain\\Two.lnk" ],
  "watcher": { "debounceMs": 750 },
  "logging": { "maxSizeMB": 3 }
}
'@
            $dir = New-TestConfigDir -Name "full" -Json $json
            Initialize-Config -ScriptDirectory $dir
            $config = Get-Config

            $config.FirefoxExe | Should -Be "C:\FF\firefox.exe"
            $config.FirefoxDir | Should -Be "C:\FF"
            $config.ProfileName | Should -Be "work"
            $config.ShortcutLocations | Should -Be @("C:\FirebatTestRoot\One.lnk", "C:\Plain\Two.lnk")
            $config.DebounceMs | Should -Be 750
            $config.LogMaxSizeMB | Should -Be 3
            $config.IconPath | Should -Be (Join-Path $dir "firebatpro.ico")
            $config.ScriptDir | Should -Be $dir
            Get-ScriptDir | Should -Be $dir
        }

        It "Throws when config.json is missing" {
            $dir = New-TestConfigDir -Name "missing" -NoFile

            { Initialize-Config -ScriptDirectory $dir } | Should -Throw "*Configuration file not found*"
        }

        It "Loads an empty config.json without error" {
            # CURRENT BEHAVIOUR (suspected bug): an empty file is not rejected; every value is
            # null and the problem only shows later, e.g. install.ps1 reports "Firefox not found at ".
            $dir = New-TestConfigDir -Name "empty" -Json ""

            { Initialize-Config -ScriptDirectory $dir } | Should -Not -Throw
            $config = Get-Config
            $config.FirefoxExe | Should -BeNullOrEmpty
            $config.ProfileName | Should -BeNullOrEmpty
            @($config.ShortcutLocations).Count | Should -Be 0
        }

        It "Throws when config.json is not valid JSON" {
            $dir = New-TestConfigDir -Name "malformed" -Json '{ "firefox": { "exePath": '

            { Initialize-Config -ScriptDirectory $dir } | Should -Throw
        }

        It "Leaves optional watcher and logging values null when their sections are missing" {
            # install.ps1 passes these straight to [int] parameters, so null becomes 0 there.
            # See Logging.Tests.ps1 for what MaxSizeMB 0 does to the log.
            $json = @'
{
  "firefox": { "exePath": "C:\\FF\\firefox.exe", "directory": "C:\\FF" },
  "profile": { "name": "work" },
  "shortcuts": [ "C:\\Plain\\Two.lnk" ]
}
'@
            $dir = New-TestConfigDir -Name "nooptional" -Json $json
            Initialize-Config -ScriptDirectory $dir
            $config = Get-Config

            $config.DebounceMs | Should -BeNullOrEmpty
            $config.LogMaxSizeMB | Should -BeNullOrEmpty
        }

        It "Yields no shortcut locations when the shortcuts list is missing" {
            $json = '{ "firefox": { "exePath": "C:\\FF\\firefox.exe", "directory": "C:\\FF" }, "profile": { "name": "work" } }'
            $dir = New-TestConfigDir -Name "noshortcuts" -Json $json
            Initialize-Config -ScriptDirectory $dir
            $config = Get-Config

            @($config.ShortcutLocations).Count | Should -Be 0
        }
    }

    Context "Get-Config before initialization" {
        BeforeAll {
            Remove-Module Config -Force -ErrorAction SilentlyContinue
            Import-Module $ModulePath -Force
        }

        It "Throws when config not initialized" {
            { Get-Config } | Should -Throw "*not initialized*"
        }
    }
}
