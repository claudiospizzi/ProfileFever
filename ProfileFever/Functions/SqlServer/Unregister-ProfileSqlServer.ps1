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
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    Unregister-ProfileObject -Type 'SqlServer' -Name $Name
}
