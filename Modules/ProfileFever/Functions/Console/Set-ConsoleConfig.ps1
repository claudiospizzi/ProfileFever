<#
    .SYNOPSIS
        Set the console host configuration.
#>
function Set-ConsoleConfig
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $WindowWidth,

        [Parameter(Mandatory = $false)]
        [System.Int32]
        $WindowHeight,

        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]
        $ForegroundColor,

        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]
        $BackgroundColor
    )


    # Step 1: Window and buffer size

    $bufferSize = $Host.UI.RawUI.BufferSize
    $windowSize = $Host.UI.RawUI.WindowSize

    $bufferSize.Height = 9999

    if ($PSBoundParameters.ContainsKey('WindowWidth'))
    {
        $bufferSize.Width = $WindowWidth
        $windowSize.Width = $WindowWidth
    }

    if ($PSBoundParameters.ContainsKey('WindowHeight'))
    {
        $windowSize.Height = $WindowHeight
    }

    $Host.UI.RawUI.BufferSize = $bufferSize
    $Host.UI.RawUI.WindowSize = $windowSize


    # Step 2: Window foreground and background color

    if ($PSBoundParameters.ContainsKey('ForegroundColor'))
    {
        $host.ui.RawUI.ForegroundColor = $ForegroundColor
    }

    if ($PSBoundParameters.ContainsKey('BackgroundColor'))
    {
        $host.ui.RawUI.BackgroundColor = $BackgroundColor
    }
}
