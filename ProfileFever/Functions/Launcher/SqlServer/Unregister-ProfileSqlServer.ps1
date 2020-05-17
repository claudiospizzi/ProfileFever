<#
    .SYNOPSIS
        Unregister the SQL Server connection from the profile.

    .DESCRIPTION
        This command will remove the stored SQL Server connection from the
        SqlServer.json file stored in the users AppData folder.
#>
function Unregister-ProfileSqlServer
{
    [CmdletBinding()]
    param
    (
        # Name to identify the SQL Server connection.
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Name
    )

    process
    {
        $object = Get-ProfileObject -Type 'SqlServer' -Name $Name

        if ($null -ne $object)
        {
            if (-not [System.String]::IsNullOrEmpty($object.Object.SqlCredential))
            {
                Get-VaultEntry -TargetName "PowerShell ProfileFever SqlServer $Name" | Remove-VaultEntry -Force
            }

            Unregister-ProfileObject -Type 'SqlServer' -Name $Name
        }
    }
}
