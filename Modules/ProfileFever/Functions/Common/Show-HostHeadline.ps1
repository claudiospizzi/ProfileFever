<#
    .SYNOPSIS
        Show the headline with information about the local system and current
        user.
#>
function Show-HostHeadline
{
    # Get Windows version from registry. Update the object for non Windows 10 or
    # Windows Server 2016 systems to match the same keys.
    $osVersion = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    if ($null -eq $osVersion.ReleaseId)
    {
        $osVersion | Add-Member -MemberType NoteProperty -Name 'ReleaseId' -Value $osVersion.CurrentVersion
    }
    if ($null -eq $osVersion.UBR)
    {
        $osVersion | Add-Member -MemberType NoteProperty -Name 'UBR' -Value '0'
    }

    # Rename the ConsoleHost string to a nice understandable string
    $profileHost = $Host.Name.Replace('ConsoleHost', 'Windows PowerShell Console Host')

    # Get the PowerShell version depending on the edition
    if ($PSVersionTable.PSEdition -eq 'Core')
    {
        $psVersion = 'Version {0}' -f $PSVersionTable.PSVersion
    }
    else
    {
        $psVersion = 'Version {0}.{1} (Build {2}.{3})' -f $PSVersionTable.PSVersion.Major, $PSVersionTable.PSVersion.Minor, $PSVersionTable.PSVersion.Build, $PSVersionTable.PSVersion.Revision
    }

    $Host.UI.WriteLine(('{0}, Version {1} (Build {2}.{3})' -f $osVersion.ProductName, $osVersion.ReleaseId, $osVersion.CurrentBuildNumber, $osVersion.UBR))
    $Host.UI.WriteLine(('{0}, {1}' -f $profileHost, $psVersion))
    $Host.UI.WriteLine()
    $Host.UI.WriteLine(('{0}\{1} on {2}, Uptime {3:%d} day(s) {3:hh\:mm\:ss}' -f $Env:USERDOMAIN, $Env:USERNAME, $Env:COMPUTERNAME.ToUpper(), [System.TimeSpan]::FromMilliseconds([System.Environment]::TickCount)))
    $Host.UI.WriteLine()
}
