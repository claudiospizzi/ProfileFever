<#
    .SYNOPSIS
        Get the workspace configuration of Visual Studio Code.

    .DESCRIPTION
        Use the workspace file of the VS Code extension vscode-open-project and
        extract all projects and workspaces.

    .EXAMPLE
        PS C:\> Get-Workspace
        Get all projects and workspaces.

    .EXAMPLE
        PS C:\> Get-Workspace -Type 'Project'
        Get all projects.

    .LINK
        https://github.com/claudiospizzi/ProfileFever
        https://marketplace.visualstudio.com/items?itemName=svetlozarangelov.vscode-open-project
#>
function Get-Workspace
{
    [CmdletBinding()]
    param
    (
        # Option to filter the type.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Workspace', 'Project')]
        [System.String]
        $Type,

        # Path to the JSON config file of the vscode-open-project extension.
        [Parameter(Mandatory = $false)]
        [System.String]
        $ProjectListPath = "$Env:AppData\Code\User\projectlist.json"
    )

    try
    {
        $projectList = Get-Content -Path $ProjectListPath | ConvertFrom-Json

        foreach ($projectDisplay in $projectList.projects.PSObject.Properties.Name)
        {
            $projectName = $projectDisplay.Split('\')[-1].Trim()

            # Define the output type by the display name.
            $projectType = 'Project'
            if ($projectName -like 'Workspace *' -and $projectName -notlike '*\*')
            {
                $projectName = $projectName.Substring(10)
                $projectType = 'Workspace'
            }

            # Filter the type, if specified.
            if ($PSBoundParameters.ContainsKey('Type') -and $Type -ne $projectType)
            {
                continue
            }

            [PSCustomObject] @{
                PSTypeName = 'ProfileFever.Workspace'
                Type       = $projectType
                Name       = $projectName
                Display    = $projectDisplay
                Path       = $projectList.projects.$projectDisplay
            }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
