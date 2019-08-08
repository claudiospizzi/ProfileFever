<#
    .SYNOPSIS
        Enable the custom prompt by replacing the default prompt.
#>
function Enable-Prompt
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalFunctions', '')]
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

            $Host.UI.Write($Script:PromptColor, $Host.UI.RawUI.BackgroundColor, "[$Script:PromptInfo]")
            $Host.UI.Write(" $($ExecutionContext.SessionState.Path.CurrentLocation)")
            if ($Script:PromptGit) { Write-VcsStatus }
            return "`n$($MyInvocation.HistoryId.ToString().PadLeft(3, '0'))$('>' * ($NestedPromptLevel + 1)) "
        }
    }
    else
    {
        Import-Module 'PANSIES' -ErrorAction 'Stop' -Global
        Import-Module 'posh-git' -ErrorAction 'Stop' -Global

        function Global:Prompt
        {
            # Definition of used colours
            # See shades on https://www.color-hex.com/color/3a96dd
            $colorText = 'White'
            $colorInfo = [PoshCode.Pansies.RgbColor]::FromRgb('#173c58')
            $colorPath = [PoshCode.Pansies.RgbColor]::FromRgb('#28699a')
            $colorGit1 = [PoshCode.Pansies.RgbColor]::FromRgb('#3a96dd')
            $colorGit2 = [PoshCode.Pansies.RgbColor]::FromRgb('#75b5e7')

            # Definition of special characters
            $separator = [char] 57520
            $branch    = [char] 57504
            $vertical  = [char] 10072

            # If the prompt history id chagned, e.g. a command was executed,
            # show the alias suggestion and last command duration, if enabled.
            if ($Script:PromptHistory -ne $MyInvocation.HistoryId)
            {
                $Script:PromptHistory = $MyInvocation.HistoryId
                if ($Script:PromptAlias) { Show-PromptAliasSuggestion }
                if ($Script:PromptTimeSpan) { Show-PromptLastCommandDuration }
            }

            # Get location and replace the current
            $location = $ExecutionContext.SessionState.Path.CurrentLocation.Path
            $location = $location.Replace($Home, "~")

            # Set the window title
            if ($null -eq $Script:PromptTitle)
            {
                $Host.UI.RawUI.WindowTitle = "$Env:Username@$Env:ComputerName | $location"
            }
            else
            {
                $Host.UI.RawUI.WindowTitle = $Script:PromptTitle
            }

            # Show prompt info and current location
            Write-Host -ForegroundColor $colorText -BackgroundColor $colorInfo -NoNewline " $Script:PromptInfo "
            Write-Host -ForegroundColor $colorInfo -BackgroundColor $colorPath -NoNewline "$separator"
            Write-Host -ForegroundColor $colorText -BackgroundColor $colorPath -NoNewline " $location "
            Write-Host -ForegroundColor $colorPath -NoNewline $separator

            # Check if the current directory is member of a git repo
            if ($Script:PromptGit -and $null -ne (Get-GitDirectory))
            {
                try
                {
                    $Global:GitStatus = Get-GitStatus

                    $status  = $Global:GitStatus
                    $setting = $Global:GitPromptSettings

                    $branchText = '{0} {1}' -f $branch, (Format-GitBranchName -BranchName $status.Branch)

                    if (!$status.Upstream)
                    {
                        # No upstream branch configured
                        $branchText += ' '
                        $branchColor = $colorGit1
                    }
                    elseif ($status.UpstreamGone -eq $true)
                    {
                        # Upstream branch is gone
                        $branchText += ' {0} ' -f $setting.BranchGoneStatusSymbol.Text
                        $branchColor = 'DarkRed'
                    }
                    elseif (($status.BehindBy -eq 0) -and ($status.AheadBy -eq 0))
                    {
                        # We are aligned with remote
                        $branchText += ' {0} ' -f $setting.BranchIdenticalStatusSymbol.Text
                        $branchColor = $colorGit1
                    }
                    elseif (($status.BehindBy -ge 1) -and ($status.AheadBy -ge 1))
                    {
                        # We are both behind and ahead of remote
                        $branchText += ' {0}{1} {2}{3} ' -f $setting.BranchBehindStatusSymbol.Text, $status.BehindBy, $setting.BranchAheadStatusSymbol.Text, $status.AheadBy
                        $branchColor = 'DarkYellow'
                    }
                    elseif ($status.BehindBy -ge 1)
                    {
                        # We are behind remote
                        $branchText += ' {0}{1} ' -f $setting.BranchBehindStatusSymbol.Text, $status.BehindBy
                        $branchColor = 'DarkRed'
                    }
                    elseif ($status.AheadBy -ge 1)
                    {
                        # We are ahead of remote
                        $branchText += ' {0}{1} ' -f $setting.BranchAheadStatusSymbol.Text, $status.AheadBy
                        $branchColor = 'DarkGreen'
                    }
                    else
                    {
                        $branchText += ' ? '
                        $branchColor = $colorGit1
                    }

                    Write-Host "`b$separator " -ForegroundColor $colorPath -BackgroundColor $branchColor -NoNewline
                    Write-Host $branchText -ForegroundColor 'White' -BackgroundColor $branchColor -NoNewline
                    Write-Host $separator -ForegroundColor $branchColor -NoNewline

                    if ($status.HasIndex -or $Status.HasWorking)
                    {
                        Write-Host "`b$separator" -ForegroundColor $branchColor -BackgroundColor $colorGit2 -NoNewline

                        if ($status.HasIndex)
                        {
                            $indexText = ' '
                            $indexText += '{0}{1} ' -f $setting.FileAddedText, $status.Index.Added.Count
                            $indexText += '{0}{1} ' -f $setting.FileModifiedText, $status.Index.Modified.Count
                            $indexText += '{0}{1} ' -f $setting.FileRemovedText, $status.Index.Deleted.Count
                            if ($status.Index.Unmerged)
                            {
                                $indexText += '{0}{1} ' -f $setting.FileConflictedText, $status.Index.Unmerged.Count
                            }

                            Write-Host $indexText -ForegroundColor 'Black' -BackgroundColor $colorGit2 -NoNewline
                        }

                        if ($status.HasIndex -and $Status.HasWorking)
                        {
                            Write-Host $vertical -ForegroundColor 'Black' -BackgroundColor $colorGit2 -NoNewline
                        }

                        if ($Status.HasWorking)
                        {
                            $workingText = ' '
                            $workingText += '{0}{1} ' -f $setting.FileAddedText, $status.Working.Added.Count
                            $workingText += '{0}{1} ' -f $setting.FileModifiedText, $status.Working.Modified.Count
                            $workingText += '{0}{1} ' -f $setting.FileRemovedText, $status.Working.Deleted.Count
                            if ($status.Working.Unmerged)
                            {
                                $workingText += '{0}{1} ' -f $setting.FileConflictedText, $status.Working.Unmerged.Count
                            }

                            Write-Host $workingText -ForegroundColor 'Black' -BackgroundColor $colorGit2 -NoNewline
                        }

                        Write-Host $separator -ForegroundColor $colorGit2 -NoNewline
                    }

                    # Todo
                    # https://github.com/dahlbyk/posh-git/blob/a64e5e073f6ce4dcd01394965bf0bbc91a0e3016/src/GitPrompt.ps1
                    # Write-GitWorkingDirStatusSummary
                    # Write-GitStashCount
                }
                catch
                {
                    Write-Host "`b$separator" -ForegroundColor $colorPath -BackgroundColor $colorGit1 -NoNewline
                    Write-Host " ERROR: $_ " -ForegroundColor $colorText -BackgroundColor $colorGit1 -NoNewline
                    Write-Host $separator -ForegroundColor $colorGit1 -NoNewline
                }
            }

            # Finally, show the command count and the prompt level indicator.
            return "`n$($MyInvocation.HistoryId.ToString().PadLeft(3, '0'))$('>' * ($NestedPromptLevel + 1)) "
        }

        return


        function Global:Prompt
        {
            Write-Host ''


            Write-Host $separator -ForegroundColor $colorInfo -BackgroundColor $colorPath -NoNewline
            Write-Host " $($ExecutionContext.SessionState.Path.CurrentLocation) " -ForegroundColor $colorText -BackgroundColor $colorPath -NoNewline

            if ($null -eq (Get-GitDirectory))
            {
                Write-Host $separator -ForegroundColor $colorPath -NoNewline
            }
            else
            {
                try
                {
                    $Global:GitStatus = Get-GitStatus

                    if (!$Global:GitStatus.Upstream)
                    {
                        # No upstream on this branch
                        $colorBranch = $Global:GitPromptSettings.BranchBackgroundColor
                    }
                    elseif ($Global:GitStatus.UpstreamGone -eq $true)
                    {
                        # Upstream branch is gone
                        $colorBranch = $Global:GitPromptSettings.BranchGoneStatusBackgroundColor
                    }
                    elseif ($Global:GitStatus.BehindBy -eq 0 -and $Global:GitStatus.AheadBy -eq 0)
                    {
                        # We are aligned with remote
                        $colorBranch = $Global:GitPromptSettings.BranchIdenticalStatusToBackgroundColor
                    }
                    elseif ($Global:GitStatus.BehindBy -ge 1 -and $Global:GitStatus.AheadBy -ge 1)
                    {
                        # We are both behind and ahead of remote
                        $colorBranch = $Global:GitPromptSettings.BranchBehindAndAheadStatusBackgroundColor
                    }
                    elseif ($Global:GitStatus.BehindBy -ge 1)
                    {
                        # We are behind remote
                        $colorBranch = $Global:GitPromptSettings.BranchBehindStatusBackgroundColor
                    }
                    elseif ($Global:GitStatus.AheadBy -ge 1)
                    {
                        # We are ahead remote
                        $colorBranch = $Global:GitPromptSettings.BranchAheadStatusBackgroundColor
                    }
                    else
                    {
                        # This condition should not be possible but defaulting the variables to be safe
                        $colorBranch = $Global:GitPromptSettings.BranchBackgroundColor
                    }

                    $Global:GitPromptSettings.DelimBackgroundColor = $colorBranch

                    Write-Host "$separator " -ForegroundColor $colorPath -BackgroundColor $colorBranch -NoNewline
                    Write-Host "$branch " -ForegroundColor 'White' -BackgroundColor $colorBranch -NoNewline

                    Write-GitStatus -Status $GitStatus

                    Write-Host " " -BackgroundColor $colorBranch -NoNewline
                    Write-Host $separator -ForegroundColor $colorBranch -NoNewline
                }
                catch
                {
                    $s = $Global:GitPromptSettings
                    if ($s) {
                        Write-Prompt $s.BeforeText -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor
                        Write-Prompt "Error: $_" -BackgroundColor $s.ErrorBackgroundColor -ForegroundColor $s.ErrorForegroundColor
                        if ($s.Debug) {
                            Write-Host
                            Write-Verbose "PoshGitVcsPrompt error details: $($_ | Format-List * -Force | Out-String)" -Verbose
                        }
                        Write-Prompt $s.AfterText -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor
                    }
                }
            }
        }
    }
}
