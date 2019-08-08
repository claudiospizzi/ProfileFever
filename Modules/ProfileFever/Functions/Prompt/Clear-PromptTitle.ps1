<#
    .SYNOPSIS
        Create the static prompt title.
#>
function Clear-PromptTitle
{
    [CmdletBinding()]
    [Alias('ctitle')]
    param ()

    Remove-Variable -Scope 'Script' -Name 'PromptTitle' -ErrorAction 'SilentlyContinue' -Force
    New-Variable -Scope 'Script' -Name 'PromptTitle' -Option 'ReadOnly' -Value $null -Force
}
