﻿<#
    .SYNOPSIS
        Get the current processor usage on the local system.

    .DESCRIPTION
        Use WMI/CIM and the Windows Performance Counters to retrieve the current
        processor usage on the local system.
        - Hyper-V
          If available, the current usage in percent on the Hyper-V Host level.
          This is the sum of the host system including all guest VMs and is
          higher than the local CPU usage.
        - Usage
          The local CPU usage in percent.
        - Queue
          Number of processes in ready state. This does not include the
          currently active processes.
        - Clock
          Current average CPU speed in MHz.

    .EXAMPLE
        PS C:\> processor
        Use the alias of Measure-Processor to show the current processor
        usage.
#>
function Measure-Processor
{
    [CmdletBinding()]
    [Alias('processor')]
    param
    (
        # Flag to continue showing the memory every second.
        [Parameter(Mandatory = $false)]
        [Alias('c')]
        [Switch]
        $Continue,

        # Threshold for the processor usage in percent. If the threshold is
        # reached, a warning message will be shown.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $ProcessorUsagePercentThreshold = 80,

        # Threshold for the processor queue length. If the threshold is reached,
        # a warning message will be shown.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $ProcessorQueueLengthThreshold = 10,

        # Threshold for the Hyper-V Hypervisor Logical Processor Total Run Time
        # in percent. If the threshold is reached, a warning message will be
        # shown.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $HyperVUsagePercentThreshold = 75
    )

    $vmmService = Get-Service -Name 'vmms' -ErrorAction 'SilentlyContinue'
    if ($null -ne $vmmService -and $vmmService.Status -eq 'Running')
    {
        $vmmSvcActive = $true
        $counterNames = '\Processor Information(_Total)\% Processor Time',
                        '\System\Context Switches/sec',
                        '\System\Processor Queue Length',
                        '\Hyper-V Hypervisor Logical Processor(_Total)\% Total Run Time'
    }
    else
    {
        $vmmSvcActive = $false
        $counterNames = '\Processor Information(_Total)\% Processor Time',
                        '\System\Context Switches/sec',
                        '\System\Processor Queue Length'
    }

    # Global counters, will not change
    $cimProcessorInfo = Get-CimInstance -ClassName 'Win32_Processor' -Property 'NumberOfLogicalProcessors' | Measure-Object -Sum 'NumberOfLogicalProcessors'

    do
    {
        # Counters new for every run
        $perfCounterProcessor = Get-Counter -Counter $counterNames -SampleInterval 1 -MaxSamples 1
        $cimProcessorClock    = Get-CimInstance -ClassName 'Win32_Processor' -Property 'CurrentClockSpeed'

        $counterProc = [PSCustomObject] @{
            PSTypeName = 'ProfileFever.Performance.Processor'
            Timestamp  = Get-Date
            Name       = '{0:0}x{1:0} Processors' -f $cimProcessorInfo.Count, ($cimProcessorInfo.Sum / $cimProcessorInfo.Count)
            HyperV     = $(if ($vmmSvcActive) { [System.Math]::Round($perfCounterProcessor.CounterSamples.Where({$_.Path -like '\\*\Hyper-V Hypervisor Logical Processor(_Total)\% Total Run Time'}).CookedValue, 1) } else { -1 })
            Usage      = $perfCounterProcessor.CounterSamples.Where({$_.Path -like '\\*\Processor Information(_Total)\% Processor Time'}).CookedValue
            Queue      = $perfCounterProcessor.CounterSamples.Where({$_.Path -like '\\*\System\Processor Queue Length'}).CookedValue
            Clock      = ($cimProcessorClock | Measure-Object -Average 'CurrentClockSpeed').Average
        }
        Write-Output $counterProc

        # Show warning messages if thresholds are reached
        if ($counterProc.Usage -gt $ProcessorUsagePercentThreshold)
        {
            Write-Warning ('The Processor Time is {0:0.0}% exceeding {1}%' -f $counterProc.Usage, $ProcessorUsagePercentThreshold)
        }
        if ($counterProc.Queue -gt $ProcessorQueueLengthThreshold)
        {
            Write-Warning ('The Processor Queue Length is {0:0} exceeding {1}' -f $counterProc.Queue, $ProcessorQueueLengthThreshold)
        }
        if ($counterProc.HyperV -ne 'n/a' -and $counterProc.HyperV -gt $HyperVUsagePercentThreshold)
        {
            Write-Warning ('The Hyper-V Hypervisor Logical Processor Total Run Time is {0:0.0}% exceeding {1}%' -f $counterProc.HyperV. $HyperVUsagePercentThreshold)
        }
    }
    while ($Continue.IsPresent)
}
