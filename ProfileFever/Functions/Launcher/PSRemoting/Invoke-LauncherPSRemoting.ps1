<#
    .SYNOPSIS
        Connect to a remote system by using a registered PowerShell Remoting
        connection.

    .DESCRIPTION
        Use the PowerShell Remoting connections registered in the profile
        launcher to connect to the remote host. This can be done by opening an
        interactive connection, invoke a script block or create a session.

    .EXAMPLE
        PS C:\> winrm
        List all available PowerShell Remoting connections.

    .EXAMPLE
        PS C:\> winrm srv01
        Connect to the remote interactive prompt of PowerShell Remoting.

    .EXAMPLE
        PS C:\> $session = winrm srv01
        Open a new PowerShell Remoting session to the remote system.

    .EXAMPLE
        PS C:\> winrm srv01 'gpupdate'
        Invoke the command on the remote system.
#>
function Invoke-LauncherPSRemoting
{
    [CmdletBinding(DefaultParameterSetName = 'Show')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseUsingScopeModifierInNewRunspaces', '')]
    [Alias('winrm', 'win', 'w')]
    param
    (
        # Name of the PowerShell Remoting connection to use.
        [Parameter(Mandatory = $true, ParameterSetName = 'Connect', Position = 0)]
        [System.String]
        $Name,

        # Optional a script block to invoke it on the remote system. If it's not
        # a script block, use the string representation to convert it to a
        # script block.
        [Parameter(Mandatory = $false, ParameterSetName = 'Connect', Position = 1)]
        [System.Object]
        $ScriptBlock
    )

    $ErrorActionPreference = 'Stop'

    if ($PSCmdlet.ParameterSetName -eq 'Show')
    {
        # Show all registered PowerShell Remoting connections. This may help to
        # choose the correct connection.

        Get-LauncherPSRemoting
    }

    if ($PSCmdlet.ParameterSetName -eq 'Connect')
    {
        $launcherPSRemoting = @(Get-LauncherPSRemoting -Name $Name)

        if ($null -eq $launcherPSRemoting -or $launcherPSRemoting.Count -eq 0)
        {
            throw "PowerShell Remoting connection named '$Name' not found."
        }

        if ($launcherPSRemoting.Count -gt 1)
        {
            $launcherPSRemoting | ForEach-Object { Write-Host "[Launcher] PS Remoting target found: $($_.Name)" -ForegroundColor 'Yellow' }
            throw "Multiple PowerShell Remoting connections named '$Name' found. Be more specific."
        }

        # Define a splat to connect to the remoting system.
        $connectionSplat = @{
            ComputerName = $launcherPSRemoting.ComputerName
        }

        # Credentials specified by using the local Credential Vault. Get the
        # credential by name out of the vault.
        if (-not [System.String]::IsNullOrEmpty($launcherPSRemoting.Credential))
        {
            $connectionSplat['Credential'] = Get-VaultCredential -TargetName $launcherPSRemoting.Credential
        }

        # Credentials specified by using a local callback script. Invoke the
        # script to get the credentials. Check a credential object is returned.
        if (-not [System.String]::IsNullOrEmpty($launcherPSRemoting.CredentialCallback))
        {
            Write-Host "[Launcher] Invoke a credential callback: { $($launcherPSRemoting.CredentialCallback) } ..." -ForegroundColor 'Yellow'

            $credentialCallback = [System.Management.Automation.ScriptBlock]::Create($launcherPSRemoting.CredentialCallback)
            $connectionSplat['Credential'] = $credentialCallback.Invoke() | Select-Object -First 1

            if ($connectionSplat['Credential'] -isnot [System.Management.Automation.PSCredential])
            {
                throw "The credential callback for '$Name' did not return a valid credential object."
            }
        }

        $verbose = "'{0}'" -f $connectionSplat['ComputerName']
        if ($connectionSplat.ContainsKey('Credential'))
        {
            $verbose += " as '{0}'" -f $connectionSplat['Credential'].Username
        }

        # It's time to open the remoting session. Try to open an encrypted
        # session if possible. If not, fall back to an unencrypted session.
        Write-Host "[Launcher] Create an encrypted session on $verbose ..." -ForegroundColor 'Yellow'
        try
        {
            $sessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
            $session = New-PSSession @connectionSplat -SessionOption $sessionOption -UseSSL
        }
        catch
        {
            Write-Host "[Launcher] Create an plain text session on $verbose ..." -ForegroundColor 'Yellow'
            $session = New-PSSession @connectionSplat
        }

        if ($PSBoundParameters.ContainsKey('ScriptBlock'))
        {
            # Option 1: Invoke Command
            # If a script is appended to the command, execute that script on the
            # remote system.

            Write-Host "[Launcher] Invoke a remote command on $verbose ..." -ForegroundColor 'Yellow'

            if ($ScriptBlock -isnot [System.Management.Automation.ScriptBlock])
            {
                $ScriptBlock = [System.Management.Automation.ScriptBlock]::Create([System.String] $ScriptBlock)
            }

            Invoke-Command -Session $session -ScriptBlock $ScriptBlock

            Remove-Session -Session $session
        }
        else
        {
            $commandLine = (Get-PSCallStack)[1].Position.Text.Trim()

            if ($commandLine -like '$*')
            {
                # Option 2: Open Session
                # If a variable is specified as output of the command, a new
                # remoting session will be opened and returned.

                Write-Host "[Launcher] Return the new session on $verbose ..." -ForegroundColor 'Yellow'

                Write-Output $session
            }
            else
            {
                # Option 3: Enter Session
                # If no parameters were specified, just enter into a remote
                # session to the target system.

                Write-Host "[Launcher] Enter remote shell on $verbose  ..." -ForegroundColor 'Yellow'

                # Upload a stub module with helper commands to troubleshoot a
                # Windows system.
                $stubModule = ''
                $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Troubleshooting\Invoke-WindowsAnalyzer.ps1" -Raw
                $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Troubleshooting\Measure-System.ps1" -Raw
                $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Troubleshooting\Measure-Processor.ps1" -Raw
                $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Troubleshooting\Measure-Memory.ps1" -Raw
                $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Troubleshooting\Measure-Storage.ps1" -Raw
                $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Troubleshooting\Measure-Session.ps1" -Raw
                $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Format\Format-HostText.ps1" -Raw
                $stubFormat = Get-Content -Path "$PSScriptRoot\..\..\..\ProfileFever.Xml.Format.ps1xml" -Raw
                Invoke-Command -Session $session -ScriptBlock {
                    Set-Content -Path "$Env:Temp\ProfileFeverStub.psm1" -Value $using:stubModule -Force
                    Import-Module -Name "$Env:Temp\ProfileFeverStub.psm1"
                    Set-Content -Path "$Env:Temp\ProfileFeverStub.Xml.Format.ps1xml" -Value $using:stubFormat -Force
                    Update-FormatData -AppendPath "$Env:Temp\ProfileFeverStub.Xml.Format.ps1xml"
                    Set-Location -Path "$Env:SystemDrive\"
                }

                # Update the prompt of the remoting session to show the name of
                # the connected server.
                if ($Host.Name -eq 'ConsoleHost')
                {
                    Invoke-Command -Session $session -ScriptBlock {
                        $PromptLabel = $Env:ComputerName.ToUpper()
                        $PromptIndent = $using:session.ComputerName.Length + 4
                        function Global:prompt
                        {
                            $Host.UI.RawUI.WindowTitle = "$Env:Username@$Env:ComputerName | $($executionContext.SessionState.Path.CurrentLocation)"
                            Write-Host "[$PromptLabel]" -NoNewline -ForegroundColor Cyan; "$("`b `b" * $PromptIndent) $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
                        }
                    }
                }

                # Show the system state on the remote prompt.
                $state = Invoke-Command -Session $session -ScriptBlock {
                    $perfCounter = Get-Counter -Counter '\Processor Information(_Total)\% Processor Time', '\Memory\Available MBytes' -SampleInterval 1 -MaxSamples 1
                    $computerSystem = Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property 'Name'
                    $operatingSystem = Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property 'Caption', 'LastBootUpTime', 'TotalVisibleMemorySize'
                    $systemDisk = Get-CimInstance -ClassName 'Win32_Volume' -Filter "DriveLetter = 'C:'" -Property 'FreeSpace', 'Capacity'
                    $pageFile = Get-CimInstance -ClassName 'Win32_PageFileUsage'
                    [PSCustomObject] @{
                        Hostname        = $computerSystem.Name
                        OperatingSystem = $operatingSystem.Caption.Replace('Microsoft Windows', 'Windows')
                        Timestamp       = Get-Date
                        LastBootUp      = $operatingSystem.LastBootUpTime
                        Uptime          = (Get-Date) - $operatingSystem.LastBootUpTime
                        SystemLoad      = $perfCounter.CounterSamples.Where({$_.Path -like '\\*\Processor Information(_Total)\% Processor Time'}).CookedValue
                        DiskUsage       = ($systemDisk.Capacity  - $systemDisk.FreeSpace) / $systemDisk.Capacity * 100
                        DiskSize        = $systemDisk.Capacity / 1GB
                        MemoryUsage     = (($operatingSystem.TotalVisibleMemorySize / 1KB) - $perfCounter.CounterSamples.Where({$_.Path -like '\\*\Memory\Available MBytes'}).CookedValue) / ($operatingSystem.TotalVisibleMemorySize / 1KB) * 100
                        MemorySize      = $operatingSystem.TotalVisibleMemorySize / 1MB
                        PageUsage       = $pageFile.CurrentUsage / $pageFile.AllocatedBaseSize * 100
                        PageSize        = $pageFile.AllocatedBaseSize / 1KB
                        ProcessCount    = (Get-Process).Count
                        SessionCount    = (qwinsta.exe).Count - 3
                    }
                }
                Write-Host ''
                Write-Host ('  System information as of {0:dd.MM.yyyy HH:mm:ss zzz} on {1}' -f $state.Timestamp, $state.Hostname)
                Write-Host ''
                Write-Host ('  System load:  {0:0.0}%' -f $state.SystemLoad).PadRight(40)                              ('Processes:        {0:0}' -f $state.ProcessCount)
                Write-Host ('  Disk used:    {0:0.0}% of {1:0}GB (C:\)' -f $state.DiskUsage, $state.DiskSize).PadRight(40)   ('User sessions:    {0:0}' -f $state.SessionCount)
                Write-Host ('  Memory usage: {0:0}% of {1:0}GB' -f $state.MemoryUsage, $state.MemorySize).PadRight(40) ('Operating System: {0}' -f $state.OperatingSystem)
                Write-Host ('  Page usage:   {0:0}% of {1:0}GB' -f $state.PageUsage, $state.PageSize).PadRight(40)     ('Last boot time:   {0:dd.MM.yyyy HH:mm:ss} / {1:d\d\ h\h\ m\m}' -f $state.LastBootUp, $state.Uptime)
                Write-Host ''
                Write-Host '  Troubleshooting:' -ForegroundColor 'DarkGray'
                Write-Host '  Invoke-WindowsAnalyzer     Measure-Processor       Measure-Storage' -ForegroundColor 'DarkGray'
                Write-Host '  Measure-System             Measure-Memory          Measure-Session' -ForegroundColor 'DarkGray'
                Write-Host ''

                Enter-PSSession -Session $session
            }
        }
    }
}

# Register the argument completer for the Name parameter
Register-ArgumentCompleter -CommandName 'Invoke-LauncherPSRemoting' -ParameterName 'Name' -ScriptBlock {
    param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-LauncherPSRemoting -Name "$wordToComplete*" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.ComputerName)
    }
}
