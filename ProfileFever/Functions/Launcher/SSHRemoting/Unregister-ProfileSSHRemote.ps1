<#
    .SYNOPSIS
        Unregister the SSH remote connection from the profile.

    .DESCRIPTION
        This command will remove the stored SSH remote connection from the
        SSHRemote.json file stored in the users AppData folder.
#>
function Unregister-ProfileSSHRemote
{
    [CmdletBinding()]
    param
    (
        # Name to identify the SSH remote connection.
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Name
    )

    process
    {
        $object = Get-ProfileObject -Type 'SSHRemote' -Name $Name

        if ($null -ne $object)
        {
            if (-not [System.String]::IsNullOrEmpty($object.Object.Credential))
            {
                Get-VaultEntry -TargetName $object.Object.Credential | Remove-VaultEntry -Force
            }

            Unregister-ProfileObject -Type 'SSHRemote' -Name $Name
        }
    }
}
