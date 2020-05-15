<#
    .SYNOPSIS
        Test if the current directory is a git repository.

    .DESCRIPTION
        Recursive test the current and all it's parents if the repository is
        part of a git repository. It will use the current location provided by
        the Get-Location cmdlet.
#>
function Test-GitRepository
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param ()

    $pathInfo = Get-Location

    if (!$pathInfo -or ($pathInfo.Provider.Name -ne 'FileSystem'))
    {
        return $false
    }
    elseif ($Env:GIT_DIR)
    {
        return $true
    }
    else
    {
        $currentDir = Get-Item -LiteralPath $pathInfo -Force
        while ($currentDir)
        {
            $gitDirPath = Join-Path -Path $currentDir.FullName -ChildPath '.git'
            if (Test-Path -LiteralPath $gitDirPath -PathType Container)
            {
                return $true
            }
            if (Test-Path -LiteralPath $gitDirPath -PathType Leaf)
            {
                return $true
            }

            $headPath = Join-Path -Path $currentDir.FullName -ChildPath 'HEAD'
            if (Test-Path -LiteralPath $headPath -PathType Leaf)
            {
                $refsPath = Join-Path -Path $currentDir.FullName -ChildPath 'refs'
                $objsPath = Join-Path -Path $currentDir.FullName -ChildPath 'objects'
                if ((Test-Path -LiteralPath $refsPath -PathType Container) -and
                    (Test-Path -LiteralPath $objsPath -PathType Container))
                {
                    return $true
                }
            }

            $currentDir = $currentDir.Parent
        }
    }

    return $false
}
