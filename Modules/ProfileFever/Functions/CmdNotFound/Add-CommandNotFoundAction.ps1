<#
    .SYNOPSIS
        Add a command not found action to the list of actions.
#>
function Add-CommandNotFoundAction
{
    [CmdletBinding()]
    param
    (
        # Name of the command.
        [Parameter(Mandatory = $true)]
        [System.String]
        $CommandName,

        # For the remoting command, set the computer name of the target system.
        [Parameter(Mandatory = $true, ParameterSetName = 'PSRemotingWithCredential')]
        [Parameter(Mandatory = $true, ParameterSetName = 'PSRemotingWithVault')]
        [System.String]
        $ComputerName,

        # For the remoting command, set the credentials.
        [Parameter(Mandatory = $false, ParameterSetName = 'PSRemotingWithCredential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        # For the remoting command, but only a pointer to the credential vault.
        [Parameter(Mandatory = $true, ParameterSetName = 'PSRemotingWithVault')]
        [System.String]
        $VaultTargetName,

        # Define a script block to execute for the command.
        [Parameter(Mandatory = $true, ParameterSetName = 'PSScriptBlock')]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,

        # To invoke an ssh session, the target hostname.
        [Parameter(Mandatory = $true, ParameterSetName = 'SSHRemoting')]
        [System.String]
        $Hostname,

        # To invoke an ssh session, the username to use.
        [Parameter(Mandatory = $true, ParameterSetName = 'SSHRemoting')]
        [System.String]
        $Username
    )

    $command = [PSCustomObject] @{
        PSTypeName      = 'ProfileFever.CommandNotFoundAction'
        CommandName     = $CommandName
        CommandType     = $null
        ComputerName    = $null
        Credential      = $null
        CredentialVault = $null
        ScriptBlock     = $null
        Hostname        = $null
        Username        = $null
    }

    switch ($PSCmdlet.ParameterSetName)
    {
        'PSRemotingWithCredential'
        {
            $command.CommandType  = 'Remoting'
            $command.ComputerName = $ComputerName
            $command.Credential   = $Credential
        }

        'PSRemotingWithVault'
        {
            $command.CommandType     = 'Remoting'
            $command.ComputerName    = $ComputerName
            $command.CredentialVault = $VaultTargetName
        }

        'PSScriptBlock'
        {
            $command.CommandType = 'ScriptBlock'
            $command.ScriptBlock = $ScriptBlock
        }

        'SSHRemoting'
        {
            $command.CommandType = 'SSH'
            $command.Hostname    = $Hostname
            $command.Username    = $Username
        }
    }

    $Script:CommandNotFoundAction[$CommandName] = $command
}
