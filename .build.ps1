
# Import build tasks
. InvokeBuildHelperTasks

# Build configuration
$IBHConfig.GalleryTask.TokenCallback    = { Get-BuildSecret -EnvironmentVariable 'PS_GALLERY_KEY' -CredentialManager 'PowerShell Gallery Key (claudiospizzi)' }
$IBHConfig.RepositoryTask.TokenCallback = { Get-BuildSecret -EnvironmentVariable 'GITHUB_TOKEN' -CredentialManager 'GitHub Token (claudiospizzi)' }

# Special config for the analyzer
$IBHConfig.AnalyzerTestTask.ScriptAnalyzerRules = Get-ScriptAnalyzerRule | Where-Object { $_.RuleName -notin 'PSReviewUnusedParameter', 'PSAvoidGlobalVars', 'PSAvoidGlobalFunctions', 'PSAvoidUsingWriteHost' }
