<#
    .SYNOPSIS
        Get the core performance counter and system information for the
        PowerShell Remoting launcher welcome screen.

    .DESCRIPTION
        This command will use CIM and Performance Counter as well as some other
        command line tools to get the current system summary. The summary will
        be returned as a PowerShell object.

    .EXAMPLE
        PS C:\> Get-LauncherPSRemotingWelcome
        Get the system summary of the local system.

    .EXAMPLE
        PS C:\> Get-LauncherPSRemotingWelcome -Session $session
        Get the system summary of the system behind the session.
#>
function Get-LauncherPSRemotingWelcome
{
    [CmdletBinding()]
    param
    (
        # Optional session to use for the system summary.
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [System.Management.Automation.Runspaces.PSSession]
        $Session
    )

    try
    {
        $queryScriptBlock = {

            # Use a sub-scope to have all variables cleared after this execution
            # to prevent polluting the execution environment.
            & {
                Set-StrictMode -Version latest

                switch -wildcard ([System.Globalization.CultureInfo]::InstalledUICulture.Name)
                {
                    'de-*'
                    {
                        $perfProcessorUtilityName = '\Prozessorinformationen(_Total)\Prozessorauslastung'
                        $perfMemoryAvailableName  = '\Arbeitsspeicher\Verfügbare MB'
                    }
                    default
                    {
                        $perfProcessorUtilityName = '\Processor Information(_Total)\% Processor Utility'
                        $perfMemoryAvailableName  = '\Memory\Available MBytes'
                    }
                }

                # Gather data from performance counters and CIM system
                $perfCounter        = Get-Counter -Counter $perfProcessorUtilityName, $perfMemoryAvailableName -SampleInterval 1 -MaxSamples 1
                $cimComputerSystem  = Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property 'Name', 'Domain', 'NumberOfProcessors', 'NumberOfLogicalProcessors'
                $cimOperatingSystem = Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property 'Caption', 'Version', 'OSLanguage', 'OSArchitecture', 'LastBootUpTime', 'TotalVisibleMemorySize'
                $cimPageFile        = Get-CimInstance -ClassName 'Win32_PageFileUsage' -Property 'CurrentUsage', 'AllocatedBaseSize'
                $cimDisks           = Get-CimInstance -Namespace 'ROOT/Microsoft/Windows/Storage' -ClassName 'MSFT_Disk' -Property 'Number'
                $cimPartitions      = Get-CimInstance -Namespace 'ROOT/Microsoft/Windows/Storage' -ClassName 'MSFT_Partition' -Property 'DiskNumber', 'PartitionNumber', 'MbrType', 'GptType', 'DriveLetter', 'AccessPaths', 'Size'
                $cimVolumes         = Get-CimInstance -Namespace 'ROOT/Microsoft/Windows/Storage' -ClassName 'MSFT_Volume' -Property 'Path', 'FileSystemLabel', 'Size', 'SizeRemaining'
                $processCount       = (Get-Process).Count
                $connectionCount    = (netstat.exe -n).Count - 4    # Subtract the netstat header

                # Enumerate the sessions
                $sessions = @(@(qwinsta.exe) | Where-Object { $_ -match '(Active|Aktiv)' } | Select-Object @{ N = 'Id'; E = { $_.Substring(41,5).Trim() } }, @{ N = 'User'; E = { $_.Substring(19,22).Trim() } }, @{ N = 'Session'; E = { $_.Substring(1,18).Trim() } })

                $outputDisks = @()
                foreach ($cimDisk in $cimDisks)
                {
                    $diskNumber = $cimDisk.Number

                    # Skip the disk if it does not have a number. This indicates
                    # a non-local disk of another failover cluster node.
                    if ([System.String]::IsNullOrEmpty($diskNumber))
                    {
                        continue
                    }

                    foreach ($cimPartition in ($cimPartitions | Where-Object { $_.DiskNumber -eq $cimDisk.Number }))
                    {
                        $partitionNumber = $cimPartition.PartitionNumber

                        $partitionType = 'Unknown'
                        switch ($cimPartition.MbrType)
                        {
                            1   { $partitionType = 'FAT12' }
                            2   { $partitionType = 'Xenix' }
                            3   { $partitionType = 'Xenix' }
                            4   { $partitionType = 'FAT16' }
                            5   { $partitionType = 'Extended' }
                            6   { $partitionType = 'Logical' }
                            7   { $partitionType = 'IFS' }
                            10  { $partitionType = 'OS/2 BootMgr' }
                            11  { $partitionType = 'FAT32' }
                            12  { $partitionType = 'FAT32 XINT13' }
                            14  { $partitionType = 'XINT13' }
                            15  { $partitionType = 'XINT13 Extended' }
                            65  { $partitionType = 'PReP' }
                            66  { $partitionType = 'LDM' }
                            99  { $partitionType = 'Unix' }
                            231 { $partitionType = 'Space Protective' }
                        }
                        switch ($cimPartition.GptType)
                        {
                            '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' { $partitionType = 'System' }
                            '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' { $partitionType = 'Reserved' }
                            '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}' { $partitionType = 'Basic' }
                            '{5808c8aa-7e8f-42e0-85d2-e1e90434cfb3}' { $partitionType = 'LDM Metadata' }
                            '{af9b60a0-1431-4f62-bc68-3311714a69ad}' { $partitionType = 'LDM Data' }
                            '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}' { $partitionType = 'Recovery' }
                            '{e75caf8f-f680-4cee-afa3-b001e56efc2d}' { $partitionType = 'Space Protective' }
                            '{eeff8352-dd2a-44db-ae83-bee1cf7481dc}' { $partitionType = 'S2D Cache' }
                            '{03aaa829-ebfc-4e7e-aac9-c4d76c63b24b}' { $partitionType = 'S2D Cache Metadata' }
                        }

                        $outputDisk = [PSCustomObject] @{
                            Id          = '{0}x{1}' -f $diskNumber, $partitionNumber
                            Label       = $partitionType
                            DriveLetter = $cimPartition.DriveLetter.ToSTring().Trim()
                            AccessPath  = [System.String] ($cimPartition.AccessPaths | Where-Object { $_ -match '^[A-Z]:\\' } | Select-Object -First 1)
                            Size        = $cimPartition.Size
                            Usage       = $null
                            Free        = $null
                            Used        = $null
                            IsSystem    = $cimPartition.DriveLetter -eq 'C'
                        }

                        $volumeNumber = $cimPartition.AccessPaths | Where-Object { $_ -match '^\\\\\?\\Volume{(?<VolumeNumber>[0-9a-fA-F-]{36}})\\$' } | Select-Object -First 1
                        if ($null -ne $volumeNumber)
                        {
                            $cimVolume = $cimVolumes | Where-Object { $_.Path -eq $volumeNumber } | Select-Object -First 1
                            if ($null -ne $cimVolume)
                            {
                                if (-not [System.String]::IsNullOrEmpty($cimVolume.FileSystemLabel))
                                {
                                    $outputDisk.Label = $cimVolume.FileSystemLabel
                                }

                                $outputDisk.Size  = $cimVolume.Size
                                $outputDisk.Free  = $cimVolume.SizeRemaining
                                $outputDisk.Used  = $cimVolume.Size - $cimVolume.SizeRemaining
                                if ($cimVolume.Size -gt 0)
                                {
                                    $outputDisk.Usage = ($cimVolume.Size - $cimVolume.SizeRemaining) / $cimVolume.Size
                                }
                            }
                        }

                        # if ($null -eq $volumeNumber -or $null -eq $cimVolume)
                        # {
                            # continue
                        # }

                        $outputDisks += $outputDisk
                    }
                }

                $output = [PSCustomObject] @{
                    Timestamp       = $null
                    Hostname        = $cimComputerSystem.Name
                    Domain          = $cimComputerSystem.Domain
                    PowerShell      = $PSVersionTable.PSVersion
                    ComputerSystem  = [PSCustomObject] @{
                        Timestamp       = [System.DateTime]::Now
                        Uptime          = [System.DateTime]::Now - $cimOperatingSystem.LastBootUpTime
                        BootTime        = $cimOperatingSystem.LastBootUpTime
                    }
                    OperatingSystem = [PSCustomObject] @{
                        Name            = $cimOperatingSystem.Caption.Replace('Microsoft Windows', 'Windows')
                        Version         = $cimOperatingSystem.Version
                        Language        = [System.Globalization.CultureInfo]::new([int] $cimOperatingSystem.OSLanguage).Name
                        Architecture    = $cimOperatingSystem.OSArchitecture
                    }
                    Processor       = [PSCustomObject] @{
                        SocketCount     = $cimComputerSystem.NumberOfProcessors
                        CoreCount       = $cimComputerSystem.NumberOfLogicalProcessors
                        Load            = $perfCounter.CounterSamples.Where({$_.Path -like "\\*$perfProcessorUtilityName"}).CookedValue * $cimComputerSystem.NumberOfLogicalProcessors / 100
                        Usage           = $perfCounter.CounterSamples.Where({$_.Path -like "\\*$perfProcessorUtilityName"}).CookedValue / 100
                    }
                    Memory          = [PSCustomObject] @{
                        Size            = $cimOperatingSystem.TotalVisibleMemorySize / 1MB
                        Usage           = (($cimOperatingSystem.TotalVisibleMemorySize / 1KB) - $perfCounter.CounterSamples.Where({$_.Path -like "\\*$perfMemoryAvailableName"}).CookedValue) / ($cimOperatingSystem.TotalVisibleMemorySize / 1KB)
                    }
                    Page            = [PSCustomObject] @{
                        Size            = $cimPageFile.AllocatedBaseSize / 1KB
                        Usage           = $cimPageFile.CurrentUsage / $cimPageFile.AllocatedBaseSize
                    }
                    Disks           = $outputDisks
                    Processes       = [PSCustomObject] @{
                        Count           = $processCount
                    }
                    Connections     = [PSCustomObject] @{
                        Count           = $connectionCount
                    }
                    Sessions        = [PSCustomObject] @{
                        Count           = $sessions.Count
                    }
                    PSSessions     = [PSCustomObject] @{
                        Count           = @(Get-Process -Name 'pwsh', 'powershell' -ErrorAction 'SilentlyContinue').Count
                    }
                    WinRMSessions   = [PSCustomObject] @{
                        Count           = @(Get-Process -Name 'wsmprovhost' -ErrorAction 'SilentlyContinue').Count
                    }
                }

                # Update the timestamp as the last step
                $output.Timestamp = [System.DateTime]::Now

                Write-Output $output
            }
        }

        if ($PSBoundParameters.ContainsKey('Session') -and $null -ne $Session)
        {
            $output = Invoke-Command -Session $Session -ScriptBlock $queryScriptBlock
        }
        else
        {
            $output = & $queryScriptBlock
        }

        Write-Output $output
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
