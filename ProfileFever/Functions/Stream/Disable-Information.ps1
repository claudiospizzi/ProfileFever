<#
    .SYNOPSIS
        Disable the information output stream for the global shell.
#>
function Disable-Information
{
    [CmdletBinding()]
    [Alias('di')]
    param ()

    Set-Variable -Scope 'Global' -Name 'InformationPreference' -Value 'SilentlyContinue'
}
