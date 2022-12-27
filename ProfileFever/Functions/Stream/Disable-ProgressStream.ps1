<#
    .SYNOPSIS
        Disable the progress stream.

    .DESCRIPTION
        This command will update the global ProgressPreference to the value
        SilentlyContinue which will hide the progress stream on the console
        host.

    .EXAMPLE
        PS C:\> Disable-ProgressStream
        Disable the progress stream.

    .LINK
        https://github.com/claudiospizzi/ProfileFever
#>
function Disable-ProgressStream
{
    [CmdletBinding()]
    [Alias('di')]
    param ()

    try
    {
        Set-Variable -Scope 'Global' -Name 'ProgressPreference' -Value 'SilentlyContinue'
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
