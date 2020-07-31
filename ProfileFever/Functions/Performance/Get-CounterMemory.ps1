<#
    .SYNOPSIS
        Get the current memory usage on the local system.

    .DESCRIPTION
        Use WMI/CIM and the Windows Performance Counters to retrieve the current
        memory usage on the local system.
        - Total
          Installed physical memory on the system excluding the hardware
          reserved memory part.
        - Used
          Memory currently in use by a process or the system..
        - Free
          Size of the free and zeroed memory. This memory does not contian
          cached data, it is immediately available for allocation.
        - Cache
          This memory contains cached data and code that is not actively in use.
          It is immediately available for allocation."
        - Available
          The summary of free and cached memory.

    .EXAMPLE
        PS C:\> free
        Use the alias of Get-CounterMemory to show the current memory usage.
#>
function Get-CounterMemory
{
    [CmdletBinding()]
    [Alias('free')]
    param
    (
        # Flag to continue showing the memory every second.
        [Parameter(Mandatory = $false)]
        [Alias('c')]
        [Switch]
        $Continue
    )

    $counterNames = '\Memory\Available MBytes',
                    '\Memory\Free & Zero Page List Bytes',
                    '\Memory\Standby Cache Core Bytes',
                    '\Memory\Standby Cache Normal Priority Bytes',
                    '\Memory\Standby Cache Reserve Bytes'

    # Global counters, will not change
    $cimOperatingSystem = Get-CimInstance -ClassName 'Win32_OperatingSystem'

    do
    {
        # Counters new for every run
        $perfCounterMemory = Get-Counter -Counter $counterNames -SampleInterval 1 -MaxSamples 1
        $cimPageFileUsage  = Get-CimInstance -ClassName 'Win32_PageFileUsage'

        $timestamp = Get-Date

        [PSCustomObject] @{
            PSTypeName = 'ProfileFever.MemoryCounter'
            Timestamp  = $timestamp
            Name       = 'Physical Memory'
            Total      = [System.Int32] ($cimOperatingSystem.TotalVisibleMemorySize / 1KB)
            Used       = [System.Int32] ($cimOperatingSystem.TotalVisibleMemorySize / 1KB) - $perfCounterMemory.CounterSamples.Where({$_.Path -like '\\*\Memory\Available MBytes'}).CookedValue
            Free       = [System.Int32] ($perfCounterMemory.CounterSamples.Where({$_.Path -like '\\*\Memory\Free & Zero Page List Bytes'}).CookedValue / 1MB)
            Cache      = [System.Int32] (($perfCounterMemory.CounterSamples.Where({$_.Path -like '\\*\Memory\Standby Cache * Bytes'}).CookedValue | Measure-Object -Sum).Sum / 1MB)
            Available  = [System.Int32] $perfCounterMemory.CounterSamples.Where({$_.Path -like '\\*\Memory\Available MBytes'}).CookedValue
        }

        [PSCustomObject] @{
            PSTypeName = 'ProfileFever.MemoryCounter'
            Timestamp  = $timestamp
            Name       = 'Page File'
            Total      = $cimPageFileUsage.AllocatedBaseSize
            Used       = $cimPageFileUsage.CurrentUsage
            Free       = $cimPageFileUsage.AllocatedBaseSize - $cimPageFileUsage.CurrentUsage
            Cache      = $null
            Available  = $null
        }
    }
    while ($Continue.IsPresent)
}
