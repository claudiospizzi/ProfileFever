<#
    .SYNOPSIS
        Connect to a SSH jump host.

    .DESCRIPTION
        This script will connect to the specified SSH jump host by using the
        credentials and the plink.exe tool. With the shared secret, it will
        generate a time-based one-time password as two factor authentication.

    .PARAMETER ComputerName
        DNS hostname of the jump host.

    .PARAMETER Credential
        Username and password of the jump host user.

    .PARAMETER SharedSecret
        Shared secret for the TOTP calculation.
#>
function Connect-JumpHost
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ComputerName,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]
        $SharedSecret,

        [Parameter(Mandatory = $false)]
        [System.Int32]
        $InputOffset = 2
    )

    # Hide verbose preference
    $VerbosePreference = 'SilentlyContinue'

    # Connection credentials
    $username = $Credential.UserName
    $password = $Credential.Password | Unprotect-SecureString

    # TOTP shared secret
    $secret = $SharedSecret | Unprotect-SecureString

    # Get the current cursor position, to calculate the input
    $cursorTop = [System.Console]::CursorTop + $InputOffset

    # This script block is invoked asynchronously to enter the TOTP two factor
    # as soon as the desired line is reached.
    $scriptBlock = {
        param ($title, $line, $secret)
        while ([System.Console]::CursorTop -lt $line)
        {
            Start-Sleep -Milliseconds 5
        }
        $wShell = New-Object -ComObject 'WScript.Shell'
        $wShell.AppActivate($title)
        $totp = Get-TimeBasedOneTimePassword -SharedSecret $secret
        $totp.ToString().ToCharArray() | ForEach-Object { $wShell.SendKeys($_) }
        $wShell.SendKeys('~')
    }
    $runspace = [PowerShell]::Create()
    $runspace.AddScript($scriptBlock).AddArgument($Host.UI.RawUI.WindowTitle).AddArgument($cursorTop).AddArgument($secret) | Out-Null
    $runspace.BeginInvoke() | Out-Null

    plink.exe '-ssh' "$username@$ComputerName" '-pw' $password
}
