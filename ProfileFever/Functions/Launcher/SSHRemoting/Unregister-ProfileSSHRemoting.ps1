<#
    .SYNOPSIS
        Unregister the SSH remoting connection from the profile.

    .DESCRIPTION
        This command will remove the stored SSH remoting connection from the
        SSHRemoting.json file stored in the users AppData folder.
#>
function Unregister-ProfileSSHRemoting
{
    [CmdletBinding()]
    param
    (
        # Name to identify the SSH remoting connection.
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Name
    )

    process
    {
        $object = Get-ProfileObject -Type 'SSHRemoting' -Name $Name

        if ($null -ne $object)
        {
            if (-not [System.String]::IsNullOrEmpty($object.Object.Credential))
            {
                Get-VaultEntry -TargetName $object.Object.Credential | Remove-VaultEntry -Force
            }

            Unregister-ProfileObject -Type 'SSHRemoting' -Name $Name
        }
    }
}
