
<#
    .SYNOPSIS
    Play the fun tool of Rick Astley.
#>
function Start-RickAstley
{
    Start-Process -FilePath 'powershell.exe' -ArgumentList '-noprofile -noexit -command iex (New-Object Net.WebClient).DownloadString(''http://bit.ly/e0Mw9w'')'
}
