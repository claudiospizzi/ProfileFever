<#
    .SYNOPSIS
        Register the SSH remote connection in the profile.

    .DESCRIPTION
        This command will store the SSH temote connection in the SSHRemote.json
        file stored in the users AppData folder. The name must be unique,
        already existing SSH remote connections will be overwritten.
#>
function Register-ProfileSSHRemote
{
    [CmdletBinding(DefaultParameterSetName = 'PublicPrivateKey')]
    param
    (
        # Name to identify the SSH remote connection.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        # Tags for the SSH remote connection.
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [System.String[]]
        $Tag = @(),

        # DNS name or IP address to connect to the remote system by SSH
        # remote.
        [Parameter(Mandatory = $true)]
        [System.String]
        $HostName,

        # The remote credentials are optional and can be used, if public/private
        # key authentication on the remote system is not available.
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicPrivateKey')]
        [System.String]
        $Username = 'root',

        # The remote credentials are optional and can be used, if public/private
        # key authentication on the remote system is not available.
        [Parameter(Mandatory = $true, ParameterSetName = 'UsernamePassword')]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    if ($PSCmdlet.ParameterSetName -eq 'PublicPrivateKey')
    {
        # Yeah just use the username
    }
    else
    {
        $Username = $null
    }

    if ($PSCmdlet.ParameterSetName -eq 'UsernamePassword')
    {
        $credentialTargetName = $Script:LauncherCredentialFormat -f 'SSHRemote', $Name
        New-VaultEntry -TargetName $credentialTargetName -Credential $Credential -Force | Out-Null
    }
    else
    {
        $credentialTargetName = $null
    }

    $object = [PSCustomObject] @{
        HostName   = $HostName
        Username   = $Username
        Credential = $credentialTargetName
    }

    Register-ProfileObject -Type 'SSHRemote' -Name $Name -Tag $Tag -Object $object
}
