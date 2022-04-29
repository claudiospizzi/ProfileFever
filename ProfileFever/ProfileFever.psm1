<#
    .SYNOPSIS
        Root module file.

    .DESCRIPTION
        The root module file loads all classes, helpers and functions into the
        module context.
#>


## Module loader

# Get and dot source all model classes (internal)
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


## Module configuration

# Module behaviour
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

# Module metadata
$Script:PSModulePath = [System.IO.Path]::GetDirectoryName($PSCommandPath)
$Script:PSModuleName = [System.IO.Path]::GetFileName($PSCommandPath).Split('.')[0]

# Module Context: Environment



# Initialize all relevant launcher vairables
$Script:LAUNCHER_PATH             = "$Env:AppData\PowerShell\ProfileFever"
$Script:LAUNCHER_CREDENTIAL_FORMAT = 'PowerShell ProfileFever {0} {1}'
$Script:LAUNCHER_SQL_SERVER        = $null
