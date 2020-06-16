<#
    .SYNOPSIS
        Format the text with RGB colors and weight.

    .DESCRIPTION
        Use the ANSI escape sequence to use the full RGB colors formatting the
        text. The foreground and background can be specified as RGB. The font
        can be specified as bold
#>
function Format-HostText
{
    [CmdletBinding()]
    param
    (
        # Optional string builder. If specified, the text will be appended to
        # the existing string builer. Else returned as string.
        [Parameter(Mandatory = $false)]
        [System.Text.StringBuilder]
        $StringBuilder,

        # The message to format.
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $Message,

        # Set the foreground color as RGB with an ANSI escape sequence.
        [Parameter(Mandatory = $false)]
        [ValidateRange(0,255)]
        [ValidateCount(3,3)]
        [System.Int32[]]
        $ForegroundColor,

        # Set the background color as RGB with an ANSI escape sequence.
        [Parameter(Mandatory = $false)]
        [ValidateRange(0,255)]
        [ValidateCount(3,3)]
        [System.Int32[]]
        $BackgroundColor,

        # Show the text in bold font.
        [Parameter(Mandatory = $false)]
        [Switch]
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
