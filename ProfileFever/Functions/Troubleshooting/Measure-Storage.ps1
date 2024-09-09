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
        $Continue,

        # Threshold for the disk free space in giga bytes. If the threshold is
        # reached, a warning message will be shown.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $DiskFreeGigaByteThreshold = 5,

        # Threshold for the disk free space in percent. If the threshold is
        # reached, a warning message will be shown.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $DiskFreePercentThreshold = 5,

        # Threshold for the disk time in percent. If the threshold is reached, a
        # warning message will be shown.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $DiskTimePercentThreshold = 80,

        # Threshold for the disk queue length. If the threshold is reached, a
        # warning message will be shown.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $DiskQueueLengthThreshold = 2,

        # Threshold for the average read time in seconds. If the threshold is
        # reached, a warning message will be shown.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $AvgReadTimeMillisecondThreshold = 10,

        # Threshold for the average write time in seconds. If the threshold is
        # reached, a warning message will be shown.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $AvgWriteTimeMillisecondThreshold = 10
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
                Used       = ($volume.Capacity - $volume.FreeSpace) / 1GB
                DiskTime   = $perfCounterStorage.CounterSamples.Where({$_.Path -like "\\*\PhysicalDisk($perfCounterStorageIdentifier)\% Disk Time"}).CookedValue
                DiskQueue  = $perfCounterStorage.CounterSamples.Where({$_.Path -like "\\*\PhysicalDisk($perfCounterStorageIdentifier)\Current Disk Queue Length"}).CookedValue
                AvgRead    = $perfCounterStorage.CounterSamples.Where({$_.Path -like "\\*\PhysicalDisk($perfCounterStorageIdentifier)\Avg. Disk sec/Read"}).CookedValue
                AvgWrite   = $perfCounterStorage.CounterSamples.Where({$_.Path -like "\\*\PhysicalDisk($perfCounterStorageIdentifier)\Avg. Disk sec/Write"}).CookedValue
                IOPS       = $perfCounterStorage.CounterSamples.Where({$_.Path -like "\\*\PhysicalDisk($perfCounterStorageIdentifier)\Disk Transfers/sec"}).CookedValue
            }
            Write-Output $counterDisk

            # Show warning messages if thresholds are reached.
            if ($counterDisk.Free -lt $DiskFreeGigaByteThreshold)
            {
                Write-Warning ('The Disk {0} Free Space is {1:0}MB falling below {2}GB' -f $counterDisk.Name, ($counterDisk.Free * 1000), $DiskFreeGigaByteThreshold)
            }
            $counterDiskFreePercent = $counterDisk.Free / $counterDisk.Size * 100
            if ($counterDiskFreePercent -lt $DiskFreePercentThreshold)
            {
                Write-Warning ('The Disk {0} Free Space is {1:0.0}% falling below {2}%' -f $counterDisk.Name, $counterDiskFreePercent, $DiskFreePercentThreshold)
            }
            if ($counterDisk.DiskTime -gt $DiskTimePercentThreshold)
            {
                Write-Warning ('The Disk {0} Disk Time is {1:0.0} exceeding {2}%' -f $counterDisk.Name, $counterDisk.DiskTime, $DiskTimePercentThreshold)
            }
            if ($counterDisk.DiskQueue -gt $DiskQueueLengthThreshold)
            {
                Write-Warning ('The Disk {0} Queue Length is {1:0} exceeding {2}' -f $counterDisk.Name, $counterDisk.DiskQueue, $DiskQueueLengthThreshold)
            }
            $counterDiskAvgReadMillisecond = $counterDisk.AvgRead * 1000
            if ($counterDiskAvgReadMillisecond -gt $AvgReadTimeMillisecondThreshold)
            {
                Write-Warning ('The Disk {0} Average Millisecond per Read is {1:0}ms exceeding {2}ms' -f $counterDisk.Name, $counterDiskAvgReadMillisecond, $AvgReadTimeMillisecondThreshold)
            }
            $counterDiskAvgWriteMillisecond = $counterDisk.AvgWrite * 1000
            if ($counterDiskAvgWriteMillisecond -gt $AvgWriteTimeMillisecondThreshold)
            {
                Write-Warning ('The Disk {0} Average Millisecond per Write is {1:0}ms exceeding {2}ms' -f $counterDisk.Name, $counterDiskAvgWriteMillisecond, $AvgWriteTimeMillisecondThreshold)
            }
        }
    }
    while ($Continue.IsPresent)
}
