
<#
    .SYNOPSIS
    Disable the custom prompt and restore the default prompt.
#>
function Disable-Prompt
{
    [CmdletBinding()]
    param ()

    function Global:Prompt
    {
        "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
        # .Link
        # http://go.microsoft.com/fwlink/?LinkID=225750
        # .ExternalHelp System.Management.Automation.dll-help.xml
    }
}
