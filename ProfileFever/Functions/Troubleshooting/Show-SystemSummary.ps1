<#
    .SYNOPSIS
        Show the system summary of the local system or the host behind the
        PowerShell session.

    .DESCRIPTION
        This command will use CIM and Performance Counter as well as some other
        command line tools to get the current system summary. The summary will
        displayed in a nice way on the console.

    .EXAMPLE
        PS C:\> Show-SystemSummary
        Show the local system summary.

    .EXAMPLE
        PS C:\> Show-SystemSummary -Session $session
        Show the system summary of the host behind the session.
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

    $colorDarkRed    = 197, 15, 31
    $colorDarkYellow = 193, 156, 0
    $colorDarkGreen  = 19, 161, 14
    $colorDarkGray   = 118, 118, 118

    function Get-Color ($Value, $WarningThreshold, $ErrorThreshold)
    {
        if ($Value -gt $ErrorThreshold)
        {
            $colorDarkRed
            # 197, 15, 31
        }
        elseif ($Value -gt $WarningThreshold)
        {
            $colorDarkYellow
            # 193, 156, 0
        }
        else
        {
            $colorDarkGreen
            # 19, 161, 14
        }
    }

    try
    {
        $data = Get-SystemSummary -Session $Session

        $timestamp = [System.DateTime]::Now #.AddSeconds(61)
        $timestampDiffSec = ($data.ComputerSystem.Timestamp - $timestamp).TotalSeconds

        # Special calculations for the summary output
        $systemDisk  = $data.Disks | Where-Object { $_.IsSystem } | Select-Object -First 1
        $allDiskSize = $data.Disks | Measure-Object -Property 'Size' -Sum | Select-Object -ExpandProperty 'Sum'

        # [void] $summary.AppendFormat('  󰚗  Memory usage  : {0,-40:0}     Processes     : {1}', $summaryMemoryUsage, $data.ProcessCount).AppendLine()
        # [void] $summary.AppendFormat('  󱪓  Page usage    : {0,-40:0}   󰴽  Connections   : {1}', $summaryPageUsage, $data.ConnectionCount).AppendLine()
        # [void] $summary.AppendFormat('  󰋊  C:\ disk used : {0,-40:0}   󰡉  User sessions : {1}', $summaryDiskUsed, $data.SessionCount).AppendLine()

        # All entries which are displayed in a narrow column layout in the
        # output. Two entries are displayed per line.
        $summaryNarrowEntries = @(
            @{
                Icon    = '󰅐 '
                Name    = 'Current time'
                Value   = '{0:dd\.MM\.yyyy\ HH\:mm}' -f $data.ComputerSystem.Timestamp
                Color   = $(if ([System.Math]::Abs($timestampDiffSec) -gt 60) { 'Red' } elseif ([System.Math]::Abs($timestampDiffSec) -gt 3) { 'Yellow' } else { 'Default' })
                Sidecar = ''
            }
            @{
                Icon    = ' '
                Name    = 'Boot time'
                Value   = '{0:dd\.MM\.yyyy\ HH\:mm}' -f $data.ComputerSystem.BootTime
                Color   = $(if ($data.ComputerSystem.Uptime.TotalMinutes -lt 180) { 'Yellow' } else { 'Default' })
                Sidecar = '(up {0:d\d\ h\h\ m\m})' -f $data.ComputerSystem.Uptime
            }
            @{
                Icon    = ' '
                Name    = 'System load'
                Value   = '{0:0.000}' -f $data.Processor.Load
                Color   = $(if ($data.Processor.Usage -ge 0.8) { 'Red' } elseif ($data.Processor.Usage -ge 0.6) { 'Yellow' } else { 'Green' })
                Sidecar = '({0:0%})' -f $data.Processor.Usage
            }
            @{
                Icon    = ' '
                Name    = 'Hostname'
                Value   = $(if($data.Domain -eq 'WORKGROUP') { '{0} ({1})' -f $data.Hostname, $data.Domain } else { '{0}.{1}' -f $data.Hostname, $data.Domain })
                Color   = 'Default'
                Sidecar = ''
            }
            @{
                Icon    = '󰚗 '
                Name    = 'Memory usage'
                Value   = '{0:0%}' -f $data.Memory.Usage
                Color   = $(if ($data.Memory.Usage -ge 0.9) { 'Red' } elseif ($data.Memory.Usage -ge 0.8) { 'Yellow' } else { 'Green' })
                Sidecar = 'of {0:0}GB' -f $data.Memory.Size
            }
            @{
                Icon    = ' '
                Name    = 'Processes'
                Value   = $data.Processes.Count
                Color   = 'Default'
                Sidecar = ''
            }
            @{
                Icon    = '󱪓 '
                Name    = 'Page usage'
                Value   = '{0:0%}' -f $data.Page.Usage
                Color   = $(if ($data.Page.Usage -ge 0.5) { 'Red' } elseif ($data.Page.Usage -ge 0.2) { 'Yellow' } else { 'Green' })
                Sidecar = 'of {0:0}GB' -f $data.Page.Size
            }
            @{
                Icon    = '󰴽 '
                Name    = 'Connections'
                Value   = $data.Connections.Count
                Color   = 'Default'
                Sidecar = ''
            }
            @{
                Icon    = '󰋊 '
                Name    = 'Disk C:\ usage'
                Value   = '{0:0.0%}' -f $systemDisk.Usage
                Color   = $(if ($systemDisk.Usage -ge 0.9) { 'Red' } elseif ($systemDisk.Usage -ge 0.8) { 'Yellow' } else { 'Green' })
                Sidecar = 'of {0:0}GB' -f ($systemDisk.Size / 1GB)
            }
            @{
                Icon    = '󰡉 '
                Name    = 'User sessions'
                Value   = $data.Sessions.Count
                Color   = 'Default'
                Sidecar = ''
            }
        )

        # All entries which are displayed in a wide column layout. Only one
        # entry is displayed per line.
        $summaryWideEntries = @()
        foreach ($dataDisk in @($data.Disks | Sort-Object -Property 'AccessPath'))
        {
            if ([System.String]::IsNullOrEmpty($dataDisk.AccessPath))
            {
                continue
            }

            $summaryWideEntries += @{
                Icon    = '󰋊 '
                Name    = 'Disk #{0}' -f $dataDisk.Id
                Value   = '{0:0%}' -f $dataDisk.Usage
                Color   = $(if ($dataDisk.Usage -ge 0.9) { 'Red' } elseif ($dataDisk.Usage -ge 0.8) { 'Yellow' } else { 'Green' })
                Sidecar = 'of {0:0}GB on {1}' -f ($dataDisk.Size / 1GB), $dataDisk.AccessPath
            }
        }


        # $summaryDiskUsed = Format-HostText -Message ('{0:0.0%}' -f $data.SystemDiskUsage) -ForegroundColor (Get-Color -Value $data.SystemDiskUsage -WarningThreshold 0.8 -ErrorThreshold 0.9)
        # $summaryDiskUsed = '{0} of {1:0}GB' -f $summaryDiskUsed, $data.SystemDiskSize

        # # # If the all disk size is greater than the system disk (plus 2GB for the
        # # the EFI boot and recovery partition), show it after the system disk
        # # size in ths system information summary.
        # $summaryDiskAllSizeText = ''
        # if ($data.AllDiskSize -gt ($data.SystemDiskSize + 2))
        # {
        #     $summaryDiskAllSizeText = '+{0:0}GB' -f ($data.AllDiskSize - $data.SystemDiskSize)
        # }

        # $summaryMemoryUsage = Format-HostText -Message ('{0:0%}' -f $data.MemoryUsage) -ForegroundColor (Get-Color -Value $data.MemoryUsage -WarningThreshold 0.7 -ErrorThreshold 0.85)
        # $summaryMemoryUsage = '{0} of {1:0}GB' -f $summaryMemoryUsage, $data.MemorySize

        # $summaryPageUsage = Format-HostText -Message ('{0:0%}' -f $data.PageUsage) -ForegroundColor (Get-Color -Value $data.PageUsage -WarningThreshold 0.6 -ErrorThreshold 0.8)
        # $summaryPageUsage = '{0} of {1:0}GB' -f $summaryPageUsage, $data.PageSize

        # $summaryCurrentTime = '{0} {1}' -f $data.Timestamp.ToShortDateString(), $data.Timestamp.ToLongTimeString()

        $summary = [System.Text.StringBuilder]::new()
        [void] $summary.AppendLine()
        [void] $summary.AppendFormat('Welcome to PowerShell {0}.{1} on {2}', $data.PowerShell.Major, $data.PowerShell.Minor, $data.OperatingSystem.Name).AppendLine()
        [void] $summary.AppendLine()
        [void] $summary.AppendFormat('   {0}  󰓯 {1}   {2}   {3}  󰚗 {4:0}GB  󰋊 {5:0}GB', $data.OperatingSystem.Version, $data.OperatingSystem.Architecture, $data.OperatingSystem.Language, $data.Processor.Count, $data.Memory.Size, $allDiskSize / 1GB).AppendLine()
        [void] $summary.AppendLine()

        # Format the narrow entries in a two column layout
        for ($i = 0; $i -lt $summaryNarrowEntries.Count; $i++)
        {
            $summaryEntry = $summaryNarrowEntries[$i]

            [void] $summary.AppendFormat('  {0,1} {1,-15} : ', $summaryEntry.Icon, $summaryEntry.Name)

            switch ($summaryEntry.Color)
            {
                'Default' { [void] $summary.Append($summaryEntry.Value) }
                'Red'     { [void] $summary.Append((Format-HostText -Message $summaryEntry.Value -ForegroundColor $colorDarkRed)) }
                'Yellow'  { [void] $summary.Append((Format-HostText -Message $summaryEntry.Value -ForegroundColor $colorDarkYellow)) }
                'Green'   { [void] $summary.Append((Format-HostText -Message $summaryEntry.Value -ForegroundColor $colorDarkGreen)) }
            }

            $summarySidecarLength = 20 - $summaryEntry.Value.Length
            if ($summarySidecarLength -lt 0)
            {
                $summarySidecarLength = 0
            }
            [void] $summary.AppendFormat(" {0,-$summarySidecarLength}", [System.String] $summaryEntry.Sidecar)

            if ($i % 2 -eq 1)
            {
                [void] $summary.AppendLine()
            }
        }

        [void] $summary.AppendLine()

        # Format the wide entries in a one column layout
        for ($i = 0; $i -lt $summaryWideEntries.Count; $i++)
        {
            $summaryEntry = $summaryWideEntries[$i]

            [void] $summary.AppendFormat('  {0,1} {1,-10} : ', $summaryEntry.Icon, $summaryEntry.Name)

            switch ($summaryEntry.Color)
            {
                'Default' { [void] $summary.Append($summaryEntry.Value) }
                'Red'     { [void] $summary.Append((Format-HostText -Message $summaryEntry.Value -ForegroundColor $colorDarkRed)) }
                'Yellow'  { [void] $summary.Append((Format-HostText -Message $summaryEntry.Value -ForegroundColor $colorDarkYellow)) }
                'Green'   { [void] $summary.Append((Format-HostText -Message $summaryEntry.Value -ForegroundColor $colorDarkGreen)) }
            }

            $summarySidecarLength = 14 - $summaryEntry.Value.Length
            if ($summarySidecarLength -lt 0)
            {
                $summarySidecarLength = 0
            }
            [void] $summary.AppendFormat(" {0,-$summarySidecarLength}", [System.String] $summaryEntry.Sidecar)

            [void] $summary.AppendLine()
        }

        [void] $summary.AppendLine()
        Format-HostText -StringBuilder $summary -ForegroundColor $colorDarkGray -Message '  󰢫  Troubleshooting' -AppendLine
        Format-HostText -StringBuilder $summary -ForegroundColor $colorDarkGray -Message '  ¦ Invoke-WindowsAnalyzer    Measure-Processor         Measure-Storage' -AppendLine
        Format-HostText -StringBuilder $summary -ForegroundColor $colorDarkGray -Message '  ¦ Measure-System            Measure-Memory            Measure-Session' -AppendLine
        [void] $summary.AppendLine()
        Format-HostText -StringBuilder $summary -ForegroundColor $colorDarkGray -Message '    System Auditing' -AppendLine
        Format-HostText -StringBuilder $summary -ForegroundColor $colorDarkGray -Message '  ¦ Install-Module -Name "SecurityFever" -Repository "PSGallery" -Force' -AppendLine
        Format-HostText -StringBuilder $summary -ForegroundColor $colorDarkGray -Message '  ¦ Get-SystemAuditFileSystem         Get-SystemAuditPowerCycle' -AppendLine
        Format-HostText -StringBuilder $summary -ForegroundColor $colorDarkGray -Message '  ¦ Get-SystemAuditGroupPolicy        Get-SystemAuditUserSession' -AppendLine
        Format-HostText -StringBuilder $summary -ForegroundColor $colorDarkGray -Message '  ¦ Get-SystemAuditMsiInstaller       Get-SystemAuditWindowsService' -AppendLine
        [void] $summary.AppendLine()
        # [void] $summary.AppendFormat('Up since {0:d\d\ h\h\ m\m}', $data.SystemUptime).AppendLine()

        Write-Host $summary.ToString()
    }
    catch
    {
        # Write-Warning "Failed to show system summary: $_"
        throw $_
    }
}
