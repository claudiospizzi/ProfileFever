<#
    .SYNOPSIS
        Unregister the PowerShell Remoting connection from the profile launcher.

    .DESCRIPTION
        This command will remove the stored PowerShell Remoting connection from
        the PSRemoting.json file stored in the users AppData folder.
#>
function Unregister-LauncherPSRemoting
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
        $object = Get-LauncherObject -Type 'PSRemoting' -Name $Name

        if ($null -ne $object)
        {
            if (-not [System.String]::IsNullOrEmpty($object.Object.Credential))
            {
                Get-VaultEntry -TargetName $object.Object.Credential | Remove-VaultEntry -Force
            }

            Unregister-LauncherObject -Type 'PSRemoting' -Name $Name
        }
    }
}
