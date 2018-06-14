<#
    .SYNOPSIS
        Set the console host configuration.
#>
function Set-ConsoleConfig
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalFunctions', '')]
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
    if ($PSCmdlet.ShouldProcess('Window and Buffer', 'Change Size'))
    {
        $bufferSize = $Global:Host.UI.RawUI.BufferSize
        $windowSize = $Global:Host.UI.RawUI.WindowSize

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

        $Global:Host.UI.RawUI.BufferSize = $bufferSize
        $Global:Host.UI.RawUI.WindowSize = $windowSize
    }


    # Step 2: Window foreground and background color
    if ($PSCmdlet.ShouldProcess('Color', 'Change Color'))
    {
        if ($PSBoundParameters.ContainsKey('ForegroundColor'))
        {
            $Global:Host.UI.RawUI.ForegroundColor = $ForegroundColor
        }

        if ($PSBoundParameters.ContainsKey('BackgroundColor'))
        {
            $Global:Host.UI.RawUI.BackgroundColor = $BackgroundColor
        }
    }
}
