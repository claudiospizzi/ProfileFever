
$modulePath = $PSScriptRoot | Split-Path | Split-Path
$moduleName = Split-Path -Path $modulePath -Leaf

$resourceName = 'PSRepository'
$resourcePath = "$modulePath\DSCResources\$moduleName`_$resourceName"

Remove-Module -Name "$moduleName`_$resourceName" -ErrorAction SilentlyContinue
Import-Module "$resourcePath\$moduleName`_$resourceName.psm1"

InModuleScope "$moduleName`_$resourceName" {

    Describe 'PSRepository' {

        Context 'Get' {

            Mock Get-PSRepository -ParameterFilter { $Name -eq 'PSGallery' } {
                [PSCustomObject] @{
                    Name                  = 'PSGallery'
                    InstallationPolicy    = 'Untrusted'
                    SourceLocation        = 'https://www.powershellgallery.com/api/v2'
                    PublishLocation       = 'https://www.powershellgallery.com/api/v2/package/'
                    ScriptSourceLocation  = 'https://www.powershellgallery.com/api/v2/items/psscript/'
                    ScriptPublishLocation = 'https://www.powershellgallery.com/api/v2/package/'
                }
            }
            Mock Get-PSRepository -ParameterFilter { $Name -ne 'PSGallery' } { throw 'Not found!' }

            It 'should return as present' {

                $resource = Get-TargetResource -Name 'PSGallery' -SourceLocation 'https://www.powershellgallery.com/api/v2'

                $resource.Ensure                | Should -Be 'Present'
                $resource.Name                  | Should -Be 'PSGallery'
                $resource.InstallationPolicy    | Should -Be 'Untrusted'
                $resource.SourceLocation        | Should -Be 'https://www.powershellgallery.com/api/v2'
                $resource.PublishLocation       | Should -Be 'https://www.powershellgallery.com/api/v2/package/'
                $resource.ScriptSourceLocation  | Should -Be 'https://www.powershellgallery.com/api/v2/items/psscript/'
                $resource.ScriptPublishLocation | Should -Be 'https://www.powershellgallery.com/api/v2/package/'
            }

            It 'should return as absent' {

                $resource = Get-TargetResource -Name 'Demo' -SourceLocation 'https://www.demo.com/api/v2'

                $resource.Ensure                | Should -Be 'Absent'
                $resource.Name                  | Should -Be 'Demo'
                $resource.InstallationPolicy    | Should -Be ''
                $resource.SourceLocation        | Should -Be ''
                $resource.PublishLocation       | Should -Be ''
                $resource.ScriptSourceLocation  | Should -Be ''
                $resource.ScriptPublishLocation | Should -Be ''
            }
        }
    }
}
