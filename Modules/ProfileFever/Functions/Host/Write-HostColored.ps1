<#
    .SYNOPSIS
        Write to the host with RGB colors.

    .DESCRIPTION
        Use the ANSI escape sequence to use the full RGB colors writing text to
        the host. The foreground and background can be specified as RGB.

    .PARAMETER Message
        The message to show colored.

    .PARAMETER ForegroundColor
        Set the foreground color as RGB.

    .PARAMETER BackgroundColor
        Set the background color as RGB.

    .PARAMETER NoNewLine
        Switch to pervent a newline at the end of the message.

    .PARAMETER PassThru
        Return the string to the output stream instead of writing it to the
        console host.
#>
function Write-HostColored
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Message,

        [Parameter(Mandatory = $false)]
        [switch]
        $Bold,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0,255)]
        [ValidateCount(3,3)]
        [System.Int32[]]
        $ForegroundColor,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0,255)]
        [ValidateCount(3,3)]
        [System.Int32[]]
        $BackgroundColor,

        [Parameter(Mandatory = $false)]
        [switch]
        $NoNewLine,

        [Parameter(Mandatory = $false)]
        [switch]
        $PassThru
    )

    $ansiEscape = [System.Char] 27

    $output = [System.Text.StringBuilder]::new()


    if ($PSBoundParameters.ContainsKey('ForegroundColor'))
    {
        $output.AppendFormat("$ansiEscape[38;2;{0};{1};{2}m", $ForegroundColor[0], $ForegroundColor[1], $ForegroundColor[2]) | Out-Null
    }

    if ($PSBoundParameters.ContainsKey('BackgroundColor'))
    {
        $output.AppendFormat("$ansiEscape[48;2;{0};{1};{2}m", $BackgroundColor[0], $BackgroundColor[1], $BackgroundColor[2]) | Out-Null
    }

    if ($Bold.IsPresent)
    {
        $output.Append("$ansiEscape[1m") | Out-Null
    }

    $output.Append($Message) | Out-Null

    if ($Bold.IsPresent)
    {
        $output.Append("$ansiEscape[0m") | Out-Null
    }

    if ($PSBoundParameters.ContainsKey('BackgroundColor'))
    {
        $output.Append("$ansiEscape[0m") | Out-Null
    }

    if ($PSBoundParameters.ContainsKey('ForegroundColor'))
    {
        $output.Append("$ansiEscape[0m") | Out-Null
    }

    if (-not $NoNewLine.IsPresent)
    {
        $output.AppendLine('') | Out-Null
    }

    if ($PassThru.IsPresent)
    {
        Write-Output $output.ToString()
    }
    else
    {
        Write-Host $output.ToString() -NoNewline
    }
}
