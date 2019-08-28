<#
    .SYNOPSIS
        Enable the information output stream for the global shell.
#>
function Enable-Information
{
    [CmdletBinding()]
    [Alias('ei')]
    param ()

    Set-Variable -Scope 'Global' -Name 'InformationPreference' -Value 'Continue'
}
