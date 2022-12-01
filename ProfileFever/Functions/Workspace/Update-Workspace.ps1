<#
    .SYNOPSIS
        Update the workspace configuration for Visual Studio Code which is used
        by the extension vscode-open-project.

    .DESCRIPTION
        By default the path $HOME\Workspace is used to prepare the project list
        for the vscode-open-project extension. All .code-workspace files in the
        root of the path or in the .vscode subfolder are used for grouped
        Visual Studio Code workspaces.

    .EXAMPLE
        PS C:\> Update-Workspace
        Update the workspace using the default paths.

    .LINK
        https://github.com/claudiospizzi/ProfileFever
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
        $ProjectListPath = "$Env:AppData\Code\User\projectlist.json"
    )

    try
    {
        $projectList = @{
            projects = [Ordered] @{}
        }

        foreach ($currentPath in $Path)
        {
            if (Test-Path -Path "$currentPath\.vscode")
            {
                foreach ($workspace in (Get-ChildItem -Path "$currentPath\.vscode" -Filter '*.code-workspace' -File))
                {
                    $projectList.projects.Add(('Workspace {0}' -f $workspace.BaseName), $workspace.FullName)
                }
            }
            else
            {
                Write-Warning "The path '$currentPath\.vscode' to the workspace files was not found, skip it."
            }

            foreach ($group in (Get-ChildItem -Path $currentPath -Directory))
            {
                foreach ($repo in (Get-ChildItem -Path $group.FullName -Directory))
                {
                    $key = '{0} \ {1}' -f $group.Name, $repo.Name

                    $projectList.projects.Add($key, $repo.FullName)
                }
            }
        }

        if ($PSCmdlet.ShouldProcess($ProjectListPath, 'Update Project List'))
        {
            $projectList | ConvertTo-Json | Set-Content -Path $ProjectListPath
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
