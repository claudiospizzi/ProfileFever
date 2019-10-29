<#
    .SYNOPSIS
        Enable the history browser, basic history search and history save.

    .DESCRIPTION
        On Windows PowerShell, use the F7 key to show a grid view with the last
        commands. A command can be selected and inserted to the current cmdline
        position.
        With the up and down arrows, search the history by the currently typed
        characters on the command line.
        Sometimes you enter a command but realize you forgot to do something
        else first. This binding will let you save that command in the history
        so you can recall it, but it doesn't actually execute. It also clears
        the line with RevertLine so the undo stack is reset - though redo will
        still reconstruct the command line.

    .LINK
        https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1
#>
function Enable-PSReadLineHistoryHelper
{
    [CmdletBinding()]
    param ()

    # Basic history searching
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key 'UpArrow' -Function 'HistorySearchBackward'
    Set-PSReadLineKeyHandler -Key 'DownArrow' -Function 'HistorySearchForward'

    # Save current command line to history
    $saveInHistorySplat = @{
        Key              = 'Alt+w'
        BriefDescription = 'SaveInHistory'
        LongDescription  = 'Save current line in history but do not execute'
        ScriptBlock      = {

            param($key, $arg)

            $line = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$null)
            [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        }
    }
    Set-PSReadLineKeyHandler @saveInHistorySplat

    # Show a grid view output
    if ($PSVersionTable.PSEdition -ne 'Core')
    {
        $historySplat = @{
            Key              = 'F7'
            BriefDescription = 'History'
            LongDescription  = 'Show command history'
            ScriptBlock      = {

                $pattern = $null
                [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$pattern, [ref]$null)
                if ($pattern)
                {
                    $pattern = [regex]::Escape($pattern)
                }

                $history = [System.Collections.ArrayList] @(
                    $last = ''
                    $lines = ''
                    foreach ($line in [System.IO.File]::ReadLines((Get-PSReadLineOption).HistorySavePath))
                    {
                        if ($line.EndsWith('`'))
                        {
                            $line = $line.Substring(0, $line.Length - 1)
                            $lines = if ($lines)
                            {
                                "$lines`n$line"
                            }
                            else
                            {
                                $line
                            }
                            continue
                        }

                        if ($lines)
                        {
                            $line = "$lines`n$line"
                            $lines = ''
                        }

                        if (($line -cne $last) -and (!$pattern -or ($line -match $pattern)))
                        {
                            $last = $line
                            $line
                        }
                    }
                )
                $history.Reverse()

                $command = $history | Out-GridView -Title 'History' -PassThru
                if ($command)
                {
                    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
                    [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($command -join "`n"))
                }
            }
        }
        Set-PSReadLineKeyHandler @historySplat
    }
}
