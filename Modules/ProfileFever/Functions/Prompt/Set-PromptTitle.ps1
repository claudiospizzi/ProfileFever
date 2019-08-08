<#
    .SYNOPSIS
        Set a static prompt title.
#>
function Set-PromptTitle
{
    [CmdletBinding()]
    [Alias('title')]
    param
    (
        # Global title definition
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Title
    )

    Remove-Variable -Scope 'Script' -Name 'PromptTitle' -ErrorAction 'SilentlyContinue' -Force
    New-Variable -Scope 'Script' -Name 'PromptTitle' -Option 'ReadOnly' -Value $Title -Force
}
