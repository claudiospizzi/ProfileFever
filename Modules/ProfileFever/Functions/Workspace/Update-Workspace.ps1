
<#
    .SYNOPSIS
    Disable the verbose output stream for the global shell.
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

    # Step 1: Generate VS Code Project list (Extension = vscode-open-project)

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
