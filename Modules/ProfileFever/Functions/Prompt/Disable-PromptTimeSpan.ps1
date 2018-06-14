<#
    .SYNOPSIS
        Disable the prompt timestamp output.
#>
function Disable-PromptTimeSpan
{
    [CmdletBinding()]
    [Alias('dtimespan')]
    param ()

    Remove-Variable -Scope Script -Name PromptTimeSpan -ErrorAction SilentlyContinue -Force
    New-Variable -Scope Script -Option ReadOnly -Name PromptTimeSpan -Value $false -Force
}
