<#
    .SYNOPSIS
        Enable the custom prompt by replacing the default prompt.

    .DESCRIPTION
        There are two prompts available. Be default, the Basic prompt is used.
        It will show all information without any fancy formatting. For a nice
        formiatting, the Advanced type can be used. It's recommended that the
        font Delugia Nerd Font is used. This is an extension of the new font
        Cascadia Code.

    .LINK
        https://github.com/microsoft/cascadia-code/
        https://github.com/adam7/delugia-code/
#>
function Enable-Prompt
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Basic', 'Advanced')]
        [System.String]
        $Type = 'Basic'
    )

    if ($Type -eq 'Basic')
    {
        function Global:Prompt
        {
            if ($Script:PromptHistory -ne $MyInvocation.HistoryId)
            {
                $Script:PromptHistory = $MyInvocation.HistoryId

                if ($Script:PromptAlias) { Show-PromptAliasSuggestion }
                if ($Script:PromptTimeSpan) { Show-PromptLastCommandDuration }
            }

            if ($Script:PromptIsAdmin -or $Script:PromptIsRoot)
            {
                $color = 'Red'
            }
            else
            {
                $color =  'DarkCyan'
            }

            $Host.UI.Write($color, $Host.UI.RawUI.BackgroundColor, "[$Script:PromptInfo]")
            $Host.UI.Write(" $($ExecutionContext.SessionState.Path.CurrentLocation)")
            if ($Script:PromptGit) { Write-VcsStatus }
            return "`n$($MyInvocation.HistoryId.ToString().PadLeft(3, '0'))$('>' * ($NestedPromptLevel + 1)) "
        }
    }

    if ($Type -eq 'Advanced')
    {
        if ($PSVersionTable.PSVersion -lt '6.0')
        {
            Add-Type -AssemblyName 'PresentationFramework'
        }

        function Global:Prompt
        {
            $config = $Global:ProfileFeverPromptConfig

            # Get location and replace the user home directory
            $locationPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path
            $locationPath = $locationPath.Replace($Home, '~')
            $locationParts = @($locationPath -split '\\|/')
            if ($locationParts.Count -gt 4)
            {
                $location = '{1}{0}...{0}{2}{0}{3}{0}{4}' -f ([System.IO.Path]::DirectorySeparatorChar), $locationParts[0], $locationParts[-3], $locationParts[-2], $locationParts[-1]
            }
            else
            {
                $location = $locationParts -join ([System.IO.Path]::DirectorySeparatorChar)
            }


            ## WINDOW TITLE

            # Set the window title with the current location
            if ($null -eq $Script:PromptTitle)
            {
                $Host.UI.RawUI.WindowTitle = "$Env:Username@$Env:ComputerName | $location"
            }
            else
            {
                $Host.UI.RawUI.WindowTitle = $Script:PromptTitle
            }


            ## PROMPT OUTPUT

            $output = [System.Text.StringBuilder]::new()

            # If the prompt history id chagned, e.g. a command was executed,
            # show the alias suggestion and last command duration, if enabled.
            if ($Script:PromptHistory -ne $MyInvocation.HistoryId -or ($PSVersionTable.PSVersion -lt '6.0' -and ([System.Windows.Input.Keyboard]::IsKeyDown('RightShift'))))
            {
                # Update history information
                $Script:PromptHistory = $MyInvocation.HistoryId

                # Show promt alias and command duration
                if ($Script:PromptAlias) { Show-PromptAliasSuggestion }
                if ($Script:PromptTimeSpan) { Show-PromptLastCommandDuration }


                ## PROMPT OUTPUT DEBUG / ADMIN

                if ($NestedPromptLevel -gt 0)
                {
                    Format-HostText -StringBuilder $output -Message $config.DebugText -ForegroundColor $config.DebugForeground -BackgroundColor $config.DebugBackground
                    Format-HostText -StringBuilder $output -Message $config.DebugSeperator -ForegroundColor $config.DebugBackground -BackgroundColor $config.InfoBackground
                }
                elseif ($Script:PromptIsAdmin -or $Script:PromptIsRoot)
                {
                    Format-HostText -StringBuilder $output -Message $config.AdminText -ForegroundColor $config.AdminForeground -BackgroundColor $config.AdminBackground
                    Format-HostText -StringBuilder $output -Message $config.AdminSeperator -ForegroundColor $config.AdminBackground -BackgroundColor $config.InfoBackground
                }


                ## PROMPT OUTPUT INFO

                Format-HostText -StringBuilder $output -Message $config.InfoText -ForegroundColor $config.InfoForeground -BackgroundColor $config.InfoBackground
                Format-HostText -StringBuilder $output -Message $config.InfoSeperator -ForegroundColor $config.InfoBackground -BackgroundColor $config.LocationBackground


                ## PROMPT OUTPUT LOCATION

                Format-HostText -StringBuilder $output -Message " $location " -ForegroundColor $config.LocationForeground -BackgroundColor $config.LocationBackground
                # The seperator is displayed based on the git mode


                ## PROMPT OUTPUT GIT

                # Show an information about the debug prompt
                # Check if the current directory is member of a git repo
                if ($NestedPromptLevel -eq 0 -and $Script:PromptGit -and (Test-GitRepository))
                {
                    try
                    {
                        if ($null -eq (Get-Module -Name 'posh-git'))
                        {
                            Import-Module -Name 'posh-git' -Global
                        }

                        $Global:GitPromptSettings.EnableStashStatus = $true
                        $Global:GitStatus = Get-GitStatus

                        $status  = $Global:GitStatus
                        $setting = $Global:GitPromptSettings


                        ## PROMPT OUTPUT GIT BRANCH

                        $branchText = ' {0} {1}' -f $config.GitBranchIcon, (Format-GitBranchName -BranchName $status.Branch)

                        if (!$status.Upstream)
                        {
                            # No upstream branch configured
                            $branchText += ' '
                            $branchColor = $config.GitBranchBackgroundDefault
                        }
                        elseif ($status.UpstreamGone -eq $true)
                        {
                            # Upstream branch is gone
                            $branchText += ' {0} ' -f $setting.BranchGoneStatusSymbol.Text
                            $branchColor = $config.GitBranchBackgroundBehind
                        }
                        elseif (($status.BehindBy -eq 0) -and ($status.AheadBy -eq 0))
                        {
                            # We are aligned with remote
                            $branchText += ' {0} ' -f $setting.BranchIdenticalStatusSymbol.Text
                            $branchColor = $config.GitBranchBackgroundDefault
                        }
                        elseif (($status.BehindBy -ge 1) -and ($status.AheadBy -ge 1))
                        {
                            # We are both behind and ahead of remote
                            $branchText += ' {0}{1} {2}{3} ' -f $setting.BranchBehindStatusSymbol.Text, $status.BehindBy, $setting.BranchAheadStatusSymbol.Text, $status.AheadBy
                            $branchColor = $config.GitBranchBackgroundMixed
                        }
                        elseif ($status.BehindBy -ge 1)
                        {
                            # We are behind remote
                            $branchText += ' {0}{1} ' -f $setting.BranchBehindStatusSymbol.Text, $status.BehindBy
                            $branchColor = $config.GitBranchBackgroundBehind
                        }
                        elseif ($status.AheadBy -ge 1)
                        {
                            # We are ahead of remote
                            $branchText += ' {0}{1} ' -f $setting.BranchAheadStatusSymbol.Text, $status.AheadBy
                            $branchColor = $config.GitBranchBackgroundAhead
                        }
                        else
                        {
                            # Unknown state, whats that?
                            $branchText += ' ? '
                            $branchColor = $config.GitBranchBackgroundDefault
                        }

                        Format-HostText -StringBuilder $output -Message $config.LocationSeperator -ForegroundColor $config.LocationBackground -BackgroundColor $branchColor
                        Format-HostText -StringBuilder $output -Message $branchText -ForegroundColor $config.GitBranchForeground -BackgroundColor $branchColor
                        # The seperator is displayed based on the git index/working/stash mode

                        if ($status.HasIndex -or $status.HasWorking -or $GitStatus.StashCount -gt 0)
                        {
                            Format-HostText -StringBuilder $output -Message $config.GitBranchSeperator -ForegroundColor $branchColor -BackgroundColor $config.GitDetailBackground

                            if ($status.HasIndex)
                            {
                                $indexText = ' {0} ' -f $config.GitDetailTextIndex
                                $indexText += '{0}{1} ' -f $setting.FileAddedText, $status.Index.Added.Count
                                $indexText += '{0}{1} ' -f $setting.FileModifiedText, $status.Index.Modified.Count
                                $indexText += '{0}{1} ' -f $setting.FileRemovedText, $status.Index.Deleted.Count
                                if ($status.Index.Unmerged)
                                {
                                    $indexText += '{0}{1} ' -f $setting.FileConflictedText, $status.Index.Unmerged.Count
                                }

                                Format-HostText -StringBuilder $output -Message $indexText -ForegroundColor $config.GitDetailForegroundIndex -BackgroundColor $config.GitDetailBackground
                            }

                            # Splitter between index and working or stash
                            if ($status.HasIndex -and ($status.HasWorking -or $GitStatus.StashCount -gt 0))
                            {
                                Format-HostText -StringBuilder $output -Message $config.GitDetailTextSplit -ForegroundColor $config.GitDetailForegroundSplit -BackgroundColor $config.GitDetailBackground
                            }

                            if ($status.HasWorking)
                            {
                                $workingText = ' {0} ' -f $config.GitDetailTextWorking
                                $workingText += '{0}{1} ' -f $setting.FileAddedText, $status.Working.Added.Count
                                $workingText += '{0}{1} ' -f $setting.FileModifiedText, $status.Working.Modified.Count
                                $workingText += '{0}{1} ' -f $setting.FileRemovedText, $status.Working.Deleted.Count
                                if ($status.Working.Unmerged)
                                {
                                    $workingText += '{0}{1} ' -f $setting.FileConflictedText, $status.Working.Unmerged.Count
                                }

                                Format-HostText -StringBuilder $output -Message $workingText -ForegroundColor $config.GitDetailForegroundWorking -BackgroundColor $config.GitDetailBackground
                            }

                            # Splitter between working and stash
                            if ($status.HasWorking -and $GitStatus.StashCount -gt 0)
                            {
                                Format-HostText -StringBuilder $output -Message $config.GitDetailTextSplit -ForegroundColor $config.GitDetailForegroundSplit -BackgroundColor $config.GitDetailBackground
                            }

                            if ($GitStatus.StashCount -gt 0)
                            {
                                $stashText = ' {0} ' -f $config.GitDetailTextStash
                                $stashText += '={0} ' -f $GitStatus.StashCount

                                Format-HostText -StringBuilder $output -Message $stashText -ForegroundColor $config.GitDetailForegroundStash -BackgroundColor $config.GitDetailBackground
                            }

                            Format-HostText -StringBuilder $output -Message $config.GitDetailSeperator -ForegroundColor $config.GitDetailBackground
                        }
                        else
                        {
                            Format-HostText -StringBuilder $output -Message $config.GitBranchSeperator -ForegroundColor $branchColor
                        }
                    }
                    catch
                    {
                        Write-Warning $_

                        #$output.Append((Format-HostText -Message "$separator" -ForegroundColor $colorCyan2 -BackgroundColor $colorCyan3)) | Out-Null
                        #$output.Append((Format-HostText -Message " ERROR: $_ " -ForegroundColor $colorWhite -BackgroundColor $colorCyan3)) | Out-Null
                        #$output.Append((Format-HostText -Message $separator -ForegroundColor $colorCyan3)) | Out-Null
                    }
                }
                else
                {
                    Format-HostText -StringBuilder $output -Message $config.LocationSeperator -ForegroundColor $config.LocationBackground
                }
            }

            # Define the command counter and imput line
            $promptInput = "$($MyInvocation.HistoryId.ToString().PadLeft(3, '0'))$('>' * ($NestedPromptLevel + 1)) "

            # Finally, show the output about path, debug, git etc. and then on a
            # new line the command count and the prompt level indicator
            if ([System.String]::IsNullOrEmpty($output.ToString()))
            {
                return $promptInput
            }
            else
            {
                Write-Host $output -NoNewline
                return "`n$promptInput"
            }
        }
    }
}
