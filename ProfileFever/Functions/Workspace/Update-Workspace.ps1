<#
    .SYNOPSIS
        Update the workspace configuration for Visual Studio Code which is used
        by the extension Project Manager.

    .DESCRIPTION
        By default the path $HOME\Workspace is used to prepare the project list.
        It's possible to add multiple workspace paths to the configuration.

        The module dynamically detects if a subfolder of the workspace is a git
        repository or not. If not, it will recurse for one more level and add
        the following folders as projects.

        All .code-workspace files in the root of the path or in the .vscode
        subfolder are used for grouped Visual Studio Code workspaces for the
        vscode-open-project extension.

    .EXAMPLE
        PS C:\> Update-Workspace
        Update the workspace using the default paths.

    .LINK
        https://github.com/claudiospizzi/ProfileFever
        https://marketplace.visualstudio.com/items?itemName=alefragnani.project-manager
#>
function Update-Workspace
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        # Path to the workspace. $HOME\Workspace is used by default.
        [Parameter(Mandatory = $false)]
        [ValidateScript({Test-Path -Path $_})]
        [System.String[]]
        $Path = "$HOME\Workspace",

        # Path to the JSON config file of the Project Manager extension.
        [Parameter(Mandatory = $false)]
        [System.String]
        $ProjectManagerPath = "$Env:AppData\Code\User\globalStorage\alefragnani.project-manager\projects.json",

        # Specify the mode for orphaned projects. By default, the orphaned
        # projects are disabled.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Disable', 'Remove')]
        [System.String]
        $OrphanedProjectMode = 'Disable'
    )

    try
    {
        if (Test-Path -Path $ProjectManagerPath)
        {
            $config = @(Get-Content -Path $ProjectManagerPath -Encoding 'UTF8' | ConvertFrom-Json)
        }
        else
        {
            $config = @()
        }

        foreach ($currentPath in $Path)
        {
            $currentPath = Get-Item -Path $currentPath

            $detectedPaths = @()

            # Add VS Code workspaces as projects
            $detectedPaths +=
                Get-ChildItem -Path $currentPath -Filter '*.code-workspace' -File |
                    Select-Object @{ N = 'BaseName'; E = { "Workspace $($_.BaseName)" } }, 'FullName', @{ N = 'Tags'; E = { @($currentPath.BaseName) } }
            if (Test-Path -Path "$currentPath\.vscode")
            {
                $detectedPaths +=
                    Get-ChildItem -Path "$currentPath\.vscode" -Filter '*.code-workspace' -File |
                        Select-Object @{ N = 'BaseName'; E = { "Workspace $($_.BaseName)" } }, 'FullName', @{ N = 'Tags'; E = { @($currentPath.BaseName) } }
            }

            # Add root git folders as projects
            $detectedPaths +=
                Get-ChildItem -Path $currentPath.FullName -Directory |
                    Where-Object { Test-Path -Path "$($_.FullName)\.git" } |
                        Select-Object 'BaseName', 'FullName', @{ N = 'Tags'; E = { @($currentPath.BaseName) } }

            # Add child git folders as projects
            $detectedPaths +=
                Get-ChildItem -Path $currentPath.FullName -Directory |
                    Where-Object { -not (Test-Path -Path "$($_.FullName)\.git") } |
                        ForEach-Object {
                            $childPath = $_
                            Get-ChildItem -Path $childPath.FullName -Directory |
                                Select-Object 'BaseName', 'FullName', @{ N = 'Tags'; E = { @($currentPath.BaseName, $childPath.BaseName) } }
                        }

            foreach ($detectedPath in $detectedPaths)
            {
                # Add a new project if it does not exist
                if ($config.Count -eq 0 -or $config.rootPath -notcontains $detectedPath.FullName)
                {
                    $config += [PSCustomObject] @{
                        name     = $detectedPath.BaseName
                        rootPath = $detectedPath.FullName
                        paths    = @()
                        tags     = @($detectedPath.Tags -join ' / ')
                        enabled  = $true
                    }
                }
                else
                {
                    # Search for the existing entry and patch the details.
                    for ($i = 0; $i -lt $config.Count; $i++)
                    {
                        if ($config[$i].rootPath -eq $detectedPath.FullName)
                        {
                            $config[$i] = [PSCustomObject] @{
                                name     = $detectedPath.BaseName
                                rootPath = $detectedPath.FullName
                                paths    = @()
                                tags     = @($detectedPath.Tags -join ' / ')
                                enabled  = $true
                            }
                            break
                        }
                    }
                }
            }
        }

        # Remove or disable all projects not existing on the file system.
        switch ($OrphanedProjectMode)
        {
            'Disable'
            {
                for ($i = 0; $i -lt $config.Count; $i++)
                {
                    if (-not (Test-Path -Path $config[$i].rootPath))
                    {
                        $config[$i].enabled = $false
                    }
                }
            }
            'Remove'
            {
                $config = @($config | Where-Object { Test-Path -Path $_.rootPath })
            }
        }

        # Use the .NET class to write the JSON file to prevent writing the UTF-8
        # BOM header, as the Project Manager is not able to read the profile
        # file with an UTF-8 BOM header.
        if ($PSCmdlet.ShouldProcess($ProjectManagerPath, 'Update the Project Manager workspace configuration.'))
        {
            [System.IO.File]::WriteAllLines($ProjectManagerPath, ($config | ConvertTo-Json))
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
