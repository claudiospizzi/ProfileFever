<#
    .SYNOPSIS
        Format the last errors and show them on the console.
#>
function Show-Error
{
    [CmdletBinding()]
    param
    (
        # Number of errors to show.
        [Parameter(Mandatory = $false, Position = 0)]
        [System.Int32]
        $Last = 1,

        # Show all errors.
        [Parameter(Mandatory = $false)]
        [Switch]
        $All
    )

    if ($All.IsPresent)
    {
        $errorRecords = $Global:Error
    }
    else
    {
        $errorRecords = $Global:Error | Select-Object -First $Last
    }

    for ($i = 0; $i -lt $errorRecords.Count; $i++)
    {
        $errorRecord = $errorRecords[$i]

        if ($null -ne $errorRecord)
        {
            $outerException = ''
            $innerException = ''
            if ($null -ne $errorRecord.Exception)
            {
                $outerException = $errorRecord.Exception.GetType().FullName
                if ($null -ne $errorRecord.Exception.InnerException)
                {
                    $innerException = $errorRecord.Exception.InnerException.GetType().FullName
                }
            }

            Write-Host "Error #$i" -ForegroundColor 'Red'
            Write-Host $errorRecord.ToString()
            foreach ($errorRecordStackTraceLine in ($errorRecord.ScriptStackTrace -split "`n"))
            {
                if (-not [System.String]::IsNullOrWhiteSpace($errorRecordStackTraceLine))
                {
                    Write-Host "  $($errorRecordStackTraceLine.Trim())"
                }
            }
            Write-Host "Exception Type : $outerException"
            if (-not [System.String]::IsNullOrWhiteSpace($innerException))
            {
                Write-Host "               : $innerException"
            }
        }
        Write-Host "Target Object  : $($errorRecord.TargetObject)"
        Write-Host ''
    }
}
