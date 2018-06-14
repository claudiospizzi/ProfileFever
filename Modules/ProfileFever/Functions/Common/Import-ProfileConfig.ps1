<#
    .SYNOPSIS
        Import the profile configuration file.
#>
function Import-ProfileConfig
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    $configs = Get-Content -Path $Path | ConvertFrom-Json

    # Update configurations
    if ($configs.Name -contains "$Env:ComputerName\$Env:Username")
    {
        $config = $configs.Where({$_.Name -eq "$Env:ComputerName\$Env:Username"})[0]
    }
    else
    {
        $config = $configs.Where({$_.Name -eq 'Default'})[0]
    }

    Write-Output $config
}
