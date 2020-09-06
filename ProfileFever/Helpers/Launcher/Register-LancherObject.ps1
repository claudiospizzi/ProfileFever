<#
    .SYNOPSIS
        Register the object in the profile.

    .DESCRIPTION
        This command will store the object in the JSON file named like the
        specified type. The JSON file is stored in the users AppData folder. The
        name must be unique, already existing objects will be overwritten.
#>
function Register-LauncherObject
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        # Type of the object. Will be used as filename.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        # Name to identify the object. Must be unique.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        # Optional tags for the object.
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [System.String[]]
        $Tag = @(),

        # The object to register.
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Object
    )

    $file = "$Script:LauncherPath\$Type.json"

    if (Test-Path -Path $file)
    {
        # The content must be read as raw string, to convert it to JSON.
        [System.Object[]] $objects = Get-Content -Path $file -Encoding 'UTF8' -Raw | ConvertFrom-Json
    }
    else
    {
        # Ensure the parent path exists, important for the export at the end.
        New-Item -Path $Script:LauncherPath -ItemType 'Directory' -ErrorAction 'SilentlyContinue' | Out-Null

        [System.Object[]] $objects
    }

    [System.Object[]] $objects = $objects | Where-Object { $_.Name -ne $Name }

    $objects += [PSCustomObject] @{
        Name   = $Name
        Tag    = $Tag
        Object = $Object
    }

    [System.Object[]] $objects = $objects | Sort-Object -Property 'Name'

    # Export the objects as JSON.
    ConvertTo-Json -InputObject $objects -Depth 2 | Set-Content -Path $file -Encoding 'UTF8'
}
