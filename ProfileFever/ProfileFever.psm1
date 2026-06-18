<#
    .SYNOPSIS
        Root module file.

    .DESCRIPTION
        The root module file loads all functions and helpers into the module
        context.
#>

[CmdletBinding()]
param
(
    # Enable debug mode for the module. This will allow to debug the module
    # functions and helpers using breakpoints but will slow down module loading
    # due to the slow dot-sourcing.
    [Parameter(Mandatory = $false)]
    [System.Boolean]
    $DebugModule = $false
)


## Module Core

# Module behavior
Set-StrictMode -Version 'Latest'
$Script:ErrorActionPreference = 'Stop'
$Script:ProgressPreference    = 'SilentlyContinue'


# Module metadata
$Script:PSModulePath    = [System.IO.Path]::GetDirectoryName($PSCommandPath)
$Script:PSModuleName    = [System.IO.Path]::GetFileName($PSCommandPath).Split('.')[0]
$Script:PSModuleVersion = (Import-PowerShellDataFile -Path "$Script:PSModulePath\$Script:PSModuleName.psd1")['ModuleVersion']


## Module Loader

# Get and dot source all functions
Get-ChildItem -Path "$Script:PSModulePath\Helpers", "$Script:PSModulePath\Functions" -Filter '*.ps1' -File -Recurse |
    ForEach-Object {
        if ($DebugModule -or $Env:PWSH_DEBUG_MODULE -eq 'true')
        {
            . $_.FullName
        }
        else
        {
            . ([System.Management.Automation.ScriptBlock]::Create(
                [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
            ))
        }
    }


## Module Context

# Initialize all relevant launcher variables
$Script:LAUNCHER_PATH             = "$Env:AppData\PowerShell\ProfileFever"
$Script:LAUNCHER_CREDENTIAL_FORMAT = 'PowerShell ProfileFever {0} {1}'
$Script:LAUNCHER_SQL_SERVER        = $null
