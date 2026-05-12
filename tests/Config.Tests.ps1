#Requires -Version 5.1
#Requires -Modules Pester

Describe "Config Module" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot "..\modules\Config.psm1"
        Import-Module $ModulePath -Force
        $TestDir = Split-Path $PSScriptRoot -Parent
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
