<#
    .SYNOPSIS
        Clear the static prompt title.

    .DESCRIPTION
        Clear the previously defined static title.
#>
function Clear-PromptTitle
{
    [CmdletBinding()]
    [Alias('ctitle')]
    param ()

    Remove-Variable -Scope 'Script' -Name 'PromptTitle' -ErrorAction 'SilentlyContinue' -Force
    New-Variable -Scope 'Script' -Name 'PromptTitle' -Option 'ReadOnly' -Value $null -Force
}
