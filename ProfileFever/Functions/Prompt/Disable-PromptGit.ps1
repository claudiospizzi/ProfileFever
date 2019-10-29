<#
    .SYNOPSIS
        Disable the git repository status in the prompt.
#>
function Disable-PromptGit
{
    [CmdletBinding()]
    [Alias('dgit')]
    param ()

    Remove-Variable -Scope Script -Name PromptGit -ErrorAction SilentlyContinue -Force
    New-Variable -Scope Script -Option ReadOnly -Name PromptGit -Value $false -Force
}
