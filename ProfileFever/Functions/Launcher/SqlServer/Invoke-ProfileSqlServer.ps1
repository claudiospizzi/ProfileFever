<#
    .SYNOPSIS
        ...

    .DESCRIPTION
        ...
#>
function Invoke-ProfileSqlServer
{
    [CmdletBinding(DefaultParameterSetName = 'Show')]
    [Alias('mssql')]
    param
    (
        # Name of the SQL Server to connect.
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Connect')]
        [System.String]
        $Name,

        # Name of the SQL Server to connect.
        [Parameter(Mandatory = $true, ParameterSetName = 'Disconnect')]
        [Switch]
        $Disconnect
    )

    if ($PSCmdlet.ParameterSetName -eq 'Show')
    {
        if ($null -eq $Script:ProfileSqlServer)
        {
            Write-Warning 'Not connected, return list of all available SQL Server connections...'

            Get-ProfileSqlServer | Write-Output
        }
        else
        {
            Write-Output $Script:ProfileSqlServer
        }
    }

    if ($PSCmdlet.ParameterSetName -eq 'Connect')
    {
        $profileSqlServer = Get-ProfileSqlServer -Name $Name

        if ($null -eq $profileSqlServer)
        {
            throw "SQL Server connection named $Name not found."
        }

        if ($profileSqlServer.Count -gt 1)
        {
            throw "Multiple SQL Server connections found. Be more specific."
        }

        $Script:ProfileSqlServer = $profileSqlServer

        Write-Host "Connect to SQL Server $($Script:ProfileSqlServer.SqlInstance)"

        $Global:PSDefaultParameterValues['*-Dba*:SqlInstance'] = $Script:ProfileSqlServer.SqlInstance
        if (-not [System.String]::IsNullOrEmpty($Script:ProfileSqlServer.SqlCredential))
        {
            $Global:PSDefaultParameterValues['*-Dba*:SqlCredential'] = Get-VaultCredential -TargetName $Script:ProfileSqlServer.SqlCredential
        }
    }

    # Disconnect from the SQL Server by cleaning the default parameter values
    # for the dbatools cmdlets.
    if ($PSCmdlet.ParameterSetName -eq 'Disconnect')
    {
        if ($null -ne $Script:ProfileSqlServer)
        {
            Write-Host "Disconnect the SQL Server $($Script:ProfileSqlServer.SqlInstance)"

            $Script:ProfileSqlServer = $null

            $Global:PSDefaultParameterValues.Remove('*-Dba*:SqlInstance')
            $Global:PSDefaultParameterValues.Remove('*-Dba*:SqlCredential')
        }
    }
}
