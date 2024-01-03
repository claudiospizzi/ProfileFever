<#
    .SYNOPSIS
        Show the object as an interactive tree in a separate window.

    .DESCRIPTION
        The command will show the specified object in a separate window. The
        object will be shown as an interactive tree, which allows to expand and
        collapse the properties and inspect the object.

    .EXAMPLE
        PS C:\> Show-Object -InputObject $object
        Show the object in a separate window.

    .EXAMPLE
        PS C:\> Get-Service | Show-Object
        Show the output of the Get-Service command in a separate window.

    .NOTES
        Pending features:
        - Enable the window to be resized
        - Allow pass through of the selected object
        - Add checkboxes for dynamically update the view

    .LINK
        https://github.com/claudiospizzi/ProfileFever
#>
function Show-Object
{
    [CmdletBinding()]
    param
    (
        # The object to show.
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowNull()]
        [System.Object[]]
        $InputObject,

        # The title of the window.
        [Parameter(Mandatory = $false)]
        [System.String]
        $Title
    )

    begin
    {
        $objects = @()
    }

    process
    {
        $objects += $InputObject
    }

    end
    {
        try
        {
            ##
            ## Prerequisites & Prepare
            ##

            # Load the required assemblies
            Add-Type -AssemblyName 'System.Windows.Forms'

            # Update the title if not specified
            if (-not $PSBoundParameters.ContainsKey('Title'))
            {
                $Title = $MyInvocation.Line
            }

            # Cache variables for performance
            $cacheTypeTreeNodes = @{}

            # Main form specifications
            $mainFormIcon    = [System.Drawing.Icon]::ExtractAssociatedIcon([System.Diagnostics.Process]::GetCurrentProcess().Path)
            $mainFormWidth   = 1200
            $mainFormHeight  = 700
            $mainFormPadding = 10

            # Tree view specifications
            $treeViewIcons = [Ordered] @{
                'Blank'      = @{ Id = 0 }
                'Object'     = @{ Id = 1 }
                'ObjectNull' = @{ Id = 2 }
                'Class'      = @{ Id = 3 }
                'Interface'  = @{ Id = 4 }
                'String'     = @{ Id = 5 }
                'Number'     = @{ Id = 6 }
                'Enum'       = @{ Id = 7 }
                'Boolean'    = @{ Id = 8 }
                'Event'      = @{ Id = 9 }
                'Method'     = @{ Id = 10 }
                'Property'   = @{ Id = 11 }
            }


            ##
            ## Helper Functions
            ##

            <#
                .SYNOPSIS
                    Convert an object to a tree node and add it to the parent.
            #>
            function Add-TreeNodeObject
            {
                [CmdletBinding()]
                param
                (
                    # The parent tree node.
                    [Parameter(Mandatory = $false)]
                    # [System.Windows.Forms.TreeNode]
                    $Parent,

                    # The object to add as tree node.
                    [Parameter(Mandatory = $true)]
                    [AllowNull()]
                    [System.Object]
                    $Object
                )

                if ($null -eq $Object)
                {
                    $treeNode = [System.Windows.Forms.TreeNode]::new('$null')
                    $treeNode.ImageIndex         = $treeViewIcons.ObjectNull.Id
                    $treeNode.SelectedImageIndex = $treeViewIcons.ObjectNull.Id
                }
                else
                {
                    $treeNode = [System.Windows.Forms.TreeNode]::new($Object.ToString())
                    $treeNode.ImageIndex         = $treeViewIcons.Object.Id
                    $treeNode.SelectedImageIndex = $treeViewIcons.Object.Id

                    Add-TreeNodeType -Parent $treeNode -Type $Object.GetType()

                    # Use the Get-Member to get the methods instead of using the
                    # $object.PSObject.Methods property. The Methods property
                    # will return getter, setter, adder, remover methods for
                    # properties and events. They are displayed separately.
                    foreach ($method in @(Get-Member -InputObject $Object -MemberType 'Methods'))
                    {
                        Add-TreeNodeMethod -Parent $treeNode -Method $Object.PSObject.Methods.Where({ $_.Name -eq $method.Name })[0]
                    }

                    # Get all properties and show them as tree nodes.
                    foreach ($property in $Object.PSObject.Properties)
                    {
                        Add-TreeNodeProperty -Parent $treeNode -Property $property
                    }

                    # Get all events and show them as tree nodes.
                    foreach ($event in @(Get-Member -InputObject $Object -MemberType 'Event'))
                    {
                        Add-TreeNodeEvent -Parent $treeNode -Event $event
                    }
                }

                $treeNode.Tag = $Object

                $Parent.Nodes.Add($treeNode) | Out-Null
            }

            <#
                .SYNOPSIS
                    Convert a type to a tree node and add it to the parent.
            #>
            function Add-TreeNodeType
            {
                [CmdletBinding()]
                param
                (
                    # The parent tree node.
                    [Parameter(Mandatory = $false)]
                    # [System.Windows.Forms.TreeNode]
                    $Parent,

                    # The type definition to show.
                    [Parameter(Mandatory = $true, ParameterSetName = 'Type')]
                    [System.Type]
                    $Type,

                    # The type name definition to show.
                    [Parameter(Mandatory = $true, ParameterSetName = 'Name')]
                    [System.String]
                    $Name
                )

                # If the type was specified by name, try to resolve the name and
                # add it as type and update the type's full name. If the type
                # was specified directly, use it and populate the name.
                if ($PSCmdlet.ParameterSetName -eq 'Name')
                {
                    $Type = Resolve-Type -TypeName $Name
                    if ($null -ne $Type)
                    {
                        $Name = $Type.FullName
                    }
                }
                else
                {
                    $Name = $Type.FullName
                }

                if ($cacheTypeTreeNodes.ContainsKey($Name))
                {
                    $treeNode = $cacheTypeTreeNodes[$Name].Clone()
                }
                else
                {
                    if ($null -ne $Type)
                    {
                        # Create a full type node with base type and interfaces
                        $treeNode = [System.Windows.Forms.TreeNode]::new($Name)

                        # Add the base type as the first child node
                        if ($null -ne $Type.BaseType)
                        {
                            Add-TreeNodeType -Parent $treeNode -Type $Type.BaseType
                        }

                        # Add the implemented interfaces as child nodes
                        foreach ($typeImplementedInterface in $type.ImplementedInterfaces)
                        {
                            $treeNodeInterface = [System.Windows.Forms.TreeNode]::new($typeImplementedInterface.FullName)
                            $treeNodeInterface.ImageIndex         = $treeViewIcons.Interface.Id
                            $treeNodeInterface.SelectedImageIndex = $treeViewIcons.Interface.Id
                            $treeNode.Nodes.Add($treeNodeInterface) | Out-Null
                        }
                    }
                    else
                    {
                        # Create a stub type node with only the type name
                        $treeNode = [System.Windows.Forms.TreeNode]::new($Name)
                    }

                    $treeNode.ImageIndex         = $treeViewIcons.Class.Id
                    $treeNode.SelectedImageIndex = $treeViewIcons.Class.Id

                    $cacheTypeTreeNodes[$Name] = $treeNode
                }

                $Parent.Nodes.Add($treeNode) | Out-Null
            }

            <#
                .SYNOPSIS
                    Convert a method to a tree node and add it to the parent.
            #>
            function Add-TreeNodeMethod
            {
                [CmdletBinding()]
                param
                (
                    # The parent tree node.
                    [Parameter(Mandatory = $false)]
                    $Parent,

                    # The method to add as tree node.
                    [Parameter(Mandatory = $true)]
                    [System.Management.Automation.PSMethodInfo]
                    $Method
                )

                foreach ($methodOverloadDefinition in $Method.OverloadDefinitions)
                {
                    # Try to match the method definition to extract the return type and the definition itself.
                    if ($methodOverloadDefinition -match "^(?<ReturnType>.*) ((?<Interface>.*\.))?$($Method.Name)\((?<Parameter>.*)\);?$")
                    {
                        # if ($Matches.ContainsKey('Interface'))
                        # {
                            $treeNode = [System.Windows.Forms.TreeNode]::new(('{0}{1}({2})' -f $Matches['Interface'], $Method.Name, $Matches['Parameter']))
                        # }
                        # else
                        # {
                        #     $treeNode = [System.Windows.Forms.TreeNode]::new(('{0}({1})' -f $Method.Name, $Matches['Parameter']))
                        # }

                        Add-TreeNodeType -Parent $treeNode -Name $Matches['ReturnType']

                        # $methodReturnType = Resolve-Type -TypeName $Matches['ReturnType']
                        # if ($null -ne $methodReturnType)
                        # {
                        #     Add-TreeNodeType -Parent $treeNode -Type $methodReturnType
                        # }
                        # else
                        # {
                        #     $treeNodeType = [System.Windows.Forms.TreeNode]::new($Matches['ReturnType'])
                        #     $treeNodeType.ImageIndex         = $treeViewIcons.Class.Id
                        #     $treeNodeType.SelectedImageIndex = $treeViewIcons.Class.Id
                        #     $treeNode.Nodes.Add($treeNodeType) | Out-Null
                        # }
                    }
                    else
                    {
                        # No match of an method definition
                        Write-Warning "[Show-Object] Method definition '$methodOverloadDefinition' was unexpected. Show the original method definition."

                        $treeNode = [System.Windows.Forms.TreeNode]::new($methodOverloadDefinition)
                    }

                    $treeNode.ImageIndex         = $treeViewIcons.Method.Id
                    $treeNode.SelectedImageIndex = $treeViewIcons.Method.Id

                    $Parent.Nodes.Add($treeNode) | Out-Null
                }
            }

            <#
                .SYNOPSIS
                    Convert a property to a tree node and add it to the parent.
            #>
            function Add-TreeNodeProperty
            {
                [CmdletBinding()]
                param
                (
                    # The parent tree node.
                    [Parameter(Mandatory = $false)]
                    $Parent,

                    # The event to add as tree node.
                    [Parameter(Mandatory = $true)]
                    [System.Management.Automation.PSPropertyInfo]
                    $Property
                )

                $treeNode = [System.Windows.Forms.TreeNode]::new(('{0} = {1}' -f $Property.Name, $Property.Value))

                $treeNodeDummy = [System.Windows.Forms.TreeNode]::new('')
                $treeNodeDummy.Tag = @($Property.Value)
                $treeNode.Nodes.Add($treeNodeDummy) | Out-Null

                $treeNode.ImageIndex         = $treeViewIcons.Property.Id
                $treeNode.SelectedImageIndex = $treeViewIcons.Property.Id

                $Parent.Nodes.Add($treeNode) | Out-Null
            }

            <#
                .SYNOPSIS
                    Convert an event to a tree node and add it to the parent.
            #>
            function Add-TreeNodeEvent
            {
                [CmdletBinding()]
                param
                (
                    # The parent tree node.
                    [Parameter(Mandatory = $false)]
                    $Parent,

                    # The event to add as tree node.
                    [Parameter(Mandatory = $true)]
                    [Microsoft.PowerShell.Commands.MemberDefinition]
                    $Event
                )

                # Try to match the event definition to extract the return type and the definition itself.
                if ($Event.Definition -match "^(?<ReturnType>.*) ((?<Interface>.*\.))?$($Event.Name)\((?<Parameter>.*)\);?$")
                {
                    $treeNode = [System.Windows.Forms.TreeNode]::new(('{0}{1}({2})' -f $Matches['Interface'], $Event.Name, $Matches['Parameter']))

                    Add-TreeNodeType -Parent $treeNode -Name $Matches['ReturnType']
                }
                else
                {
                    # No match of an event definition
                    Write-Warning "[Show-Object] Event definition '$($Event.Definition)' was unexpected. Show the original event definition."

                    $treeNode = [System.Windows.Forms.TreeNode]::new($Event.Definition)
                }

                $treeNode.ImageIndex         = $treeViewIcons.Event.Id
                $treeNode.SelectedImageIndex = $treeViewIcons.Event.Id

                $Parent.Nodes.Add($treeNode) | Out-Null



                # if ($MemberDefinition.Definition -like "* $($MemberDefinition.Name)(*)")
                # {
                #     # Extract the return type and the definition from the event
                #     # without the type name.
                #     $eventReturnTypeName, $eventDefinition = $MemberDefinition.Definition.Split(' ', 2)

                #     $node = [System.Windows.Forms.TreeNode]::new($eventDefinition)

                #     $eventReturnType = [System.Type]::GetType($eventReturnTypeName)
                #     if ($null -ne $eventReturnType)
                #     {
                #         # Add the full node type, as the runtime type was found
                #         # in the current runtime
                #         $nodeType = Convert-TypeToTreeNode -Type $eventReturnType
                #         $node.Nodes.Add($nodeType) | Out-Null
                #     }
                #     else
                #     {
                #         # Only add a stub information about the node type, as
                #         # the runtime type was not found in the current runtime
                #         $nodeType = [System.Windows.Forms.TreeNode]::new($eventReturnTypeName)
                #         $nodeType.ImageIndex         = $treeViewIcons.Class.Id
                #         $nodeType.SelectedImageIndex = $treeViewIcons.Class.Id
                #         $node.Nodes.Add($nodeType) | Out-Null
                #     }
                # }
                # else
                # {
                #     $node = [System.Windows.Forms.TreeNode]::new($node)
                # }

                # $node.ImageIndex         = $treeViewIcons.Event.Id
                # $node.SelectedImageIndex = $treeViewIcons.Event.Id

                # Write-Output $node
            }

            <#
                .SYNOPSIS
                    Resolve a type name to a runtime type object.
            #>
            function Resolve-Type
            {
                [CmdletBinding()]
                param
                (
                    # The type name to resolve.
                    [Parameter(Mandatory = $true)]
                    [System.String]
                    $TypeName
                )

                # Try to find a valid type directly by the full name.
                $type = [System.Type]::GetType($TypeName)

                # Fall back to the type accelerators if the type was not found.
                if ($null -eq $type)
                {
                    $typeAccelerators = [System.Management.Automation.PSObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')::Get
                    if ($typeAccelerators.ContainsKey($TypeName))
                    {
                        $type = $typeAccelerators[$TypeName]
                    }
                }

                # Return the resolved type or show a warning, if the type was
                # not found.
                if ($null -ne $type)
                {
                    Write-Output $type
                }
                else
                {
                    Write-Verbose "[Show-Object] The assembly type '$TypeName' was not found."
                }
            }


            ##
            ## Render Main Form
            ##

            $treeViewIconList = [System.Windows.Forms.ImageList]::new()
            foreach ($treeViewIconName in $treeViewIcons.Keys)
            {
                $treeViewIconList.Images.Add([System.Drawing.Image]::FromFile("$Script:PSModulePath\Images\$treeViewIconName.png"))
            }

            $treeView = [System.Windows.Forms.TreeView]::new()
            $treeView.Size = [System.Drawing.Size]::new($mainFormWidth - 16 - (2 * $mainFormPadding), $mainFormHeight - 39 - (2 * $mainFormPadding))
            $treeView.Location = [System.Drawing.Point]::new($mainFormPadding, $mainFormPadding)
            $treeView.ImageList = $treeViewIconList
            $treeView.add_BeforeExpand({
                param ($Sender, $TreeViewCancelEventArgs)
                # Check if we have a single dummy child node, which needs to be
                # replaced with the real children on demand.
                $treeNode = $TreeViewCancelEventArgs.Node
                if ($null -ne $treeNode -and $treeNode.Nodes.Count -eq 1 -and $treeNode.Nodes[0].Text -eq '' -and $null -ne $treeNode.Nodes[0].Tag)
                {
                    $objects = @($treeNode.Nodes[0].Tag)
                    $treeNode.Nodes.Clear()
                    foreach ($object in $objects)
                    {
                        Add-TreeNodeObject -Parent $treeNode -Object $object
                    }
                }
            })

            foreach ($object in $objects)
            {
                Add-TreeNodeObject -Parent $treeView -Object $object
            }

            $mainForm = [System.Windows.Forms.Form]::new()
            $mainForm.Text = $Title
            $mainForm.Icon = $mainFormIcon
            $mainForm.Size = [System.Drawing.Size]::new($mainFormWidth, $mainFormHeight)
            $mainForm.MaximizeBox = $false
            $mainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
            $mainForm.Controls.Add($treeView)
            $mainForm.ShowDialog() | Out-Null
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
