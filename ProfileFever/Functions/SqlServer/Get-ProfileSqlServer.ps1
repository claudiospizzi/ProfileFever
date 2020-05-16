<#
    .SYNOPSIS
        Get all SQL Server connections from the profile.

    .DESCRIPTION
        By registering a SQL Server connection, the connection then can be used
        with the Invoke-ProfileSqlServer (alias mssql) to connect to the desired
        SQL Server.
#>
function Get-ProfileSqlServer
{
    [CmdletBinding()]
    param
    (
        # Name to identify the SQL Server connection.
        [Parameter(Mandatory = $false)]
        [SupportsWildcards()]
        [System.String]
        $Name
    )

    $path = "$Env:AppData\PowerShell\ProfileFever"
    $file = "$path\SqlServer.json"

    if (Test-Path -Path $file)
    {
        # The content must be read as raw string, to convert it to JSON.
        [System.Object[]] $objects = Get-Content -Path $file -Encoding 'UTF8' -Raw | ConvertFrom-Json

        # If the name was specified, use it as filter.
        if ($PSBoundParameters.ContainsKey('Name'))
        {
            [System.Object[]] $objects = $objects | Where-Object { $_.Name -like $Name }
        }

        foreach ($object in $objects)
        {
            [PSCustomObject] @{
                PSTypeName    = 'ProfileFever.SqlServer'
                Name          = $object.Name
                Tag           = $object.Tag
                SqlInstance   = $object.Object.SqlInstance
                SqlCredential = $object.Object.SqlCredential
            }
        }
    }
}
