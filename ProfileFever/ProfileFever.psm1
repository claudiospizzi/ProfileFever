<#
    .SYNOPSIS
        Root module file.

    .DESCRIPTION
        The root module file loads all classes, helpers and functions into the
        module context.
#>

# Use namespaces for PSReadLine extension
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

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

# Module-wide settings for prompt configuration
$Script:PromptHistory  = 0
$Script:PromptColor    = 'Yellow'
$Script:PromptInfo     = 'PS {0}.{1}' -f $PSVersionTable.PSVersion.Major, $PSVersionTable.PSVersion.Minor
$Script:PromptAlias    = $false
$Script:PromptTimeSpan = $false
$Script:PromptGit      = $false
$Script:PromptDefault  = Get-Command -Name 'prompt' | Select-Object -ExpandProperty 'Definition'
$Script:PromptTitle    = $null
$Script:PromptIsAdmin  = [System.Environment]::OSVersion.Platform -eq 'Win32NT' -and ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$Script:PromptIsRoot   = [System.Environment]::OSVersion.Platform -eq 'Unix' -and (whoami) -eq 'root'

# Global prompt configuration
$Global:ProfileFeverPromptConfig = [PSCustomObject] [Ordered] @{

    # Debug indicator
    DebugText                  = ' DBG '
    DebugSeperator             = [System.Char] 57544
    DebugForeground            = 0xF2, 0xF2, 0xF2   # White
    DebugBackground            = 0x88, 0x17, 0x98   # Dark Magenta

    # Admin/Root indiator
    AdminText                  = ' ADM '
    AdminSeperator             = [System.Char] 57544
    AdminForeground            = 0xF2, 0xF2, 0xF2   # White
    AdminBackground            = 0xAA, 0x00, 0x00   # Red

    # Prompt info (PoerShell version)
    InfoText                   = " $Script:PromptInfo "
    InfoSeperator              = [System.Char] 57520
    InfoForeground             = 0xF2, 0xF2, 0xF2   # White
    InfoBackground             = 0x17, 0x3C, 0x58   # Cyan 1

    # Current shell location (pwd)
    LocationSeperator          = [System.Char] 57520
    LocationForeground         = 0xF2, 0xF2, 0xF2   # White
    LocationBackground         = 0x28, 0x69, 0x9A   # Cyan 2

    # Git branch
    GitBranchIcon              = [System.Char] 57504
    GitBranchSeperator         = [System.Char] 57520
    GitBranchForeground        = 0xF2, 0xF2, 0xF2   # White
    GitBranchBackgroundDefault = 0x3A, 0x96, 0xDD   # Cyan 3
    GitBranchBackgroundAhead   = 0x13, 0x90, 0x0E   # DarkGreen, darker than console color
    GitBranchBackgroundMixed   = 0xC1, 0x9C, 0x00   # Yellow
    GitBranchBackgroundBehind  = 0xC5, 0x0F, 0x1F   # DarkRed

    # Git details for index/working/stash
    GitDetailTextSplit         = [System.Char] 57521
    GitDetailTextIndex         = 'idx'
    GitDetailTextWorking       = 'wrk'
    GitDetailTextStash         = 'sth'
    GitDetailSeperator         = [System.Char] 57520
    GitDetailForegroundSplit   = 0x3A, 0x96, 0xDD
    GitDetailForegroundIndex   = 0x00, 0x60, 0x00   # Green(?)
    GitDetailForegroundWorking = 0x60, 0x00, 0x00   # ?
    GitDetailForegroundStash   = 0x00, 0x00, 0x60   # ?
    GitDetailBackground        = 0x75, 0xB5, 0xE7   # Cyan 4
}

# Module command not found action variables
$Script:CommandNotFoundEnabled = $false

# Initialize all relevant launcher vairables
$Script:LauncherPath             = "$Env:AppData\PowerShell\ProfileFever"
$Script:LauncherCredentialFormat = 'PowerShell ProfileFever {0} {1}'
$Script:LauncherSqlServer        = $null
