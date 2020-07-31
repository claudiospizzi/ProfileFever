<#
    .SYNOPSIS
        Get the current processor usage on the local system.

    .DESCRIPTION
        Use WMI/CIM and the Windows Performance Counters to retrieve the current
        processor usage on the local system.
        - S | C | L
          Number of active sockets, cores, and logical processors.
        - Speed
          Current average CPU speed in MHz.
        - Hyper-V
          If available, the current usage in percent on the Hyper-V Host level.
          This is the sum of the host system including all guest VMs and is
          higher than the local CPU usage.
        - Usage
          The local CPU usage in percent.
        - Queue
          Number of processes in ready state. This does not include the
          currently active processes.

    .EXAMPLE
        PS C:\> top
        Use the alias of Get-CounterProcessor to show the current processor
        usage.
#>
function Get-CounterProcessor
{
    [CmdletBinding()]
    [Alias('top')]
    param
    (
        # Flag to continue showing the memory every second.
        [Parameter(Mandatory = $false)]
        [Alias('c')]
        [Switch]
        $Continue
    )

    $vmmService = Get-Service -Name 'vmms' -ErrorAction 'SilentlyContinue'
    if ($null -ne $vmmService -and $vmmService.Status -eq 'Running')
    {
        $vmmSvcActive = $true
        $counterNames = '\Processor Information(_Total)\% Processor Time',
                        '\System\Processor Queue Length',
                        '\Hyper-V Hypervisor Logical Processor(_Total)\% Total Run Time'
    }
    else
    {
        $vmmSvcActive = $false
        $counterNames = '\Processor Information(_Total)\% Processor Time',
                        '\System\Processor Queue Length'
    }

    # Global counters, will not change
    $cimProcessorSCP = Get-CimInstance -ClassName 'Win32_Processor' -Property 'NumberOfCores', 'NumberOfLogicalProcessors'
    $infoSockets    = ($cimProcessorSCP | Measure-Object).Count
    $infoCores      = ($cimProcessorSCP | Measure-Object -Sum 'NumberOfCores').Sum
    $infoPrcessors  = ($cimProcessorSCP | Measure-Object -Sum 'NumberOfLogicalProcessors').Sum

    do
    {
        # Counters new for every run
        $perfCounterProcessor = Get-Counter -Counter $counterNames -SampleInterval 1 -MaxSamples 1
        $cimProcessorClock    = Get-CimInstance -ClassName 'Win32_Processor' -Property 'CurrentClockSpeed'

        [PSCustomObject] @{
            PSTypeName = 'ProfileFever.ProcessorCounter'
            Timestamp  = Get-Date
            Name       = 'Processor'
            Sockets    = $infoSockets
            Cores      = $infoCores
            Prcessors  = $infoPrcessors
            Clock      = ($cimProcessorClock | Measure-Object -Average 'CurrentClockSpeed').Average
            HyperV     = $(if ($vmmSvcActive) { [System.Math]::Round($perfCounterProcessor.CounterSamples.Where({$_.Path -like '\\*\Hyper-V Hypervisor Logical Processor(_Total)\% Total Run Time'}).CookedValue, 1) } else { 'n/a' })
            Usage      = $perfCounterProcessor.CounterSamples.Where({$_.Path -like '\\*\Processor Information(_Total)\% Processor Time'}).CookedValue
            Queue      = $perfCounterProcessor.CounterSamples.Where({$_.Path -like '\\*\System\Processor Queue Length'}).CookedValue
        }
    }
    while ($Continue.IsPresent)
}
