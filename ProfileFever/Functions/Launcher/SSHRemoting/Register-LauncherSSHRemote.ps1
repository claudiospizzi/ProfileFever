<#
    .SYNOPSIS
        Register the SSH remote connection in the profile.

    .DESCRIPTION
        This command will store the SSH temote connection in the SSHRemote.json
        file stored in the users AppData folder. The name must be unique,
        already existing SSH remote connections will be overwritten.
#>
function Register-LauncherSSHRemote
{
    [CmdletBinding(DefaultParameterSetName = 'PublicPrivateKey')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
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
        [Parameter(Mandatory = $true, ParameterSetName = 'SpecificCredential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        # Instead of specifying the credentials, reuse an existing vault entry
        # as credential. If the vault entry does not exist, it will query the
        # username and password.
        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificCredential')]
        [System.String]
        $CredentialNameSuffix
    )

    $credentialTargetName = $null

    # Reset the username, if credential instead of public/private key were
    # specified.
    if ($PSCmdlet.ParameterSetName -ne 'PublicPrivateKey')
    {
        $Username = $null
    }

    if ($PSCmdlet.ParameterSetName -eq 'SpecificCredential')
    {
        if ($PSBoundParameters.ContainsKey('CredentialNameSuffix'))
        {
            $credentialTargetName = $Script:LauncherCredentialFormat -f 'SSHRemote', $CredentialNameSuffix
        }
        else
        {
            $credentialTargetName = $Script:LauncherCredentialFormat -f 'SSHRemote', $Name
        }

        if ($null -eq (Get-VaultEntry -TargetName $credentialTargetName))
        {
            New-VaultEntry -TargetName $credentialTargetName -Credential $Credential -Force | Out-Null
        }
        else
        {
            Use-VaultCredential -TargetName $credentialTargetName | Out-Null
        }
    }

    $object = [PSCustomObject] @{
        HostName   = $HostName
        Username   = $Username
        Credential = $credentialTargetName
    }

    Register-LauncherObject -Type 'SSHRemote' -Name $Name -Tag $Tag -Object $object
}
