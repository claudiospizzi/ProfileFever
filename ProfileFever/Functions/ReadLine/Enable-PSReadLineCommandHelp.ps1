<#
    .SYNOPSIS
        Enable command help.

    .DESCRIPTION
        Type F1 for help off the current command line.

    .LINK
        https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1
#>
function Enable-PSReadLineCommandHelp
{
    # Show a grid view output
    if ($PSVersionTable.PSEdition -ne 'Core')
    {
        $commandHelpSplat = @{
            Key              = 'F1'
            BriefDescription = 'CommandHelp'
            LongDescription  = 'Open the help window for the current command'
            ScriptBlock      = {

                param($key, $arg)

                $ast = $null
                $tokens = $null
                $errors = $null
                $cursor = $null
                [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

                $commandAst = $ast.FindAll( {
                    $node = $args[0]
                    $node -is [CommandAst] -and
                        $node.Extent.StartOffset -le $cursor -and
                        $node.Extent.EndOffset -ge $cursor
                    }, $true) | Select-Object -Last 1

                if ($null -ne $commandAst)
                {
                    $commandName = $commandAst.GetCommandName()
                    if ($null -ne $commandName)
                    {
                        $command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
                        if ($command -is [AliasInfo])
                        {
                            $commandName = $command.ResolvedCommandName
                        }

                        if ($null -ne $commandName)
                        {
                            Get-Help $commandName -ShowWindow
                        }
                    }
                }
            }
        }
        Set-PSReadLineKeyHandler @commandHelpSplat
    }
}
