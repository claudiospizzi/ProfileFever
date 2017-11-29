
Import-Module -Name 'PackageManagement' -Verbose:$false

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $false)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $false)]
        [System.String]
        $Version = 'latest',

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Repository = 'PSGallery'
    )

    # Detect the latest version from the repository
    if ($Version -eq 'latest')
    {
        $Version = Get-LatestModuleVersion -Name $Name -Repository $Repository
    }

    Write-Verbose "Get the current state: Name = $Name, Version = $Version"

    try
    {
        $module = Get-InstalledModule -Name $Name -RequiredVersion $Version -ErrorAction Stop

        # Return the installed module
        return @{
            Ensure     = 'Present'
            Name       = $module.Name
            Version    = $module.Version
            Repository = $module.Repository
        }
    }
    catch
    {
        # No module was found, return absent
        return @{
            Ensure     = 'Absent'
            Name       = $Name
            Version    = $Version
            Repository = ''
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
        [parameter(Mandatory = $false)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $false)]
        [System.String]
        $Version = 'latest',

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Repository = 'PSGallery'
    )

    # Detect the latest version from the repository
    if ($Version -eq 'latest')
    {
        $Version = Get-LatestModuleVersion -Name $Name -Repository $Repository
    }

    $module = Get-TargetResource @PSBoundParameters

    # The module must be present
    if ($Ensure -eq 'Present' -and $module.Ensure -eq 'Absent')
    {
        Write-Verbose "Ensure the module is installed: Name = $Name, Version = $Version"

        # Install the target version
        Install-ModuleVersion -Name $Name -Version $Version -Repository $Repository
    }

    # The module must be absent
    if ($Ensure -eq 'Absent' -and $module.Ensure -eq 'Present')
    {
        Write-Verbose "Ensure the module is not installed: Name = $Name, Version = $Version"

        # Remove the installed module version because it's present
        Uninstall-ModuleVersion -Name $Name -Version $Version
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $false)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $false)]
        [System.String]
        $Version = 'latest',

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Repository = 'PSGallery'
    )

    # Detect the latest version from the repository
    if ($Version -eq 'latest')
    {
        $Version = Get-LatestModuleVersion -Name $Name -Repository $Repository
    }

    $module = Get-TargetResource @PSBoundParameters

    Write-Verbose "Test the current state: Name = $Name, Version = $Version"

    if ($Ensure -eq 'Present')
    {
        $result = $Ensure -eq $module.Ensure -and
                  $Repository -eq $module.Repository
    }
    else
    {
        $result = $Ensure -eq $module.Ensure
    }

    return $result
}

function Get-LatestModuleVersion($Name, $Repository)
{
    $cachePath = Join-Path -Path $Env:ProgramData -ChildPath 'PowerShell\Modules\ProfileFever'
    $cacheFile = Join-Path -Path $cachePath -ChildPath "$Name.xml"

    # Create the cache path
    if (!(Test-Path -Path $cachePath))
    {
        New-Item -Path $cachePath -ItemType Directory | Out-Null
    }

    # Check for the cache file
    if ((Test-Path -Path $cacheFile))
    {
        $cacheData = Import-Clixml -Path $cacheFile

        if ($cacheData.Timestamp -gt (Get-Date).AddDays(-1))
        {
            Write-Verbose "Cached version found: Timestamp = $($cacheData.Timestamp), Version = $($cacheData.Version)"

            return $cacheData.Version
        }
    }

    Write-Verbose "Detect latest version in $Repository`: Name = $Name"

    $module = Find-Module -Name $Name -Repository $Repository -ErrorAction Stop
    $version = [String] $module.Version

    Write-Verbose "Detect latest version in $Repository`: Name = $Name, Version = $version"

    # Update cache
    [PSCustomObject] @{ Timestamp = [DateTime]::Now; Version = $version } | Export-Clixml -Path $cacheFile

    return $version
}

function Install-ModuleVersion($Name, $Version, $Repository)
{
    Write-Verbose "Install module from $Repository`: Name = $Name, Version = $Version"

    Install-Module -Name $Name -RequiredVersion $Version -Repository $Repository -Force -AllowClobber -SkipPublisherCheck
}

function Uninstall-ModuleVersion($Name, $Version)
{
    Write-Verbose "Uninstall module: Name = $Name, Version = $Version"

    Uninstall-Module -Name $Name -RequiredVersion $Version -Force
}

Export-ModuleMember -Function *-TargetResource
