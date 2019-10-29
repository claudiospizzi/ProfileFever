<#
    .SYNOPSIS
        Set a static prompt title.

    .DESCRIPTION
        Overwrite the dynamic prompt title with a static title.
#>
function Set-PromptTitle
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias('title')]
    param
    (
        # Global title definition
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Title
    )

    if ($PSCmdlet.ShouldProcess('Prompt Title', 'Set'))
    {
        Remove-Variable -Scope 'Script' -Name 'PromptTitle' -ErrorAction 'SilentlyContinue' -Force
        New-Variable -Scope 'Script' -Name 'PromptTitle' -Option 'ReadOnly' -Value $Title -Force
    }
}
