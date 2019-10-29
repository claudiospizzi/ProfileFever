<#
    .SYNOPSIS
        Disable the verbose output stream for the global shell.
#>
function Disable-Verbose
{
    [CmdletBinding()]
    [Alias('dv')]
    param ()

    Set-Variable -Scope 'Global' -Name 'VerbosePreference' -Value 'SilentlyContinue'
}