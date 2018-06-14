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
        $duration = ($history.EndExecutionTime - $history.StartExecutionTime).ToString('\ \ \ h\:mm\:ss\.ffff')

        # Move cursor one up and to the right to show the execution time.
        $position = $Host.UI.RawUI.CursorPosition
        $position.Y = $position.Y - 1
        $position.X = $Host.UI.RawUI.WindowSize.Width - $duration.Length
        $Host.UI.RawUI.CursorPosition = $position

        $Host.UI.Write('Gray', $Host.UI.RawUI.BackgroundColor, $duration)
    }
}
