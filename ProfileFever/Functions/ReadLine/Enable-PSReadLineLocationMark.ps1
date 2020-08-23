<#
    .SYNOPSIS
        Use this helper function to easy jump around in the shell.

    .DESCRIPTION
        Use Ctrl+Shift+J with a marker key to save the current directory in the
        marker list. Afterwards, with Ctrl+J, jump to the saved directory. To
        show all saved markers, use Alt+J.

    .LINK
        https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1
#>
function Enable-PSReadLineLocationMark
{
    [CmdletBinding()]
    param ()

    $Global:PSReadLineMarks = @{}

    $markDirectorySplat = @{
        Key              = 'Ctrl+Shift+j'
        BriefDescription = 'MarkDirectory'
        LongDescription  = 'Mark the current directory'
        ScriptBlock      = {
            param($key, $arg)

            $key = [Console]::ReadKey($true)
            $Global:PSReadLineMarks[$key.KeyChar] = $pwd
        }
    }
    Set-PSReadLineKeyHandler @markDirectorySplat

    $jumpDirectorySplat = @{
        Key              = 'Ctrl+j'
        BriefDescription = 'JumpDirectory'
        LongDescription  = 'Goto the marked directory'
        ScriptBlock      = {
            param($key, $arg)

            $key = [Console]::ReadKey()
            $dir = $Global:PSReadLineMarks[$key.KeyChar]
            if ($dir)
            {
                Set-Location $dir
                [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
            }
        }
    }
    Set-PSReadLineKeyHandler @jumpDirectorySplat

    $showDirectoryMarks = @{
        Key              = 'Alt+j'
        BriefDescription = 'ShowDirectoryMarks'
        LongDescription  = 'Show the currently marked directories'
        ScriptBlock      = {
            param($key, $arg)

            $Global:PSReadLineMarks.GetEnumerator() | ForEach-Object {
                [PSCustomObject]@{Key = $_.Key; Dir = $_.Value}
            } | Format-Table -AutoSize | Out-Host

            [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
        }
    }
    Set-PSReadLineKeyHandler @showDirectoryMarks
}
