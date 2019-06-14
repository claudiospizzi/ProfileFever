<#
    .SYNOPSIS
        Enable the smart insert/delete.

    .DESCRIPTION
        The next four key handlers are designed to make entering matched quotes
        parens, and braces a nicer experience. I'd like to include functions in
        the module that do this, but this implementation still isn't as smart as
        ReSharper, so I'm just providing it as a sample.

    .LINK
        https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1
#>
function Enable-PSReadLineSmartInsertDelete
{
    [CmdletBinding()]
    param ()

    $smartInsertQuoteSplat = @{
        Key              = '"',"'"
        BriefDescription = 'SmartInsertQuote'
        LongDescription  = 'Insert paired quotes if not already on a quote'
        ScriptBlock      = {

            param($key, $arg)

            $quote = $key.KeyChar

            $selectionStart = $null
            $selectionLength = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

            $line = $null
            $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

            # If text is selected, just quote it without any smarts
            if ($selectionStart -ne -1)
            {
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $quote + $line.SubString($selectionStart, $selectionLength) + $quote)
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
                return
            }

            $ast = $null
            $tokens = $null
            $parseErrors = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseErrors, [ref]$null)

            function FindToken
            {
                param($tokens, $cursor)

                foreach ($token in $tokens)
                {
                    if ($cursor -lt $token.Extent.StartOffset) { continue }
                    if ($cursor -lt $token.Extent.EndOffset) {
                        $result = $token
                        $token = $token -as [StringExpandableToken]
                        if ($token) {
                            $nested = FindToken $token.NestedTokens $cursor
                            if ($nested) { $result = $nested }
                        }

                        return $result
                    }
                }
                return $null
            }

            $token = FindToken $tokens $cursor

            # If we're on or inside a **quoted** string token (so not generic), we need to be smarter
            if ($token -is [StringToken] -and $token.Kind -ne [TokenKind]::Generic) {
                # If we're at the start of the string, assume we're inserting a new string
                if ($token.Extent.StartOffset -eq $cursor) {
                    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote ")
                    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
                    return
                }

                # If we're at the end of the string, move over the closing quote if present.
                if ($token.Extent.EndOffset -eq ($cursor + 1) -and $line[$cursor] -eq $quote) {
                    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
                    return
                }
            }

            if ($null -eq $token) {
                if ($line[0..$cursor].Where{$_ -eq $quote}.Count % 2 -eq 1) {
                    # Odd number of quotes before the cursor, insert a single quote
                    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
                }
                else {
                    # Insert matching quotes, move cursor to be in between the quotes
                    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote")
                    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
                }
                return
            }

            if ($token.Extent.StartOffset -eq $cursor) {
                if ($token.Kind -eq [TokenKind]::Generic -or $token.Kind -eq [TokenKind]::Identifier) {
                    $end = $token.Extent.EndOffset
                    $len = $end - $cursor
                    [Microsoft.PowerShell.PSConsoleReadLine]::Replace($cursor, $len, $quote + $line.SubString($cursor, $len) + $quote)
                    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($end + 2)
                }
                return
            }

            # We failed to be smart, so just insert a single quote
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
        }
    }
    Set-PSReadLineKeyHandler @smartInsertQuoteSplat

    $insertPairedBracesSplat = @{
        Key              = '(','{','['
        BriefDescription = 'InsertPairedBraces'
        LongDescription  = 'Insert matching braces'
        ScriptBlock      = {

            param($key, $arg)

            $closeChar = switch ($key.KeyChar)
            {
            <#case#> '(' { [char]')'; break }
            <#case#> '{' { [char]'}'; break }
            <#case#> '[' { [char]']'; break }
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
            $line = $null
            $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor - 1)
        }
    }
    Set-PSReadLineKeyHandler @insertPairedBracesSplat

    $smartCloseBracesSplat = @{
        Key              = ')',']','}'
        BriefDescription = 'SmartCloseBraces'
        LongDescription  = 'Insert closing brace or skip'
        ScriptBlock      = {

            param($key, $arg)

            $line = $null
            $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

            if ($line[$cursor] -eq $key.KeyChar)
            {
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
            }
            else
            {
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)")
            }
        }
    }
    Set-PSReadLineKeyHandler @smartCloseBracesSplat

    $backspaceSplat = @{
        Key              = 'Backspace'
        BriefDescription = 'SmartBackspace'
        LongDescription  = 'Delete previous character or matching quotes/parens/braces'
        ScriptBlock      = {

            param($key, $arg)

            $line = $null
            $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

            if ($cursor -gt 0)
            {
                $toMatch = $null
                if ($cursor -lt $line.Length)
                {
                    switch ($line[$cursor])
                    {
                        <#case#> '"' { $toMatch = '"'; break }
                        <#case#> "'" { $toMatch = "'"; break }
                        <#case#> ')' { $toMatch = '('; break }
                        <#case#> ']' { $toMatch = '['; break }
                        <#case#> '}' { $toMatch = '{'; break }
                    }
                }

                if ($null -ne $toMatch -and $line[$cursor-1] -eq $toMatch)
                {
                    [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
                }
                else
                {
                    [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
                }
            }
        }
    }
    Set-PSReadLineKeyHandler @backspaceSplat
}
