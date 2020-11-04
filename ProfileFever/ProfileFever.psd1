@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'ProfileFever.psm1'

    # Version number of this module.
    ModuleVersion = '3.5.0'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID = 'EAAB77B3-CA8D-4CBF-8C2F-5BF5B3C11D1C'

    # Author of this module
    Author = 'Claudio Spizzi'

    # Company or vendor of this module
    # CompanyName = ''

    # Copyright statement for this module
    Copyright = 'Copyright (c) 2019 by Claudio Spizzi. Licensed under MIT license.'

    # Description of the functionality provided by this module
    Description = 'PowerShell Module with functions to configure a system and the PowerShell profile.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @(
        'ProfileFever.Xml.Types.ps1xml'
    )

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @(
        'ProfileFever.Xml.Format.ps1xml'
    )

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        # CmdNotFound
        'Register-CommandNotFound'
        'Unregister-CommandNotFound'
        'Enable-CommandNotFound'
        'Disable-CommandNotFound'
        # Format
        'Format-HostText'
        # Git
        'Test-GitRepository'
        # Profile
        'Start-Profile'
        'Install-Profile'
        'Update-ProfileConfig'
        'Get-ProfileHeadline'
        # Prompt
        'Enable-Prompt'
        'Disable-Prompt'
        'Enable-PromptAlias'
        'Disable-PromptAlias'
        'Enable-PromptGit'
        'Disable-PromptGit'
        'Enable-PromptTimeSpan'
        'Disable-PromptTimeSpan'
        'Set-PromptTitle'
        'Clear-PromptTitle'
        'Show-PromptAliasSuggestion'
        'Show-PromptLastCommandDuration'
        # ReadLine
        'Enable-PSReadLineCommandHelp'
        'Enable-PSReadLineHistoryHelper'
        'Enable-PSReadLineLocationMark'
        'Enable-PSReadLineSmartInsertDelete'
        # Stream
        'Enable-Verbose'
        'Disable-Verbose'
        'Enable-Information'
        'Disable-Information'
        'Show-Error'
        # Workspace
        'Update-Workspace'
        # Performance
        'Measure-System'
        'Measure-Processor'
        'Measure-Memory'
        'Measure-Storage'
        'Measure-Session'
        # PowerShell Remoting Launcher
        'Get-LauncherPSRemoting'
        'Invoke-LauncherPSRemoting'
        'Register-LauncherPSRemoting'
        'Unregister-LauncherPSRemoting'
        # SSH Remoting Launcher
        'Get-LauncherSSHRemote'
        'Invoke-LauncherSSHRemote'
        'Register-LauncherSSHRemote'
        'Unregister-LauncherSSHRemote'
        # SQL Server Launcher
        'Get-LauncherSqlServer'
        'Invoke-LauncherSqlServer'
        'Register-LauncherSqlServer'
        'Unregister-LauncherSqlServer'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @(
        # Prompt
        'ealias'
        'dalias'
        'egit'
        'dgit'
        'etimestamp'
        'dtimestamp'
        'title'
        'ctitle'
        # Stream
        'ev'
        'dv'
        'ei'
        'di'
        # PowerShell Remoting
        'winrm'
        'win'
        'w'
        # SSH Remote
        'shell'
        'l'
        # SQL Server
        'sql'
        # Performance
        'system'
        'processor'
        'memory'
        'storage'
        'session'
    )

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('PSModule', 'Profile')

            # A URL to the license for this module.
            LicenseUri = 'https://raw.githubusercontent.com/claudiospizzi/ProfileFever/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/claudiospizzi/ProfileFever'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/claudiospizzi/ProfileFever/blob/master/CHANGELOG.md'

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}
