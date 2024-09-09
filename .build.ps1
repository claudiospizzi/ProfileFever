
# Import build tasks
. InvokeBuildHelperTasks

# Build configuration
$IBHConfig.RepositoryTask.TokenCallback = { Use-VaultSecureString -TargetName 'GitHub Token (claudiospizzi)' }
$IBHConfig.GalleryTask.TokenCallback    = { Use-VaultSecureString -TargetName 'PowerShell Gallery Key (claudiospizzi)' }

# Special config for the analyzer
$IBHConfig.AnalyzerTestTask.ScriptAnalyzerRules = Get-ScriptAnalyzerRule | Where-Object { $_.RuleName -notin 'PSReviewUnusedParameter', 'PSAvoidGlobalVars', 'PSAvoidGlobalFunctions', 'PSAvoidUsingWriteHost' }
