<#
    .SYNOPSIS
        Get the current local system info.

    .DESCRIPTION
        Use WMI/CIM to retrieve the local system info.
        - Update
          Duration since the last system boot up time.

    .EXAMPLE
        PS C:\> system
        Use the alias of Measure-System to show the current system info.
#>
function Measure-System
{
    [CmdletBinding()]
    [Alias('system')]
    param ()

    $cimComputerSystem  = Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property 'Name', 'Domain', 'TotalPhysicalMemory', 'Manufacturer', 'Model'
    $cimOperatingSystem = Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property 'Caption', 'InstallDate', 'LocalDateTime', 'LastBootUpTime'
    $cimProcessorInfo   = Get-CimInstance -ClassName 'Win32_Processor' -Property 'Name', 'NumberOfLogicalProcessors'
    # $cimLogicalDisks    = Get-CimInstance -ClassName 'Win32_LogicalDisk' -Property  | Where-Object { $_.DriveType -eq 3 }

    [PSCustomObject] @{
        PSTypeName       = 'ProfileFever.Performance.System'
        Name             = $cimComputerSystem.Name
        Domain           = $cimComputerSystem.Domain
        Timestamp        = $cimOperatingSystem.LocalDateTime
        Uptime           = $cimOperatingSystem.LocalDateTime - $cimOperatingSystem.LastBootUpTime
        StartupDate      = $cimOperatingSystem.LastBootUpTime
        OperatingSystem  = $cimOperatingSystem.Caption
        Manufacturer     = $cimComputerSystem.Manufacturer
        Model            = $cimComputerSystem.Model
        ProcessorInfo    = $cimProcessorInfo.Name
        ProcessorCores   = $cimProcessorInfo | Measure-Object -Sum 'NumberOfLogicalProcessors' | Select-Object -ExpandProperty 'Sum'
        PhysicalMemoryMB = $cimComputerSystem.TotalPhysicalMemory / 1MB -as [int]
        InstallationDate = $cimOperatingSystem.InstallDate
    }
}
