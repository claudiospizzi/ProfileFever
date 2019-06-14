<#
    .SYNOPSIS
        .
#>
function Install-Profile
{
    [CmdletBinding()]
    param ()


    ##
    ## MODULE DEPENDENCY
    ##

    $moduleNames = 'SecurityFever', 'Pester', 'posh-git', 'psake'

    foreach ($moduleName in $moduleNames)
    {
        if ($null -eq (Get-Module -Name $moduleName -ListAvailable))
        {
            Install-Module -Name $moduleName -Repository 'PSGallery' -Force -AllowClobber -AcceptLicense -SkipPublisherCheck -Verbose
        }
        else
        {
            Update-Module -Name $moduleName -Force -Verbose -AcceptLicense
        }
    }


    ##
    ## PROFILE SCRIPT
    ##

    $profilePaths = @()
    if ($IsWindows)
    {
        $profilePaths += '$HOME\Documents\PowerShell'
        $profilePaths += '$HOME\Documents\WindowsPowerShell'
    }

    foreach ($profilePath in $profilePaths)
    {
        if (-not (Test-Path -Path $profilePath))
        {
            New-Item -Path $profilePath -ItemType 'Directory' -Force | Out-Null
        }

        if (-not (Test-Path -Path "$profilePath\profile.ps1"))
        {
            Set-Content -Path "$profilePath\profile.ps1" -Value 'Start-Profile'
        }
    }
}
