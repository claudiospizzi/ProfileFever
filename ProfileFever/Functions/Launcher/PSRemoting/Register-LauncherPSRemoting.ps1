<#
    .SYNOPSIS
        Register the PowerShell Remoting connection in the profile.

    .DESCRIPTION
        This command will store the PowerShell Remoting connection in the
        PSRemoting.json file stored in the users AppData folder. The name must
        be unique, already existing PowerShell Remoting connections will be
        overwritten.
#>
function Register-LauncherPSRemoting
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
        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificCredential')]
        [System.String]
        $CredentialNameSuffix,

        # Provide a script block to get the remoting credentials on demand, e.g.
        # by using a central password management tool.
        [Parameter(Mandatory = $true, ParameterSetName = 'CredentialCallback')]
        [System.Management.Automation.ScriptBlock]
        $CredentialCallbackScript
    )

    $credentialTargetName = $null

    if ($PSCmdlet.ParameterSetName -eq 'SpecificCredential')
    {
        if ($PSBoundParameters.ContainsKey('CredentialNameSuffix'))
        {
            $credentialTargetName = $Script:LAUNCHER_CREDENTIAL_FORMAT -f 'PSRemoting', $CredentialNameSuffix
        }
        else
        {
            $credentialTargetName = $Script:LAUNCHER_CREDENTIAL_FORMAT -f 'PSRemoting', $Name
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

    $credentialScript = $null

    if ($PSCmdlet.ParameterSetName -eq 'CredentialCallback')
    {
        $credentialScript = $CredentialCallbackScript.ToString()
    }

    $object = [PSCustomObject] @{
        ComputerName       = $ComputerName
        Credential         = $credentialTargetName
        CredentialCallback = $credentialScript
    }

    Register-LauncherObject -Type 'PSRemoting' -Name $Name -Tag $Tag -Object $object
}
