<#
    .SYNOPSIS
        Show the current profile load status.
#>
function Show-ProfileLoadStatus
{
    param
    (
        # Section which will be loaded now.
        [Parameter(Mandatory = $false)]
        [System.String]
        $Section
    )

    if ($VerbosePreference -eq 'Continue')
    {
        Write-Verbose "$(Get-Date -Format HH:mm:ss.fffff) $Section"
    }
    else
    {
        Write-Host "`r$(' ' * $Host.UI.RawUI.WindowSize.Width)`r$Section..." -NoNewline
    }
}
