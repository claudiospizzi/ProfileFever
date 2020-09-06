<#
    .SYNOPSIS
        Get the regeistered objects from the profile.

    .DESCRIPTION
        This command will get all registerd objects from the JSON file named
        like the specified type. The JSON file is stored in the users AppData
        folder. The output can be filted by name (wildcard supported) and/or by
        tags.
#>
function Get-LauncherObject
{
    [CmdletBinding()]
    param
    (
        # Type of the objects. Will be used as filename.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        # Name to filter the objects. Supports wildcards. If not specified or
        # the name is an empty string, all objects are returned.
        [Parameter(Mandatory = $false)]
        [SupportsWildcards()]
        [AllowEmptyString()]
        [System.String]
        $Name,

        # Optional filter by tags. Don't use wildcards. If any tag was found,
        # the object will match the filter.
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [System.String[]]
        $Tag
    )

    $file = "$Script:LauncherPath\$Type.json"

    if (Test-Path -Path $file)
    {
        # The content must be read as raw string, to convert it to JSON.
        [System.Object[]] $objects = Get-Content -Path $file -Encoding 'UTF8' -Raw | ConvertFrom-Json

        # Filter all objects by the specified name.
        if ($PSBoundParameters.ContainsKey('Name') -and -not [System.String]::IsNullOrEmpty($Name))
        {
            [System.Object[]] $objects = $objects | Where-Object { $_.Name -like $Name }
        }

        # Filter all objects by the specified tags.
        if ($PSBoundParameters.ContainsKey('Tag') -and $Tag.Count -gt 0)
        {
            [System.Object[]] $objects = $objects | Where-Object { [System.Linq.Enumerable]::Intersect([System.String[]] $_.Tag, [System.String[]] $Tag, [System.StringComparer]::OrdinalIgnoreCase).Count -gt 0 }
        }

        Write-Output $objects
    }
}
