<#
    .SYNOPSIS
        Unregister the PowerShell Remoting connection from the profile.

    .DESCRIPTION
        This command will remove the stored PowerShell Remoting connection from
        the PSRemoting.json file stored in the users AppData folder.
#>
function Unregister-ProfilePSRemoting
{
    [CmdletBinding()]
    param
    (
        # Name to identify the PowerShell Remoting connection.
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Name
    )

    process
    {
        $object = Get-ProfileObject -Type 'PSRemoting' -Name $Name

        if ($null -ne $object)
        {
            if (-not [System.String]::IsNullOrEmpty($object.Object.Credential))
            {
                Get-VaultEntry -TargetName "PowerShell ProfileFever PSRemoting $Name" | Remove-VaultEntry -Force
            }

            Unregister-ProfileObject -Type 'PSRemoting' -Name $Name
        }
    }
}
