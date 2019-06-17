<#
    .SYNOPSIS
        Root module file.

    .DESCRIPTION
        The root module file loads all classes, helpers and functions into the
        module context.
#>

#region Namepsace Loader

# Use namespaces for PSReadLine extension
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

#endregion Namepsace Loader

#region Module Loader

# Get and dot source all classes (internal)
Split-Path -Path $PSCommandPath |
    Get-ChildItem -Filter 'Classes' -Directory |
        Get-ChildItem -Include '*.ps1' -File -Recurse |
            ForEach-Object { . $_.FullName }

# Get and dot source all helper functions (internal)
Split-Path -Path $PSCommandPath |
    Get-ChildItem -Filter 'Helpers' -Directory |
        Get-ChildItem -Include '*.ps1' -File -Recurse |
            ForEach-Object { . $_.FullName }

# Get and dot source all external functions (public)
Split-Path -Path $PSCommandPath |
    Get-ChildItem -Filter 'Functions' -Directory |
        Get-ChildItem -Include '*.ps1' -File -Recurse |
            ForEach-Object { . $_.FullName }

#endregion Module Loader

#region Module Configuration

# Prompt configuration and variables
$Script:PromptHistory  = 0
$Script:PromptColor    = 'Yellow'
$Script:PromptInfo     = '[PS {0}.{1}]' -f $PSVersionTable.PSVersion.Major, $PSVersionTable.PSVersion.Minor
$Script:PromptAlias    = $false
$Script:PromptTimeSpan = $false
$Script:PromptGit      = $false
$Script:PromptDefault  = Get-Command -Name 'prompt' | Select-Object -ExpandProperty 'Definition'

# Enumerate the prompt color based on the operating system
if ([System.Environment]::OSVersion.Platform -eq 'Win32NT')
{
    $Script:PromptColor = $(if(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { 'Red' } else { 'DarkCyan' })
}
if ([System.Environment]::OSVersion.Platform -eq 'Unix')
{
    $Script:PromptColor = $(if((whoami) -eq 'root') { 'Red' } else { 'DarkCyan' })
}

# Module command not found action variables
$Script:CommandNotFoundEnabled = $false
$Script:CommandNotFoundAction  = @{}

#endregion Module Configuration
