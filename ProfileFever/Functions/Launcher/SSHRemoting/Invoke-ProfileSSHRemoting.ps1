<#
    .SYNOPSIS
        Connect to a remote system by using a registered SSH remote connection.

    .DESCRIPTION
        Use the SSH remote connections registered in the profile to connect to
        the remote host. Currently only opening an interactive connection is
        supported.

    .EXAMPLE
        PS C:\> ssh
        List all available SSH remote connections.

    .EXAMPLE
        PS C:\> ssh srv01
        Connect to the remote interactive shell of SSH remote.
#>
function Invoke-ProfileSSHRemote
{
    [CmdletBinding(DefaultParameterSetName = 'Show')]
    [Alias('ssh', 'l')]
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
        # Show all registered SSH Remote connections. This may help to
        # choose the correct connection.

        Get-ProfileSSHRemote
    }

    if ($PSCmdlet.ParameterSetName -eq 'Connect')
    {
        $profileSSHRemote = @(Get-ProfileSSHRemote -Name $Name)

        if ($null -eq $profileSSHRemote)
        {
            throw "SSH remote connection named '$Name' not found."
        }

        if ($profileSSHRemote.Count -gt 1)
        {
            $profileSSHRemote | ForEach-Object { Write-Host "[Profile Launcher] SSH remote target found: $($_.Name)" -ForegroundColor 'DarkYellow' }
            throw "Multiple SSH remote connections found. Be more specific."
        }


        if (-not [System.String]::IsNullOrEmpty($profileSSHRemote.Username))
        {
            # Use public/private key authentication
            $hostname = $profileSSHRemote.ComputerName
            $username = $profileSSHRemote.Username

            Write-Host "[Profile Launcher] Enter remote shell on $hostname as $username ..." -ForegroundColor 'DarkYellow'

            ssh.exe "$username@$hostname"
        }
        else
        {
            # Use username/password authentication
            $credential = Get-VaultCredential -TargetName $profileSSHRemote.Credential
            $hostname = $profileSSHRemote.ComputerName
            $username = $credential.UserName
            $password = $credential.GetNetworkCredential().Password

            Write-Host "[Profile Launcher] Enter remote shell on $hostname as $username ..." -ForegroundColor 'DarkYellow'

            plink.exe '-ssh' "$username@$hostname" '-pw' $password
        }
    }
}

# Register the argument completer for the Name parameter
Register-ArgumentCompleter -CommandName 'Invoke-ProfileSSHRemote' -ParameterName 'Name' -ScriptBlock {
    param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-ProfileSSHRemote -Name "$wordToComplete*" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.ComputerName)
    }
}
