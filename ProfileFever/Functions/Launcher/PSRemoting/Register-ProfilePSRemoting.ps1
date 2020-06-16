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
    [CmdletBinding()]
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
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    if ($PSBoundParameters.ContainsKey('Credential'))
    {
        $credentialTargetName = $Script:LauncherCredentialFormat -f 'PSRemoting', $Name
        New-VaultEntry -TargetName $credentialTargetName -Credential $Credential -Force | Out-Null
    }
    else
    {
        $credentialTargetName = $null
    }

    $object = [PSCustomObject] @{
        ComputerName = $ComputerName
        Credential   = $credentialTargetName
    }

    Register-ProfileObject -Type 'PSRemoting' -Name $Name -Tag $Tag -Object $object
}
