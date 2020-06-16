<#
    .SYNOPSIS
        Connect to a remote system by using a registered SSH remoting
        connection.

    .DESCRIPTION
        Use the SSH remoting connections registered in the profile to connect to
        the remote host. Currently only opening an interactive connection is
        supported.

    .EXAMPLE
        PS C:\> ssh
        List all available SSH remoting connections.

    .EXAMPLE
        PS C:\> ssh srv01
        Connect to the remote interactive shell of SSH remoting.
#>
function Invoke-ProfileSSHRemoting
{
    [CmdletBinding(DefaultParameterSetName = 'Show')]
    [Alias('ssh', 'l')]
    param
    (
        # Name of the SSH remoting connection to use.
        [Parameter(Mandatory = $true, ParameterSetName = 'Connect', Position = 0)]
        [System.String]
        $Name
    )

    $ErrorActionPreference = 'Stop'

    if ($PSCmdlet.ParameterSetName -eq 'Show')
    {
        # Show all registered SSH Remoting connections. This may help to
        # choose the correct connection.

        Get-ProfileSSHRemoting
    }

    if ($PSCmdlet.ParameterSetName -eq 'Connect')
    {
        $profileSSHRemoting = @(Get-ProfileSSHRemoting -Name $Name)

        if ($null -eq $profileSSHRemoting)
        {
            throw "SSH remoting connection named '$Name' not found."
        }

        if ($profileSSHRemoting.Count -gt 1)
        {
            $profileSSHRemoting | ForEach-Object { Write-Host "[Profile Launcher] SSH remoting target found: $($_.Name)" -ForegroundColor 'DarkYellow' }
            throw "Multiple SSH remoting connections found. Be more specific."
        }


        if (-not [System.String]::IsNullOrEmpty($profileSSHRemoting.Username))
        {
            # Use public/private key authentication
            $hostname = $profileSSHRemoting.ComputerName
            $username = $profileSSHRemoting.Username

            Write-Host "[Profile Launcher] Enter remote shell on $hostname as $username ..." -ForegroundColor 'DarkYellow'

            ssh.exe "$username@$hostname"
        }
        else
        {
            # Use username/password authentication
            $credential = Get-VaultCredential -TargetName $profileSSHRemoting.Credential
            $hostname = $profileSSHRemoting.ComputerName
            $username = $credential.UserName
            $password = $credential.GetNetworkCredential().Password

            Write-Host "[Profile Launcher] Enter remote shell on $hostname as $username ..." -ForegroundColor 'DarkYellow'

            plink.exe '-ssh' "$username@$hostname" '-pw' $password
        }
    }
}

# Register the argument completer for the Name parameter
Register-ArgumentCompleter -CommandName 'Invoke-ProfileSSHRemoting' -ParameterName 'Name' -ScriptBlock {
    param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-ProfileSSHRemoting -Name "$wordToComplete*" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.ComputerName)
    }
}
