<#
    .SYNOPSIS
        Get the current memory usage on the local system.

    .DESCRIPTION
        Use WMI/CIM and the Windows Performance counters to retrieve the current
        memory usage on the local system.
        - Total
          Installed physical memory on the system excluding the hardware
          reserved memory part.
        - Used
          Memory currently in use by a process or the system.
        - Free
          Size of the free and zeroed memory. This memory does not contain
          cached data, it is immediately available for allocation.
        - Cache
          This memory contains cached data and code that is not actively in use.
          It is immediately available for allocation.
        - Available
          The summary of free and cached memory.

    .EXAMPLE
        PS C:\> memory
        Use the alias of Measure-Memory to show the current memory usage.
#>
function Measure-Memory
{
    [CmdletBinding()]
    [Alias('memory')]
    param
    (
        # Flag to continue showing the memory every second.
        [Parameter(Mandatory = $false)]
        [Alias('c')]
        [Switch]
        $Continue,

        # Threshold for the memory available in mega bytes. If the threshold is
        # reached, a warning message will be shown.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $MemoryAvailableMegaByteThreshold = 100,

        # Threshold for the memory available in percent. If the threshold is
        # reached, a warning message will be shown.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $MemoryAvailablePercentThreshold = 10,

        # Threshold for the page file usage in percent. If the threshold is
        # reached, a warning message will be shown.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $PageFileUsedPercentThreshold = 80
    )

    $counterNames = '\Memory\Available MBytes',
                    '\Memory\Free & Zero Page List Bytes',
                    '\Memory\Standby Cache Core Bytes',
                    '\Memory\Standby Cache Normal Priority Bytes',
                    '\Memory\Standby Cache Reserve Bytes'

    # Global counters, will not change.
    $cimOperatingSystem = Get-CimInstance -ClassName 'Win32_OperatingSystem'

    do
    {
        # Counters new for every run.
        $perfCounterMemory = Get-Counter -Counter $counterNames -SampleInterval 1 -MaxSamples 1
        $cimPageFileUsage  = Get-CimInstance -ClassName 'Win32_PageFileUsage'

        $timestamp = Get-Date

        $counterMemory = [PSCustomObject] @{
            PSTypeName = 'ProfileFever.Performance.Memory'
            Timestamp  = $timestamp
            Name       = 'Physical Memory'
            Total      = [System.Int32] ($cimOperatingSystem.TotalVisibleMemorySize / 1KB)
            Used       = [System.Int32] ($cimOperatingSystem.TotalVisibleMemorySize / 1KB) - $perfCounterMemory.CounterSamples.Where({$_.Path -like '\\*\Memory\Available MBytes'}).CookedValue
            Free       = [System.Int32] ($perfCounterMemory.CounterSamples.Where({$_.Path -like '\\*\Memory\Free & Zero Page List Bytes'}).CookedValue / 1MB)
            Cache      = [System.Int32] (($perfCounterMemory.CounterSamples.Where({$_.Path -like '\\*\Memory\Standby Cache * Bytes'}).CookedValue | Measure-Object -Sum).Sum / 1MB)
            Available  = [System.Int32] $perfCounterMemory.CounterSamples.Where({$_.Path -like '\\*\Memory\Available MBytes'}).CookedValue
        }
        Write-Output $counterMemory

        $counterPage = [PSCustomObject] @{
            PSTypeName = 'ProfileFever.Performance.Memory'
            Timestamp  = $timestamp
            Name       = 'Page File'
            Total      = $cimPageFileUsage.AllocatedBaseSize
            Used       = $cimPageFileUsage.CurrentUsage
            Free       = $cimPageFileUsage.AllocatedBaseSize - $cimPageFileUsage.CurrentUsage
            Cache      = $null
            Available  = $null
        }
        Write-Output $counterPage

        # Show warning messages if thresholds are reached.
        if ($counterMemory.Available -lt $MemoryAvailableMegaByteThreshold)
        {
            Write-Warning ('The Memory Available is {0:0}MB falling below {1}MB' -f $counterMemory.Available, $MemoryAvailableMegaByteThreshold)
        }
        $counterMemoryAvailablePercent = $counterMemory.Available / $counterMemory.Total * 100
        if ($counterMemoryAvailablePercent -lt $MemoryAvailablePercentThreshold)
        {
            Write-Warning ('The Memory Available is {0:0}% falling below {1}%' -f $counterMemoryAvailablePercent, $MemoryAvailablePercentThreshold)
        }
        $counterPageUsedOfMemoryPercent = $counterPage.Used / $counterMemory.Total * 100
        if ($counterPageUsedOfMemoryPercent -gt $PageFileUsedPercentThreshold)
        {
            Write-Warning ('The Page File Usage is {0:0.0}% exceeding {1}% compared to the Memory Total' -f $counterPageUsedOfMemoryPercent, $PageFileUsedPercentThreshold)
        }
    }
    while ($Continue.IsPresent)
}
