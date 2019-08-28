<#
    .SYNOPSIS
        Return the headline with information about the local system and current
        user.

    .DESCRIPTION
        Get the current PowerShell version, Operationg System details an the
        user session as profile headline in one string.
#>
function Get-ProfileHeadline
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()

    $stringBuilder = [System.Text.StringBuilder]::new()

    # Get the PowerShell version depending on the edition
    if ($PSVersionTable.PSEdition -eq 'Core')
    {
        $stringBuilder.AppendFormat('PowerShell {0}', $PSVersionTable.PSVersion) | Out-Null
    }
    else
    {
        $stringBuilder.AppendFormat('Windows PowerShell {0}.{1}', $PSVersionTable.PSVersion.Major, $PSVersionTable.PSVersion.Minor) | Out-Null
    }

    $stringBuilder.AppendLine() | Out-Null

    # Get the operating system information, based on the operating system
    if ([System.Environment]::OSVersion.Platform -eq 'Win32NT')
    {
        # Get Windows version from registry. Update the object for non
        # Windows 10 or Windows Server 2016 systems to match the same keys.
        $osVersion = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select-Object 'ProductName', 'ReleaseId', 'CurrentVersion'
        if ([System.String]::IsNullOrEmpty($osVersion.ReleaseId))
        {
            $osVersion.ReleaseId = $osVersion.CurrentVersion
        }

        $stringBuilder.AppendFormat('{0}, Version {1}', $osVersion.ProductName, $osVersion.ReleaseId) | Out-Null
    }
    if ([System.Environment]::OSVersion.Platform -eq 'Unix')
    {
        # Kernel name, Kenrel release, Kerner version
        $stringBuilder.AppendFormat('{0} {1} {2}', (uname -s), (uname -r), (uname -v)) | Out-Null
    }

    $stringBuilder.AppendLine() | Out-Null
    $stringBuilder.AppendLine() | Out-Null

    # Get the info about the current logged on user, system and uptime
    if ([System.Environment]::OSVersion.Platform -eq 'Win32NT')
    {
        $stringBuilder.AppendFormat('{0}\{1} on {2} ({3}), Uptime {4:%d} day(s) {4:hh\:mm\:ss}', $Env:UserDomain, $Env:Username, $Env:ComputerName.ToUpper(), $PID, [System.TimeSpan]::FromMilliseconds([System.Environment]::TickCount)) | Out-Null
    }
    if ([System.Environment]::OSVersion.Platform -eq 'Unix')
    {
        $stringBuilder.AppendFormat('{0} on {1} ({2}), {3}', $Env:Username, (hostname), $PID, (uptime).Split(',')[0].Trim()) | Out-Null
    }

    $stringBuilder.AppendLine() | Out-Null

    return $stringBuilder.ToString()
}
