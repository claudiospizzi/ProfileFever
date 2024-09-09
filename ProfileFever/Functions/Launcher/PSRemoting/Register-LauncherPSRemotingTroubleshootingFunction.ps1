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
        # Generate a stub module by getting the content of the troubleshooting
        # functions and the format data.
        $stubModule = ''
        $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Troubleshooting\Measure-System.ps1" -Raw
        $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Troubleshooting\Measure-Processor.ps1" -Raw
        $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Troubleshooting\Measure-Memory.ps1" -Raw
        $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Troubleshooting\Measure-Storage.ps1" -Raw
        $stubModule += Get-Content -Path "$PSScriptRoot\..\..\Troubleshooting\Measure-Session.ps1" -Raw
        $stubFormat = Get-Content -Path "$PSScriptRoot\..\..\..\ProfileFever.Xml.Format.ps1xml" -Raw

        # Register the stub module and the format data in the remote session.
        Invoke-Command -Session $Session -ScriptBlock {
            Set-Content -Path "$Env:Temp\ProfileFeverStub.psm1" -Value $using:stubModule -Force
            Import-Module -Name "$Env:Temp\ProfileFeverStub.psm1"
            Set-Content -Path "$Env:Temp\ProfileFeverStub.Xml.Format.ps1xml" -Value $using:stubFormat -Force
            Update-FormatData -AppendPath "$Env:Temp\ProfileFeverStub.Xml.Format.ps1xml"
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
