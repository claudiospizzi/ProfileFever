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
        [Parameter(Mandatory = $true, ParameterSetName = 'Remoting')]
        [System.String]
        $ComputerName,

        # For the remoting command, set the credentials.
        [Parameter(Mandatory = $false, ParameterSetName = 'Remoting')]
        [System.Management.Automation.PSCredential]
        $Credential,

        # Define a script block to execute for the command.
        [Parameter(Mandatory = $true, ParameterSetName = 'ScriptBlock')]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock
    )

    $command = @{
        CommandType = $PSCmdlet.ParameterSetName
        CommandName = $CommandName
    }

    switch ($PSCmdlet.ParameterSetName)
    {
        'Remoting'
        {
            $command['ComputerName'] = $ComputerName
            $command['Credential']   = $Credential
        }

        'ScriptBlock'
        {
            $command['ScriptBlock'] = $ScriptBlock
        }
    }

    $Script:CommandNotFoundAction += [PSCustomObject] $command
}
