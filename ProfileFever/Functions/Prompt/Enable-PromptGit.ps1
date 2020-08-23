<#
    .SYNOPSIS
        Enable the git repository status in the prompt.
#>
function Enable-PromptGit
{
    [CmdletBinding()]
    [Alias('egit')]
    param ()

    Remove-Variable -Scope Script -Name PromptGit -ErrorAction SilentlyContinue -Force
    New-Variable -Scope Script -Option ReadOnly -Name PromptGit -Value $true -Force
}
