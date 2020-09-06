<#
    .SYNOPSIS
        Connect to a SQL Server by using a registered connection.

    .DESCRIPTION
        Use the SQL Server connections registered in the profile launcher to
        connect to the SQL Server.

    .EXAMPLE
        PS C:\> sql
        If not connected, list all available SQL Server connections. Else return
        the active connection.

    .EXAMPLE
        PS C:\> sql srv01
        Connect to the SQL Server by using the demo SQL Server connection.

    .EXAMPLE
        PS C:\> sql srv01 -Disconnect
        Disconnect from the SQL Server.
#>
function Invoke-LauncherSqlServer
{
    [CmdletBinding(DefaultParameterSetName = 'Show')]
    [Alias('sql')]
    param
    (
        # Name of the SQL Server to connect.
        [Parameter(Mandatory = $true, ParameterSetName = 'Connect', Position = 0)]
        [System.String]
        $Name,

        # Flag to disconnect.
        [Parameter(Mandatory = $true, ParameterSetName = 'Disconnect')]
        [Switch]
        $Disconnect
    )

    $ErrorActionPreference = 'Stop'

    if ($PSCmdlet.ParameterSetName -eq 'Show')
    {
        if ($null -eq $Script:LauncherSqlServer)
        {
            # Show all registered SQL Server connections. This may help to
            # choose the correct connection.

            Get-LauncherSqlServer
        }
        else
        {
            # Get the current connection.

            $Script:LauncherSqlServer
        }
    }

    if ($PSCmdlet.ParameterSetName -eq 'Connect')
    {
        $launcherSqlServer = @(Get-LauncherSqlServer -Name $Name)

        if ($null -eq $launcherSqlServer)
        {
            Write-Error "SQL Server connection named '$Name' not found."
        }
        elseif ($launcherSqlServer.Count -gt 1)
        {
            $launcherSqlServer | ForEach-Object { Write-Host "[Launcher] SQL Server target found: $($_.Name)" -ForegroundColor 'DarkYellow' }
            Write-Error "Multiple SQL Server connections found. Be more specific."
        }
        else
        {
            # Connect to the SQL Server with an SQL login or with integrated
            # authentication. Only if the query test was successful, store the
            # connection in the profile context.

            if ([System.String]::IsNullOrEmpty($launcherSqlServer.SqlCredential))
            {
                Write-Host "[Launcher] Connect to the SQL Server '$($launcherSqlServer.SqlInstance)' with integrated authentication ..." -ForegroundColor 'DarkYellow'

                $result = Test-SqlConnection -SqlInstance $launcherSqlServer.SqlInstance

                $Global:PSDefaultParameterValues['*-Dba*:SqlInstance'] = $launcherSqlServer.SqlInstance
                $Global:PSDefaultParameterValues.Remove('*-Dba*:SqlCredential')

                $Global:PSDefaultParameterValues['*-Sql*:ServerInstance'] = $launcherSqlServer.SqlInstance
                $Global:PSDefaultParameterValues.Remove('*-Sql*:Credential')

                $Global:PSDefaultParameterValues['Test-SqlConnection:SqlInstance'] = $launcherSqlServer.SqlInstance
                $Global:PSDefaultParameterValues.Remove('Test-SqlConnection:SqlCredential')

                $Script:LauncherSqlServer = [PSCustomObject] @{
                    PSTypeName    = 'ProfileFever.Launcher.SqlServer.Session'
                    SqlInstance   = $launcherSqlServer.SqlInstance
                    SqlCredential = ''
                    StartTime     = $result.StartDate
                    Server        = $result.Server
                    Version       = $result.Version
                }

                return $Script:LauncherSqlServer
            }
            else
            {
                $sqlCredential = Get-VaultCredential -TargetName $launcherSqlServer.SqlCredential

                Write-Host "[Launcher] Connect to the SQL Server '$($launcherSqlServer.SqlInstance)' as '$($sqlCredential.Username)' ..." -ForegroundColor 'DarkYellow'

                $result = Test-SqlConnection -SqlInstance $launcherSqlServer.SqlInstance -SqlCredential $sqlCredential

                $Global:PSDefaultParameterValues['*-Dba*:SqlInstance'] = $launcherSqlServer.SqlInstance
                $Global:PSDefaultParameterValues['*-Dba*:SqlCredential'] = $sqlCredential

                $Global:PSDefaultParameterValues['*-Sql*:ServerInstance'] = $launcherSqlServer.SqlInstance
                $Global:PSDefaultParameterValues['*-Sql*:Credential'] = $sqlCredential

                $Global:PSDefaultParameterValues['Test-SqlConnection:SqlInstance'] = $launcherSqlServer.SqlInstance
                $Global:PSDefaultParameterValues['Test-SqlConnection:SqlCredential'] = $sqlCredential

                $Script:LauncherSqlServer = [PSCustomObject] @{
                    PSTypeName    = 'ProfileFever.Launcher.SqlServer.Session'
                    SqlInstance   = $launcherSqlServer.SqlInstance
                    SqlCredential = $sqlCredential.Username
                    StartTime     = $result.StartDate
                    Server        = $result.Server
                    Version       = $result.Version
                }

                return $Script:LauncherSqlServer
            }
        }
    }

    if ($PSCmdlet.ParameterSetName -eq 'Disconnect')
    {
        if ($null -ne $Script:LauncherSqlServer)
        {
            # Disconnect from the SQL Server connection by cleaning the default
            # parameter values for the dbatools cmdlets.

            Write-Host "[Launcher] Disconnect from the SQL Server '$($Script:LauncherSqlServer.SqlInstance)' ..." -ForegroundColor 'DarkYellow'

            $Global:PSDefaultParameterValues.Remove('*-Dba*:SqlInstance')
            $Global:PSDefaultParameterValues.Remove('*-Dba*:SqlCredential')

            $Global:PSDefaultParameterValues.Remove('*-Sql*:ServerInstance')
            $Global:PSDefaultParameterValues.Remove('*-Sql*:Credential')

            $Global:PSDefaultParameterValues.Remove('Test-SqlConnection:SqlInstance')
            $Global:PSDefaultParameterValues.Remove('Test-SqlConnection:SqlCredential')

            $Script:LauncherSqlServer = $null
        }
    }
}

# Register the argument completer for the Name parameter
Register-ArgumentCompleter -CommandName 'Invoke-LauncherSqlServer' -ParameterName 'Name' -ScriptBlock {
    param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-LauncherSqlServer -Name "$wordToComplete*" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.SqlInstance)
    }
}
