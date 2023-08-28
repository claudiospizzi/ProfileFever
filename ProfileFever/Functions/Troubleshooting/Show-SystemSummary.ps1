<#
    .SYNOPSIS
        .

    .DESCRIPTION
        .

    .INPUTS
        .

    .OUTPUTS
        .

    .EXAMPLE
        PS C:\> Show-SystemSummary
        .

    .LINK
        https://github.com/claudiospizzi/ProfileFever
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

    try
    {
        $queryScriptBlock = {

            # Gather data from performance counters and CIM system
            $perfCounter        = Get-Counter -Counter '\Processor Information(_Total)\% Processor Time', '\Memory\Available MBytes' -SampleInterval 1 -MaxSamples 1
            $cimComputerSystem  = Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property 'Name', 'Domain'
            $cimOperatingSystem = Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property 'Caption', 'Version', 'OSLanguage', 'OSArchitecture', 'LastBootUpTime', 'TotalVisibleMemorySize'
            $cimVolumeSystem    = Get-CimInstance -ClassName 'Win32_Volume' -Filter "DriveLetter = 'C:'" -Property 'FreeSpace', 'Capacity'
            $cimPageFile        = Get-CimInstance -ClassName 'Win32_PageFileUsage' -Property 'CurrentUsage', 'AllocatedBaseSize'
            $processCount       = (Get-Process).Count
            $connectionCount    = (netstat -n).Count - 4    # Subtract the netstat header
            $sessionCount       = (qwinsta.exe).Count - 3   # Subtract the qwinsta header and the two built-in sessions

            [PSCustomObject] @{
                Timestamp       = [System.DateTime]::Now
                Hostname        = $cimComputerSystem.Name + $(if ($cimComputerSystem.Domain -ne 'WORKGROUP') { '.' + $cimComputerSystem.Domain } )
                OperatingSystem = [PSCustomObject] @{
                    Name            = $cimOperatingSystem.Caption.Replace('Microsoft Windows', 'Windows')
                    Version         = $cimOperatingSystem.Version
                    Language        = [System.Globalization.CultureInfo]::new([int] $cimOperatingSystem.OSLanguage).Name
                    Architecture    = $cimOperatingSystem.OSArchitecture
                }
                SystemUptime    = [System.DateTime]::Now - $cimOperatingSystem.LastBootUpTime
                SystemBootTime  = $cimOperatingSystem.LastBootUpTime
                ProcessorLoad   = $perfCounter.CounterSamples.Where({$_.Path -like '\\*\Processor Information(_Total)\% Processor Time'}).CookedValue
                SystemDiskUsage = ($cimVolumeSystem.Capacity - $cimVolumeSystem.FreeSpace) / $cimVolumeSystem.Capacity
                SystemDiskSize  = $cimVolumeSystem.Capacity / 1GB
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

        $colorDarkGray = 118, 118, 118

        $summarySystemLoad  = '{0:0.000}' -f $queryResult.ProcessorLoad
        $summaryDiskUsed    = '{0:0.0%} of {1:0}GB' -f $queryResult.SystemDiskUsage, $queryResult.SystemDiskSize
        $summaryMemoryUsage = '{0:0%} of {1:0}GB' -f $queryResult.MemoryUsage, $queryResult.MemorySize
        $summaryPageUsage   = '{0:0%} of {1:0}GB' -f $queryResult.PageUsage, $queryResult.PageSize

        $summary = [System.Text.StringBuilder]::new()
        [void] $summary.AppendFormat('Welcome to {0} ({1} {2} {3})', $queryResult.OperatingSystem.Name, $queryResult.OperatingSystem.Version, $queryResult.OperatingSystem.Language, $queryResult.OperatingSystem.Architecture).AppendLine()
        [void] $summary.AppendLine()
        [void] $summary.AppendFormat('  System information as of {0:dd.MM.yyyy HH:mm:ss zzz}', $queryResult.Timestamp).AppendLine()
        [void] $summary.AppendLine()
        [void] $summary.AppendFormat('  System load   : {0,-20:0}   Hostname      : {1}', $summarySystemLoad, $queryResult.Hostname).AppendLine()
        [void] $summary.AppendFormat('  C:\ disk used : {0,-20:0}   Processes     : {1}', $summaryDiskUsed, $queryResult.ProcessCount).AppendLine()
        [void] $summary.AppendFormat('  Memory usage  : {0,-20:0}   Connections   : {1}', $summaryMemoryUsage, $queryResult.ConnectionCount).AppendLine()
        [void] $summary.AppendFormat('  Page usage    : {0,-20:0}   User sessions : {1}', $summaryPageUsage, $queryResult.SessionCount).AppendLine()
        [void] $summary.AppendLine()
        [void] $summary.AppendLine(' {0}' -f (Format-HostText -Message '¦ Troubleshoot commands:' -ForegroundColor $colorDarkGray))
        [void] $summary.AppendLine(' {0}' -f (Format-HostText -Message '¦ Invoke-WindowsAnalyzer     Measure-Processor       Measure-Storage' -ForegroundColor $colorDarkGray))
        [void] $summary.AppendLine(' {0}' -f (Format-HostText -Message '¦ Measure-System             Measure-Memory          Measure-Session' -ForegroundColor $colorDarkGray))
        [void] $summary.AppendLine()
        [void] $summary.AppendFormat('Up since {0:d\d\ h\h\ m\m} startet on {1:ddd d. MMM yyyy HH:mm}', $queryResult.SystemUptime, $queryResult.SystemBootTime).AppendLine()

        Write-Host $summary.ToString()


        # 'Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-79-generic x86_64)'


        # $colorWarning = 255, 204, 0

        # $queryScriptBlock = {
        #     [PSCustomObject] @{
        #         Timestamp          = Get-Date
        #         PerformanceCounter = Get-Counter -Counter '\Processor Information(_Total)\% Processor Time', '\Memory\Available MBytes' -SampleInterval 1 -MaxSamples 1
        #         CimComputerSystem  = Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property 'Name'
        #         CimOperatingSystem = Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property 'Caption', 'LastBootUpTime', 'TotalVisibleMemorySize'
        #         CimVolumeC         = Get-CimInstance -ClassName 'Win32_Volume' -Filter "DriveLetter = 'C:'" -Property 'FreeSpace', 'Capacity'
        #         CimPageFileUsage   = Get-CimInstance -ClassName 'Win32_PageFileUsage' -Property 'CurrentUsage', 'AllocatedBaseSize'
        #     }
        # }


        # # System load
        # $summarySystemLoad = $queryResult.PerformanceCounter
        # $summarySystemLoadText = '{0:0.0}%' -f $summarySystemLoad
        # if ($summarySystemLoad -gt 80)
        # {
        #     $summarySystemLoadText = Format-HostText -Message $summarySystemLoadText -ForegroundColor $colorWarning
        # }

        # # Disk used
        # $summaryDiskUsed = ($queryResult.CimVolumeC.Capacity - $queryResult.CimVolumeC.FreeSpace) / $queryResult.CimVolumeC.Capacity * 100
        # $summaryDiskUsedText = '{0:0.0}%' -f $summaryDiskUsed
        # if ($summaryDiskUsed -gt 90)
        # {
        #     $summaryDiskUsedText = Format-HostText -Message $summaryDiskUsedText -ForegroundColor $colorWarning
        # }
        # $summaryDiskUsedText += (' of {0}GB' -f $queryResult.CimVolumeC.Capacity)

        # # Memory usage
        # $summaryMemoryUsage = (($queryResult.CimOperatingSystem.TotalVisibleMemorySize / 1KB) - $perfCounter.CounterSamples.Where({$_.Path -like '\\*\Memory\Available MBytes'}).CookedValue) / ($queryResult.CimOperatingSystem.TotalVisibleMemorySize / 1KB) * 100
        # $summaryMemoryUsageText = '{0:0}%' -f $summaryMemoryUsage
        # if ($summaryMemoryUsage -gt 90)
        # {
        #     $summaryMemoryUsageText = Format-HostText -Message $summaryMemoryUsageText -ForegroundColor $colorWarning
        # }


        # $summary = [System.Text.StringBuilder]::new()
        # $summary.AppendLine() | Out-Null
        # $summary.AppendFormat('  System information as of {0:dd.MM.yyyy HH:mm:ss zzz} on {1}', $queryResult.Timestamp, $queryResult.CimComputerSystem.Name) | Out-Null
        # $summary.AppendLine() | Out-Null
        # $summary.AppendFormat('  System load:  {0,40}x', $summarySystemLoadText) | Out-Null
        # $summary.AppendLine()
        # $summary.AppendFormat('  Disk used:    {0,40}x', $summaryDiskUsedText) | Out-Null
        # $summary.AppendLine()
        # $summary.AppendFormat('  Memory usage: {0,40}x', $summaryMemoryUsageText) | Out-Null
        # $summary.AppendLine()

        # Write-Host $summary.ToString()
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
