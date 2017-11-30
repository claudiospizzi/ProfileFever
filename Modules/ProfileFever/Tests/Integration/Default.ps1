
# Default configuration
Configuration 'Default'
{
    Import-DscResource -ModuleName 'ProfileFever'

    Node 'localhost'
    {
        PSRepository 'Arcade'
        {
            Name               = 'Arcade'
            InstallationPolicy = 'Trusted'
            SourceLocation     = 'https://psgallery.arcade.ch/nuget/powershell/'
            PublishLocation    = 'https://psgallery.arcade.ch/nuget/powershell/package/'
        }

        PSModule 'Pester'
        {
            Name    = 'Pester'
            Version = 'latest'
        }

        PSModule 'PSScriptAnalyzer'
        {
            Name    = 'PSScriptAnalyzer'
            Version = 'latest'
        }

        PSModule 'OperationValidation'
        {
            Name    = 'OperationValidation'
            Version = 'latest'
        }

        PSModule 'Plaster'
        {
            Name    = 'Plaster'
            Version = 'latest'
        }

        PSModule 'psake'
        {
            Name    = 'psake'
            Version = 'latest'
        }

        PSModule 'PScribo'
        {
            Name    = 'PScribo'
            Version = 'latest'
        }

        PSModule 'posh-git'
        {
            Name    = 'posh-git'
            Version = 'latest'
        }

        PSModule 'ActiveDirectoryFever'
        {
            Name    = 'ActiveDirectoryFever'
            Version = 'latest'
        }

        PSModule 'OperationsManagerFever'
        {
            Name    = 'OperationsManagerFever'
            Version = 'latest'
        }

        PSModule 'SecurityFever'
        {
            Name    = 'SecurityFever'
            Version = 'latest'
        }

        PSModule 'SharePointFever'
        {
            Name    = 'SharePointFever'
            Version = 'latest'
        }

        PSModule 'WindowsFever'
        {
            Name    = 'WindowsFever'
            Version = 'latest'
        }

        PSModule 'ScriptLogger'
        {
            Name    = 'ScriptLogger'
            Version = 'latest'
        }

        PSModule 'ScriptConfig'
        {
            Name    = 'ScriptConfig'
            Version = 'latest'
        }

        PSModule 'ISEPresenter'
        {
            Name    = 'ISEPresenter'
            Version = 'latest'
        }

        PSModule 'ISEScriptAnalyzerAddOn'
        {
            Name    = 'ISEScriptAnalyzerAddOn'
            Version = 'latest'
        }

        PSModule 'PsISEProjectExplorer'
        {
            Name    = 'PsISEProjectExplorer'
            Version = 'latest'
        }

        PSModule 'ImportExcel'
        {
            Name    = 'ImportExcel'
            Version = 'latest'
        }

        PSModule 'VMware.PowerCLI'
        {
            Name    = 'VMware.PowerCLI'
            Version = 'latest'
        }

        # PSModule 'ArcadeIcinga'
        # {
        #     Name       = 'ArcadeIcinga'
        #     Version    = 'latest'
        #     Repository = 'Arcade'
        # }

        # PSModule 'ArcadeKunden'
        # {
        #     Name       = 'ArcadeKunden'
        #     Version    = 'latest'
        #     Repository = 'Arcade'
        # }
    }
}

# Compile configuration
Default -OutputPath "$PSScriptRoot\Default"

# Invoke the DSC configuration
Start-DscConfiguration -Path "$PSScriptRoot\Default" -Wait -Force -Verbose
