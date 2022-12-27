<#
    .SYNOPSIS
        Format the last errors and show them on the console.

    .DESCRIPTION
        The command will get the specified number of errors of the global Error
        variable and shows them in a optimized way to analyze the occurred
        issues. This includes a better error description, the script stack trace
        and all exceptions and inner exceptions.

    .EXAMPLE
        PS C:\> Show-Error
        Show the last 3 errors on the console host.

    .LINK
        https://github.com/claudiospizzi/ProfileFever
#>
function Show-Error
{
    [CmdletBinding(DefaultParameterSetName = 'Last')]
    [Alias('err')]
    param
    (
        # Number of errors to show.
        [Parameter(Mandatory = $false, ParameterSetName = 'Last', Position = 0)]
        [System.Int32]
        $Last = 3,

        # Show all errors.
        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [Switch]
        $All
    )

    try
    {
        $errorRecords = $Global:Error
        if (-not $All.IsPresent)
        {
            $errorRecords = @($errorRecords | Select-Object -First $Last)
        }

        Write-Host ''

        for ($i = 0; $i -lt $errorRecords.Count; $i++)
        {
            $errorRecord = $errorRecords[$i]

            if ($null -ne $errorRecord)
            {
                Write-Host "Error #$i" -ForegroundColor 'Red'
                Write-Host $errorRecord.ToString()
                Write-Host "   $($errorRecord.CategoryInfo)"

                # Optional error details, only show if the exist
                if ($null -ne $errorRecord.TargetObject)
                {
                    Write-Host "   TargetObject: $($errorRecord.TargetObject)"
                }
                if ($null -ne $errorRecord.ErrorDetails)
                {
                    Write-Host "   ErrorDetails: $($errorRecord.ErrorDetails)"
                }

                # Show the stack trace where the exception happened
                foreach ($errorRecordStackTraceLine in ($errorRecord.ScriptStackTrace -split "`n"))
                {
                    if (-not [System.String]::IsNullOrWhiteSpace($errorRecordStackTraceLine))
                    {
                        Write-Host "      $($errorRecordStackTraceLine.Trim())"
                    }
                }

                $errorException = $errorRecord.Exception
                while ($null -ne $errorException)
                {
                    Write-Host $errorException.Message
                    Write-Host "   $($errorException.GetType().FullName)"
                    foreach ($errorExceptionStackTraceLine in ($errorException.StackTrace -split "`n"))
                    {
                        if (-not [System.String]::IsNullOrWhiteSpace($errorExceptionStackTraceLine))
                        {
                            Write-Host "      $($errorExceptionStackTraceLine.Trim())"
                        }
                    }

                    $errorException = $errorException.InnerException
                }
            }

            Write-Host ''
        }

    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
