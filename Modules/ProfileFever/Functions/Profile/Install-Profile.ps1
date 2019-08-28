<#
    .SYNOPSIS
        Install all dependencies for the profile.

    .DESCRIPTION
        Insted of adding theses module dependencies into the module manifest,
        they are separated in this command. This is by design, to speed up the
        module load duration of ProfileFever. The module load time is essential
        for a fast profile scripts.
#>
function Install-Profile
{
    [CmdletBinding()]
    param ()


    ##
    ## MODULE DEPENDENCY
    ##

    $moduleNames = 'SecurityFever', 'Pester', 'posh-git', 'psake'

    if ($PSVersionTable.PSEdition -ne 'Core')
    {
        Install-PackageProvider -Name 'NuGet' -Scope 'CurrentUser' -MinimumVersion '2.8.5.201' -Force -ForceBootstrap -Verbose | Out-Null
    }

    # Only for Pester, update the built-in module with version 3.4.0
    if ((Get-Module -Name 'Pester' -ListAvailable | Sort-Object -Property 'Version' -Descending | Select-Object -First 1).Version -eq '3.4.0')
    {
        Install-Module -Name 'Pester' -Repository 'PSGallery' -Scope 'CurrentUser' -Force -AllowClobber -SkipPublisherCheck -Verbose
    }

    foreach ($moduleName in $moduleNames)
    {
        if ($null -eq (Get-Module -Name $moduleName -ListAvailable))
        {
            Install-Module -Name $moduleName -Repository 'PSGallery' -Scope 'CurrentUser' -Force -AllowClobber -SkipPublisherCheck -Verbose
        }
        else
        {
            Update-Module -Name $moduleName -Force -Verbose
        }
    }


    ##
    ## PROFILE SCRIPT
    ##

    $profilePaths = @()
    if ([System.Environment]::OSVersion.Platform -eq 'Win32NT')
    {
        $profilePaths += "$HOME\Documents\PowerShell"
        $profilePaths += "$HOME\Documents\WindowsPowerShell"
    }
    if ([System.Environment]::OSVersion.Platform -eq 'Unix')
    {
        $profilePaths += "$HOME/.config/powershell"
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
