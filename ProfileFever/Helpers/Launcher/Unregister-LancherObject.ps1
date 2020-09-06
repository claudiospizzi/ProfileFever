<#
    .SYNOPSIS
        Unregister the object from the profile.

    .DESCRIPTION
        This command will remove the stored object from the JSON file named like
        the specified type. The JSON file is stored in the users AppData folder.
#>
function Unregister-LauncherObject
{
    [CmdletBinding()]
    param
    (
        # Type of the object. Will be used as filename.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        # Name to identify the object.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $file = "$Script:LauncherPath\$Type.json"

    if (Test-Path -Path $file)
    {
        # The content must be read as raw string, to convert it to JSON.
        [System.Object[]] $objects = Get-Content -Path $file -Encoding 'UTF8' -Raw | ConvertFrom-Json

        # Filter all objects to remove the target object identified by name.
        [System.Object[]] $objects = $objects | Where-Object { $_.Name -ne $Name }

        # Export the objects as JSON. Create a workaround for the empty array,
        # because this is not handled well by the pipeline.
        if ($objects.Count -eq 0)
        {
            Set-Content -Value '[ ]' -Path $file -Encoding 'UTF8'
        }
        else
        {
            ConvertTo-Json -InputObject $objects -Depth 2 | Set-Content -Path $file -Encoding 'UTF8'
        }
    }
}
