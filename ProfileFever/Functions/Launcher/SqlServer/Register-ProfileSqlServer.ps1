<#
    .SYNOPSIS
        Register the SQL Server connection in the profile.

    .DESCRIPTION
        This command will store the SQL Server connection in the SqlServer.json
        file stored in the users AppData folder. The name must be unique,
        already existing SQL Server connections will be overwritten.
#>
function Register-ProfileSqlServer
{
    [CmdletBinding()]
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
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $SqlCredential
    )

    if ($PSBoundParameters.ContainsKey('SqlCredential'))
    {
        $sqlCredentialTargetName = "PowerShell ProfileFever SqlServer $Name"
        New-VaultEntry -TargetName $sqlCredentialTargetName -Credential $SqlCredential -Force | Out-Null
    }
    else
    {
        $sqlCredentialTargetName = $null
    }

    $object = [PSCustomObject] @{
        SqlInstance   = $SqlInstance
        SqlCredential = $sqlCredentialTargetName
    }

    Register-ProfileObject -Type 'SqlServer' -Name $Name -Tag $Tag -Object $object
}
