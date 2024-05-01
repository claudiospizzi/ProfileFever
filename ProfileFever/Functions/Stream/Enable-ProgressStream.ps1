<#
    .SYNOPSIS
        Enable the progress stream.

    .DESCRIPTION
        This command will update the global ProgressPreference to the value
        Continue which will show the progress stream on the console host.

    .EXAMPLE
        PS C:\> Enable-ProgressStream
        Enable the progress stream.

    .LINK
        https://github.com/claudiospizzi/ProfileFever
#>
function Enable-ProgressStream
{
    [CmdletBinding()]
    [Alias('ep')]
    param ()

    try
    {
        Set-Variable -Scope 'Global' -Name 'ProgressPreference' -Value 'Continue'
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
