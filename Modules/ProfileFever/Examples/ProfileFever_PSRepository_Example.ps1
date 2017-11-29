<#
    .EXAMPLE
    Register the repository PSGallery.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -Module ProfileFever

    Node $NodeName
    {
        PSRepository 'PSGallery'
        {
            Ensure         = 'Present'
            Name           = 'PSGallery'
            SourceLocation = 'https://www.powershellgallery.com/api/v2/'
        }
    }
}
