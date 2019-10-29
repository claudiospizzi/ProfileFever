<#
    .SYNOPSIS
        Disable the prompt alias recommendation output after each command.
#>
function Disable-PromptAlias
{
    [CmdletBinding()]
    [Alias('dalias')]
    param ()

    Remove-Variable -Scope Script -Name PromptAlias -ErrorAction SilentlyContinue -Force
    New-Variable -Scope Script -Option ReadOnly -Name PromptAlias -Value $false -Force
}
