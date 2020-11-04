# Changelog

All notable changes to this project will be documented in this file.

The format is mainly based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## 3.5.0 - 2020-11-04

* Changed: Set launcher function names
* Fixed: Prevent long paths in the prompt

## 3.4.0 - 2020-08-23

* Added: Function to show the last errors with more details (Show-Error)
* Added: Function to show or measure system information (Measure-System)
* Added: Function to measure the processor usage (Measure-Processor)
* Added: Function to measure the memory usage (Measure-Memory)
* Added: Function to measure the storage usage (Measure-Storage)
* Added: Function to measure the user sessions (Measure-Session)
* Fixed: Minor issues in the profile functions
* Fixed: Various code styling issues

## 3.3.0 - 2019-10-21

* Added: Prompt indicator if the current process is administrator
* Added: Move last prompt duration on line down and add clock icon
* Fixed: PresentationFramework only loaded in Windows PowerShell
* Fixed: Alias suggestion did show wrong suggestions (word parts)

## 3.2.1 - 2019-09-13

* Fixed: Don't show the full prompt if the user enters Shift+Enter
* Fixed: Import the posh-git module in the global scope

## 3.2.0 - 2019-08-29

* Changed: Remove dependencies to Pansis module
* Added: Function to format text (Format-HostText)

## 3.1.0 - 2019-08-08

* Added: Advanced prompt mode
* Added: Show current load state during profile start
* Added: Support SSH connections with the command not found feature
* Added: Functions to control the prompt title

## 3.0.2 - 2019-06-18

* Fixed: Load scripts with dot-sourcing instead of a separate scope
* Fixed: Credential not loaded from vault for command not found action

## 3.0.1 - 2019-06-17

* Fixed: Switch default install scope to current user
* Fixed: Multiple bugs for cross platform support

## 3.0.0 - 2019-06-17

* Changed: Update whole module and add cross platform

## 2.0.1 - 2019-04-24

* Fixed: Wrong last command execution duration format

## 2.0.0 - 2019-04-24

* Changed: Change format of last command execution duration to 0.000
* Removed: DSC resources available in the official PowerShellGet module

## 1.1.1 - 2019-02-15

* Added: Add VS Code Workspace to Update-Workspace

## 1.1.0 - 2019-01-04

* Added: Connect-JumpHost function

## 1.0.4 - 2019-01-03

* Fixed: Replace Get-VaultCredential with Use-VaultCredential

## 1.0.3 - 2018-09-26

* Fixed: Windows title with enabled git mode in a git repo folder

## 1.0.2 - 2018-06-19

* Fixed: Execute the script block command not found action.

## 1.0.1 - 2018-06-18

* Fixed: Add an option to provide a vault target name for the command not found
  remoting actions.

## 1.0.0 - 2018-06-15

* Added: Command not found action helper functions

## 0.0.4 - 2017-11-30

* Added: Update-Workspace function

## 0.0.3 - 2017-11-30

* Added: Useful functions for a profile script

## 0.0.2 - 2017-11-30

* Fixed: Module manifest is missing the DSC resources

## 0.0.1 - 2017-11-30

* Added: Initial version
