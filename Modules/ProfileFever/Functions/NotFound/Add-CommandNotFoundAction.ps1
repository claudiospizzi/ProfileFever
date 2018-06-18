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
        [Parameter(Mandatory = $true)]
        [Parameter(ParameterSetName = 'RemotingWithCredential')]
        [Parameter(ParameterSetName = 'RemotingWithVault')]
        [System.String]
        $ComputerName,

        # For the remoting command, set the credentials.
        [Parameter(Mandatory = $false, ParameterSetName = 'RemotingWithCredential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        # For the remoting command, but only a pointer to the credential vault.
        [Parameter(Mandatory = $true, ParameterSetName = 'RemotingWithVault')]
        [System.String]
        $VaultTargetName,

        # Define a script block to execute for the command.
        [Parameter(Mandatory = $true, ParameterSetName = 'ScriptBlock')]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock
    )

    $command = @{
        CommandName = $CommandName
    }

    switch ($PSCmdlet.ParameterSetName)
    {
        'RemotingWithCredential'
        {
            $command['CommandType']  = 'Remoting'
            $command['ComputerName'] = $ComputerName
            $command['Credential']   = $Credential
        }

        'RemotingWithVault'
        {
            $command['CommandType']     = 'Remoting'
            $command['ComputerName']    = $ComputerName
            $command['VaultTargetName'] = $VaultTargetName
        }

        'ScriptBlock'
        {
            $command['CommandType'] = 'ScriptBlock'
            $command['ScriptBlock'] = $ScriptBlock
        }
    }

    $Script:CommandNotFoundAction += [PSCustomObject] $command
}
