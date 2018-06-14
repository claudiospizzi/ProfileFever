<#
    .SYNOPSIS
        Unregister the command not found action callback.
#>
function Disable-CommandNotFoundAction
{
    [CmdletBinding()]
    param ()

    $Global:ExecutionContext.InvokeCommand.CommandNotFoundAction = $null
}
