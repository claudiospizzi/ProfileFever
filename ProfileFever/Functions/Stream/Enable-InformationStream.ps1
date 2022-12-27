<#
    .SYNOPSIS
        Enable the information stream.

    .DESCRIPTION
        This command will update the global InformationPreference to the value
        Continue which will show the information stream on the console host.

    .EXAMPLE
        PS C:\> Enable-InformationStream
        Enable the information stream.

    .LINK
        https://github.com/claudiospizzi/ProfileFever
#>
function Enable-InformationStream
{
    [CmdletBinding()]
    [Alias('ei')]
    param ()

    try
    {
        Set-Variable -Scope 'Global' -Name 'InformationPreference' -Value 'Continue'
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
