<#
    .SYNOPSIS
        Connect to a remote system by using a registered SSH remote connection.

    .DESCRIPTION
        Use the SSH remote connections registered in the profile launcher to
        connect to the remote host. Currently only opening an interactive
        connection is supported.

    .EXAMPLE
        PS C:\> ssh
        List all available SSH remote connections.

    .EXAMPLE
        PS C:\> ssh srv01
        Connect to the remote interactive shell of SSH remote.
#>
function Invoke-LauncherSSHRemote
{
    [CmdletBinding(DefaultParameterSetName = 'Show')]
    [Alias('shell', 'l')]
    param
    (
        # Name of the SSH remote connection to use.
        [Parameter(Mandatory = $true, ParameterSetName = 'Connect', Position = 0)]
        [System.String]
        $Name
    )

    $ErrorActionPreference = 'Stop'

    if ($PSCmdlet.ParameterSetName -eq 'Show')
    {
        # Show all registered SSH Remote connections. This may help to choose
        # the correct connection.

        Get-LauncherSSHRemote
    }

    if ($PSCmdlet.ParameterSetName -eq 'Connect')
    {
        $launcherSSHRemote = @(Get-LauncherSSHRemote -Name $Name)

        if ($null -eq $launcherSSHRemote -or $launcherSSHRemote.Count -eq 0)
        {
            Write-Error "SSH remote connection named '$Name' not found."
        }
        elseif ($launcherSSHRemote.Count -gt 1)
        {
            $launcherSSHRemote | ForEach-Object { Write-Host "[Launcher] SSH remote target found: $($_.Name)" -ForegroundColor 'DarkYellow' }
            Write-Error "Multiple SSH remote connections found. Be more specific."
        }
        else
        {
            if (-not [System.String]::IsNullOrEmpty($launcherSSHRemote.Username))
            {
                # Use public/private key authentication
                $hostname = $launcherSSHRemote.ComputerName
                $username = $launcherSSHRemote.Username

                Write-Host "[Launcher] Enter remote shell on $hostname as $username ..." -ForegroundColor 'DarkYellow'

                ssh.exe "$username@$hostname"
            }
            else
            {
                # Use username/password authentication
                $credential = Get-VaultCredential -TargetName $launcherSSHRemote.Credential
                $hostname = $launcherSSHRemote.ComputerName
                $username = $credential.UserName
                $password = $credential.GetNetworkCredential().Password

                Write-Host "[Launcher] Enter remote shell on $hostname as $username ..." -ForegroundColor 'DarkYellow'

                plink.exe '-ssh' "$username@$hostname" '-pw' $password
            }
        }
    }
}

# Register the argument completer for the Name parameter
Register-ArgumentCompleter -CommandName 'Invoke-LauncherSSHRemote' -ParameterName 'Name' -ScriptBlock {
    param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-LauncherSSHRemote -Name "$wordToComplete*" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.ComputerName)
    }
}
