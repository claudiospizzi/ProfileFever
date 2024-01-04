<#
    .SYNOPSIS
        Get the workspace configuration of Visual Studio Code which is used by
        the extension Project Manager.

    .DESCRIPTION
        The project file of the Visual Studio Code Project Manager is loaded and
        parsed. The result is returned as PowerShell objects.

    .EXAMPLE
        PS C:\> Get-Workspace
        Get all projects and workspaces.

    .LINK
        https://github.com/claudiospizzi/ProfileFever
        https://marketplace.visualstudio.com/items?itemName=alefragnani.project-manager
#>
function Get-Workspace
{
    [CmdletBinding()]
    param
    (
        # Path to the JSON config file of the Project Manager extension.
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path -Path $_ })]
        [System.String]
        $ProjectManagerPath = "$Env:AppData\Code\User\globalStorage\alefragnani.project-manager\projects.json"
    )

    try
    {
        $projects =
            Get-Content -Path $ProjectManagerPath |
                ConvertFrom-Json
        foreach ($project in $projects)
        {
            [PSCustomObject] @{
                PSTypeName = 'ProfileFever.Workspace'
                Name    = $project.name
                Tag     = [System.String] $project.tags
                Type    = $(if ($project.rootPath -like '*.code-workspace') { 'Workspace' } else { 'Project' })
                Path    = $project.rootPath
                Enabled = $project.enabled
            }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
