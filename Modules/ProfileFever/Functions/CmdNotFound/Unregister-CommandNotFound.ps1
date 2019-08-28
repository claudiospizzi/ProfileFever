<#
    .SYNOPSIS
        Unregister the command not found action callback.
#>
function Unregister-CommandNotFound
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalFunctions', '')]
    param ()

    $Global:ExecutionContext.InvokeCommand.CommandNotFoundAction = $null
}
