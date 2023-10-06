<#
    .SYNOPSIS
        Show the system summary of the local system or the host behind the
        PowerShell session.

    .DESCRIPTION
        This command will use CIM and Performance Counter as well as some other
        command line tools to get the current system summary. The summary will
        displayed in a nice way on the console.

    .EXAMPLE
        PS C:\> Show-SystemSummary
        Show the local system summary.

    .EXAMPLE
        PS C:\> Show-SystemSummary -Session $session
        Show the system summary of the host behind the session.
#>
function Show-SystemSummary
{
    [CmdletBinding()]
    param
    (
        # Optional session to use for the system summary.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.Runspaces.PSSession]
        $Session
    )

    $colorDarkRed    = 197, 15, 31
    $colorDarkYellow = 193, 156, 0
    $colorDarkGreen  = 19, 161, 14
    $colorDarkGray   = 118, 118, 118

    function Get-Color ($Value, $WarningThreshold, $ErrorThreshold)
    {
        if ($Value -gt $ErrorThreshold)
        {
            $colorDarkRed
            # 197, 15, 31
        }
        elseif ($Value -gt $WarningThreshold)
        {
            $colorDarkYellow
            # 193, 156, 0
        }
        else
        {
            $colorDarkGreen
            # 19, 161, 14
        }
    }

    try
    {
        $queryScriptBlock = {

            # Gather data from performance counters and CIM system
            $perfCounter        = Get-Counter -Counter '\Processor Information(_Total)\% Processor Utility', '\Memory\Available MBytes' -SampleInterval 1 -MaxSamples 1
            $cimComputerSystem  = Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property 'Name', 'Domain', 'NumberOfLogicalProcessors'
            $cimOperatingSystem = Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property 'Caption', 'Version', 'OSLanguage', 'OSArchitecture', 'LastBootUpTime', 'TotalVisibleMemorySize'
            $cimVolumeSystem    = Get-CimInstance -ClassName 'Win32_Volume' -Filter "DriveLetter = 'C:'" -Property 'FreeSpace', 'Capacity'
            $cimVolumeAll       = Get-CimInstance -ClassName 'Win32_Volume' -Property 'Capacity'
            $cimPageFile        = Get-CimInstance -ClassName 'Win32_PageFileUsage' -Property 'CurrentUsage', 'AllocatedBaseSize'
            $processCount       = (Get-Process).Count
            $connectionCount    = (netstat.exe -n).Count - 4    # Subtract the netstat header
            $sessionCount       = (qwinsta.exe).Count - 3   # Subtract the qwinsta header and the two built-in sessions

            [PSCustomObject] @{
                Timestamp       = [System.DateTime]::Now
                Hostname        = $cimComputerSystem.Name + $(if ($cimComputerSystem.Domain -ne 'WORKGROUP') { '.' + $cimComputerSystem.Domain } )
                PowerShell      = $PSVersionTable.PSVersion
                OperatingSystem = [PSCustomObject] @{
                    Name            = $cimOperatingSystem.Caption.Replace('Microsoft Windows', 'Windows')
                    Version         = $cimOperatingSystem.Version
                    Language        = [System.Globalization.CultureInfo]::new([int] $cimOperatingSystem.OSLanguage).Name
                    Architecture    = $cimOperatingSystem.OSArchitecture
                }
                SystemUptime    = [System.DateTime]::Now - $cimOperatingSystem.LastBootUpTime
                SystemBootTime  = $cimOperatingSystem.LastBootUpTime
                ProcessorLoad   = $perfCounter.CounterSamples.Where({$_.Path -like '\\*\Processor Information(_Total)\% Processor Utility'}).CookedValue * $cimComputerSystem.NumberOfLogicalProcessors / 100
                ProcessorUsage  = $perfCounter.CounterSamples.Where({$_.Path -like '\\*\Processor Information(_Total)\% Processor Utility'}).CookedValue / 100
                ProcessorCount  = $cimComputerSystem.NumberOfLogicalProcessors
                SystemDiskUsage = ($cimVolumeSystem.Capacity - $cimVolumeSystem.FreeSpace) / $cimVolumeSystem.Capacity
                SystemDiskSize  = $cimVolumeSystem.Capacity / 1GB
                AllDiskSize     = ($cimVolumeAll | Measure-Object -Property 'Capacity' -Sum | Select-Object -ExpandProperty 'Sum') / 1GB
                MemoryUsage     = (($cimOperatingSystem.TotalVisibleMemorySize / 1KB) - $perfCounter.CounterSamples.Where({$_.Path -like '\\*\Memory\Available MBytes'}).CookedValue) / ($cimOperatingSystem.TotalVisibleMemorySize / 1KB)
                MemorySize      = $cimOperatingSystem.TotalVisibleMemorySize / 1MB
                PageUsage       = $cimPageFile.CurrentUsage / $cimPageFile.AllocatedBaseSize
                PageSize        = $cimPageFile.AllocatedBaseSize / 1KB
                ProcessCount    = $processCount
                ConnectionCount = $connectionCount
                SessionCount    = $sessionCount
            }
        }

        if ($PSBoundParameters.ContainsKey('Session'))
        {
            $queryResult = Invoke-Command -Session $Session -ScriptBlock $queryScriptBlock
        }
        else
        {
            $queryResult = & $queryScriptBlock
        }

        $summarySystemLoad = Format-HostText -Message ('{0:0.000}' -f $queryResult.ProcessorLoad) -ForegroundColor (Get-Color -Value $queryResult.ProcessorUsage -WarningThreshold 0.6 -ErrorThreshold 0.8)

        $summaryDiskUsed = Format-HostText -Message ('{0:0.0%}' -f $queryResult.SystemDiskUsage) -ForegroundColor (Get-Color -Value $queryResult.SystemDiskUsage -WarningThreshold 0.8 -ErrorThreshold 0.9)
        $summaryDiskUsed = '{0} of {1:0}GB' -f $summaryDiskUsed, $queryResult.SystemDiskSize

        # If the all disk size is greater than the system disk (plus 2GB for the
        # the EFI boot and recovery partition), show it after the system disk
        # size in ths system information summary.
        $summaryDiskAllSizeText = ''
        if ($queryResult.AllDiskSize -gt ($queryResult.SystemDiskSize + 2))
        {
            $summaryDiskAllSizeText = '+{0:0}GB' -f ($queryResult.AllDiskSize - $queryResult.SystemDiskSize)
        }

        $summaryMemoryUsage = Format-HostText -Message ('{0:0%}' -f $queryResult.MemoryUsage) -ForegroundColor (Get-Color -Value $queryResult.MemoryUsage -WarningThreshold 0.7 -ErrorThreshold 0.85)
        $summaryMemoryUsage = '{0} of {1:0}GB' -f $summaryMemoryUsage, $queryResult.MemorySize

        $summaryPageUsage = Format-HostText -Message ('{0:0%}' -f $queryResult.PageUsage) -ForegroundColor (Get-Color -Value $queryResult.PageUsage -WarningThreshold 0.6 -ErrorThreshold 0.8)
        $summaryPageUsage = '{0} of {1:0}GB' -f $summaryPageUsage, $queryResult.PageSize

        $summary = [System.Text.StringBuilder]::new()
        [void] $summary.AppendLine()
        [void] $summary.AppendFormat('Welcome to PowerShell {0}.{1} on {2}', $queryResult.PowerShell.Major, $queryResult.PowerShell.Minor, $queryResult.OperatingSystem.Name).AppendLine()
        [void] $summary.AppendLine()
        [void] $summary.AppendFormat('  System information as of {0:dd.MM.yyyy HH:mm:ss zzz}', $queryResult.Timestamp).AppendLine()
        [void] $summary.AppendFormat('   {0}  󰓯 {1}   {2}   {3}  󰚗 {4:0}GB  󰋊 {5:0}GB{6}', $queryResult.OperatingSystem.Version, $queryResult.OperatingSystem.Architecture, $queryResult.OperatingSystem.Language, $queryResult.ProcessorCount, $queryResult.MemorySize, $queryResult.SystemDiskSize, $summaryDiskAllSizeText).AppendLine()
        [void] $summary.AppendLine()
        [void] $summary.AppendFormat('    System load   : {0,-40:0}     Hostname      : {1}', $summarySystemLoad, $queryResult.Hostname).AppendLine()
        [void] $summary.AppendFormat('  󰚗  Memory usage  : {0,-40:0}     Processes     : {1}', $summaryMemoryUsage, $queryResult.ProcessCount).AppendLine()
        [void] $summary.AppendFormat('  󱪓  Page usage    : {0,-40:0}   󰴽  Connections   : {1}', $summaryPageUsage, $queryResult.ConnectionCount).AppendLine()
        [void] $summary.AppendFormat('  󰋊  C:\ disk used : {0,-40:0}   󰡉  User sessions : {1}', $summaryDiskUsed, $queryResult.SessionCount).AppendLine()
        [void] $summary.AppendLine()
        Format-HostText -StringBuilder $summary -ForegroundColor $colorDarkGray -Message '  󰢫  Troubleshooting' -AppendLine
        Format-HostText -StringBuilder $summary -ForegroundColor $colorDarkGray -Message '  ¦ Invoke-WindowsAnalyzer    Measure-Processor         Measure-Storage' -AppendLine
        Format-HostText -StringBuilder $summary -ForegroundColor $colorDarkGray -Message '  ¦ Measure-System            Measure-Memory            Measure-Session' -AppendLine
        [void] $summary.AppendLine()
        Format-HostText -StringBuilder $summary -ForegroundColor $colorDarkGray -Message '    System Auditing' -AppendLine
        Format-HostText -StringBuilder $summary -ForegroundColor $colorDarkGray -Message '  ¦ Install-Module -Name "SecurityFever" -Repository "PSGallery" -Force' -AppendLine
        Format-HostText -StringBuilder $summary -ForegroundColor $colorDarkGray -Message '  ¦ Get-SystemAuditFileSystem         Get-SystemAuditPowerCycle' -AppendLine
        Format-HostText -StringBuilder $summary -ForegroundColor $colorDarkGray -Message '  ¦ Get-SystemAuditGroupPolicy        Get-SystemAuditUserSession' -AppendLine
        Format-HostText -StringBuilder $summary -ForegroundColor $colorDarkGray -Message '  ¦ Get-SystemAuditMsiInstaller       Get-SystemAuditWindowsService' -AppendLine
        [void] $summary.AppendLine()
        [void] $summary.AppendFormat('Up since {0:d\d\ h\h\ m\m} startet on {1:ddd d. MMMM yyyy HH:mm}', $queryResult.SystemUptime, $queryResult.SystemBootTime).AppendLine()

        Write-Host $summary.ToString()
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
