
$modulePath = $PSScriptRoot | Split-Path | Split-Path
$moduleName = Split-Path -Path $modulePath -Leaf

$resourceName = 'PSModule'
$resourcePath = "$modulePath\DSCResources\$moduleName`_$resourceName"

Remove-Module -Name "$moduleName`_$resourceName" -ErrorAction SilentlyContinue
Import-Module "$resourcePath\$moduleName`_$resourceName.psm1"

Describe $resourceName {

    Context 'Get' {

        Mock Get-InstalledModule -ParameterFilter { $Name -eq 'TestModule' } { [PSCustomObject] @{ Name = 'TestModule'; Version = '1.0.0'; Repository = 'PSGallery' } }
        Mock Get-InstalledModule -ParameterFilter { $Name -ne 'TestModule' } { throw 'Not found!' }

        It 'should return as present' {

            # Act
            $resource = Get-TargetResource -Name 'TestModule' -Version '1.0.0'

            # Assert
            $resource.Ensure     | Should -Be 'Present'
            $resource.Name       | Should -Be 'TestModule'
            $resource.Version    | Should -Be '1.0.0'
            $resource.Repository | Should -Be 'PSGallery'
        }

        It 'should return as absent' {

            # Act
            $resource = Get-TargetResource -Name 'Demo' -Version '0.0.1'

            # Assert
            $resource.Ensure     | Should -Be 'Absent'
            $resource.Name       | Should -Be 'Demo'
            $resource.Version    | Should -Be '0.0.1'
            $resource.Repository | Should -Be ''
        }
    }
}
