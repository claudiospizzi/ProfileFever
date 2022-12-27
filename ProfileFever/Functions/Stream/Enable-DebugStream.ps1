<#
    .SYNOPSIS
        Enable the debug stream.

    .DESCRIPTION
        This command will update the global DebugPreference to the value
        Continue which will show the debug stream on the console host.

    .EXAMPLE
        PS C:\> Enable-DebugStream
        Enable the debug stream.

    .LINK
        https://github.com/claudiospizzi/ProfileFever
#>
function Enable-DebugStream
{
    [CmdletBinding()]
    [Alias('ed')]
    param ()

    try
    {
        Set-Variable -Scope 'Global' -Name 'DebugPreference' -Value 'Continue'
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
