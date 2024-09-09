<#
    .SYNOPSIS
        Register the PSRemoting troubleshooting function in the remote session
        without the need of having ProfileFever installed on the remote machine.

    .DESCRIPTION
        This command will register the PSRemoting troubleshooting function in
        the remote session by getting the function definition of these
        self-contained troubleshooting functions and registering them in the
        remoting session.

    .EXAMPLE
        PS C:\> Register-LauncherPSRemotingTroubleshootingFunction -Session $session
        Register the PSRemoting troubleshooting function in the remote session.
#>
function Register-LauncherPSRemotingTroubleshootingFunction
{
    [CmdletBinding()]
    param
    (
        # Session to use for the troubleshooting function registration.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession]
        $Session
    )

    try
    {

    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
