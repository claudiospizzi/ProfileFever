<#
    .SYNOPSIS
        Register the SQL Server connection in the profile.

    .DESCRIPTION
        This command will store the SQL Server connection in the SqlServer.json
        file stored in the users AppData folder. The name must be unique,
        already existing SQL Server connections will be overwritten.
#>
function Register-LauncherSqlServer
{
    [CmdletBinding(DefaultParameterSetName = 'NoCredential')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
    param
    (
        # Name to identify the SQL Server connection.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        # Tags for the SQL Server connection.
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [System.String[]]
        $Tag = @(),

        # DNS name or alias to connect to the SQL Server. May include the
        # instance name.
        [Parameter(Mandatory = $true)]
        [System.String]
        $SqlInstance,

        # The SQL credentials are optional and can be used, if integration
        # authentication is not available.
        [Parameter(Mandatory = $true, ParameterSetName = 'SpecificCredential')]
        [System.Management.Automation.PSCredential]
        $SqlCredential,

        # Instead of specifying the SQL credentials, reuse an existing vault
        # entry as credential. If the vault entry does not exist, it will query
        # the username and password.
        [Parameter(Mandatory = $false, ParameterSetName = 'SpecificCredential')]
        [System.String]
        $SqlCredentialNameSuffix
    )

    $sqlCredentialTargetName = $null

    if ($PSCmdlet.ParameterSetName -eq 'SpecificCredential')
    {
        if ($PSBoundParameters.ContainsKey('SqlCredentialNameSuffix'))
        {
            $sqlCredentialTargetName = $Script:LauncherCredentialFormat -f 'SqlServer', $SqlCredentialNameSuffix
        }
        else
        {
            $sqlCredentialTargetName = $Script:LauncherCredentialFormat -f 'SqlServer', $Name
        }

        if ($null -eq (Get-VaultEntry -TargetName $sqlCredentialTargetName))
        {
            New-VaultEntry -TargetName $sqlCredentialTargetName -Credential $SqlCredential -Force | Out-Null
        }
        else
        {
            Use-VaultCredential -TargetName $sqlCredentialTargetName | Out-Null
        }
    }

    $object = [PSCustomObject] @{
        SqlInstance   = $SqlInstance
        SqlCredential = $sqlCredentialTargetName
    }

    Register-LauncherObject -Type 'SqlServer' -Name $Name -Tag $Tag -Object $object
}
