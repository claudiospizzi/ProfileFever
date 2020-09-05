<#
    .SYNOPSIS
        Show the object or array in UI with all details.

    .DESCRIPTION
        .

    .INPUTS
        .

    .OUTPUTS
        .

    .EXAMPLE
        PS C:\> Out-ObjectView
        .

    .LINK
        https://github.com/claudiospizzi/ProfileFever
#>
function Out-ObjectView
{
    [CmdletBinding()]
    param
    (
        # The object to show.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object[]]
        $InputObject
    )

    begin
    {
        $objectList = [System.Collections.ArrayList]::new()
    }

    process
    {
        foreach ($object in $InputObject)
        {
            if ($null -ne $object)
            {
                $objectList.Add($object) | Out-Null
            }
        }
    }

    end
    {
        # Quit if we have no objects.
        if ($objectList.Count -eq 0)
        {
            throw 'No objects provided.'
        }

        try
        {
            $wpfTreeViewItems = @()

            # Generate the tree view, combine all items.
            $wpfTreeView = [System.Windows.Controls.TreeView]::new()
            $wpfTreeViewItems | ForEach-Object { $wpfTreeView.Items.Add($_) | Out-Null }

            # Generate the window, use the tree view as conent.
            $wpfWindow = [System.Windows.Window]::new()
            $wpfWindow.Content = $wpfTreeView
            $wpfWindow.Title = 'Object View'
            $wpfWindow.WindowStartupLocation = 'CenterScreen'
            $wpfWindow.Width = 800
            $wpfWindow.Height = 600
            $wpfWindow.MinWidth = 400
            $wpfWindow.MinHeight = 300
            $wpfWindow.TopMost = $true

            # Show to the caller.
            $wpfWindow.ShowDialog() | Out-Null
        }
        catch
        {
            throw "Failed to show the object view: $_"
        }
    }
}
