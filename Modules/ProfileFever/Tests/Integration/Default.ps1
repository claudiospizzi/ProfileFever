
# Default configuration
Configuration 'Default'
{
    Import-DscResource -ModuleName 'ProfileFever'

    Node 'localhost'
    {
        PSRepository 'Demo'
        {
            Name               = 'Demo'
            InstallationPolicy = 'Trusted'
            SourceLocation     = 'https://psgallery.demo.com/nuget/powershell/'
            PublishLocation    = 'https://psgallery.demo.com/nuget/powershell/package/'
        }

        PSModule 'Pester'
        {
            Name    = 'Pester'
            Version = '3.4.0'
        }

        PSModule 'PSScriptAnalyzer'
        {
            Name    = 'PSScriptAnalyzer'
            Version = 'latest'
        }

        PSModule 'VMware.PowerCLI'
        {
            Name    = 'VMware.PowerCLI'
            Version = 'latest'
        }

        PSModule 'DemoTools'
        {
            Name       = 'DemoTools'
            Version    = 'latest'
            Repository = 'Demo'
        }
    }
}

# Compile configuration
Default -OutputPath "$PSScriptRoot\Default"

# Invoke the DSC configuration
Start-DscConfiguration -Path "$PSScriptRoot\Default" -Wait -Force -Verbose -WhatIf
