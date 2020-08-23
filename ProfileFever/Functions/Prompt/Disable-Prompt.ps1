<#
    .SYNOPSIS
        Disable the custom prompt and restore the default prompt.
#>
function Disable-Prompt
{
    [CmdletBinding()]
    param ()

    Set-Item -Path 'Function:Global:prompt' -Value $Script:PromptDefault
}
