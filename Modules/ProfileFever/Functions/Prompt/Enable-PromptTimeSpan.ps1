<#
    .SYNOPSIS
        Enable the prompt timestamp output.
#>
function Enable-PromptTimeSpan
{
    [CmdletBinding()]
    [Alias('etimespan')]
    param ()

    Remove-Variable -Scope Script -Name PromptTimeSpan -ErrorAction SilentlyContinue -Force
    New-Variable -Scope Script -Option ReadOnly -Name PromptTimeSpan -Value $true -Force
}
