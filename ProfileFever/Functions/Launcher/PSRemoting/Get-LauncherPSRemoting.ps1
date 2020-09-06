<#
    .SYNOPSIS
        Get all PowerShell Remoting connections from the profile launcher.

    .DESCRIPTION
        By registering a PowerShell Remoting connection, the connection then can
        be used with the Invoke-LauncherPSRemoting (alias w) to connect to the
        desired remote system with PowerShell Remoting.
#>
function Get-LauncherPSRemoting
{
    [CmdletBinding()]
    param
    (
        # Name to filter the PowerShell Remoting connection. Supports wildcards.
        # If not specified or the name is an empty string, all PowerShell
        # Remoting connections are returned.
        [Parameter(Mandatory = $false)]
        [SupportsWildcards()]
        [AllowEmptyString()]
        [System.String]
        $Name,

        # Optional filter by tags. Don't use wildcards. If any tag was found,
        # the PowerShell Remoting connection will match the filter.
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [System.String[]]
        $Tag
    )

    $objects = Get-LauncherObject -Type 'PSRemoting' -Name $Name -Tag $Tag

    foreach ($object in $objects)
    {
        [PSCustomObject] @{
            PSTypeName   = 'ProfileFever.Launcher.PSRemoting.Definition'
            Name         = $object.Name
            Tag          = $object.Tag
            ComputerName = $object.Object.ComputerName
            Credential   = $object.Object.Credential
        }
    }
}
