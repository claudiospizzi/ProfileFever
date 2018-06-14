<#
    .SYNOPSIS
        Enable the custom prompt by replacing the default prompt.
#>
function Enable-Prompt
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalFunctions', '')]
    param ()

    function Global:Prompt
    {
        if ($Script:PromptHistory -ne $MyInvocation.HistoryId)
        {
            $Script:PromptHistory = $MyInvocation.HistoryId

            if ($Script:PromptAlias) { Show-PromptAliasSuggestion }
            if ($Script:PromptTimeSpan) { Show-PromptLastCommandDuration }
        }

        $Host.UI.Write($Script:PromptColor, $Host.UI.RawUI.BackgroundColor, '[{0:dd MMM HH:mm}]' -f [DateTime]::Now)
        $Host.UI.Write(" $($ExecutionContext.SessionState.Path.CurrentLocation)")
        if ($Script:PromptGit) { Write-VcsStatus }
        return "`n$($MyInvocation.HistoryId.ToString().PadLeft(3, '0'))$('>' * ($NestedPromptLevel + 1)) "
    }
}
