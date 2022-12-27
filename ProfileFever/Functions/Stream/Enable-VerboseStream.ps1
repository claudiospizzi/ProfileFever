<#
    .SYNOPSIS
        Enable the verbose stream.

    .DESCRIPTION
        This command will update the global VerbosePreference to the value
        Continue which will show the verbose stream on the console host.

    .EXAMPLE
        PS C:\> Enable-VerboseStream
        Enable the verbose stream.

    .LINK
        https://github.com/claudiospizzi/ProfileFever
#>
function Enable-VerboseStream
{
    [CmdletBinding()]
    [Alias('ev')]
    param ()

    try
    {
        Set-Variable -Scope 'Global' -Name 'VerbosePreference' -Value 'Continue'
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
