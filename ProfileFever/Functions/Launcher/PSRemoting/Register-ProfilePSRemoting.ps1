<#
    .SYNOPSIS
        Register the PowerShell Remoting connection in the profile.

    .DESCRIPTION
        This command will store the PowerShell Remoting connection in the
        PSRemoting.json file stored in the users AppData folder. The name must
        be unique, already existing PowerShell Remoting connections will be
        overwritten.
#>
function Register-ProfilePSRemoting
{
    [CmdletBinding(DefaultParameterSetName = 'NoCredential')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
    param
    (
        # Name to identify the PowerShell Remoting connection.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        # Tags for the PowerShell Remoting connection.
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [System.String[]]
        $Tag = @(),

        # DNS name or IP address to connect to the remote system by PowerShell
        # Remoting.
        [Parameter(Mandatory = $true)]
        [System.String]
        $ComputerName,

        # The Windows credentials are optional and can be used, if Kerberos
        # based single sign on is not available.
        [Parameter(Mandatory = $true, ParameterSetName = 'SpecificCredential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        # Instead of specifying the credentials, reuse an existing vault entry
        # as credential. If the vault entry does not exist, it will query the
        # username and password.
        [Parameter(Mandatory = $true, ParameterSetName = 'ExisitngCredential')]
        [System.String]
        $CredentialNameSuffix
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'SpecificCredential'
        {
            $credentialTargetName = $Script:LauncherCredentialFormat -f 'PSRemoting', $Name
            New-VaultEntry -TargetName $credentialTargetName -Credential $Credential -Force | Out-Null
        }

        'ExisitngCredential'
        {
            $credentialTargetName = $Script:LauncherCredentialFormat -f 'PSRemoting', $CredentialNameSuffix
            Use-VaultCredential -TargetName $credentialTargetName | Out-Null
        }

        default
        {
            $credentialTargetName = $null
        }
    }

    $object = [PSCustomObject] @{
        ComputerName = $ComputerName
        Credential   = $credentialTargetName
    }

    Register-ProfileObject -Type 'PSRemoting' -Name $Name -Tag $Tag -Object $object
}
