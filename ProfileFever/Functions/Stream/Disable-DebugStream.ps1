<#
    .SYNOPSIS
        Disable the debug stream.

    .DESCRIPTION
        This command will update the global DebugPreference to the value
        SilentlyContinue which will hide the debug stream on the console host.

    .EXAMPLE
        PS C:\> Disable-DebugStream
        Disable the debug stream.

    .LINK
        https://github.com/claudiospizzi/ProfileFever
#>
function Disable-DebugStream
{
    [CmdletBinding()]
    [Alias('dd')]
    param ()

    try
    {
        Set-Variable -Scope 'Global' -Name 'DebugPreference' -Value 'SilentlyContinue'
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
