[![PowerShell Gallery - ProfileFever](https://img.shields.io/badge/PowerShell_Gallery-ProfileFever-0072C6.svg)](https://www.powershellgallery.com/packages/ProfileFever)
[![GitHub - Release](https://img.shields.io/github/release/claudiospizzi/ProfileFever.svg)](https://github.com/claudiospizzi/ProfileFever/releases)
[![AppVeyor - master](https://img.shields.io/appveyor/ci/claudiospizzi/ProfileFever/master.svg)](https://ci.appveyor.com/project/claudiospizzi/ProfileFever/branch/master)

# ProfileFever PowerShell Module

PowerShell module with functions to configure a PowerShell console.

## Introduction

The module is primary aligned to be used by myself - but feel free to use it. It
supports the new Windows Terminal.

## Features

### Profile

* **Start-Profile**  
  Initialize the PowerShell console profile.

* **Install-Profile**  
  Install all dependencies for the profile.

* **Update-ProfileConfig**  
  Create and update the profile configuration.

* **Get-ProfileHeadline**  
  Return the headline with information about the local system and current user.

### Prompt

* **Enable-Prompt**  
  Enable the custom prompt by replacing the default prompt.

* **Enable-PromptAlias**  
  Enable the prompt alias recommendation output after each command.

* **Enable-PromptGit**  
  Enable the git repository status in the prompt.

* **Enable-PromptTimeSpan**  
  Enable the prompt timestamp output.

* **Disable-Prompt**  
  Disable the custom prompt and restore the default prompt.

* **Disable-PromptAlias**  
  Disable the prompt alias recommendation output after each command.

* **Disable-PromptGit**  
  Disable the git repository status in the prompt.

* **Disable-PromptTimeSpan**  
  Disable the prompt timestamp output.

* **Set-PromptTitle**  
  Set a static prompt title.

* **Clear-PromptTitle**  
  Clear the static prompt title.

* **Show-PromptAliasSuggestion**  
  Show the alias suggestion for the latest command.

* **Show-PromptLastCommandDuration**  
  Show the during of the last executed command.

### ReadLine

* **Enable-PSReadLineCommandHelp**  
  Enable command help.

* **Enable-PSReadLineHistoryHelper**  
  Enable the history browser, basic history search and history save.

* **Enable-PSReadLineLocationMark**  
  Use this helper function to easy jump around in the shell.

* **Enable-PSReadLineSmartInsertDelete**  
  Enable the smart insert/delete.

### Stream

* **Enable-Verbose**  
  Enable the verbose output stream for the global shell.

* **Disable-Verbose**  
  Disable the verbose output stream for the global shell.

* **Enable-Information**  
  Enable the information output stream for the global shell.

* **Disable-Information**  
  Disable the information output stream for the global shell.

### Format

* **Format-HostText**  
  Format the text with RGB colors and weight.

### Git

* **Test-GitRepository**  
  Test if the current directory is a git repository.

### Command Not Found Action

* **Register-CommandNotFound**  
  Register the command not found action callback.

* **Unregister-CommandNotFound**  
  Unregister the command not found action callback.

* **Enable-CommandNotFound**  
  Enable the command not found actions.

* **Disable-CommandNotFound**  
  Disable the command not found actions.

* **Get-CommandNotFoundAction**  
  Get the registered command not found actions.

* **Add-CommandNotFoundAction**  
   Add a command not found action to the list of actions.

### Workspace

* **Update-Workspace**  
  Update the workspace configuration for Visual Studio Code which is used by the
  extension vscode-open-project.

## Versions

Please find all versions in the [GitHub Releases] section and the release notes
in the [CHANGELOG.md] file.

## Installation

Use the following command to install the module from the [PowerShell Gallery],
if the PackageManagement and PowerShellGet modules are available:

```powershell
# Download and install the module
Install-Module -Name 'ProfileFever'
```

Alternatively, download the latest release from GitHub and install the module
manually on your local system:

1. Download the latest release from GitHub as a ZIP file: [GitHub Releases]
2. Extract the module and install it: [Installing a PowerShell Module]

## Requirements

The following minimum requirements are necessary to use this module, or in other
words are used to test this module:

* Windows 10
* Windows PowerShell 5.1

## Contribute

Please feel free to contribute by opening new issues or providing pull requests.
For the best development experience, open this project as a folder in Visual
Studio Code and ensure that the PowerShell extension is installed.

* [Visual Studio Code] with the [PowerShell Extension]
* [Pester], [PSScriptAnalyzer] and [psake] PowerShell Modules

[PowerShell Gallery]: https://www.powershellgallery.com/packages/ProfileFever
[GitHub Releases]: https://github.com/claudiospizzi/ProfileFever/releases
[Installing a PowerShell Module]: https://msdn.microsoft.com/en-us/library/dd878350

[CHANGELOG.md]: CHANGELOG.md

[Visual Studio Code]: https://code.visualstudio.com/
[PowerShell Extension]: https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell
[Pester]: https://www.powershellgallery.com/packages/Pester
[PSScriptAnalyzer]: https://www.powershellgallery.com/packages/PSScriptAnalyzer
[psake]: https://www.powershellgallery.com/packages/psake
