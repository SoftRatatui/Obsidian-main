local Onboarding = {
    ReleaseVersion = "0.0.1-release-3",
}

local function NormalizeText(Value, Fallback)
    if Value == nil then
        return Fallback or ""
    end
    return tostring(Value)
end

function Onboarding.Create(Library, Info)
    assert(Library and Library.ScreenGui, "Onboarding requires an active MonHub window")
    Info = Info or {}

    local Style = type(Library.GetAddonStyle) == "function" and Library:GetAddonStyle(Info.Style)
        or {
            StrokeThickness = 1,
            OutlineTransparency = 0.5,
            SelectionThickness = 1,
            TextSize = 14,
            CaptionSize = 12,
        }
    local IsMobile = Library.IsMobile == true
    local Embedded = typeof(Info.Parent) == "Instance" and Info.Parent:IsA("GuiObject") or Info.Embedded == true

    local CardRadius = type(Library.GetDesignToken) == "function" and Library:GetDesignToken("Radius.Card", 6) or 6
    local PopupRadius = type(Library.GetDesignToken) == "function" and Library:GetDesignToken("Radius.Popup", 6) or 6
    local ControlRadius = type(Library.GetDesignToken) == "function" and Library:GetDesignToken("Radius.Control", 5)
        or 5

    local Tour = {
        Destroyed = false,
        Running = false,
        Index = 0,
        Steps = {},
        Connections = {},
        Subscriptions = {},
        Style = Style,
        IsMobile = IsMobile,
        Embedded = Embedded,
        Visible = Info.Visible ~= false,
        Height = math.clamp(math.floor(tonumber(Info.Height) or 96), 64, 400),
        Folder = NormalizeText(Info.Folder, "ObsidianLibSettings"),
        FlagName = NormalizeText(Info.FlagName, "onboarding"),
        Seen = nil,
    }

    local function Motion(Name)
        if type(Library.GetMotion) == "function" then
            return Library:GetMotion(Name)
        end
        return TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    end

    local function Snap(Value)
        if type(Library.Snap) == "function" then
            return Library:Snap(Value)
        end
        return math.round(tonumber(Value) or 0)
    end

    local function Make(ClassName, Properties, Registry)
        local Object = Instance.new(ClassName)
        if Object:IsA("GuiObject") then
            Object.BorderSizePixel = 0
        end
        local Parent = Properties.Parent
        Properties.Parent = nil
        for Key, Value in Properties do
            Object[Key] = Value
        end
        if Registry and type(Library.AddToRegistry) == "function" then
            Library:AddToRegistry(Object, Registry)
        end
        if Parent then
            Object.Parent = Parent
        end
        return Object
    end

    local function RemoveRegistryTree(Root)
        if type(Library.RemoveFromRegistry) ~= "function" or typeof(Root) ~= "Instance" then
            return
        end
        for _, Object in Root:GetDescendants() do
            Library:RemoveFromRegistry(Object)
        end
        Library:RemoveFromRegistry(Root)
    end

    local function AddConnection(Connection)
        table.insert(Tour.Connections, Connection)
        return Connection
    end

    local NativeIsFolder, NativeIsFile = isfolder, isfile
    local NativeMakeFolder, NativeReadFile, NativeWriteFile = makefolder, readfile, writefile
    local FileSystemAvailable = type(NativeIsFolder) == "function"
        and type(NativeIsFile) == "function"
        and type(NativeMakeFolder) == "function"
        and type(NativeReadFile) == "function"
        and type(NativeWriteFile) == "function"

    local function FlagPath()
        return string.format("%s/%s.flag", Tour.Folder, Tour.FlagName)
    end

    function Tour:HasSeen()
        if Tour.Seen ~= nil then
            return Tour.Seen
        end
        if not FileSystemAvailable then
            return false
        end
        local Path = FlagPath()
        local ExistsOk, Exists = pcall(NativeIsFile, Path)
        if not ExistsOk or not Exists then
            Tour.Seen = false
            return false
        end
        local ReadOk, Content = pcall(NativeReadFile, Path)
        Tour.Seen = ReadOk and Content == "1"
        return Tour.Seen
    end

    local function MarkSeen()
        Tour.Seen = true
        if not FileSystemAvailable then
            return
        end
        pcall(function()
            local FolderOk = NativeIsFolder(Tour.Folder)
            if not FolderOk then
                NativeMakeFolder(Tour.Folder)
            end
            NativeWriteFile(FlagPath(), "1")
        end)
    end

    function Tour:Reset()
        Tour.Seen = false
        if not FileSystemAvailable then
            return Tour
        end
        pcall(function()
            if NativeIsFile(FlagPath()) then
                NativeWriteFile(FlagPath(), "0")
            end
        end)
        return Tour
    end

    local function FindGroup(GroupName, TabName)
        for Name, Tab in Library.Tabs or {} do
            if TabName == nil or Name == TabName then
                local Group = (Tab.Groupboxes or {})[GroupName]
                if Group then
                    return Tab, Group
                end
            end
        end
        return nil
    end

    local function ResolveStep(Step)
        if Step.Control ~= nil and type(Library.GetControl) == "function" then
            local Control = Library:GetControl(Step.Control)
            if Control and not Control.Destroyed and typeof(Control.Holder) == "Instance" then
                return {
                    Instance = Control.Holder,
                    Prepare = function()
                        if type(Library.RevealControl) == "function" then
                            Library:RevealControl(Step.Control)
                        end
                    end,
                }
            end
        end
        if Step.Group ~= nil then
            local Tab, Group = FindGroup(Step.Group, Step.Tab)
            if Group then
                local Anchor = Group.BoxHolder or Group.Holder
                if typeof(Anchor) == "Instance" then
                    return {
                        Instance = Anchor,
                        Prepare = function()
                            if Tab and Tab.SetVisible then
                                Tab:SetVisible(true)
                            end
                            if Tab and Tab.Show then
                                Tab:Show()
                            end
                            if Group.SetCollapsed then
                                Group:SetCollapsed(false)
                            end
                            if type(Library.RequestLayout) == "function" then
                                Library:RequestLayout(Group)
                            end
                        end,
                    }
                end
            end
        end
        if Step.Tab ~= nil then
            local Tab = (Library.Tabs or {})[Step.Tab]
            if Tab and not Tab.Destroyed and typeof(Tab.Button) == "Instance" then
                return {
                    Instance = Tab.Button,
                    Prepare = function()
                        if Tab.SetVisible then
                            Tab:SetVisible(true)
                        end
                        if Tab.Show then
                            Tab:Show()
                        end
                    end,
                }
            end
        end
        return nil
    end

    local function ResolveFrom(Index, Direction)
        local Count = #Tour.Steps
        local Current = math.clamp(math.floor(Index), 1, math.max(1, Count))
        while Current >= 1 and Current <= Count do
            local Resolved = ResolveStep(Tour.Steps[Current])
            if Resolved then
                return Current, Resolved
            end
            Current += Direction
        end
        return nil
    end

    local Highlight, HighlightStroke
    local Callout, ButtonRow
    local StepLabel, TitleLabel, BodyLabel
    local BackButton, NextButton, SkipButton
    local TargetInstance
    local OverlayConnections = {}
    local TrackConnections = {}
    local UpdateKey = {}
    local StartKey = {}

    local ButtonHeight = IsMobile and 44 or 28
    local NextWidth = IsMobile and 100 or 84
    local BackWidth = IsMobile and 84 or 72
    local SkipWidth = IsMobile and 72 or 56
    local ButtonGap = 8

    local function Reflow()
        if not ButtonRow then
            return
        end
        local Width = Snap(ButtonRow.AbsoluteSize.X)
        if Width <= 0 then
            return
        end
        SkipButton.Position = UDim2.fromOffset(0, 0)
        SkipButton.Size = UDim2.fromOffset(SkipWidth, ButtonHeight)
        local NextX = Width - NextWidth
        NextButton.Position = UDim2.fromOffset(Snap(NextX), 0)
        NextButton.Size = UDim2.fromOffset(NextWidth, ButtonHeight)
        if BackButton.Visible then
            BackButton.Position = UDim2.fromOffset(Snap(NextX - ButtonGap - BackWidth), 0)
            BackButton.Size = UDim2.fromOffset(BackWidth, ButtonHeight)
        end
    end

    local function PositionCallout(TargetX, TargetY, TargetW, TargetH)
        if not Callout then
            return
        end
        local Bounds = Library.ScreenGui.AbsoluteSize
        if IsMobile then
            local Margin = 12
            local Width = Snap(math.clamp(Bounds.X - Margin * 2, 200, 460))
            if Callout.Size.X.Offset ~= Width then
                Callout.Size = UDim2.fromOffset(Width, 0)
            end
            local PosX = Snap((Bounds.X - Width) * 0.5)
            local PosY = Snap(Bounds.Y - Callout.AbsoluteSize.Y - Margin)
            Library:PlayTween(Callout, "OnboardingMove", Motion("Popup"), {
                Position = UDim2.fromOffset(PosX, math.max(Margin, PosY)),
            })
            return
        end
        local CalloutW = Snap(Callout.AbsoluteSize.X)
        local CalloutH = Snap(Callout.AbsoluteSize.Y)
        local Gap = 12
        local Margin = 10
        local PosX = TargetX + TargetW + Gap
        local PosY = TargetY
        if PosX + CalloutW > Bounds.X - Margin then
            PosX = TargetX - CalloutW - Gap
        end
        if PosX < Margin then
            PosX = TargetX
            PosY = TargetY + TargetH + Gap
            if PosY + CalloutH > Bounds.Y - Margin then
                PosY = TargetY - CalloutH - Gap
            end
        end
        PosX = math.clamp(PosX, Margin, math.max(Margin, Bounds.X - CalloutW - Margin))
        PosY = math.clamp(PosY, Margin, math.max(Margin, Bounds.Y - CalloutH - Margin))
        Library:PlayTween(Callout, "OnboardingMove", Motion("Popup"), {
            Position = UDim2.fromOffset(Snap(PosX), Snap(PosY)),
        })
    end

    local function UpdateHighlight()
        if Tour.Destroyed or not Highlight or not TargetInstance or not TargetInstance.Parent then
            return
        end
        local Origin = Library.ScreenGui.AbsolutePosition
        local Position = TargetInstance.AbsolutePosition
        local Size = TargetInstance.AbsoluteSize
        local Pad = 4
        local X = Snap(Position.X - Origin.X - Pad)
        local Y = Snap(Position.Y - Origin.Y - Pad)
        local W = Snap(Size.X + Pad * 2)
        local H = Snap(Size.Y + Pad * 2)
        Highlight.Position = UDim2.fromOffset(X, Y)
        Highlight.Size = UDim2.fromOffset(W, H)
        PositionCallout(X, Y, W, H)
    end

    local function DeferUpdate()
        if type(Library.QueueFrame) == "function" then
            Library:QueueFrame(UpdateKey, UpdateHighlight)
        else
            task.defer(UpdateHighlight)
        end
    end

    local function ClearTargetTracking()
        for _, Connection in TrackConnections do
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end
        table.clear(TrackConnections)
    end

    local function BindTargetTracking()
        ClearTargetTracking()
        if not TargetInstance then
            return
        end
        table.insert(
            TrackConnections,
            TargetInstance:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdateHighlight)
        )
        table.insert(TrackConnections, TargetInstance:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateHighlight))
        if Callout then
            table.insert(TrackConnections, Callout:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateHighlight))
        end
    end

    local function BuildOverlay()
        if Callout then
            return
        end
        local Gui = Library.ScreenGui
        local Font = Library.Scheme.Font
        local White = Library.Scheme.WhiteColor or Color3.new(1, 1, 1)

        Highlight = Make("Frame", {
            Name = "MonHubOnboardingHighlight",
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 0),
            Visible = false,
            ZIndex = 500,
            Parent = Gui,
        })
        Make("UICorner", { CornerRadius = UDim.new(0, ControlRadius), Parent = Highlight })
        HighlightStroke = Make("UIStroke", {
            Color = Library.Scheme.AccentColor,
            Thickness = math.max(1, tonumber(Style.SelectionThickness) or 1) + 1,
            Transparency = 0.1,
            Parent = Highlight,
        }, { Color = "AccentColor" })

        local Width = IsMobile and 320 or 264
        Callout = Make("Frame", {
            Name = "MonHubOnboardingCallout",
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Library.Scheme.SurfaceColor,
            Position = UDim2.fromOffset(-9999, -9999),
            Size = UDim2.fromOffset(Width, 0),
            Visible = false,
            ZIndex = 502,
            Parent = Gui,
        }, { BackgroundColor3 = "SurfaceColor" })
        Make("UICorner", { CornerRadius = UDim.new(0, PopupRadius), Parent = Callout })
        Make("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = Library.Scheme.OutlineColor,
            Thickness = tonumber(Style.StrokeThickness) or 1,
            Transparency = tonumber(Style.OutlineTransparency) or 0.5,
            Parent = Callout,
        }, { Color = "OutlineColor" })
        if type(Library.AddSoftShadow) == "function" then
            local ShadowTransparency = type(Library.GetDesignToken) == "function"
                    and Library:GetDesignToken("Opacity.Shadow", 0.44)
                or 0.44
            Library:AddSoftShadow(Callout, 20, ShadowTransparency, UDim2.fromOffset(0, 4))
        end
        Make("UIPadding", {
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 12),
            Parent = Callout,
        })
        Make("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Callout,
        })

        StepLabel = Make("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = Font,
            LayoutOrder = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Text = "",
            TextColor3 = Library.Scheme.MutedFontColor,
            TextSize = math.max(10, (tonumber(Style.CaptionSize) or 12) - 1),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 503,
        }, { FontFace = "Font", TextColor3 = "MutedFontColor" })

        TitleLabel = Make("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = Font,
            LayoutOrder = 2,
            Size = UDim2.new(1, 0, 0, 20),
            Text = "",
            TextColor3 = Library.Scheme.FontColor,
            TextSize = tonumber(Style.TextSize) or 14,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 503,
        }, { FontFace = "Font", TextColor3 = "FontColor" })

        BodyLabel = Make("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            FontFace = Font,
            LayoutOrder = 3,
            Size = UDim2.new(1, 0, 0, 0),
            Text = "",
            TextColor3 = Library.Scheme.MutedFontColor,
            TextSize = tonumber(Style.CaptionSize) or 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 503,
        }, { FontFace = "Font", TextColor3 = "MutedFontColor" })

        ButtonRow = Make("Frame", {
            BackgroundTransparency = 1,
            LayoutOrder = 4,
            Size = UDim2.new(1, 0, 0, ButtonHeight),
            ZIndex = 503,
            Parent = Callout,
        })

        local function StyleButton(Button, AccentFill)
            Make("UICorner", { CornerRadius = UDim.new(0, ControlRadius), Parent = Button })
            if AccentFill then
                return
            end
            Make("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Color = Library.Scheme.OutlineColor,
                Thickness = tonumber(Style.StrokeThickness) or 1,
                Transparency = tonumber(Style.OutlineTransparency) or 0.5,
                Parent = Button,
            }, { Color = "OutlineColor" })
        end

        SkipButton = Make("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Library.Scheme.ElementColor,
            BackgroundTransparency = 1,
            FontFace = Font,
            Size = UDim2.fromOffset(SkipWidth, ButtonHeight),
            Text = NormalizeText(Info.SkipText, "Skip"),
            TextColor3 = Library.Scheme.MutedFontColor,
            TextSize = tonumber(Style.CaptionSize) or 12,
            ZIndex = 504,
            Parent = ButtonRow,
        }, { FontFace = "Font", TextColor3 = "MutedFontColor" })

        BackButton = Make("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Library.Scheme.ElementColor,
            FontFace = Font,
            Size = UDim2.fromOffset(BackWidth, ButtonHeight),
            Text = NormalizeText(Info.BackText, "Back"),
            TextColor3 = Library.Scheme.FontColor,
            TextSize = tonumber(Style.CaptionSize) or 12,
            Visible = false,
            ZIndex = 504,
            Parent = ButtonRow,
        }, { BackgroundColor3 = "ElementColor", FontFace = "Font", TextColor3 = "FontColor" })
        StyleButton(BackButton, false)

        NextButton = Make("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Library.Scheme.AccentColor,
            FontFace = Font,
            Size = UDim2.fromOffset(NextWidth, ButtonHeight),
            Text = NormalizeText(Info.NextText, "Next"),
            TextColor3 = Library:GetContrastColor(Library.Scheme.AccentColor),
            TextSize = tonumber(Style.CaptionSize) or 12,
            ZIndex = 504,
            Parent = ButtonRow,
        }, {
            BackgroundColor3 = "AccentColor",
            FontFace = "Font",
            TextColor3 = function()
                return Library:GetContrastColor(Library.Scheme.AccentColor)
            end,
        })
        StyleButton(NextButton, true)

        table.insert(
            OverlayConnections,
            NextButton.Activated:Connect(function()
                Tour:Next()
            end)
        )
        table.insert(
            OverlayConnections,
            BackButton.Activated:Connect(function()
                Tour:Back()
            end)
        )
        table.insert(
            OverlayConnections,
            SkipButton.Activated:Connect(function()
                Tour:Skip()
            end)
        )
        table.insert(OverlayConnections, ButtonRow:GetPropertyChangedSignal("AbsoluteSize"):Connect(Reflow))

        if not IsMobile then
            table.insert(
                OverlayConnections,
                NextButton.MouseEnter:Connect(function()
                    if not Tour.Destroyed then
                        Library:PlayTween(NextButton, "OnboardingNextHover", Motion("Hover"), {
                            BackgroundColor3 = Library.Scheme.AccentColor:Lerp(White, 0.08),
                        })
                    end
                end)
            )
            table.insert(
                OverlayConnections,
                NextButton.MouseLeave:Connect(function()
                    if not Tour.Destroyed then
                        Library:PlayTween(NextButton, "OnboardingNextHover", Motion("Hover"), {
                            BackgroundColor3 = Library.Scheme.AccentColor,
                        })
                    end
                end)
            )
            table.insert(
                OverlayConnections,
                BackButton.MouseEnter:Connect(function()
                    if not Tour.Destroyed then
                        Library:PlayTween(BackButton, "OnboardingBackHover", Motion("Hover"), {
                            BackgroundColor3 = Library.Scheme.HoverColor,
                        })
                    end
                end)
            )
            table.insert(
                OverlayConnections,
                BackButton.MouseLeave:Connect(function()
                    if not Tour.Destroyed then
                        Library:PlayTween(BackButton, "OnboardingBackHover", Motion("Hover"), {
                            BackgroundColor3 = Library.Scheme.ElementColor,
                        })
                    end
                end)
            )
        end
    end

    local function DestroyOverlay()
        if type(Library.CancelTween) == "function" then
            Library:CancelTween(Callout, "OnboardingMove")
        end
        for _, Connection in OverlayConnections do
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end
        table.clear(OverlayConnections)
        ClearTargetTracking()
        for _, Object in { Highlight, Callout } do
            if Object then
                RemoveRegistryTree(Object)
                Object:Destroy()
            end
        end
        Highlight, HighlightStroke = nil, nil
        Callout, ButtonRow = nil, nil
        StepLabel, TitleLabel, BodyLabel = nil, nil, nil
        BackButton, NextButton, SkipButton = nil, nil, nil
        TargetInstance = nil
    end

    local function ShowOverlay()
        if Highlight then
            Highlight.Visible = true
        end
        if Callout then
            Callout.Visible = true
        end
    end

    local function HideOverlay()
        if Highlight then
            Highlight.Visible = false
        end
        if Callout then
            Callout.Visible = false
        end
    end

    local function ApplyStepText(Step, Index)
        local Total = #Tour.Steps
        if StepLabel then
            StepLabel.Text = string.format("Step %d of %d", Index, Total)
        end
        if TitleLabel then
            TitleLabel.Text = NormalizeText(Step.Title or Step.Name, "Step")
        end
        if BodyLabel then
            BodyLabel.Text = NormalizeText(Step.Body or Step.Description, "")
        end
        if NextButton then
            NextButton.Text = Index >= Total and NormalizeText(Info.FinishText, "Done")
                or NormalizeText(Info.NextText, "Next")
        end
        if BackButton then
            BackButton.Visible = Index > 1
        end
        Reflow()
    end

    local function BindMenuEvents()
        if type(Library.On) ~= "function" then
            return
        end
        table.insert(
            Tour.Subscriptions,
            Library:On("Hidden", function()
                if Tour.Running then
                    HideOverlay()
                end
            end)
        )
        table.insert(
            Tour.Subscriptions,
            Library:On("Shown", function()
                if Tour.Running then
                    ShowOverlay()
                    DeferUpdate()
                end
            end)
        )
    end

    local function UnbindMenuEvents()
        for _, Unsubscribe in Tour.Subscriptions do
            pcall(Unsubscribe)
        end
        table.clear(Tour.Subscriptions)
    end

    function Tour:Goto(Index, Direction)
        if not Tour.Running or Tour.Destroyed then
            return Tour
        end
        Direction = Direction or 1
        local ResolvedIndex, Resolved = ResolveFrom(Index, Direction)
        if not Resolved then
            if Direction > 0 then
                return Tour:Finish()
            end
            return Tour
        end
        Tour.Index = ResolvedIndex
        ClearTargetTracking()
        if Resolved.Prepare and type(Library.SafeCallback) == "function" then
            Library:SafeCallback(Resolved.Prepare)
        elseif Resolved.Prepare then
            pcall(Resolved.Prepare)
        end
        TargetInstance = Resolved.Instance
        ApplyStepText(Tour.Steps[ResolvedIndex], ResolvedIndex)
        BindTargetTracking()
        ShowOverlay()
        DeferUpdate()
        return Tour
    end

    function Tour:Start(FromIndex)
        if Tour.Destroyed or Tour.Running or #Tour.Steps == 0 then
            return Tour
        end
        Tour.Running = true
        BuildOverlay()
        BindMenuEvents()
        Tour:Goto(math.floor(tonumber(FromIndex) or 1), 1)
        return Tour
    end

    function Tour:Next()
        if not Tour.Running then
            return Tour
        end
        return Tour:Goto(Tour.Index + 1, 1)
    end

    function Tour:Back()
        if not Tour.Running then
            return Tour
        end
        if Tour.Index <= 1 then
            return Tour
        end
        return Tour:Goto(Tour.Index - 1, -1)
    end

    local function Stop(MarkComplete)
        if not Tour.Running then
            return Tour
        end
        Tour.Running = false
        UnbindMenuEvents()
        DestroyOverlay()
        if MarkComplete then
            MarkSeen()
        end
        if type(Info.OnFinish) == "function" and type(Library.SafeCallback) == "function" then
            Library:SafeCallback(Info.OnFinish, Tour, MarkComplete == true)
        end
        return Tour
    end

    function Tour:Skip()
        return Stop(true)
    end

    function Tour:Finish()
        return Stop(true)
    end

    function Tour:SetSteps(Steps)
        if type(Steps) == "table" then
            local List = {}
            for _, Raw in Steps do
                if type(Raw) == "table" then
                    table.insert(List, Raw)
                end
            end
            Tour.Steps = List
        end
        return Tour
    end

    local function NormalizeSteps()
        local Steps = {}
        if type(Info.Steps) == "table" then
            for _, Raw in Info.Steps do
                if type(Raw) == "table" then
                    table.insert(Steps, Raw)
                end
            end
        end
        if #Steps == 0 then
            local Ordered = {}
            for Name, Tab in Library.Tabs or {} do
                if not Tab.Destroyed and Tab.Visible ~= false and not Tab.IsKeyTab then
                    table.insert(Ordered, { Name = Name, Tab = Tab })
                end
            end
            table.sort(Ordered, function(A, B)
                return (tonumber(A.Tab.Order) or 0) < (tonumber(B.Tab.Order) or 0)
            end)
            for _, Entry in Ordered do
                table.insert(Steps, {
                    Tab = Entry.Name,
                    Title = Entry.Name,
                    Body = NormalizeText(Entry.Tab.Description, string.format("Open the %s tab.", Entry.Name)),
                })
            end
        end
        Tour.Steps = Steps
    end

    local function BuildLauncher()
        local Font = Library.Scheme.Font
        local White = Library.Scheme.WhiteColor or Color3.new(1, 1, 1)

        local Root = Make("Frame", {
            Name = "MonHubOnboarding",
            BackgroundColor3 = Library.Scheme.SurfaceColor,
            Size = UDim2.new(1, 0, 0, Tour.Height),
            Visible = Tour.Visible,
        }, { BackgroundColor3 = "SurfaceColor" })
        Tour.Root = Root
        Make("UICorner", { CornerRadius = UDim.new(0, CardRadius), Parent = Root })
        Make("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = Library.Scheme.OutlineColor,
            Thickness = tonumber(Style.StrokeThickness) or 1,
            Transparency = tonumber(Style.OutlineTransparency) or 0.5,
            Parent = Root,
        }, { Color = "OutlineColor" })
        Make("UIPadding", {
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 12),
            Parent = Root,
        })
        Make("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Root,
        })

        Make("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = Font,
            LayoutOrder = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = NormalizeText(Info.LauncherTitle or Info.Title, "Guided tour"),
            TextColor3 = Library.Scheme.FontColor,
            TextSize = tonumber(Style.TextSize) or 14,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Root,
        }, { FontFace = "Font", TextColor3 = "FontColor" })

        Make("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            FontFace = Font,
            LayoutOrder = 2,
            Size = UDim2.new(1, 0, 0, 0),
            Text = NormalizeText(Info.LauncherBody, "Take a quick tour of the tabs."),
            TextColor3 = Library.Scheme.MutedFontColor,
            TextSize = tonumber(Style.CaptionSize) or 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = Root,
        }, { FontFace = "Font", TextColor3 = "MutedFontColor" })

        local Start = Make("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Library.Scheme.AccentColor,
            FontFace = Font,
            LayoutOrder = 3,
            Size = UDim2.new(1, 0, 0, IsMobile and 44 or 28),
            Text = NormalizeText(Info.LauncherButton, "Start tour"),
            TextColor3 = Library:GetContrastColor(Library.Scheme.AccentColor),
            TextSize = tonumber(Style.CaptionSize) or 12,
            Parent = Root,
        }, {
            BackgroundColor3 = "AccentColor",
            FontFace = "Font",
            TextColor3 = function()
                return Library:GetContrastColor(Library.Scheme.AccentColor)
            end,
        })
        Make("UICorner", { CornerRadius = UDim.new(0, ControlRadius), Parent = Start })

        AddConnection(Start.Activated:Connect(function()
            if not Tour.Destroyed and not Tour.Running then
                Tour:Start()
            end
        end))
        if not IsMobile then
            AddConnection(Start.MouseEnter:Connect(function()
                if not Tour.Destroyed then
                    Library:PlayTween(Start, "OnboardingLauncherHover", Motion("Hover"), {
                        BackgroundColor3 = Library.Scheme.AccentColor:Lerp(White, 0.08),
                    })
                end
            end))
            AddConnection(Start.MouseLeave:Connect(function()
                if not Tour.Destroyed then
                    Library:PlayTween(Start, "OnboardingLauncherHover", Motion("Hover"), {
                        BackgroundColor3 = Library.Scheme.AccentColor,
                    })
                end
            end))
        end

        if typeof(Info.Parent) == "Instance" and Info.Parent:IsA("GuiObject") then
            Root.Parent = Info.Parent
        end
    end

    function Tour:Destroy()
        if Tour.Destroyed then
            return
        end
        Tour.Destroyed = true
        Tour.Running = false
        UnbindMenuEvents()
        DestroyOverlay()
        for _, Connection in Tour.Connections do
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end
        table.clear(Tour.Connections)
        if Tour.Element and type(Tour.Element.Destroy) == "function" then
            local Element = Tour.Element
            Tour.Element = nil
            pcall(function()
                Element:Destroy()
            end)
        elseif Tour.Root then
            RemoveRegistryTree(Tour.Root)
            Tour.Root:Destroy()
        end
        Tour.Root = nil
    end

    NormalizeSteps()

    if Embedded then
        BuildLauncher()
    end

    if type(Library.OnUnload) == "function" then
        Library:OnUnload(function()
            Tour:Destroy()
        end)
    end

    local ShouldAutoStart = not Embedded and Info.AutoStart ~= false
    if ShouldAutoStart and not Tour:HasSeen() then
        local function Launch()
            if not Tour.Destroyed and not Tour.Running then
                Tour:Start()
            end
        end
        if type(Library.QueueFrame) == "function" then
            Library:QueueFrame(StartKey, Launch)
        else
            task.defer(Launch)
        end
    end

    return Tour
end

function Onboarding.CreateEmbedded(Library, Groupbox, Idx, Info)
    assert(
        type(Groupbox) == "table" and type(Groupbox.AddUIPassthrough) == "function",
        "Onboarding requires a groupbox"
    )
    Info = table.clone(Info or {})
    Info.Embedded = true
    local Tour = Onboarding.Create(Library, Info)
    Tour.Element = Groupbox:AddUIPassthrough(Idx or "Onboarding", {
        Instance = Tour.Root,
        Height = Tour.Height,
        Visible = Tour.Visible ~= false,
    })
    return Tour
end

function Onboarding.CreateStandalone(Library, Info)
    assert(
        Library and type(Library.CreateAddonWindow) == "function",
        "Onboarding standalone mode requires Library:CreateAddonWindow"
    )
    Info = table.clone(Info or {})
    local Host = Library:CreateAddonWindow({
        Title = Info.WindowTitle or Info.Title or "Guided tour",
        Subtitle = Info.WindowSubtitle or Info.Subtitle,
        Icon = Info.WindowIcon or Info.Icon or "compass",
        Width = Info.WindowWidth or 320,
        Height = Info.WindowHeight or 200,
        Position = Info.Position,
        AnchorPoint = Info.AnchorPoint,
        Draggable = Info.Draggable,
        Resizable = Info.Resizable,
        Closable = Info.Closable,
        HideWithMenu = Info.HideWithMenu,
        Visible = Info.Visible,
        Style = Info.Style,
    })

    Info.Embedded = true
    Info.AutoStart = Info.AutoStart == true
    Info.ShowHeader = false
    Info.Height = Info.Height or math.max(96, (Info.WindowHeight or 200) - 74)

    local Tour = Host:AddAddon("Onboarding", Onboarding, Info)
    Tour.Host = Host
    return Tour, Host
end

Onboarding.Mount = Onboarding.CreateEmbedded

return Onboarding
