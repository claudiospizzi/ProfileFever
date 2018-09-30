
Properties {

    $ModuleNames    = 'ProfileFever'

    $GalleryEnabled = $true
    $GalleryKey     = Use-VaultSecureString -TargetName 'PowerShell Gallery Key (claudiospizzi)'

    $GitHubEnabled  = $true
    $GitHubRepoName = 'claudiospizzi/ProfileFever'
    $GitHubToken    = Use-VaultSecureString -TargetName 'GitHub Token (claudiospizzi)'
}
