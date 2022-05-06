<#
    .SYNOPSIS
        Troubleshoot the local Windows system.

    .DESCRIPTION
        This command will reuse all the measurement commands of the ProfileFever
        module and combine it to a single output for troubleshooting performance
        problems.

    .EXAMPLE
        PS C:\> Invoke-WindowsAnalyzer
        Invoke the rroubleshooter on the local system.

    .LINK
        https://github.com/claudiospizzi/ProfileFever
#>
function Invoke-WindowsAnalyzer
{
    [CmdletBinding()]
    param
    (
        # Option to show the detail output
        [Parameter(Mandatory = $false)]
        [Switch]
        $Detail
    )

    try
    {
        function Write-WindowsAnalyzerTest
        {
            [CmdletBinding(DefaultParameterSetName = 'None')]
            [Alias('AnalyzerTest')]
            param
            (
                # Test description.
                [Parameter(Mandatory = $true, Position = 0)]
                [System.String]
                $Description,

                # If available, a metric for the test.
                [Parameter(Mandatory = $true, ParameterSetName = 'Metric')]
                [System.Double]
                $Metric,

                # Format string for the metric value.
                [Parameter(Mandatory = $false, ParameterSetName = 'Metric')]
                [System.String]
                $MetricFormat = '{0}',

                # If the metric was specified, the relevant thresholds. Four
                # numbers must be passed. By comparing the first and last
                # number, we can determine if the threshold are ascending or
                # descending:
                # - The minimum/maximum possible value for a healthy state
                # - The warning threshold
                # - The error threshold
                # - The minimum/maximum possible value for an error state
                [Parameter(Mandatory = $true, ParameterSetName = 'Metric')]
                [ValidateCount(4, 4)]
                [System.Double[]]
                $MetricThreshold,

                # # Optional performance data.
                # [Parameter(Mandatory = $false)]
                # [System.Collection.Hashtable]
                # $Data,

                # Test result.
                [Parameter(Mandatory = $true, ParameterSetName = 'Result')]
                [ValidateSet('Passed', 'Warning', 'Failed')]
                [System.String]
                $Result
            )

            $colorPassed  = 51, 153, 0  # Green
            $colorWarning = 255, 204, 0 # Yellow
            $colorFailed  = 204, 51, 0  # Red

            $windowWidth    = $Host.UI.RawUI.WindowSize.Width - 2
            $metricBarWidth = 20

            $output = [System.Text.StringBuilder]::new()

            [void] $output.Append($Description.PadRight($windowWidth - $metricBarWidth - 24).Substring(0, $windowWidth - $metricBarWidth - 24))
            [void] $output.Append('  ')

            if ($PSCmdlet.ParameterSetName -eq 'Metric')
            {
                $metricValue = $MetricFormat -f $Metric
                $metricValue = $metricValue.PadLeft(10).Substring(0, 10)
                [void] $output.Append($metricValue)

                # Reverse array, if the first number is larger than the last.
                if ($MetricThreshold[0] -gt $MetricThreshold[3])
                {
                    $MetricThreshold = $MetricThreshold.Reverse()
                }

                # Fix min and max values.
                if ($Metric -lt $MetricThreshold[0])
                {
                    $Metric = $MetricThreshold[0]
                }
                if ($Metric -gt $MetricThreshold[3])
                {
                    $Metric = $MetricThreshold[3]
                }

                $metricBarStep  = ($MetricThreshold[3] - $MetricThreshold[0]) / $metricBarWidth

                # Calculate the acutal test result by using the provided metric
                # and the two thresholds.
                $Result = 'Passed'
                if ($Metric -ge $MetricThreshold[2])
                {
                    $Result = 'Failed'
                }
                elseif ($Metric -ge $MetricThreshold[1])
                {
                    $Result = 'Warning'
                }

                # Calculate the actual bar.
                [void] $output.Append(' [')
                for ($i = 0; $i -lt $metricBarWidth; $i++)
                {
                    $metricBarThreshold = $MetricThreshold[0] + ($i * $metricBarStep)

                    $metricChar = [char]63191 # Three horizonzal dots
                    if ($Metric -ge $metricBarThreshold)
                    {
                        $metricChar = [char]64610 # Filled square
                    }

                    $metricColor = $colorPassed
                    if ($metricBarThreshold -ge $MetricThreshold[2])
                    {
                        $metricColor = $colorFailed
                    }
                    elseif ($metricBarThreshold -ge $MetricThreshold[1])
                    {
                        $metricColor = $colorWarning
                    }

                    Format-HostText -StringBuilder $output -Message $metricChar -ForegroundColor $metricColor
                }
                [void] $output.Append('] ')
            }
            else
            {
                [void] $output.AppendFormat('{0,34}', [System.string]::Empty)
            }

            if ($PSCmdlet.ParameterSetName -ne 'None')
            {
                [void] $output.Append('[')
                switch ($Result)
                {
                    'Passed'  { Format-HostText -StringBuilder $output -Message '  OK  ' -ForegroundColor $colorPassed }
                    'Warning' { Format-HostText -StringBuilder $output -Message ' WARN ' -ForegroundColor $colorWarning }
                    'Failed'  { Format-HostText -StringBuilder $output -Message 'FAILED' -ForegroundColor $colorFailed }
                    default   { [void] $output.Append('  ??  ') }
                }
                [void] $output.Append(']')
            }

            Write-Host $output.ToString()
        }

        # AnalyzerTest 'Short'
        # AnalyzerTest 'This is a loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong text'
        # AnalyzerTest 'Passed' -Result 'Passed'
        # AnalyzerTest 'Warning' -Result 'Warning'
        # AnalyzerTest 'Failed' -Result 'Failed'
        # AnalyzerTest 'Bar Test: -99   => 0, 50, 90, 100' -Metric -99   -MetricFormat '{0:0.0}' -MetricThreshold 0, 50, 90, 100
        # AnalyzerTest 'Bar Test:   0   => 0, 50, 90, 100' -Metric   0   -MetricFormat '{0:0.0}' -MetricThreshold 0, 50, 90, 100
        # AnalyzerTest 'Bar Test:  13   => 0, 50, 90, 100' -Metric  13   -MetricFormat '{0:0.0}' -MetricThreshold 0, 50, 90, 100
        # AnalyzerTest 'Bar Test:  49.9 => 0, 50, 90, 100' -Metric  49.9 -MetricFormat '{0:0.0}' -MetricThreshold 0, 50, 90, 100
        # AnalyzerTest 'Bar Test:  50   => 0, 50, 90, 100' -Metric  50   -MetricFormat '{0:0.0}' -MetricThreshold 0, 50, 90, 100
        # AnalyzerTest 'Bar Test:  50.1 => 0, 50, 90, 100' -Metric  50.1 -MetricFormat '{0:0.0}' -MetricThreshold 0, 50, 90, 100
        # AnalyzerTest 'Bar Test:  80   => 0, 50, 90, 100' -Metric  61   -MetricFormat '{0:0.0}' -MetricThreshold 0, 50, 90, 100
        # AnalyzerTest 'Bar Test:  95   => 0, 50, 90, 100' -Metric  95   -MetricFormat '{0:0.0}' -MetricThreshold 0, 50, 90, 100
        # AnalyzerTest 'Bar Test: 100   => 0, 50, 90, 100' -Metric 100   -MetricFormat '{0:0.0}' -MetricThreshold 0, 50, 90, 100
        # AnalyzerTest 'Bar Test: 999   => 0, 50, 90, 100' -Metric 999   -MetricFormat '{0:0.0}' -MetricThreshold 0, 50, 90, 100
        # AnalyzerTest 'Bar Test: 99999999999   => 0, 50, 90, 100' -Metric 99999999999   -MetricFormat '{0:0.0}' -MetricThreshold 0, 50, 90, 100


        ##
        ## System
        ##

        $system = Measure-System

        Write-Host ''
        AnalyzerTest 'System'

        AnalyzerTest "> Hostname : $($system.Name)"
        AnalyzerTest "> Uptime   : $($system.Uptime.ToString('d\d\ hh\.mm'))"

        if ($Detail.IsPresent)
        {
            $system | Out-String | Write-Host
        }


        ##
        ## Processor
        ##

        $processor = Measure-Processor
        $processorDetail = $processor.Name.Split(' ')[0]

        Write-Host ''
        AnalyzerTest "Processor ($processorDetail)"

        if ($processor.HyperV -ne -1)
        {
            AnalyzerTest '> Hyper-V Hypervisor Logical Processor' -Metric $processor.HyperV -MetricFormat '{0:0}%' -MetricThreshold 0, 60, 80, 100
        }
        AnalyzerTest '> Processor Usage' -Metric $processor.Usage -MetricFormat '{0:0}%' -MetricThreshold 0, 80, 90, 100
        AnalyzerTest '> Processor Queue Length' -Metric $processor.Queue -MetricFormat '{0:0} ' -MetricThreshold 0, 10, 20, 100

        if ($Detail.IsPresent)
        {
            $processor | Out-String | Write-Host
        }


        ##
        ## Memory
        ##

        $memory = Measure-Memory
        $memoryPhysical = $memory | Where-Object { $_.Name -eq 'Physical Memory' }
        $memoryPageFile = $memory | Where-Object { $_.Name -eq 'Page File' }
        $memoryDetail = '{0}GB' -f [System.Math]::Round($memoryPhysical.Total / 1024)

        Write-Host ''
        AnalyzerTest "Memory ($memoryDetail)"

        AnalyzerTest '> Physical Memory' -Metric $memoryPhysical.Used -MetricFormat '{0:0}MB' -MetricThreshold 0, ($memoryPhysical.Total * 0.88), ($memoryPhysical.Total * 0.94), $memoryPhysical.Total
        AnalyzerTest '> Page File' -Metric $memoryPageFile.Used -MetricFormat '{0:0}MB' -MetricThreshold 0, ($memoryPageFile.Total * 0.8), ($memoryPageFile.Total * 0.9), $memoryPageFile.Total

        if ($Detail.IsPresent)
        {
            $memory | Out-String | Write-Host
        }


        ##
        ## Storage
        ##

        $storageList = Measure-Storage

        foreach ($storage in $storageList)
        {
            $storageName   = $storage.Name
            $storageDetail = '{0}GB' -f [System.Math]::Round($storage.Size)

            Write-Host ''
            AnalyzerTest "Storage $storageName ($storageDetail)"

            AnalyzerTest "> Used Storage" -Metric $storage.Used -MetricFormat '{0:0}GB' -MetricThreshold 0, ($storage.Size * 0.88), ($storage.Size * 0.94), $storage.Size
            AnalyzerTest "> Disk Time" -Metric $storage.DiskTime -MetricFormat '{0:0.0}%' -MetricThreshold 0, 60, 80, 100
            AnalyzerTest "> Disk Queue" -Metric $storage.DiskQueue -MetricFormat '{0:0.0}' -MetricThreshold 0, 1, 2, 20
            AnalyzerTest "> Average Millisecond per Read" -Metric ($storage.AvgRead * 1000) -MetricFormat '{0:0}ms' -MetricThreshold 0, 10, 20, 100
            AnalyzerTest "> Average Millisecond per Write" -Metric ($storage.AvgWrite * 1000) -MetricFormat '{0:0}ms' -MetricThreshold 0, 10, 20, 100
        }

        if ($Detail.IsPresent)
        {
            $storage | Out-String | Write-Host
        }


        ##
        ## Network
        ##

        # ToDo...


        ##
        ## Session
        ##

        $sessionList = Measure-Session

        foreach ($session in $sessionList)
        {
            $sessionName   = ('{0}@{1}' -f $session.User, $session.Name).Trim('@')
            $sessionDetail = '{0}#{1}' -f $session.Status, $session.Id

            Write-Host ''
            AnalyzerTest "Session $sessionName ($sessionDetail)"

            AnalyzerTest "> Running Processes" -Metric $session.Processes -MetricFormat '{0}' -MetricThreshold 0, 100, 150, 200
            AnalyzerTest "> Assigned Memory" -Metric ($session.Memory / 1024 / 1024) -MetricFormat '{0:0}MB' -MetricThreshold 0, ($memoryPhysical.Total * 0.50), ($memoryPhysical.Total * 0.75), $memoryPhysical.Total
        }


        ##
        ## Network Endpoints
        ##

        Write-Host ''
        AnalyzerTest 'Network Endpoints'

        $endpoints = @()
        $endpoints += Get-NetTCPConnection -State 'Listen' | Select-Object 'LocalAddress', 'LocalPort', @{ N = 'Protocol'; E = { 'TCP' } }, 'OwningProcess'
        $endpoints += Get-NetUDPEndpoint | Select-Object 'LocalAddress', 'LocalPort', @{ N = 'Protocol'; E = { 'UDP' } }, 'OwningProcess'
        $endpoints = $endpoints | Sort-Object 'LocalPort', 'LocalAddress'
        foreach ($endpoint in $endpoints)
        {
            $address = $endpoint.LocalAddress
            if ($address -like '*:*')
            {
                $address = '[{0}]' -f $address
            }

            try
            {
                $processObj = Get-Process -Id $endpoint.OwningProcess
                $process = $processObj.CommandLine
                if ([System.String]::IsNullOrWhiteSpace($process))
                {
                    $process = $processObj.Name
                }
            }
            catch
            {
                $process = 'n/a'
            }

            '> {0,-32}  {1}/{2,-6}  {3}' -f $address, $endpoint.Protocol, $endpoint.LocalPort, $process
        }


        Write-Host ''
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
