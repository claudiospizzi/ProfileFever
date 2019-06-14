<#
    .SYNOPSIS
        Disable the command not found actions.
#>
function Disable-CommandNotFound
{
    [CmdletBinding()]
    param ()

    $Script:CommandNotFoundEnabled = $false
}
