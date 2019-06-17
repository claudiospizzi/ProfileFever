<#
    .SYNOPSIS
        Show the headline with information about the local system and current
        user.

    .DESCRIPTION
        Show the current PowerShell version, Operationg System details an the
        user session as profile headline.
#>
function Show-HostHeadline
{
    # Get the PowerShell version depending on the edition
    if ($PSVersionTable.PSEdition -eq 'Core')
    {
        $psInfo = 'PowerShell {0}' -f $PSVersionTable.PSVersion
    }
    else
    {
        $psInfo = 'Windows PowerShell {0}.{1}' -f $PSVersionTable.PSVersion.Major, $PSVersionTable.PSVersion.Minor
    }

    # Get the operating system information, based on the operating system
    $osInfo = ''
    if ([System.Environment]::OSVersion.Platform -eq 'Win32NT')
    {
        # Get Windows version from registry. Update the object for non Windows 10 or
        # Windows Server 2016 systems to match the same keys.
        $osVersion = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
        if ($null -eq $osVersion.ReleaseId)
        {
            $osVersion | Add-Member -MemberType NoteProperty -Name 'ReleaseId' -Value $osVersion.CurrentVersion
        }
        $osInfo = '{0}, Version {1}' -f $osVersion.ProductName, $osVersion.ReleaseId
    }
    if ([System.Environment]::OSVersion.Platform -eq 'Unix')
    {
        $osInfo = uname -a
    }

    # Get the info about the current logged on user, system and uptime
    $usrInfo = ''
    if ([System.Environment]::OSVersion.Platform -eq 'Win32NT')
    {
        $usrInfo = '{0}\{1} on {2}, Uptime {3:%d} day(s) {3:hh\:mm\:ss}' -f $Env:USERDOMAIN, $Env:USERNAME, $Env:COMPUTERNAME.ToUpper(), [System.TimeSpan]::FromMilliseconds([System.Environment]::TickCount)
    }
    if ([System.Environment]::OSVersion.Platform -eq 'Unix')
    {

    }

    # Show headline
    $Host.UI.WriteLine($psInfo)
    $Host.UI.WriteLine($osInfo)
    $Host.UI.WriteLine()
    $Host.UI.WriteLine($usrInfo)
    $Host.UI.WriteLine()
}
