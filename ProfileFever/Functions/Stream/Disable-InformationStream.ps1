<#
    .SYNOPSIS
        Disable the information stream.

    .DESCRIPTION
        This command will update the global InformationPreference to the value
        SilentlyContinue which will hide the information stream on the console
        host.

    .EXAMPLE
        PS C:\> Disable-InformationStream
        Disable the information stream.

    .LINK
        https://github.com/claudiospizzi/ProfileFever
#>
function Disable-InformationStream
{
    [CmdletBinding()]
    [Alias('di')]
    param ()

    try
    {
        Set-Variable -Scope 'Global' -Name 'InformationPreference' -Value 'SilentlyContinue'
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
