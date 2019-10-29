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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
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

    if ($Type -eq 'Advanced')
    {
        if ($PSVersionTable.PSVersion -lt '6.0')
        {
            Add-Type -AssemblyName 'PresentationFramework'
        }

        function Global:Prompt
        {
            # Definition of used colours
            # See cyan shades on https://www.color-hex.com/color/3a96dd
            $colorCyan1       = 0x17, 0x3C, 0x58
            $colorCyan2       = 0x28, 0x69, 0x9A
            $colorCyan3       = 0x3A, 0x96, 0xDD
            $colorCyan4       = 0x75, 0xB5, 0xE7
            $colorCyan5       = 0x85, 0xC5, 0xF7
            $colorWhite       = 0xF2, 0xF2, 0xF2
            # $colorBlack     = 0x0C, 0x0C, 0x0C # Not used at the moment
            $colorRed         = 0xCC, 0x00, 0x00
            $colorDarkRed     = 0xC5, 0x0F, 0x1F
            $colorDarkYellow  = 0xC1, 0x9C, 0x00
            $colorDarkGreen   = 0x13, 0x90, 0x0E # Darker than console color
            $colorDarkMagenta = 0x88, 0x17, 0x98

            # Definition of special characters
            $separator   = [char] 57520
            $diagonal    = "$([char]57532)$([char]57530)"
            $iconBranch  = [char] 57504
            $iconIndex   = [char] 57354
            $iconWorking = [char] 57353
            $iconStash   = [char] 58915
            $iconAdmin   = [char] 9760
            $iconDebug   = [char] 9874

            # Get location and replace the user home directory
            $location = $ExecutionContext.SessionState.Path.CurrentLocation.Path
            $location = $location.Replace($Home, "~")

            # Set the window title with the current location
            if ($null -eq $Script:PromptTitle)
            {
                $Host.UI.RawUI.WindowTitle = "$Env:Username@$Env:ComputerName | $location"
            }
            else
            {
                $Host.UI.RawUI.WindowTitle = $Script:PromptTitle
            }

            $output = [System.Text.StringBuilder]::new()

            $showFullPrompt = $PSVersionTable.PSVersion -lt '6.0' -and ([System.Windows.Input.Keyboard]::IsKeyDown('RightShift'))

            # If the prompt history id chagned, e.g. a command was executed,
            # show the alias suggestion and last command duration, if enabled.
            if ($Script:PromptHistory -ne $MyInvocation.HistoryId -or $showFullPrompt)
            {
                # Update history information
                $Script:PromptHistory = $MyInvocation.HistoryId

                # Show promt alias and command duration
                if ($Script:PromptAlias) { Show-PromptAliasSuggestion }
                if ($Script:PromptTimeSpan) { Show-PromptLastCommandDuration }

                if ($Script:PromptIsAdmin)
                {
                    $output.Append((Format-HostText -Message " $iconAdmin " -BackgroundColor $colorRed)) | Out-Null
                }

                # Show an information about the debug prompt
                if ($NestedPromptLevel -gt 0)
                {
                    $output.Append((Format-HostText -Message " $iconDebug " -BackgroundColor $colorDarkMagenta)) | Out-Null
                }

                # Get the prompt info and current location
                $output.Append((Format-HostText -Message " $Script:PromptInfo " -ForegroundColor $colorWhite -BackgroundColor $colorCyan1)) | Out-Null
                $output.Append((Format-HostText -Message $separator -ForegroundColor $colorCyan1 -BackgroundColor $colorCyan2)) | Out-Null
                $output.Append((Format-HostText -Message " $location " -ForegroundColor $colorWhite -BackgroundColor $colorCyan2)) | Out-Null
                $output.Append((Format-HostText -Message $separator -ForegroundColor $colorCyan2)) | Out-Null

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

                        $branchText = '{0} {1}' -f $iconBranch, (Format-GitBranchName -BranchName $status.Branch)

                        if (!$status.Upstream)
                        {
                            # No upstream branch configured
                            $branchText += ' '
                            $branchColor = $colorCyan3
                        }
                        elseif ($status.UpstreamGone -eq $true)
                        {
                            # Upstream branch is gone
                            $branchText += ' {0} ' -f $setting.BranchGoneStatusSymbol.Text
                            $branchColor = $colorDarkRed
                        }
                        elseif (($status.BehindBy -eq 0) -and ($status.AheadBy -eq 0))
                        {
                            # We are aligned with remote
                            $branchText += ' {0} ' -f $setting.BranchIdenticalStatusSymbol.Text
                            $branchColor = $colorCyan3
                        }
                        elseif (($status.BehindBy -ge 1) -and ($status.AheadBy -ge 1))
                        {
                            # We are both behind and ahead of remote
                            $branchText += ' {0}{1} {2}{3} ' -f $setting.BranchBehindStatusSymbol.Text, $status.BehindBy, $setting.BranchAheadStatusSymbol.Text, $status.AheadBy
                            $branchColor = $colorDarkYellow
                        }
                        elseif ($status.BehindBy -ge 1)
                        {
                            # We are behind remote
                            $branchText += ' {0}{1} ' -f $setting.BranchBehindStatusSymbol.Text, $status.BehindBy
                            $branchColor = $colorDarkRed
                        }
                        elseif ($status.AheadBy -ge 1)
                        {
                            # We are ahead of remote
                            $branchText += ' {0}{1} ' -f $setting.BranchAheadStatusSymbol.Text, $status.AheadBy
                            $branchColor = $colorDarkGreen
                        }
                        else
                        {
                            $branchText += ' ? '
                            $branchColor = $colorCyan3
                        }

                        $output.Append((Format-HostText -Message "`b$separator " -ForegroundColor $colorCyan2 -BackgroundColor $branchColor)) | Out-Null
                        $output.Append((Format-HostText -Message $branchText -ForegroundColor $colorWhite -BackgroundColor $branchColor)) | Out-Null
                        $output.Append((Format-HostText -Message $separator -ForegroundColor $branchColor)) | Out-Null

                        if ($status.HasIndex -or $status.HasWorking -or $GitStatus.StashCount -gt 0)
                        {
                            $output.Append((Format-HostText -Message "`b$separator" -ForegroundColor $branchColor -BackgroundColor $colorCyan4)) | Out-Null

                            $outputPart  = @()
                            $outputSplit = Format-HostText -Message $diagonal -ForegroundColor $colorCyan4 -BackgroundColor $colorCyan5

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
                                $indexText += "$iconIndex "

                                $outputPart += Format-HostText -Message $indexText -ForegroundColor 0,96,0 -BackgroundColor $colorCyan4
                            }

                            if ($status.HasWorking)
                            {
                                $workingText = ' '
                                $workingText += '{0}{1} ' -f $setting.FileAddedText, $status.Working.Added.Count
                                $workingText += '{0}{1} ' -f $setting.FileModifiedText, $status.Working.Modified.Count
                                $workingText += '{0}{1} ' -f $setting.FileRemovedText, $status.Working.Deleted.Count
                                if ($status.Working.Unmerged)
                                {
                                    $workingText += '{0}{1} ' -f $setting.FileConflictedText, $status.Working.Unmerged.Count
                                }
                                $workingText += "$iconWorking "

                                $outputPart += Format-HostText -Message $workingText -ForegroundColor 96,0,0 -BackgroundColor $colorCyan4
                            }

                            if ($GitStatus.StashCount -gt 0)
                            {
                                $stashText = " +{0} $iconStash " -f $GitStatus.StashCount

                                $outputPart += Format-HostText -Message $stashText -ForegroundColor 0,0,96 -BackgroundColor $colorCyan4
                            }

                            $output.Append($outputPart[0]) | Out-Null
                            for ($i = 1; $i -lt $outputPart.Count; $i++)
                            {
                                $output.Append($outputSplit) | Out-Null
                                $output.Append($outputPart[$i]) | Out-Null
                            }

                            $output.Append((Format-HostText -Message $separator -ForegroundColor $colorCyan4)) | Out-Null
                        }
                    }
                    catch
                    {
                        $output.Append((Format-HostText -Message "`b$separator" -ForegroundColor $colorCyan2 -BackgroundColor $colorCyan3)) | Out-Null
                        $output.Append((Format-HostText -Message " ERROR: $_ " -ForegroundColor $colorWhite -BackgroundColor $colorCyan3)) | Out-Null
                        $output.Append((Format-HostText -Message $separator -ForegroundColor $colorCyan3)) | Out-Null
                    }
                }
            }

            # Define the command counter and imput line
            $input = "$($MyInvocation.HistoryId.ToString().PadLeft(3, '0'))$('>' * ($NestedPromptLevel + 1)) "

            # Finally, show the output about path, debug, git etc. and then on a
            # new line the command count and the prompt level indicator
            if ([System.String]::IsNullOrEmpty($output.ToString()))
            {
                return $input
            }
            else
            {
                Write-Host $output -NoNewline
                return "`n$input"
            }
        }
    }
}
