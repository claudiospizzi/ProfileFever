<#
    .SYNOPSIS
        Disable the verbose stream.

    .DESCRIPTION
        This command will update the global VerbosePreference to the value
        SilentlyContinue which will hide the verbose stream on the console host.

    .EXAMPLE
        PS C:\> Disable-VerboseStream
        Disable the verbose stream.

    .LINK
        https://github.com/claudiospizzi/ProfileFever
#>
function Disable-VerboseStream
{
    [CmdletBinding()]
    [Alias('dv')]
    param ()

    try
    {
        Set-Variable -Scope 'Global' -Name 'VerbosePreference' -Value 'SilentlyContinue'
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
