<#
    .SYNOPSIS
        Update the workspace configuration for Visual Studio Code which is used
        by the extension vscode-open-project.

    .DESCRIPTION
        By default the path $HOME\Workspace is used to prepare the project list
        for the vscode-open-project extension. All *.code-workspace files in the
        root of the path are used for grouped Visual Studio Code workspaces.

    .PARAMETER Path
        Path to the workspace. $HOME\Workspace is used by default.

    .PARAMETER ProjectListPath
        Path to the JSON config file of the vscode-open-project extension.

    .LINK
        https://marketplace.visualstudio.com/items?itemName=svetlozarangelov.vscode-open-project
#>
function Update-Workspace
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateScript({Test-Path -Path $_})]
        [System.String[]]
        $Path = "$HOME\Workspace",

        [Parameter(Mandatory = $false)]
        [System.String]
        $ProjectListPath = "$Env:AppData\Code\User\projectlist.json"
    )

    begin
    {
        $projectList = @{
            projects = [Ordered] @{}
        }
    }

    process
    {
        foreach ($currentPath in $Path)
        {
            foreach ($workspace in (Get-ChildItem -Path "$currentPath\.vscode" -Filter '*.code-workspace' -File))
            {
                $projectList.projects.Add(('Workspace {0}' -f $workspace.BaseName), $workspace.FullName)
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
    }

    end
    {
        if ($PSCmdlet.ShouldProcess($ProjectListPath, 'Update Project List'))
        {
            $projectList | ConvertTo-Json | Set-Content -Path $ProjectListPath
        }
    }
}
