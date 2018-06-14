<#
    .SYNOPSIS
        Update the workspace configuration for Visual Studio Code which is used
        by the extension vscode-open-project.

    .LINK
        https://marketplace.visualstudio.com/items?itemName=svetlozarangelov.vscode-open-project
#>
function Update-Workspace
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $false)]
        [System.String]
        $Path = "$HOME\Workspace",

        [Parameter(Mandatory = $false)]
        [System.String]
        $ProjectListPath = "$Env:AppData\Code\User\projectlist.json"
    )

    $projectList = @{
        projects = [Ordered] @{}
    }

    foreach ($group in (Get-ChildItem -Path $Path -Directory))
    {
        foreach ($repo in (Get-ChildItem -Path $group.FullName -Directory))
        {
            $key = '{0} \ {1}' -f $group.Name, $repo.Name

            $projectList.projects.Add($key, $repo.FullName)
        }
    }

    if ($PSCmdlet.ShouldProcess($ProjectListPath, 'Update Project List'))
    {
        $projectList | ConvertTo-Json | Set-Content -Path $ProjectListPath
    }
}
