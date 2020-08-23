<#
    .SYNOPSIS
        Get all sessions on the local system.

    .DESCRIPTION
        Use the qwinsta.exe command to retrieve all local sessions.
        ...

    .EXAMPLE
        PS C:\> session
        Use the alias of Measure-Session to show the local sessions.
#>
function Measure-Session
{
    [CmdletBinding()]
    [Alias('session')]
    param
    (
        # Flag to continue showing the memory every second.
        [Parameter(Mandatory = $false)]
        [ValidateSet('qwinsta', 'process')]
        [System.String]
        $Mode = 'qwinsta'
    )

    $timestamp = Get-Date

    if ($Mode -eq 'qwinsta')
    {
        $rawSesssions = qwinsta.exe
        $rawSesssions = $rawSesssions | Select-Object -Skip 1

        $processesBySessionId = Get-Process | Group-Object -Property 'SessionId' -AsHashTable

        foreach ($rawSesssion in $rawSesssions)
        {
            if ($rawSesssion.PadRight(68) -match '^(?<Active>.{1})(?<Name>.{18})(?<User>.{22})(?<Id>.{5})  (?<Status>.{8})(?<Type>.{12})(?<Device>.*)$')
            {
                $counterSession = [PSCustomObject] @{
                    PSTypeName = 'ProfileFever.Performance.Session'
                    Timestamp  = $timestamp
                    Name       = $Matches.Name.Trim()
                    Id         = $Matches.Id.Trim() -as [System.Int32]
                    User       = $Matches.User.Trim()
                    Active     = -not [System.String]::IsNullOrWhiteSpace($Matches.Active)
                    Status     = $Matches.Status.Trim()
                    Type       = $Matches.Type.Trim()
                    Device     = $Matches.Device.Trim()
                    Processes  = 0
                    Memory     = 0
                }

                # The process statistic per session.
                if ($processesBySessionId.ContainsKey($counterSession.Id))
                {
                    $processMeasure = $processesBySessionId[$counterSession.Id] | Measure-Object -Sum 'WorkingSet64'
                    $counterSession.Processes = $processMeasure.Count
                    $counterSession.Memory    = $processMeasure.Sum
                }

                # Get the connection state.
                # https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ne-wtsapi32-wts_connectstate_class?redirectedfrom=MSDN
                switch ($counterSession.Status)
                {
                    'Aktiv'  { $counterSession.Status = 'Active' }
                    'Active' { $counterSession.Status = 'Active' }
                    'Verb.'  { $counterSession.Status = 'Connected' }
                    # ''     { $counterSession.Status = 'Connected' }
                    # ''     { $counterSession.Status = 'ConnectQuery' }
                    # ''     { $counterSession.Status = 'ConnectQuery' }
                    # ''     { $counterSession.Status = 'Shadow' }
                    # ''     { $counterSession.Status = 'Shadow' }
                    'Getr.'  { $counterSession.Status = 'Disconnected' }
                    'Disc'   { $counterSession.Status = 'Disconnected' }
                    # ''     { $counterSession.Status = 'Idle' }
                    # ''     { $counterSession.Status = 'Idle' }
                    'Abh”r.' { $counterSession.Status = 'Listen' }
                    'Listen' { $counterSession.Status = 'Listen' }
                    # ''     { $counterSession.Status = 'Reset' }
                    # ''     { $counterSession.Status = 'Reset' }
                    # ''     { $counterSession.Status = 'Down' }
                    'Down'   { $counterSession.Status = 'Down' }
                    # ''     { $counterSession.Status = 'Init' }
                    # ''     { $counterSession.Status = 'Init' }
                }

                Write-Output $counterSession
            }
        }
    }

    if ($Mode -eq 'wmi')
    {
        $cimSessions = Get-CimInstance -ClassName 'Win32_Process' | Group-Object -Property 'SessionId' -AsHashTable
        $sessionIds  = $cimSessions.Keys | Sort-Object

        foreach ($sessionId in $sessionIds)
        {
            $cimSessionProcesses = $cimSessions[$sessionId]

            $counterSession = [PSCustomObject] @{
                PSTypeName = 'ProfileFever.Performance.Session'
                Timestamp  = $timestamp
                Name       = ''
                Id         = $sessionId -as [System.Int32]
                User       = $cimSessionProcesses | Where-Object { $_.Name -notin 'csrss.exe', 'winlogon.exe', 'dwm.exe' -and $_.Path -notlike '*\Citrix\*' } | Select-Object -First 1 | Invoke-CimMethod -MethodName 'GetOwner' | Select-Object -ExpandProperty 'User'
                Active     = $cimSessionProcesses.ProcessId -contains $PID
                Status     = ''
                Type       = ''
                Device     = ''
                Processes  = $cimSessionProcesses.Count
                Memory     = ($cimSessionProcesses | Measure-Object -Sum 'WorkingSetSize').Sum
            }

            Write-Output $counterSession
        }
    }
}
