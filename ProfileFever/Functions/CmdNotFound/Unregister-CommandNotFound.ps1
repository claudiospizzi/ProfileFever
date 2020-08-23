<#
    .SYNOPSIS
        Unregister the command not found action callback.
#>
function Unregister-CommandNotFound
{
    [CmdletBinding()]
    param ()

    $Global:ExecutionContext.InvokeCommand.CommandNotFoundAction = $null
}
