<#
    .SYNOPSIS
        Initialize the PowerShell console profile.

    .DESCRIPTION
        This is the personal profile of Claudio Spizzi holding all commands to
        initialize the profile in the console. It's intended to be used on any
        PowerShell version and plattform.
#>
function Start-Profile
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalAliases', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        # Optionally specify a path to the config file.
        [Parameter(Mandatory = $false)]
        [System.String]
        $ConfigPath
    )


    ##
    ## PROFILE CONFIG
    ##

    Show-ProfileLoadStatus -Section 'Load Profile Config'

    # Guess the real config path for the all hosts current user
    if (-not $PSBoundParameters.ContainsKey('ConfigPath'))
    {
        $ConfigPath = $PROFILE.CurrentUserAllHosts -replace '\.ps1', '.json'
    }

    $config = Update-ProfileConfig -Path $ConfigPath -PassThru


    ##
    ## LOCATION
    ##

    Show-ProfileLoadStatus -Section 'Set Location'

    if (Test-Path -Path $config.Location)
    {
        Set-Location -Path $config.Location
    }


    ##
    ## WORKSPACE
    ##

    Show-ProfileLoadStatus -Section 'Create Workspace'



    if ((Test-Path -Path $config.Workspace) -and -not (Test-Path -Path 'Workspace:'))
    {
        New-PSDrive -PSProvider 'FileSystem' -Scope 'Global' -Name 'Workspace' -Root $config.Workspace | Out-Null

        # Aliases to jump into the workspace named Workspace: and WS:
        Set-Item -Path 'Function:Global:Workspace:' -Value 'Set-Location -Path "Workspace:"'
        Set-Item -Path 'Function:Global:WS:' -Value 'Set-Location -Path "Workspace:"'

        # Specify the path to the workspace as environment variable
        [System.Environment]::SetEnvironmentVariable('Workspace', $config.Workspace, [System.EnvironmentVariableTarget]::Process)
    }


    ##
    ## PROMPT
    ##

    Show-ProfileLoadStatus -Section 'Enable Prompt'

    if ($config.Prompt)
    {
        Enable-Prompt -Type $config.PromptType
    }

    if ($config.PromptAlias)
    {
        Enable-PromptAlias
    }

    if ($config.PromptGit)
    {
        Enable-PromptGit
    }

    if ($config.PromptTimeSpan)
    {
        Enable-PromptTimeSpan
    }


    ##
    ## COMMAND NOT FOUND
    ##

    Show-ProfileLoadStatus -Section 'Enable Command Not Found'

    if ($config.CommandNotFound)
    {
        Enable-CommandNotFound
    }


    ##
    ## ALIASES
    ##

    Show-ProfileLoadStatus -Section 'Register Aliases'

    $aliasKeys = $config.Aliases | Get-Member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name'
    foreach ($aliasKey in $aliasKeys)
    {
        New-Alias -Scope 'Global' -Name $aliasKey -Value $config.Aliases.$aliasKey
    }


    ##
    ## FUNCTIONS
    ##

    Show-ProfileLoadStatus -Section 'Register Functions'


    $functionKeys = $config.Functions | Get-Member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name'
    foreach ($functionKey in $functionKeys)
    {
        Set-Item -Path "Function:Global:$functionKey" -Value $config.Functions.$functionKey
    }


    ##
    ## SCRIPTS
    ##

    Show-ProfileLoadStatus -Section 'Invoke Scripts'

    foreach ($script in $config.Scripts)
    {
        Show-ProfileLoadStatus -Section "Invoke Script $script"

        . $script
    }


    ##
    ## BINARIES
    ##

    Show-ProfileLoadStatus -Section 'Update Path for Binaries'

    foreach ($binary in $config.Binaries)
    {
        $Env:Path += ';' + $binary
    }


    ##
    ## PSREADLINE
    ##

    Show-ProfileLoadStatus -Section 'Update PSReadLine'

    # History browser, history search and history save
    if ($config.ReadLineHistoryHelper)
    {
        Enable-PSReadLineHistoryHelper
    }

    # Enable smart insert/delete for ', ", [, ), {
    if ($config.ReadLineSmartInsertDelete)
    {
        Enable-PSReadLineSmartInsertDelete
    }

    # Enable F1 to show help
    if ($config.ReadLineCommandHelp)
    {
        Enable-PSReadLineCommandHelp
    }

    # Jump around in the file system
    if ($config.ReadLineLocationMark)
    {
        Enable-PSReadLineLocationMark
    }

    if ($config.ReadLinePSakeBuild)
    {
        # This will invoke the PSake build in the current directory
        Set-PSReadLineKeyHandler -Key 'Ctrl+B', 'Ctrl+b' -BriefDescription 'BuildCurrentDirectory' -LongDescription "Build the current directory" -ScriptBlock {
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert('Invoke-psake -buildFile ".\build.psake.ps1"')
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
        }
    }

    if ($config.ReadLinePesterTest)
    {
        # This will invoke all Pester tests in the current directory
        Set-PSReadLineKeyHandler -Key 'Ctrl+T', 'Ctrl+t' -BriefDescription 'TestCurrentDirectory' -LongDescription "Test the current directory" -ScriptBlock {
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert('Invoke-Pester')
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
        }
    }


    ##
    ## STRICT MODE
    ##

    Show-ProfileLoadStatus -Section 'Enable Strict Mode'

    if ($config.StrictMode)
    {
        Set-StrictMode -Version 'latest'
    }


    ##
    ## PIPELINE OUTPUT
    ##

    Show-ProfileLoadStatus -Section 'Enable Pipeline Output'

    $Global:PSDefaultParameterValues['Out-Default:OutVariable'] = '__'


    ##
    ## HEADLINE
    ##

    Show-ProfileLoadStatus -Section 'Show Headline'
    $Host.UI.Write("`r")
    #Write-Host  -NoNewline

    # Only show the headline, if PowerShell was started with -NoLogo switch. The
    # test is more a workaround as checking the start parameter. Not found an
    # efficient way to test that without WMI.
    if ($config.Headline -and $Host.UI.RawUI.CursorPosition.Y -eq 0)
    {
        $Host.UI.WriteLine((Get-ProfileHeadline))
    }
}
