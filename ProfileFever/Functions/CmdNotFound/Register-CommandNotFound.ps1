<#
    .SYNOPSIS
        Register the command not found action callback.
#>
function Register-CommandNotFound
{
    [CmdletBinding()]
    param ()

    $Global:ExecutionContext.InvokeCommand.CommandNotFoundAction = {
        param ($CommandName, $CommandLookupEventArgs)

        if ($Script:CommandNotFoundEnabled)
        {
            # Option 1: PS Remoting
            $launcherPSRemoting = @(Get-LauncherPSRemoting -Name $CommandName)
            if ($launcherPSRemoting.Count -eq 1)
            {
                $CommandLookupEventArgs.StopSearch = $true
                $CommandLookupEventArgs.CommandScriptBlock = {
                    Invoke-LauncherPSRemoting -Name $CommandName
                }.GetNewClosure()
                return
            }

            # Option 2: SSH Remote
            $launcherSSHRemote = @(Get-LauncherSSHRemote -Name $CommandName)
            if ($launcherSSHRemote.Count -eq 1)
            {
                $CommandLookupEventArgs.StopSearch = $true
                $CommandLookupEventArgs.CommandScriptBlock = {
                    Invoke-LauncherSSHRemote -Name $CommandName
                }.GetNewClosure()
                return
            }

            # Option 3: SQL Server
            $launcherSqlServer = @(Get-LauncherSqlServer -Name $CommandName)
            if ($launcherSqlServer.Count -eq 1)
            {
                $CommandLookupEventArgs.StopSearch = $true
                $CommandLookupEventArgs.CommandScriptBlock = {
                    Invoke-LauncherSqlServer-Name $CommandName
                }.GetNewClosure()
                return
            }
        }
    }
}
