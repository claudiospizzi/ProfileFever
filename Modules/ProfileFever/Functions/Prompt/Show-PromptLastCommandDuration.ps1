<#
    .SYNOPSIS
        Show the during of the last executed command.
#>
function Show-PromptLastCommandDuration
{
    [CmdletBinding()]
    param ()

    if ($MyInvocation.HistoryId -gt 1 -and $Host.UI.RawUI.CursorPosition.Y -gt 0)
    {
        $history  = Get-History -Id ($MyInvocation.HistoryId - 1)
        $duration = "{0:0.00}" -f ($history.EndExecutionTime - $history.StartExecutionTime).TotalSeconds

        # Move cursor one up and to the right to show the execution time
        $position = $Host.UI.RawUI.CursorPosition
        $position.Y = $position.Y - 1
        $position.X = $Host.UI.RawUI.WindowSize.Width - $duration.Length - 1
        $Host.UI.RawUI.CursorPosition = $position

        $Host.UI.WriteLine('Gray', $Host.UI.RawUI.BackgroundColor, $duration)
    }
}
