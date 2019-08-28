<#
    .SYNOPSIS
        Enable the verbose output stream for the global shell.
#>
function Enable-Verbose
{
    [CmdletBinding()]
    [Alias('ev')]
    param ()

    Set-Variable -Scope 'Global' -Name 'VerbosePreference' -Value 'Continue'
}
