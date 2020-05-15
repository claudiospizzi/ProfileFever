<#
    .SYNOPSIS
        Show the during of the last executed command.

    .DESCRIPTION
        Use the $MyInvocation variable and the Get-History to get the last
        executed command and calculate the execution duration.
#>
function Show-PromptLastCommandDuration
{
    [CmdletBinding()]
    param ()

    if ($MyInvocation.HistoryId -gt 1 -and $Host.UI.RawUI.CursorPosition.Y -gt 0)
    {
        $clock    = '' # [char] 9201
        $history  = Get-History -Id ($MyInvocation.HistoryId - 1)
        $duration = " {0} {1:0.000}s`r" -f $clock, ($history.EndExecutionTime - $history.StartExecutionTime).TotalSeconds

        # Move cursor to the right to show the execution time
        $position = $Host.UI.RawUI.CursorPosition
        $position.X = $Host.UI.RawUI.WindowSize.Width - $duration.Length - 2
        $Host.UI.RawUI.CursorPosition = $position

        $Host.UI.Write('Gray', $Host.UI.RawUI.BackgroundColor, $duration)

        # Move cursor back
        $position = $Host.UI.RawUI.CursorPosition
        $position.X = 0
        $Host.UI.RawUI.CursorPosition = $position
    }
}
