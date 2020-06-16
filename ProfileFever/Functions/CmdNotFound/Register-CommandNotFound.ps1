<#
    .SYNOPSIS
        Register the command not found action callback.
#>
function Register-CommandNotFound
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalFunctions', '')]
    param ()

    $Global:ExecutionContext.InvokeCommand.CommandNotFoundAction = {
        param ($CommandName, $CommandLookupEventArgs)

        if ($Script:CommandNotFoundEnabled)
        {
            # Option 1: PS Remoting
            $profilePSRemoting = @(Get-ProfilePSRemoting -Name $CommandName)
            if ($profilePSRemoting.Count -eq 1)
            {
                $CommandLookupEventArgs.StopSearch = $true
                $CommandLookupEventArgs.CommandScriptBlock = {
                    Invoke-ProfilePSRemoting -Name $CommandName
                }.GetNewClosure()
                return
            }

            # Option 2: SSH Remote
            $profileSSHRemote = @(Get-ProfileSSHRemote -Name $CommandName)
            if ($profileSSHRemote.Count -eq 1)
            {
                $CommandLookupEventArgs.StopSearch = $true
                $CommandLookupEventArgs.CommandScriptBlock = {
                    Invoke-ProfileSSHRemote -Name $CommandName
                }.GetNewClosure()
                return
            }

            # Option 3: SQL Server
            $profileSqlServer = @(Get-ProfileSqlServer -Name $CommandName)
            if ($profileSqlServer.Count -eq 1)
            {
                $CommandLookupEventArgs.StopSearch = $true
                $CommandLookupEventArgs.CommandScriptBlock = {
                    Invoke-ProfileSqlServer-Name $CommandName
                }.GetNewClosure()
                return
            }
        }
    }
}
