<#
    .SYNOPSIS
        Register the command not found action callback.
#>
function Enable-CommandNotFoundAction
{
    [CmdletBinding()]
    param ()

    $Global:ExecutionContext.InvokeCommand.CommandNotFoundAction = {
        param ($CommandName, $CommandLookupEventArgs)

        foreach ($command in $Script:CommandNotFoundAction)
        {
            if ($command.CommandName -eq $CommandName)
            {
                $commandLine = (Get-PSCallStack)[1].Position.Text.Trim()

                switch ($command.CommandType)
                {
                    'Remoting'
                    {
                        $credentialSplat = @{}
                        if ($command.Credential)
                        {
                            $credentialSplat['Credential'] = $command.Credential
                            $credentialVerbose = " -Credential '{1}'" -f $command.Credential.UserName
                        }

                        # Option 1: Enter Session
                        # If no parameters were specified, just enter into a
                        # remote session to the target system.
                        if ($CommandName -eq $commandLine)
                        {
                            Write-Verbose ("Enter-PSSession -ComputerName '{0}'{1}" -f $command.ComputerName, $credentialVerbose)

                            $CommandLookupEventArgs.StopSearch = $true
                            $CommandLookupEventArgs.CommandScriptBlock = {
                                $session = New-PSSession -ComputerName $command.ComputerName @credentialSplat -ErrorAction Stop
                                if ($Host.Name -eq 'ConsoleHost')
                                {
                                    Invoke-Command -Session $session -ErrorAction Stop -ScriptBlock { Set-Location -Path "$Env:SystemDrive\"; $PromptLabel = $Env:ComputerName.ToUpper(); $PromptIndent = $using:session.ComputerName.Length + 4; function Global:prompt { Write-Host "[$PromptLabel]" -NoNewline -ForegroundColor Cyan; "$("`b `b" * $PromptIndent) $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) " } }
                                }
                                Enter-PSSession -Session $session -ErrorAction Stop
                            }.GetNewClosure()
                        }

                        # Option 2: Open Session
                        # If a variable is specified as output of the command,
                        # a new remoting session will be opened and returned.
                        $openSessionRegex = '^\$\S+ = {0}$' -f ([System.Text.RegularExpressions.Regex]::Escape($CommandName))
                        if ($commandLine -match $openSessionRegex)
                        {
                            Write-Verbose ("New-PSSession -ComputerName '{0}'{1}" -f $command.ComputerName, $credentialVerbose)

                            $CommandLookupEventArgs.StopSearch = $true
                            $CommandLookupEventArgs.CommandScriptBlock = {
                                New-PSSession -ComputerName $command.ComputerName @credentialSplat -ErrorAction Stop
                            }.GetNewClosure()
                        }

                        # Option 3: Invoke Command
                        # If a script is appended to the command, execute that
                        # script on the remote system.
                        if ($commandline.StartsWith($CommandName) -and $commandLine.Length -gt $CommandName.Length)
                        {
                            $scriptBlock = [System.Management.Automation.ScriptBlock]::Create($commandLine.Substring($CommandName.Length).Trim())

                            Write-Verbose ("Invoke-Command -ComputerName '{0}'{1} -ScriptBlock {{ {2} }}" -f $command.ComputerName, $credentialVerbose, $scriptBlock.ToString())

                            $CommandLookupEventArgs.StopSearch = $true
                            $CommandLookupEventArgs.CommandScriptBlock = {
                                Invoke-Command -ComputerName $command.ComputerName @credentialSplat -ScriptBlock $scriptBlock -ErrorAction Stop
                            }.GetNewClosure()
                        }
                    }

                    'ScriptBlock'
                    {
                        throw 'Not implemented!'
                    }
                }
            }
        }
    }
}
