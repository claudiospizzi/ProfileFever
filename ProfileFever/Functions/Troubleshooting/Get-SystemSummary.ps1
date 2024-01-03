<#
    .SYNOPSIS
        Get the core performance counter and system information.

    .DESCRIPTION
        This command will use CIM and Performance Counter as well as some other
        command line tools to get the current system summary. The summary will
        be returned as a PowerShell object.

    .EXAMPLE
        PS C:\> Show-SystemSummary -Session $session
        Get the system summary of the host behind the session.
#>
function Get-SystemSummary
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

            Set-StrictMode -Version latest

            switch -wildcard ([System.Globalization.CultureInfo]::InstalledUICulture.Name)
            {
                # ToDo...
                # 'de-*'
                # {
                #     $perfProcessorUtilityName = ''
                #     $perfMemoryAvailableName  = ''
                # }
                default
                {
                    $perfProcessorUtilityName = '\Processor Information(_Total)\% Processor Utility'
                    $perfMemoryAvailableName  = '\Memory\Available MBytes'
                }
            }

            # Gather data from performance counters and CIM system
            $perfCounter        = Get-Counter -Counter $perfProcessorUtilityName, $perfMemoryAvailableName -SampleInterval 1 -MaxSamples 1
            $cimComputerSystem  = Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property 'Name', 'Domain', 'NumberOfLogicalProcessors'
            $cimOperatingSystem = Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property 'Caption', 'Version', 'OSLanguage', 'OSArchitecture', 'LastBootUpTime', 'TotalVisibleMemorySize'
            $cimPageFile        = Get-CimInstance -ClassName 'Win32_PageFileUsage' -Property 'CurrentUsage', 'AllocatedBaseSize'
            $cimDisks           = Get-CimInstance -Namespace 'ROOT/Microsoft/Windows/Storage' -ClassName 'MSFT_Disk' -Property 'Number'
            $cimPartitions      = Get-CimInstance -Namespace 'ROOT/Microsoft/Windows/Storage' -ClassName 'MSFT_Partition' -Property 'DiskNumber', 'PartitionNumber', 'DriveLetter', 'AccessPaths', 'Size'
            $cimVolumes         = Get-CimInstance -Namespace 'ROOT/Microsoft/Windows/Storage' -ClassName 'MSFT_Volume' -Property 'Path', 'FileSystemLabel', 'Size', 'SizeRemaining'
            $processCount       = (Get-Process).Count
            $connectionCount    = (netstat.exe -n).Count - 4    # Subtract the netstat header

            # Enumerate the sessions
            $sessions = @(@(qwinsta.exe) | Where-Object { $_ -match 'Active' } | Select-Object @{ N = 'Id'; E = { $_.Substring(41,5).Trim() } }, @{ N = 'User'; E = { $_.Substring(19,22).Trim() } }, @{ N = 'Session'; E = { $_.Substring(1,18).Trim() } })

            $outputDisks = @()
            foreach ($cimDisk in $cimDisks)
            {
                $diskNumber = $cimDisk.Number

                foreach ($cimPartition in ($cimPartitions | Where-Object { $_.DiskNumber -eq $cimDisk.Number }))
                {
                    $partitionNumber = $cimPartition.PartitionNumber

                    $outputDisk = [PSCustomObject] @{
                        Id          = '{0}:{1}' -f $diskNumber, $partitionNumber
                        Label       = ''
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
                        $cimVolume = $cimVolumes | Where-Object { $_.Path -eq $volumeNumber} | Select-Object -First 1
                        if ($null -ne $cimVolume)
                        {
                            $outputDisk.Label = $cimVolume.FileSystemLabel
                            $outputDisk.Size  = $cimVolume.SizeRemaining
                            $outputDisk.Free  = $cimVolume.SizeRemaining
                            $outputDisk.Used  = $cimVolume.Size - $cimVolume.SizeRemaining

                            if ($cimVolume.Size -gt 0)
                            {
                                $outputDisk.Usage = ($cimVolume.Size - $cimVolume.SizeRemaining) / $cimVolume.Size
                            }
                        }
                    }

                    if ($null -eq $volumeNumber -or $null -eq $cimVolume)
                    {
                        continue
                    }

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
                    Count           = $cimComputerSystem.NumberOfLogicalProcessors
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
            }

            # Update the timestamp as the last step
            $output.Timestamp = [System.DateTime]::Now

            Write-Output $output
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
