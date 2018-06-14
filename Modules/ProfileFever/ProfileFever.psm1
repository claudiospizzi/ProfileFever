<# ----------------- DEBUGGING ONLY -- REMOVED DURING BUILD ----------------- #>

# Get and dot source all classes (internal)
Split-Path -Path $PSCommandPath |
    Get-ChildItem -Filter 'Classes' -Directory |
        Get-ChildItem -Include '*.ps1' -Exclude '*.Tests.*' -File -Recurse |
            ForEach-Object { . $_.FullName }

# Get and dot source all helper functions (internal)
Split-Path -Path $PSCommandPath |
    Get-ChildItem -Filter 'Helpers' -Directory |
        Get-ChildItem -Include '*.ps1' -Exclude '*.Tests.*' -File -Recurse |
            ForEach-Object { . $_.FullName }

# Get and dot source all external functions (public)
Split-Path -Path $PSCommandPath |
    Get-ChildItem -Filter 'Functions' -Directory |
        Get-ChildItem -Include '*.ps1' -Exclude '*.Tests.*' -File -Recurse |
            ForEach-Object { . $_.FullName }

<# -------------------------------------------------------------------------- #>

# Module profile configuration variables
$Script:PromptHistory  = 0
$Script:PromptAdmin    = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$Script:PromptColor    = $(if($Script:PromptAdmin) { 'Red' } else { 'DarkCyan' })
$Script:PromptAlias    = $false
$Script:PromptTimeSpan = $false
$Script:PromptGit      = $false

# Module command not found action variables
$Script:CommandNotFoundAction = @()
