<#
    .SYNOPSIS
        Update the workspace configuration for Visual Studio Code which is used
        by the extensions vscode-open-project and Project Manager.

    .DESCRIPTION
        By default the path $HOME\Workspace is used to prepare the project list.
        All .code-workspace files in the root of the path or in the .vscode
        subfolder are used for grouped Visual Studio Code workspaces for the
        vscode-open-project extension.

    .EXAMPLE
        PS C:\> Update-Workspace
        Update the workspace using the default paths.

    .LINK
        https://github.com/claudiospizzi/ProfileFever
        https://marketplace.visualstudio.com/items?itemName=alefragnani.project-manager
        https://marketplace.visualstudio.com/items?itemName=svetlozarangelov.vscode-open-project
#>
function Update-Workspace
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        # Path to the workspace. $HOME\Workspace is used by default.
        [Parameter(Mandatory = $false)]
        [ValidateScript({Test-Path -Path $_})]
        [System.String[]]
        $Path = "$HOME\Workspace",

        # Path to the JSON config file of the vscode-open-project extension.
        [Parameter(Mandatory = $false)]
        [System.String]
        $ProjectListPath = "$Env:AppData\Code\User\projectlist.json",

        # Path to the JSON config file of the Project Manager extension.
        [Parameter(Mandatory = $false)]
        [System.String]
        $ProjectManagerPath = "$Env:AppData\Code\User\globalStorage\alefragnani.project-manager\projects.json"
    )

    try
    {
        ##
        ## Part 1
        ## Generate config for the vscode-open-project extension.
        ##

        # $projectList = @{
        #     projects = [Ordered] @{}
        # }

        # foreach ($currentPath in $Path)
        # {
        #     if (Test-Path -Path "$currentPath\.vscode")
        #     {
        #         foreach ($workspace in (Get-ChildItem -Path "$currentPath\.vscode" -Filter '*.code-workspace' -File))
        #         {
        #             $projectList.projects.Add(('Workspace {0}' -f $workspace.BaseName), $workspace.FullName)
        #         }
        #     }
        #     else
        #     {
        #         Write-Warning "The path '$currentPath\.vscode' to the workspace files was not found, skip it."
        #     }

        #     foreach ($group in (Get-ChildItem -Path $currentPath -Directory))
        #     {
        #         foreach ($repo in (Get-ChildItem -Path $group.FullName -Directory))
        #         {
        #             $key = '{0} \ {1}' -f $group.Name, $repo.Name

        #             $projectList.projects.Add($key, $repo.FullName)
        #         }
        #     }
        # }

        # if ($PSCmdlet.ShouldProcess($ProjectListPath, 'Update Project List'))
        # {
        #     $projectList | ConvertTo-Json | Set-Content -Path $ProjectListPath
        # }


        ##
        ## Part 2
        ## Generate config for the Project Manager extension.
        ##

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
            foreach ($group in (Get-ChildItem -Path $currentPath.FullName -Directory))
            {
                foreach ($repo in (Get-ChildItem -Path $group.FullName -Directory))
                {
                    # Add a new project if it does not exist
                    if ($config.rootPath -notcontains $repo.FullName)
                    {
                        $config += [PSCustomObject] @{
                            name     = $repo.BaseName
                            rootPath = $repo.FullName
                            paths    = @()
                            tags     = @('{0} / {1}' -f $currentPath.BaseName, $group.BaseName)
                            enabled  = $true
                        }
                    }
                    else
                    {
                        # Search for the existing entry and patch the details.
                        for ($i = 0; $i -lt $config.Count; $i++)
                        {
                            if ($config[$i].rootPath -eq $repo.FullName)
                            {
                                $config[$i] = [PSCustomObject] @{
                                    name     = $repo.BaseName
                                    rootPath = $repo.FullName
                                    paths    = @()
                                    tags     = @('{0} / {1}' -f $currentPath.BaseName, $group.BaseName)
                                    enabled  = $true
                                }
                                break
                            }
                        }
                    }
                }
            }
        }

        # Use the .NET class to write the JSON file to prevent writing the UTF-8
        # BOM header, as the Project Manager is not able to read the profile
        # file with an UTF-8 BOM header.
        [System.IO.File]::WriteAllLines($ProjectManagerPath, ($config | ConvertTo-Json))
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
