<#
    .SYNOPSIS
        Create and update the profile configuration.

    .DESCRIPTION
        The profile configuration will be created if it does not exist. Every
        property will be initialized with a default value.
#>
function Update-ProfileConfig
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        # Path to the config file.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        # Return the updated object
        [Parameter(Mandatory = $false)]
        [switch]
        $PassThru
    )

    # Load the config file or specify an empty config object
    if (Test-Path -Path $Path)
    {
        $config = Get-Content -Path $Path -Encoding 'UTF8' | ConvertFrom-Json
    }
    else
    {
        $config = [PSCustomObject] @{}
    }

    # Initialize the configuration if not specified with default values
    if ($null -eq $config.Location)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'Location' -Value $(if ($IsLinux -or $IsMacOs) { '~' } else { "$Home\Desktop" })
    }
    if ($null -eq $config.Workspace)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'Workspace' -Value $(if ($IsLinux -or $IsMacOs) { '~/workspace' } else { "$Home\Workspace" })
    }
    if ($null -eq $config.Prompt)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'Prompt' -Value $true
    }
    if ($null -eq $config.PromptType)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'PromptType' -Value 'Basic'
    }
    if ($null -eq $config.PromptAlias)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'PromptAlias' -Value $true
    }
    if ($null -eq $config.PromptGit)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'PromptGit' -Value $false   # Git client is not installed by default
    }
    if ($null -eq $config.PromptTimeSpan)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'PromptTimeSpan' -Value $true
    }
    if ($null -eq $config.ReadLineHistoryHelper)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'ReadLineHistoryHelper' -Value $true
    }
    if ($null -eq $config.ReadLineSmartInsertDelete)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'ReadLineSmartInsertDelete' -Value $true
    }
    if ($null -eq $config.ReadLineCommandHelp)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'ReadLineCommandHelp' -Value $true
    }
    if ($null -eq $config.ReadLineLocationMark)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'ReadLineLocationMark' -Value $true
    }
    if ($null -eq $config.ReadLinePSakeBuild)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'ReadLinePSakeBuild' -Value $true
    }
    if ($null -eq $config.ReadLinePesterTest)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'ReadLinePesterTest' -Value $true
    }
    if ($null -eq $config.StrictMode)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'StrictMode' -Value $false
    }
    if ($null -eq $config.CommandNotFound)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'CommandNotFound' -Value $false
    }
    if ($null -eq $config.Headline)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'Headline' -Value $true
    }
    if ($null -eq $config.Aliases)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'Aliases' -Value @{
            # Baseline
            'grep' = 'Select-String'
            # SecurityFever
            'cred' = 'Use-VaultCredential'
        }
    }
    if ($null -eq $config.Functions)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'Functions' -Value @{
            # Internet Search
            'google'        = 'Start-Process "https://www.google.com/search?q=$args"'
            'dict'          = 'Start-Process "https://www.dict.cc/?s=$args"'
            'wiki'          = 'Start-Process "https://en.wikipedia.org/wiki/Special:Search/$args"'
            'stackoverflow' = 'Start-Process "https://stackoverflow.com/search?q=$args"'
            # PSake Build Module
            'psake'         = 'Invoke-psake -buildFile ".\build.psake.ps1"'
            'psakedeploy'   = 'Invoke-psake -buildFile ".\build.psake.ps1" -taskList "Deploy"'
        }
    }
    if ($null -eq $config.Scripts)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'Scripts' -Value @()
    }
    if ($null -eq $config.Binaries)
    {
        $config | Add-Member -MemberType 'NoteProperty' -Name 'Binaries' -Value @()
    }

    # Finally, store the config file on the disk
    $config | ConvertTo-Json | Set-Content -Path $Path -Encoding 'UTF8'

    if ($PassThru.IsPresent)
    {
        Write-Output $config
    }
}
