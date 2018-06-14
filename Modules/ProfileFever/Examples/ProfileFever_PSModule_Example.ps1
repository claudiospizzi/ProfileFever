<#
    .EXAMPLE
        Install the module SecurityFever with version 1.0.0.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName 'ProfileFever'

    Node $NodeName
    {
        PSModule 'ProfileFever'
        {
            Ensure  = 'Present'
            Name    = 'ProfileFever'
            Version = '1.0.0'
        }
    }
}
