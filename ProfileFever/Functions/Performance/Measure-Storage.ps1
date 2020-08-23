<#
    .SYNOPSIS
        Get the current storage usage on the local system.

    .DESCRIPTION
        Use WMI/CIM and the Windows Performance Counters to retrieve the current
        storage usage on the local system.
        - Size
          The volume size in GB.
        - Free
          The free size in GB.
        - Usage
          Current disk activity time in percent.
        - Queue
          Current disk queue length.
        - AvgRead
          Average duration in seconds for read operations.
        - AvgWrite
          Average duration in seconds for write operations.
        - IOPS
          Number of read and write operations.

    .EXAMPLE
        PS C:\> storage
        Use the alias of Measure-Storage to show the current memory usage.
#>
function Measure-Storage
{
    [CmdletBinding()]
    [Alias('storage')]
    param
    (
        # Flag to continue showing the memory every second.
        [Parameter(Mandatory = $false)]
        [Alias('c')]
        [Switch]
        $Continue
    )

    $counterNames = '\PhysicalDisk(*)\% Disk Time',
                    '\PhysicalDisk(*)\Avg. Disk sec/Read',
                    '\PhysicalDisk(*)\Avg. Disk sec/Write',
                    '\PhysicalDisk(*)\Disk Transfers/sec',
                    '\PhysicalDisk(*)\Current Disk Queue Length'

    # Gather all volumes, partitions and disks.
    $volumes = Get-CimInstance -ClassName 'Win32_Volume' | Where-Object { $_.Name -like '?:\*' -and $_.DriveType -ne 5 } | Select-Object 'Name', 'DeviceID', 'DriveLetter', 'FreeSpace', 'Capacity'
    $partitions = Get-CimInstance -ClassName 'MSFT_Partition' -Namespace 'Root/Microsoft/Windows/Storage' | Select-Object 'DiskNumber', 'AccessPaths'

    do
    {
        # Counters new for every run.
        $perfCounterStorage = Get-Counter -Counter $counterNames -SampleInterval 1 -MaxSamples 1

        $timestamp = Get-Date

        # Iterating all volumes, get the matching partition and create a new
        # performance counter object.
        foreach ($volume in $volumes)
        {
            $partition = $partitions | Where-Object { $_.AccessPaths -contains $volume.DeviceID } | Select-Object -First 1

            $perfCounterStorageIdentifier = '{0}*{1}*' -f $partition.DiskNumber, $volume.DriveLetter

            $counterDisk = [PSCustomObject] @{
                PSTypeName = 'ProfileFever.Performance.Storage'
                Timestamp  = $timestamp
                Name       = '{0} {1}' -f $partition.DiskNumber, $volume.Name
                Size       = $volume.Capacity / 1GB
                Free       = $volume.FreeSpace / 1GB
                DiskTime   = $perfCounterStorage.CounterSamples.Where({$_.Path -like "\\*\PhysicalDisk($perfCounterStorageIdentifier)\% Disk Time"}).CookedValue
                DiskQueue  = $perfCounterStorage.CounterSamples.Where({$_.Path -like "\\*\PhysicalDisk($perfCounterStorageIdentifier)\Current Disk Queue Length"}).CookedValue
                AvgRead    = $perfCounterStorage.CounterSamples.Where({$_.Path -like "\\*\PhysicalDisk($perfCounterStorageIdentifier)\Avg. Disk sec/Read"}).CookedValue
                AvgWrite   = $perfCounterStorage.CounterSamples.Where({$_.Path -like "\\*\PhysicalDisk($perfCounterStorageIdentifier)\Avg. Disk sec/Write"}).CookedValue
                IOPS       = $perfCounterStorage.CounterSamples.Where({$_.Path -like "\\*\PhysicalDisk($perfCounterStorageIdentifier)\Disk Transfers/sec"}).CookedValue
            }
            Write-Output $counterDisk

            # Show warning messages if thresholds are reached.
            if ($counterDisk.Free -lt 1)
            {
                Write-Warning ('The Disk {0} Free Space is {1:0}MB falling below 1GB' -f $counterDisk.Name, ($counterDisk.Free * 1000))
            }
            $counterDiskFreePercent = $counterDisk.Free / $counterDisk.Size * 100
            if ($counterDiskFreePercent -lt 5)
            {
                Write-Warning ('The Disk {0} Free Space is {1:0.0}% falling below 5%' -f $counterDisk.Name, $counterDiskFreePercent)
            }
            if ($counterDisk.DiskTime -gt 80)
            {
                Write-Warning ('The Disk {0} Disk Time is {1:0.0} exceeding 80%' -f $counterDisk.Name, $counterDisk.DiskTime)
            }
            if ($counterDisk.DiskQueue -gt 2)
            {
                Write-Warning ('The Disk {0} Queue Length is {1:0} exceeding 2' -f $counterDisk.Name, $counterDisk.DiskQueue)
            }
            if ($counterDisk.AvgRead -gt 0.010)
            {
                Write-Warning ('The Disk {0} Average Millisecond per Read is {1:0}ms exceeding 10ms' -f $counterDisk.Name, ($counterDisk.AvgRead * 1000))
            }
            if ($counterDisk.AvgWrite -gt 0.010)
            {
                Write-Warning ('The Disk {0} Average Millisecond per Write is {1:0}ms exceeding 10ms' -f $counterDisk.Name, ($counterDisk.AvgWrite * 1000))
            }
        }
    }
    while ($Continue.IsPresent)
}
