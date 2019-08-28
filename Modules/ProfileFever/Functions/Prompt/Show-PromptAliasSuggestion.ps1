<#
    .SYNOPSIS
        Show the alias suggestion for the latest command.

    .DESCRIPTION
        Show a suggestion for the last prompt, all aliases for the used command
        are shown to the user.
#>
function Show-PromptAliasSuggestion
{
    [CmdletBinding()]
    param ()

    if ($MyInvocation.HistoryId -gt 1)
    {
        $history = Get-History -Id ($MyInvocation.HistoryId - 1)
        $reports = @()
        foreach ($alias in (Get-Alias))
        {
            if ($history.CommandLine.IndexOf($alias.ResolvedCommandName, [System.StringComparison]::CurrentCultureIgnoreCase) -ne -1)
            {
                $reports += $alias
            }
        }
        if ($reports.Count -gt 0)
        {
            $report = $reports | Group-Object -Property 'ResolvedCommandName' | ForEach-Object { '  ' + $_.Name + ' => ' + ($_.Group -join ', ') }
            $Host.UI.WriteLine('Magenta', $Host.UI.RawUI.BackgroundColor, "Alias suggestions:`n" + ($report -join "`n"))
        }
    }
}
