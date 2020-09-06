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
            Write-Error "PowerShell Remoting connection named '$Name' not found."
        }
        elseif ($launcherPSRemoting.Count -gt 1)
        {
            $launcherPSRemoting | ForEach-Object { Write-Host "[Launcher] PS Remoting target found: $($_.Name)" -ForegroundColor 'DarkYellow' }
            Write-Error "Multiple PowerShell Remoting connections found. Be more specific."
        }
        else
        {
            # Define a splat to connect to the remoting system.
            $splat = @{
                ComputerName = $launcherPSRemoting.ComputerName
            }
            $verbose = "'$($splat['ComputerName'])'"
            if (-not [System.String]::IsNullOrEmpty($launcherPSRemoting.Credential))
            {
                $splat['Credential'] = Get-VaultCredential -TargetName $launcherPSRemoting.Credential
                $verbose += " as '$($splat['Credential'].Username)'"
            }

            if ($PSBoundParameters.ContainsKey('ScriptBlock'))
            {
                # Option 1: Invoke Command
                # If a script is appended to the command, execute that script on the
                # remote system.

                Write-Host "[Launcher] Invoke a remote command on $verbose ..." -ForegroundColor 'DarkYellow'

                if ($ScriptBlock -isnot [System.Management.Automation.ScriptBlock])
                {
                    $ScriptBlock = [System.Management.Automation.ScriptBlock]::Create([System.String] $ScriptBlock)
                }

                Invoke-Command @splat -ScriptBlock $ScriptBlock
            }
            else
            {
                $commandLine = (Get-PSCallStack)[1].Position.Text.Trim()

                if ($commandLine -like '$*')
                {
                    # Option 2: Open Session
                    # If a variable is specified as output of the command, a new
                    # remoting session will be opened and returned.

                    Write-Host "[Launcher] Create a new session on $verbose ..." -ForegroundColor 'DarkYellow'

                    New-PSSession @splat
                }
                else
                {
                    # Option 3: Enter Session
                    # If no parameters were specified, just enter into a remote
                    # session to the target system.

                    Write-Host "[Launcher] Enter remote shell on $verbose ..." -ForegroundColor 'DarkYellow'

                    $session = New-PSSession @splat
                    $stubModule = ''
                    $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Performance\Measure-System.ps1" -Raw
                    $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Performance\Measure-Processor.ps1" -Raw
                    $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Performance\Measure-Memory.ps1" -Raw
                    $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Performance\Measure-Storage.ps1" -Raw
                    $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Performance\Measure-Session.ps1" -Raw
                    $stubFormat = Get-Content -Path "$PSScriptRoot\..\..\..\ProfileFever.Xml.Format.ps1xml" -Raw
                    Invoke-Command -Session $session -ScriptBlock {
                        Set-Content -Path "$Env:Temp\ProfileFeverStub.Xml.Format.ps1xml" -Value $using:stubFormat -Force
                        Set-Content -Path "$Env:Temp\ProfileFeverStub.psm1" -Value $using:stubModule -Force
                        Update-FormatData -AppendPath "$Env:Temp\ProfileFeverStub.Xml.Format.ps1xml"
                        Import-Module -Name "$Env:Temp\ProfileFeverStub.psm1"
                        Set-Location -Path "$Env:SystemDrive\"
                    }
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
                    Enter-PSSession -Session $session
                }
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
