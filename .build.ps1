
# Import build tasks
. InvokeBuildHelperTasks

# Build configuration
$IBHConfig.RepositoryTask.Token = Use-VaultSecureString -TargetName 'GitHub Token (claudiospizzi)'
$IBHConfig.GalleryTask.Token    = Use-VaultSecureString -TargetName 'PowerShell Gallery Key (claudiospizzi)'

# Special config for the analyzer
$IBHConfig.AnalyzeTask.ScriptAnalyzerRules = Get-ScriptAnalyzerRule | Where-Object { $_.RuleName -notin 'PSReviewUnusedParameter', 'PSAvoidGlobalVars', 'PSAvoidGlobalFunctions', 'PSAvoidUsingWriteHost' }
