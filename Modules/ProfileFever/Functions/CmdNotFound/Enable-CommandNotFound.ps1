<#
    .SYNOPSIS
        Enable the command not found actions.
#>
function Enable-CommandNotFound
{
    [CmdletBinding()]
    param ()

    Register-CommandNotFound

    $Script:CommandNotFoundEnabled = $true
}
