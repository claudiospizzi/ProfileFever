<#
    .SYNOPSIS
        Get all SSH remoting connections from the profile.

    .DESCRIPTION
        By registering an SSH remoting connection, the connection then can be
        used with the Invoke-ProfileSSHRemoting (alias ssh) to connect to the
        desired remote system with SSH remoting.
#>
function Get-ProfileSSHRemoting
{
    [CmdletBinding()]
    param
    (
        # Name to filter the SSH remoting connection. Supports wildcards. If not
        # specified or the name is an empty string, all SSH remoting connections
        # are returned.
        [Parameter(Mandatory = $false)]
        [SupportsWildcards()]
        [AllowEmptyString()]
        [System.String]
        $Name,

        # Optional filter by tags. Don't use wildcards. If any tag was found,
        # the SSH remoting connection will match the filter.
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [System.String[]]
        $Tag
    )

    $objects = Get-ProfileObject -Type 'SSHRemoting' -Name $Name -Tag $Tag

    foreach ($object in $objects)
    {
        [PSCustomObject] @{
            PSTypeName   = 'ProfileFever.SSHRemoting.Definition'
            Name         = $object.Name
            Tag          = $object.Tag
            ComputerName = $object.Object.HostName
            Username     = $object.Object.Username
            Credential   = $object.Object.Credential
        }
    }
}
