<#
    .SYNOPSIS
        Get the registered command not found actions.
#>
function Get-CommandNotFoundAction
{
    [CmdletBinding()]
    param ()

    $Script:CommandNotFoundAction.Values
}
