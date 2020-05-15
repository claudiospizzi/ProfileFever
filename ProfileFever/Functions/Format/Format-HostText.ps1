<#
    .SYNOPSIS
        Format the text with RGB colors and weight.

    .DESCRIPTION
        Use the ANSI escape sequence to use the full RGB colors formatting the
        text. The foreground and background can be specified as RGB. The font
        can be specified as bold

    .PARAMETER Message
        The message to format.

    .PARAMETER ForegroundColor
        Set the foreground color as RGB.

    .PARAMETER BackgroundColor
        Set the background color as RGB.

    .PARAMETER Bold
        Show the text in bold font.
#>
function Format-HostText
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [System.Text.StringBuilder]
        $StringBuilder,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $Message,

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
        $Bold
    )

    $ansiEscape = [System.Char] 27

    # If no string build object was passed, create a new one
    if (-not $PSBoundParameters.ContainsKey('StringBuilder'))
    {
        $StringBuilder = [System.Text.StringBuilder]::new()
    }

    # Foreground Color Prefix
    if ($PSBoundParameters.ContainsKey('ForegroundColor'))
    {
        $StringBuilder.AppendFormat("$ansiEscape[38;2;{0};{1};{2}m", $ForegroundColor[0], $ForegroundColor[1], $ForegroundColor[2]) | Out-Null
    }

    # Background Color Prefix
    if ($PSBoundParameters.ContainsKey('BackgroundColor'))
    {
        $StringBuilder.AppendFormat("$ansiEscape[48;2;{0};{1};{2}m", $BackgroundColor[0], $BackgroundColor[1], $BackgroundColor[2]) | Out-Null
    }

    # Bold Prefix
    if ($Bold.IsPresent)
    {
        $StringBuilder.Append("$ansiEscape[1m") | Out-Null
    }

    $StringBuilder.Append($Message) | Out-Null

    # Bold Suffix
    if ($Bold.IsPresent)
    {
        $StringBuilder.Append("$ansiEscape[0m") | Out-Null
    }

    # Background Color Suffix
    if ($PSBoundParameters.ContainsKey('BackgroundColor'))
    {
        $StringBuilder.Append("$ansiEscape[0m") | Out-Null
    }

    # Foreground Color Suffix
    if ($PSBoundParameters.ContainsKey('ForegroundColor'))
    {
        $StringBuilder.Append("$ansiEscape[0m") | Out-Null
    }

    if (-not $PSBoundParameters.ContainsKey('StringBuilder'))
    {
        return $StringBuilder.ToString()
    }
}
