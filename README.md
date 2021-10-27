[![PowerShell Gallery - ProfileFever](https://img.shields.io/badge/PowerShell_Gallery-ProfileFever-0072C6.svg)](https://www.powershellgallery.com/packages/ProfileFever)
[![GitHub - Release](https://img.shields.io/github/release/claudiospizzi/ProfileFever.svg)](https://github.com/claudiospizzi/ProfileFever/releases)
[![AppVeyor - master](https://img.shields.io/appveyor/ci/claudiospizzi/ProfileFever/master.svg)](https://ci.appveyor.com/project/claudiospizzi/ProfileFever/branch/master)

# ProfileFever PowerShell Module

PowerShell module with functions to extend the PowerShell console.

## Introduction

The module is primary aligned to be used by myself - but feel free to use it. It
supports the new Windows Terminal. Most of the prompt features are removed with
version 4.0.0 as I've switched to a [Oh My Posh](https://ohmyposh.dev/) prompt
with a class profile file.

## Features

### Launcher

* **Register-Launcher**  
  Register the command not found action callback for the launcher.

* **Invoke-LauncherPSRemoting**  
  Connect to a remote system by using a registered PowerShell Remoting
  connection.

* **Invoke-LauncherSqlServer**  
  Connect to a SQL Server by using a registered connection.

* **Invoke-LauncherSSHRemote**  
  Connect to a remote system by using a registered SSH remote connection.

* **Get-LauncherPSRemoting**  
  Get all PowerShell Remoting connections from the profile launcher.

* **Register-LauncherPSRemoting**  
  Register the PowerShell Remoting connection in the profile.

* **Unregister-LauncherPSRemoting**  
  Unregister the PowerShell Remoting connection from the profile launcher.

* **Get-LauncherSqlServer**  
  Get all SQL Server connections from the profile launcher.

* **Register-LauncherSqlServer**  
  Register the SQL Server connection in the profile.

* **Unregister-LauncherSqlServer**  
  Unregister the SQL Server connection from the profile launcher.

* **Get-LauncherSSHRemote**  
  Get all SSH remote connections from the profile launcher.

* **Register-LauncherSSHRemote**  
  Register the SSH remote connection in the profile.

* **Unregister-LauncherSSHRemote**  
  Unregister the SSH remote connection from the profile launcher.

### Format

* **Format-HostText**  
  Format the text with RGB colors and weight.

### Performance

* **Measure-System**  
  Get the current local system info.

* **Measure-Processor**  
  Get the current processor usage on the local system.

* **Measure-Memory**  
  Get the current memory usage on the local system.

* **Measure-Storage**  
  Get the current storage usage on the local system.

* **Measure-Session**  
  Get all sessions on the local system.

### Workspace

* **Get-Workspace**  
  Get the workspace configuration of Visual Studio Code.

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

The following minimum requirements are necessary to use this module:

* Windows PowerShell 5.1
* Windows 10

## Contribute

Please feel free to contribute to this project. For the best development
experience, please us the following tools:

* [Visual Studio Code] with the [PowerShell Extension]
* [Pester], [PSScriptAnalyzer], [InvokeBuild], [InvokeBuildHelper] modules

[PowerShell Gallery]: https://powershellgallery.com/
[CHANGELOG.md]: CHANGELOG.md

[Visual Studio Code]: https://code.visualstudio.com/
[PowerShell Extension]: https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell

[Pester]: https://www.powershellgallery.com/packages/Pester
[PSScriptAnalyzer]: https://www.powershellgallery.com/packages/PSScriptAnalyzer
[InvokeBuild]: https://www.powershellgallery.com/packages/InvokeBuild
[InvokeBuildHelper]: https://www.powershellgallery.com/packages/InvokeBuildHelper
