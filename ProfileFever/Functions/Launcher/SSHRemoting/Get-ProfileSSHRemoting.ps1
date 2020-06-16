<#
    .SYNOPSIS
        Get all SSH remote connections from the profile.

    .DESCRIPTION
        By registering an SSH remote connection, the connection then can be used
        with the Invoke-ProfileSSHRemote (alias ssh) to connect to the desired
        remote system with SSH remote.
#>
function Get-ProfileSSHRemote
{
    [CmdletBinding()]
    param
    (
        # Name to filter the SSH remote connection. Supports wildcards. If not
        # specified or the name is an empty string, all SSH remote connections
        # are returned.
        [Parameter(Mandatory = $false)]
        [SupportsWildcards()]
        [AllowEmptyString()]
        [System.String]
        $Name,

        # Optional filter by tags. Don't use wildcards. If any tag was found,
        # the SSH remote connection will match the filter.
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [System.String[]]
        $Tag
    )

    $objects = Get-ProfileObject -Type 'SSHRemote' -Name $Name -Tag $Tag

    foreach ($object in $objects)
    {
        [PSCustomObject] @{
            PSTypeName   = 'ProfileFever.SSHRemote.Definition'
            Name         = $object.Name
            Tag          = $object.Tag
            ComputerName = $object.Object.HostName
            Username     = $object.Object.Username
            Credential   = $object.Object.Credential
        }
    }
}
