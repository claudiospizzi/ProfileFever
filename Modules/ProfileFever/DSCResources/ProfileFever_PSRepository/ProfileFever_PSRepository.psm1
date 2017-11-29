
Import-Module -Name 'PackageManagement' -Verbose:$false

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $false)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $false)]
        [ValidateSet('Trusted', 'Untrusted')]
        [System.String]
        $InstallationPolicy = 'Trusted',

        [parameter(Mandatory = $true)]
        [System.String]
        $SourceLocation,

        [parameter(Mandatory = $false)]
        [System.String]
        $PublishLocation = '',

        [parameter(Mandatory = $false)]
        [System.String]
        $ScriptSourceLocation = '',

        [parameter(Mandatory = $false)]
        [System.String]
        $ScriptPublishLocation = ''
    )

    Write-Verbose "Get the repository state: Name = $Name"

    try
    {
        $repository = Get-PSRepository -Name $Name -ErrorAction Stop

        # Return the detected repository
        return @{
            Name                  = $repository.Name
            Ensure                = 'Present'
            InstallationPolicy    = $repository.InstallationPolicy
            SourceLocation        = $repository.SourceLocation
            PublishLocation       = $repository.PublishLocation
            ScriptSourceLocation  = $repository.ScriptSourceLocation
            ScriptPublishLocation = $repository.ScriptPublishLocation
        }
    }
    catch
    {
        # No repository was found, return absent
        return @{
            Name                  = $Name
            Ensure                = 'Absent'
            InstallationPolicy    = ''
            SourceLocation        = ''
            PublishLocation       = ''
            ScriptSourceLocation  = ''
            ScriptPublishLocation = ''
        }
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    [OutputType([void])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $false)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $false)]
        [ValidateSet('Trusted', 'Untrusted')]
        [System.String]
        $InstallationPolicy = 'Trusted',

        [parameter(Mandatory = $true)]
        [System.String]
        $SourceLocation,

        [parameter(Mandatory = $false)]
        [System.String]
        $PublishLocation = '',

        [parameter(Mandatory = $false)]
        [System.String]
        $ScriptSourceLocation = '',

        [parameter(Mandatory = $false)]
        [System.String]
        $ScriptPublishLocation = ''
    )

    # The repository must be registered
    if ($Ensure -eq 'Present')
    {
        $repository = Get-TargetResource @PSBoundParameters

        # Register the repository, if it's not already
        if ($repository.Ensure -eq 'Absent')
        {
            Write-Verbose "Register the repository: Name = $Name"

            Register-PSRepository -Name $Name -SourceLocation $SourceLocation
        }

        $repository = Get-TargetResource @PSBoundParameters

        # Check each mandatory property and set the value
        if ($InstallationPolicy -ne $repository.InstallationPolicy)
        {
            Set-PSRepository -Name $Name -InstallationPolicy $InstallationPolicy
        }
        if ($SourceLocation -ne $repository.SourceLocation)
        {
            Set-PSRepository -Name $Name -SourceLocation $SourceLocation
        }

        # Check the optional properties only if they were specified
        if (![String]::IsNullOrEmpty($PublishLocation) -and $PublishLocation -ne $repository.PublishLocation)
        {
            Set-PSRepository -Name $Name -PublishLocation $PublishLocation
        }
        if (![String]::IsNullOrEmpty($ScriptSourceLocation) -and $ScriptSourceLocation -ne $repository.ScriptSourceLocation)
        {
            Set-PSRepository -Name $Name -ScriptSourceLocation $ScriptSourceLocation
        }
        if (![String]::IsNullOrEmpty($ScriptPublishLocation) -and $ScriptPublishLocation -ne $repository.ScriptPublishLocation)
        {
            Set-PSRepository -Name $Name -ScriptPublishLocation $ScriptPublishLocation
        }
    }

    # The repository must be unregistered
    if ($Ensure -eq 'Absent')
    {
        $repository = Get-TargetResource @PSBoundParameters

        # Unregister the repository, if it's not already
        if ($repository.Ensure -eq 'Present')
        {
            Write-Verbose "Unregister the repository: Name = $Name"

            Unregister-PSRepository -Name $Name
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $false)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $false)]
        [ValidateSet('Trusted', 'Untrusted')]
        [System.String]
        $InstallationPolicy = 'Trusted',

        [parameter(Mandatory = $true)]
        [System.String]
        $SourceLocation,

        [parameter(Mandatory = $false)]
        [System.String]
        $PublishLocation = '',

        [parameter(Mandatory = $false)]
        [System.String]
        $ScriptSourceLocation = '',

        [parameter(Mandatory = $false)]
        [System.String]
        $ScriptPublishLocation = ''
    )

    $repository = Get-TargetResource @PSBoundParameters

    Write-Verbose "Test the repository state: Name = $Name"

    if ($Ensure -eq 'Present')
    {
        $result = $Ensure -eq $repository.Ensure -and $InstallationPolicy -eq $repository.InstallationPolicy -and $SourceLocation -eq $repository.SourceLocation

        # Check optional parameter only, if specified
        if (![String]::IsNullOrEmpty($PublishLocation))
        {
            $result = $result -and $PublishLocation -eq $repository.PublishLocation
        }
        if (![String]::IsNullOrEmpty($ScriptSourceLocation))
        {
            $result = $result -and $ScriptSourceLocation -eq $repository.ScriptSourceLocation
        }
        if (![String]::IsNullOrEmpty($ScriptPublishLocation))
        {
            $result = $result -and $ScriptPublishLocation -eq $repository.ScriptPublishLocation
        }
    }
    else
    {
        $result = $Ensure -eq $module.Ensure
    }

    return $result
}
