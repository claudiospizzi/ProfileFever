<#
    .SYNOPSIS
        Enable the prompt alias recommendation output after each command.
#>
function Enable-PromptAlias
{
    [CmdletBinding()]
    [Alias('ealias')]
    param ()

    Remove-Variable -Scope Script -Name PromptAlias -ErrorAction SilentlyContinue -Force
    New-Variable -Scope Script -Option ReadOnly -Name PromptAlias -Value $true -Force
}
