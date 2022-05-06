<#
    .SYNOPSIS
        Get the current local system info.

    .DESCRIPTION
        Use WMI/CIM to retrieve the local system info.
        - Update
          Duration since the last system boot up time.

    .EXAMPLE
        PS C:\> system
        Use the alias of Measure-System to show the current system info.
#>
function Measure-System
{
    [CmdletBinding()]
    [Alias('system')]
    param ()

    $cimOperatingSystem = Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property 'LastBootUpTime'

    $timestamp = Get-Date

    [PSCustomObject] @{
        PSTypeName = 'ProfileFever.Performance.System'
        Timestamp  = $timestamp
        Name       = $Env:ComputerName
        Uptime     = $timestamp - $cimOperatingSystem.LastBootUpTime
    }
}
