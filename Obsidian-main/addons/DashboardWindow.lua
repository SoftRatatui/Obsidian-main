local Workspace = game:GetService("Workspace")

local DashboardWindow = {
    ReleaseVersion = "0.0.1-release-7",
}

local function ApplyCorner(Object, Radius)
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, Radius)
    Corner.Parent = Object
    return Corner
end

local function RemoveRegistryTree(Library, Root)
    if type(Library.Registry) ~= "table" or typeof(Root) ~= "Instance" then
        return
    end
    local Owned = {}
    for Object in Library.Registry do
        local Success, Matches = pcall(function()
            return Object == Root or Object:IsDescendantOf(Root)
        end)
        if Success and Matches then
            table.insert(Owned, Object)
        end
    end
    for _, Object in Owned do
        Library:RemoveFromRegistry(Object)
    end
end

local function GetViewportSize()
    local Camera = Workspace.CurrentCamera
    if Camera then
        return Camera.ViewportSize
    end
    return Vector2.new(1280, 720)
end

local function NormalizeText(Value, Fallback)
    if Value == nil then
        return Fallback or ""
    end
    return tostring(Value)
end

function DashboardWindow.Create(Library, Info)
    assert(Library and Library.ScreenGui and Library.AddToRegistry, "DashboardWindow requires an active MonHub window")
    Info = Info or {}
    local Style = type(Library.GetAddonStyle) == "function" and Library:GetAddonStyle(Info.Style) or {
        HeaderHeight = 36,
        Padding = 8,
        Gap = 7,
        Radius = 5,
        ControlRadius = 4,
        ControlHeight = 25,
        OutlineTransparency = 0.46,
        StrokeThickness = 1,
        TextSize = 14,
        CaptionSize = 12,
        Motion = true,
    }

    local Dashboard = {
        Destroyed = false,
        Visible = Info.Visible ~= false,
        Draggable = Info.Draggable ~= false,
        Width = math.clamp(math.floor(tonumber(Info.Width) or 320), 240, 620),
        Height = math.clamp(math.floor(tonumber(Info.Height) or 360), 180, 760),
        Sections = {},
        Dynamic = {},
        Connections = {},
        SchedulerRunning = false,
        SchedulerRevision = 0,
        VisibilityRevision = 0,
        SectionOrder = 0,
        DefaultSection = nil,
        Style = Style,
    }

    local Holder = Instance.new("CanvasGroup")
    Holder.Name = "MonHubDashboardWindow"
    Holder.Active = true
    Holder.BackgroundColor3 = Library.Scheme.BackgroundColor
    Holder.BorderSizePixel = 0
    Holder.ClipsDescendants = true
    Holder.GroupTransparency = Dashboard.Visible and 0 or 1
    Holder.Size = UDim2.fromOffset(Dashboard.Width, Dashboard.Height)
    Holder.Visible = Dashboard.Visible
    Holder.ZIndex = 40
    Holder.Parent = Library.ScreenGui
    Dashboard.Root = Holder
    ApplyCorner(Holder, Style.Radius)
    Library:AddToRegistry(Holder, { BackgroundColor3 = "BackgroundColor" })
    if type(Library.AddSoftShadow) == "function" then
        local ShadowTransparency = type(Library.GetDesignToken) == "function" and Library:GetDesignToken("Opacity.Shadow", 0.48) or 0.48
        Library:AddSoftShadow(Holder, 16, ShadowTransparency, UDim2.fromOffset(0, 4))
    end

    local HolderStroke = Instance.new("UIStroke")
    HolderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    HolderStroke.Color = Library.Scheme.OutlineColor
    HolderStroke.Thickness = Style.StrokeThickness
    HolderStroke.Transparency = Style.OutlineTransparency
    HolderStroke.Parent = Holder
    Library:AddToRegistry(HolderStroke, { Color = "OutlineColor" })

    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Active = true
    Header.BackgroundColor3 = Library.Scheme.TopBarColor
    Header.BorderSizePixel = 0
    Header.Size = UDim2.new(1, 0, 0, Style.HeaderHeight)
    Header.ZIndex = 41
    Header.Parent = Holder
    Dashboard.Header = Header
    Library:AddToRegistry(Header, { BackgroundColor3 = "TopBarColor" })

    local HeaderLine = Instance.new("Frame")
    HeaderLine.AnchorPoint = Vector2.new(0, 1)
    HeaderLine.BackgroundColor3 = Library:GetAccentSurfaceColor(0.1)
    HeaderLine.BackgroundTransparency = type(Library.GetDesignToken) == "function" and Library:GetDesignToken("Opacity.Divider", 0.56) or 0.56
    HeaderLine.BorderSizePixel = 0
    HeaderLine.Position = UDim2.fromScale(0, 1)
    HeaderLine.Size = UDim2.new(1, 0, 0, 1)
    HeaderLine.ZIndex = 42
    HeaderLine.Parent = Header
    Library:AddToRegistry(HeaderLine, {
        BackgroundColor3 = function()
            return Library:GetAccentSurfaceColor(0.1)
        end,
    })

    local HeaderIconData = Library:GetCustomIcon(Info.Icon or "layout-dashboard")
    local HeaderIcon
    if HeaderIconData then
        HeaderIcon = Instance.new("ImageLabel")
        HeaderIcon.BackgroundTransparency = 1
        HeaderIcon.Image = HeaderIconData.Url
        HeaderIcon.ImageColor3 = Library.Scheme.AccentColor
        HeaderIcon.ImageRectOffset = HeaderIconData.ImageRectOffset
        HeaderIcon.ImageRectSize = HeaderIconData.ImageRectSize
        HeaderIcon.Position = UDim2.fromOffset(11, math.floor((Style.HeaderHeight - 18) * 0.5))
        HeaderIcon.Size = UDim2.fromOffset(18, 18)
        HeaderIcon.ZIndex = 42
        HeaderIcon.Parent = Header
        Library:AddToRegistry(HeaderIcon, { ImageColor3 = "AccentColor" })
    end

    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.FontFace = Library.Scheme.Font
    Title.Position = UDim2.fromOffset(HeaderIcon and 38 or 12, 0)
    Title.Size = UDim2.new(1, HeaderIcon and -78 or -52, 1, 0)
    Title.Text = NormalizeText(Info.Title, "Dashboard")
    Title.TextColor3 = Library.Scheme.FontColor
    Title.TextSize = Style.TextSize
    Title.TextTruncate = Enum.TextTruncate.AtEnd
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 42
    Title.Parent = Header
    Dashboard.TitleLabel = Title
    Library:AddToRegistry(Title, { FontFace = "Font", TextColor3 = "FontColor" })

    local CloseIconData = Library:GetCustomIcon("x")
    local CloseButton = Instance.new("ImageButton")
    CloseButton.AutoButtonColor = false
    CloseButton.BackgroundColor3 = Library.Scheme.ElementColor
    CloseButton.BorderSizePixel = 0
    CloseButton.Image = CloseIconData and CloseIconData.Url or ""
    CloseButton.ImageColor3 = Library.Scheme.MutedFontColor
    CloseButton.ImageRectOffset = CloseIconData and CloseIconData.ImageRectOffset or Vector2.zero
    CloseButton.ImageRectSize = CloseIconData and CloseIconData.ImageRectSize or Vector2.zero
    CloseButton.Position = UDim2.new(1, -31, 0, math.floor((Style.HeaderHeight - 24) * 0.5))
    CloseButton.Size = UDim2.fromOffset(24, 24)
    CloseButton.ZIndex = 43
    CloseButton.Parent = Header
    ApplyCorner(CloseButton, Style.ControlRadius)
    Library:AddToRegistry(CloseButton, {
        BackgroundColor3 = "ElementColor",
        ImageColor3 = "MutedFontColor",
    })

    local Content = Instance.new("ScrollingFrame")
    Content.Name = "Content"
    Content.Active = true
    Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.CanvasSize = UDim2.fromScale(0, 0)
    Content.Position = UDim2.fromOffset(0, Style.HeaderHeight)
    Content.ScrollBarImageColor3 = Library.Scheme.AccentColor
    Content.ScrollBarImageTransparency = 0.38
    Content.ScrollBarThickness = 2
    Content.ScrollingDirection = Enum.ScrollingDirection.Y
    Content.Size = UDim2.new(1, 0, 1, -Style.HeaderHeight)
    Content.ZIndex = 41
    Content.Parent = Holder
    Dashboard.Content = Content
    Library:AddToRegistry(Content, { ScrollBarImageColor3 = "AccentColor" })

    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingBottom = UDim.new(0, Style.Padding)
    ContentPadding.PaddingLeft = UDim.new(0, Style.Padding)
    ContentPadding.PaddingRight = UDim.new(0, Style.Padding + 2)
    ContentPadding.PaddingTop = UDim.new(0, Style.Padding)
    ContentPadding.Parent = Content

    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Padding = UDim.new(0, Style.Gap)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Parent = Content

    local function AddConnection(Connection)
        table.insert(Dashboard.Connections, Connection)
        return Connection
    end

    local function RemoveConnection(Connection)
        if Connection and Connection.Connected then
            Connection:Disconnect()
        end
        local Index = table.find(Dashboard.Connections, Connection)
        if Index then
            table.remove(Dashboard.Connections, Index)
        end
    end

    local function ClampToViewport()
        if Dashboard.Destroyed or not Holder.Parent then
            return
        end
        local Viewport = GetViewportSize()
        local Size = Holder.AbsoluteSize
        if Size.X <= 0 or Size.Y <= 0 then
            Size = Vector2.new(Dashboard.Width, Dashboard.Height)
        end
        local Position = Holder.Position
        local X = Position.X.Scale * Viewport.X + Position.X.Offset
        local Y = Position.Y.Scale * Viewport.Y + Position.Y.Offset
        X = math.clamp(X, 8, math.max(8, Viewport.X - Size.X - 8))
        Y = math.clamp(Y, 8, math.max(8, Viewport.Y - Size.Y - 8))
        Holder.Position = UDim2.fromOffset(math.floor(X + 0.5), math.floor(Y + 0.5))
    end

    local function Place(Value)
        if typeof(Value) == "UDim2" then
            Holder.Position = Value
            task.defer(ClampToViewport)
            return
        end
        local Viewport = GetViewportSize()
        local Side = string.lower(tostring(Value or "Right"))
        if Side == "left" then
            Holder.Position = UDim2.fromOffset(14, 74)
        elseif Side == "center" then
            Holder.Position = UDim2.fromOffset(
                math.floor((Viewport.X - Dashboard.Width) * 0.5),
                math.floor((Viewport.Y - Dashboard.Height) * 0.5)
            )
        else
            Holder.Position = UDim2.fromOffset(math.max(8, Viewport.X - Dashboard.Width - 14), 74)
        end
        task.defer(ClampToViewport)
    end

    local function UnregisterDynamic(Widget)
        Dashboard.Dynamic[Widget] = nil
    end

    local function ApplyDynamic(Widget, State, Force)
        if Dashboard.Destroyed or Widget.Destroyed or not State then
            return
        end
        local Now = os.clock()
        if not Force and Now < State.NextUpdate then
            return
        end
        State.NextUpdate = Now + State.Interval
        local Success, Value = pcall(State.Provider, Widget, Dashboard)
        if Success then
            Widget.LastError = nil
            State.Apply(Value)
        else
            Widget.LastError = tostring(Value)
            State.Apply(State.ErrorText)
        end
    end

    local function EnsureScheduler()
        if Dashboard.Destroyed or not Dashboard.Visible or Dashboard.SchedulerRunning or next(Dashboard.Dynamic) == nil then
            return
        end
        Dashboard.SchedulerRunning = true
        Dashboard.SchedulerRevision += 1
        local Revision = Dashboard.SchedulerRevision
        task.spawn(function()
            while not Dashboard.Destroyed and Dashboard.Visible and Dashboard.SchedulerRevision == Revision and next(Dashboard.Dynamic) ~= nil do
                for Widget, State in Dashboard.Dynamic do
                    ApplyDynamic(Widget, State, false)
                end
                task.wait(0.1)
            end
            if Dashboard.SchedulerRevision == Revision then
                Dashboard.SchedulerRunning = false
                if not Dashboard.Destroyed and Dashboard.Visible and next(Dashboard.Dynamic) ~= nil then
                    EnsureScheduler()
                end
            end
        end)
    end

    local function RegisterDynamic(Widget, Provider, Interval, Apply, ErrorText)
        UnregisterDynamic(Widget)
        if type(Provider) ~= "function" then
            return
        end
        Dashboard.Dynamic[Widget] = {
            Provider = Provider,
            Interval = math.clamp(tonumber(Interval) or 0.5, 0.1, 60),
            NextUpdate = 0,
            Apply = Apply,
            ErrorText = NormalizeText(ErrorText, "Unavailable"),
        }
        ApplyDynamic(Widget, Dashboard.Dynamic[Widget], true)
        EnsureScheduler()
    end

    local function AttachWidgetLifecycle(Section, Widget, Root)
        Widget.Root = Root
        Widget.Destroyed = false
        Widget.Connections = {}
        table.insert(Section.Widgets, Widget)

        function Widget:GiveConnection(Connection)
            table.insert(Widget.Connections, Connection)
            return Connection
        end

        function Widget:SetVisible(Value)
            if not Widget.Destroyed then
                Root.Visible = Value == true
            end
            return Widget
        end

        function Widget:Destroy()
            if Widget.Destroyed then
                return
            end
            Widget.Destroyed = true
            UnregisterDynamic(Widget)
            for _, Connection in Widget.Connections do
                if Connection and Connection.Connected then
                    Connection:Disconnect()
                end
            end
            table.clear(Widget.Connections)
            local Index = table.find(Section.Widgets, Widget)
            if Index then
                table.remove(Section.Widgets, Index)
            end
            RemoveRegistryTree(Library, Root)
            Root:Destroy()
        end

        return Widget
    end

    function Dashboard:AddSection(Name, SectionInfo)
        assert(not Dashboard.Destroyed, "Dashboard is destroyed")
        if type(Name) == "table" then
            SectionInfo = Name
            Name = SectionInfo.Title or SectionInfo.Name
        end
        SectionInfo = SectionInfo or {}
        Dashboard.SectionOrder += 1

        local Section = {
            Dashboard = Dashboard,
            Destroyed = false,
            Widgets = {},
            WidgetOrder = 0,
            Title = NormalizeText(Name, "Section"),
        }

        local Root = Instance.new("Frame")
        Root.AutomaticSize = Enum.AutomaticSize.Y
        Root.BackgroundColor3 = Library.Scheme.SurfaceColor
        Root.BorderSizePixel = 0
        Root.LayoutOrder = tonumber(SectionInfo.Order) or Dashboard.SectionOrder
        Root.Size = UDim2.new(1, 0, 0, 0)
        Root.ZIndex = 42
        Root.Parent = Content
        Section.Root = Root
        ApplyCorner(Root, Style.Radius)
        Library:AddToRegistry(Root, { BackgroundColor3 = "SurfaceColor" })

        local Stroke = Instance.new("UIStroke")
        Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Stroke.Color = Library.Scheme.OutlineColor
        Stroke.Thickness = Style.StrokeThickness
        Stroke.Transparency = Style.OutlineTransparency
        Stroke.Parent = Root
        Library:AddToRegistry(Stroke, { Color = "OutlineColor" })

        local RootLayout = Instance.new("UIListLayout")
        RootLayout.Padding = UDim.new(0, 0)
        RootLayout.SortOrder = Enum.SortOrder.LayoutOrder
        RootLayout.Parent = Root

        local SectionHeader = Instance.new("Frame")
        SectionHeader.BackgroundTransparency = 1
        SectionHeader.LayoutOrder = 0
        SectionHeader.Size = UDim2.new(1, 0, 0, SectionInfo.ShowTitle == false and 0 or 32)
        SectionHeader.Visible = SectionInfo.ShowTitle ~= false
        SectionHeader.ZIndex = 43
        SectionHeader.Parent = Root

        local SectionIconData = Library:GetCustomIcon(SectionInfo.Icon or SectionInfo.IconName)
        if SectionIconData then
            local SectionIcon = Instance.new("ImageLabel")
            SectionIcon.BackgroundTransparency = 1
            SectionIcon.Image = SectionIconData.Url
            SectionIcon.ImageColor3 = Library.Scheme.AccentColor
            SectionIcon.ImageRectOffset = SectionIconData.ImageRectOffset
            SectionIcon.ImageRectSize = SectionIconData.ImageRectSize
            SectionIcon.Position = UDim2.fromOffset(8, 7)
            SectionIcon.Size = UDim2.fromOffset(18, 18)
            SectionIcon.ZIndex = 44
            SectionIcon.Parent = SectionHeader
            Library:AddToRegistry(SectionIcon, { ImageColor3 = "AccentColor" })
        end

        local SectionTitle = Instance.new("TextLabel")
        SectionTitle.BackgroundTransparency = 1
        SectionTitle.FontFace = Library.Scheme.Font
        SectionTitle.Position = UDim2.fromOffset(SectionIconData and 32 or 10, 0)
        SectionTitle.Size = UDim2.new(1, SectionIconData and -42 or -20, 1, -1)
        SectionTitle.Text = Section.Title
        SectionTitle.TextColor3 = Library.Scheme.FontColor
        SectionTitle.TextSize = Style.TextSize
        SectionTitle.TextTruncate = Enum.TextTruncate.AtEnd
        SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
        SectionTitle.ZIndex = 44
        SectionTitle.Parent = SectionHeader
        Section.TitleLabel = SectionTitle
        Library:AddToRegistry(SectionTitle, { FontFace = "Font", TextColor3 = "FontColor" })

        local SectionLine = Instance.new("Frame")
        SectionLine.AnchorPoint = Vector2.new(0, 1)
        SectionLine.BackgroundColor3 = Library:GetAccentSurfaceColor(0.1)
        SectionLine.BackgroundTransparency = type(Library.GetDesignToken) == "function" and Library:GetDesignToken("Opacity.Divider", 0.56) or 0.56
        SectionLine.BorderSizePixel = 0
        SectionLine.Position = UDim2.fromScale(0, 1)
        SectionLine.Size = UDim2.new(1, 0, 0, 1)
        SectionLine.ZIndex = 44
        SectionLine.Parent = SectionHeader
        Library:AddToRegistry(SectionLine, {
            BackgroundColor3 = function()
                return Library:GetAccentSurfaceColor(0.1)
            end,
        })

        local Body = Instance.new("Frame")
        Body.AutomaticSize = Enum.AutomaticSize.Y
        Body.BackgroundTransparency = 1
        Body.LayoutOrder = 1
        Body.Size = UDim2.new(1, 0, 0, 0)
        Body.ZIndex = 43
        Body.Parent = Root

        local BodyPadding = Instance.new("UIPadding")
        BodyPadding.PaddingBottom = UDim.new(0, Style.Padding)
        BodyPadding.PaddingLeft = UDim.new(0, Style.Padding + 1)
        BodyPadding.PaddingRight = UDim.new(0, Style.Padding + 1)
        BodyPadding.PaddingTop = UDim.new(0, Style.Padding)
        BodyPadding.Parent = Body

        local BodyLayout = Instance.new("UIListLayout")
        BodyLayout.Padding = UDim.new(0, math.max(4, Style.Gap - 2))
        BodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
        BodyLayout.Parent = Body

        function Section:NextOrder()
            assert(not Section.Destroyed, "Dashboard section is destroyed")
            Section.WidgetOrder += 1
            return Section.WidgetOrder
        end

        function Section:AddText(Value)
            local TextInfo
            if type(Value) == "table" then
                TextInfo = Value
            elseif type(Value) == "function" then
                TextInfo = { Text = Value }
            else
                TextInfo = { Text = Value }
            end

            local Widget = {}
            local Row = Instance.new("Frame")
            Row.AutomaticSize = Enum.AutomaticSize.Y
            Row.BackgroundTransparency = 1
            Row.LayoutOrder = tonumber(TextInfo.Order) or Section:NextOrder()
            Row.Size = UDim2.new(1, 0, 0, 0)
            Row.ZIndex = 43
            Row.Parent = Body

            local Label = Instance.new("TextLabel")
            Label.AutomaticSize = Enum.AutomaticSize.Y
            Label.BackgroundTransparency = 1
            Label.FontFace = Library.Scheme.Font
            Label.Size = UDim2.new(1, 0, 0, 0)
            Label.Text = ""
            Label.TextColor3 = Library.Scheme.MutedFontColor
            Label.TextSize = math.clamp(tonumber(TextInfo.TextSize) or 12, 10, 18)
            Label.TextWrapped = TextInfo.Wrapped ~= false
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextYAlignment = Enum.TextYAlignment.Top
            Label.ZIndex = 44
            Label.Parent = Row
            Library:AddToRegistry(Label, { FontFace = "Font", TextColor3 = TextInfo.Emphasis and "FontColor" or "MutedFontColor" })

            local function Apply(ValueText)
                Label.Text = NormalizeText(ValueText, TextInfo.Fallback or "")
            end

            function Widget:SetText(ValueText)
                UnregisterDynamic(Widget)
                Apply(ValueText)
                return Widget
            end

            function Widget:SetProvider(Provider, Interval)
                RegisterDynamic(Widget, Provider, Interval or TextInfo.Interval, Apply, TextInfo.ErrorText)
                return Widget
            end

            AttachWidgetLifecycle(Section, Widget, Row)
            if type(TextInfo.Text) == "function" then
                Widget:SetProvider(TextInfo.Text, TextInfo.Interval)
            else
                Apply(TextInfo.Text)
            end
            return Widget
        end

        function Section:AddMetric(Value)
            local MetricInfo = type(Value) == "table" and Value or { Label = tostring(Value) }
            local Widget = {}
            local Row = Instance.new("Frame")
            Row.BackgroundTransparency = 1
            Row.LayoutOrder = tonumber(MetricInfo.Order) or Section:NextOrder()
            Row.Size = UDim2.new(1, 0, 0, 23)
            Row.ZIndex = 43
            Row.Parent = Body

            local NameLabel = Instance.new("TextLabel")
            NameLabel.BackgroundTransparency = 1
            NameLabel.FontFace = Library.Scheme.Font
            NameLabel.Size = UDim2.new(0.46, -4, 1, 0)
            NameLabel.Text = NormalizeText(MetricInfo.Label or MetricInfo.Text, "Value")
            NameLabel.TextColor3 = Library.Scheme.MutedFontColor
            NameLabel.TextSize = 12
            NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            NameLabel.TextXAlignment = Enum.TextXAlignment.Left
            NameLabel.ZIndex = 44
            NameLabel.Parent = Row
            Library:AddToRegistry(NameLabel, { FontFace = "Font", TextColor3 = "MutedFontColor" })

            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.AnchorPoint = Vector2.new(1, 0)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.FontFace = Library.Scheme.Font
            ValueLabel.Position = UDim2.fromScale(1, 0)
            ValueLabel.Size = UDim2.new(0.54, 0, 1, 0)
            ValueLabel.Text = ""
            ValueLabel.TextColor3 = Library.Scheme.FontColor
            ValueLabel.TextSize = 12
            ValueLabel.TextTruncate = Enum.TextTruncate.AtEnd
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.ZIndex = 44
            ValueLabel.Parent = Row
            Library:AddToRegistry(ValueLabel, { FontFace = "Font", TextColor3 = "FontColor" })

            local function Apply(MetricValue)
                if type(MetricInfo.Format) == "function" then
                    local Success, Formatted = pcall(MetricInfo.Format, MetricValue, Widget, Dashboard)
                    if Success then
                        MetricValue = Formatted
                    end
                end
                ValueLabel.Text = NormalizeText(MetricValue, MetricInfo.Fallback or "—")
            end

            function Widget:SetLabel(ValueText)
                NameLabel.Text = NormalizeText(ValueText, "Value")
                return Widget
            end

            function Widget:SetValue(MetricValue)
                UnregisterDynamic(Widget)
                Apply(MetricValue)
                return Widget
            end

            function Widget:SetProvider(Provider, Interval)
                RegisterDynamic(Widget, Provider, Interval or MetricInfo.Interval, Apply, MetricInfo.ErrorText)
                return Widget
            end

            Widget.NameLabel = NameLabel
            Widget.ValueLabel = ValueLabel
            AttachWidgetLifecycle(Section, Widget, Row)
            local Provider = MetricInfo.Value
            if Provider == nil then
                Provider = MetricInfo.Provider
            end
            if type(Provider) == "function" then
                Widget:SetProvider(Provider, MetricInfo.Interval)
            else
                Apply(Provider)
            end
            return Widget
        end

        function Section:AddButton(Value, Callback)
            local ButtonInfo
            if type(Value) == "table" then
                ButtonInfo = Value
            else
                ButtonInfo = { Text = Value, Callback = Callback }
            end
            local Widget = {}
            local Button = Instance.new("TextButton")
            Button.AutoButtonColor = false
            Button.BackgroundColor3 = Library.Scheme.ElementColor
            Button.BorderSizePixel = 0
            Button.FontFace = Library.Scheme.Font
            Button.LayoutOrder = tonumber(ButtonInfo.Order) or Section:NextOrder()
            Button.Size = UDim2.new(1, 0, 0, Style.ControlHeight)
            Button.Text = NormalizeText(ButtonInfo.Text, "Action")
            Button.TextColor3 = Library.Scheme.FontColor
            Button.TextSize = Style.CaptionSize
            Button.TextTruncate = Enum.TextTruncate.AtEnd
            Button.ZIndex = 44
            Button.Parent = Body
            ApplyCorner(Button, Style.ControlRadius)
            Library:AddToRegistry(Button, {
                BackgroundColor3 = "ElementColor",
                FontFace = "Font",
                TextColor3 = "FontColor",
            })

            local ButtonStroke = Instance.new("UIStroke")
            ButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            ButtonStroke.Color = Library.Scheme.OutlineColor
            ButtonStroke.Thickness = Style.StrokeThickness
            ButtonStroke.Transparency = Style.OutlineTransparency
            ButtonStroke.Parent = Button
            Library:AddToRegistry(ButtonStroke, { Color = "OutlineColor" })

            function Widget:SetText(ValueText)
                Button.Text = NormalizeText(ValueText, "Action")
                return Widget
            end

            function Widget:SetEnabled(ValueEnabled)
                Widget.Enabled = ValueEnabled == true
                Button.TextTransparency = Widget.Enabled and 0 or 0.45
                return Widget
            end

            Widget.Enabled = ButtonInfo.Enabled ~= false
            Widget.Callback = ButtonInfo.Callback or ButtonInfo.Func
            AttachWidgetLifecycle(Section, Widget, Button)

            Widget:GiveConnection(Button.MouseEnter:Connect(function()
                if not Widget.Destroyed and Widget.Enabled then
                    Library:PlayTween(Button, "DashboardHover", Library.HoverTweenInfo or Library.TweenInfo, {
                        BackgroundColor3 = Library.Scheme.HoverColor,
                    })
                end
            end))
            Widget:GiveConnection(Button.MouseLeave:Connect(function()
                if not Widget.Destroyed then
                    Library:PlayTween(Button, "DashboardHover", Library.HoverTweenInfo or Library.TweenInfo, {
                        BackgroundColor3 = Library.Scheme.ElementColor,
                    })
                end
            end))
            Widget:GiveConnection(Button.MouseButton1Click:Connect(function()
                if Widget.Destroyed or not Widget.Enabled then
                    return
                end
                if type(Widget.Callback) == "function" then
                    Library:SafeCallback(Widget.Callback, Widget, Dashboard)
                end
            end))
            Widget:SetEnabled(Widget.Enabled)
            return Widget
        end

        function Section:AddCustom(Value)
            local CustomInfo
            if typeof(Value) == "Instance" then
                CustomInfo = { Instance = Value }
            elseif type(Value) == "table" then
                CustomInfo = Value
            else
                CustomInfo = { Build = Value }
            end
            local CustomInstance = CustomInfo.Instance
            if not CustomInstance and type(CustomInfo.Build) == "function" then
                local Success, Result = pcall(CustomInfo.Build, Dashboard, Section)
                if Success then
                    CustomInstance = Result
                end
            end
            assert(typeof(CustomInstance) == "Instance" and CustomInstance:IsA("GuiObject"), "Dashboard custom widget requires a GuiObject")

            local Widget = {}
            local Row = Instance.new("Frame")
            Row.BackgroundTransparency = 1
            Row.ClipsDescendants = CustomInfo.ClipsDescendants == true
            Row.LayoutOrder = tonumber(CustomInfo.Order) or Section:NextOrder()
            Row.Size = UDim2.new(1, 0, 0, math.clamp(math.floor(tonumber(CustomInfo.Height) or 80), 20, 480))
            Row.ZIndex = 43
            Row.Parent = Body

            CustomInstance.Parent = Row
            if CustomInfo.Fill ~= false then
                CustomInstance.Position = UDim2.fromScale(0, 0)
                CustomInstance.Size = UDim2.fromScale(1, 1)
            end
            Widget.Instance = CustomInstance
            return AttachWidgetLifecycle(Section, Widget, Row)
        end

        function Section:Add(Value)
            if type(Value) == "string" or type(Value) == "function" then
                return Section:AddText(Value)
            end
            assert(type(Value) == "table", "Dashboard widget must be text, function, or table")
            local Kind = string.lower(tostring(Value.Type or Value.Kind or "Text"))
            if Kind == "metric" or Kind == "value" or Kind == "stat" then
                return Section:AddMetric(Value)
            elseif Kind == "button" or Kind == "action" then
                return Section:AddButton(Value)
            elseif Kind == "custom" or Kind == "instance" then
                return Section:AddCustom(Value)
            end
            return Section:AddText(Value)
        end

        function Section:SetTitle(ValueText)
            if Section.Destroyed then
                return Section
            end
            Section.Title = NormalizeText(ValueText, "Section")
            SectionTitle.Text = Section.Title
            return Section
        end

        function Section:SetVisible(ValueVisible)
            if not Section.Destroyed then
                Root.Visible = ValueVisible == true
            end
            return Section
        end

        function Section:Destroy()
            if Section.Destroyed then
                return
            end
            Section.Destroyed = true
            for _, Widget in table.clone(Section.Widgets) do
                Widget:Destroy()
            end
            local Index = table.find(Dashboard.Sections, Section)
            if Index then
                table.remove(Dashboard.Sections, Index)
            end
            if Dashboard.DefaultSection == Section then
                Dashboard.DefaultSection = nil
            end
            RemoveRegistryTree(Library, Root)
            Root:Destroy()
        end

        table.insert(Dashboard.Sections, Section)
        return Section
    end

    function Dashboard:GetDefaultSection()
        if not Dashboard.DefaultSection or Dashboard.DefaultSection.Destroyed then
            Dashboard.DefaultSection = Dashboard:AddSection(Info.DefaultSection or "Overview")
        end
        return Dashboard.DefaultSection
    end

    function Dashboard:Add(Value)
        return Dashboard:GetDefaultSection():Add(Value)
    end

    function Dashboard:AddText(Value)
        return Dashboard:GetDefaultSection():AddText(Value)
    end

    function Dashboard:AddMetric(Value)
        return Dashboard:GetDefaultSection():AddMetric(Value)
    end

    function Dashboard:AddButton(Value, Callback)
        return Dashboard:GetDefaultSection():AddButton(Value, Callback)
    end

    function Dashboard:AddCustom(Value)
        return Dashboard:GetDefaultSection():AddCustom(Value)
    end

    function Dashboard:SetTitle(Value)
        if not Dashboard.Destroyed then
            Title.Text = NormalizeText(Value, "Dashboard")
        end
        return Dashboard
    end

    function Dashboard:SetVisible(Value)
        if Dashboard.Destroyed then
            return Dashboard
        end
        local NewVisible = Value == true
        if Dashboard.Visible == NewVisible then
            if NewVisible then
                task.defer(ClampToViewport)
            end
            return Dashboard
        end
        Dashboard.Visible = NewVisible
        Dashboard.VisibilityRevision += 1
        local Revision = Dashboard.VisibilityRevision
        local Animate = Style.Motion ~= false and Library.Animations and Library.Animations.ToggleWindow
        if NewVisible then
            Holder.Visible = true
            if Animate then
                Holder.GroupTransparency = 1
                Library:PlayTween(Holder, "DashboardVisibility", Library.WindowOpenAnimationInfo or Library.TweenInfo, {
                    GroupTransparency = 0,
                })
            else
                Library:CancelTween(Holder, "DashboardVisibility")
                Holder.GroupTransparency = 0
            end
            task.defer(ClampToViewport)
            Dashboard:Refresh()
            EnsureScheduler()
        elseif Animate then
            local Tween = Library:PlayTween(Holder, "DashboardVisibility", Library.WindowCloseAnimationInfo or Library.TweenInfo, {
                GroupTransparency = 1,
            })
            if Tween then
                Tween.Completed:Once(function()
                    if not Dashboard.Destroyed and not Dashboard.Visible and Dashboard.VisibilityRevision == Revision then
                        Holder.Visible = false
                    end
                end)
            else
                Holder.Visible = false
            end
        else
            Library:CancelTween(Holder, "DashboardVisibility")
            Holder.GroupTransparency = 1
            Holder.Visible = false
        end
        return Dashboard
    end

    function Dashboard:Toggle()
        return Dashboard:SetVisible(not Dashboard.Visible)
    end

    function Dashboard:SetDraggable(Value)
        if not Dashboard.Destroyed then
            Dashboard.Draggable = Value == true
        end
        return Dashboard
    end

    function Dashboard:SetPosition(Value)
        if not Dashboard.Destroyed then
            Place(Value)
        end
        return Dashboard
    end

    function Dashboard:SetSize(Width, Height)
        if Dashboard.Destroyed then
            return Dashboard
        end
        Dashboard.Width = math.clamp(math.floor(tonumber(Width) or Dashboard.Width), 240, 620)
        Dashboard.Height = math.clamp(math.floor(tonumber(Height) or Dashboard.Height), 180, 760)
        Holder.Size = UDim2.fromOffset(Dashboard.Width, Dashboard.Height)
        task.defer(ClampToViewport)
        return Dashboard
    end

    function Dashboard:Refresh()
        if Dashboard.Destroyed then
            return Dashboard
        end
        for Widget, State in Dashboard.Dynamic do
            ApplyDynamic(Widget, State, true)
        end
        return Dashboard
    end

    function Dashboard:Destroy()
        if Dashboard.Destroyed then
            return
        end
        Dashboard.Destroyed = true
        Dashboard.SchedulerRevision += 1
        for _, Section in table.clone(Dashboard.Sections) do
            Section:Destroy()
        end
        for _, Connection in Dashboard.Connections do
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end
        table.clear(Dashboard.Connections)
        table.clear(Dashboard.Dynamic)
        RemoveRegistryTree(Library, Holder)
        Holder:Destroy()
    end

    AddConnection(CloseButton.MouseEnter:Connect(function()
        if not Dashboard.Destroyed then
            Library:PlayTween(CloseButton, "DashboardCloseHover", Library.HoverTweenInfo or Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.HoverColor,
                ImageColor3 = Library.Scheme.FontColor,
            })
        end
    end))
    AddConnection(CloseButton.MouseLeave:Connect(function()
        if not Dashboard.Destroyed then
            Library:PlayTween(CloseButton, "DashboardCloseHover", Library.HoverTweenInfo or Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.ElementColor,
                ImageColor3 = Library.Scheme.MutedFontColor,
            })
        end
    end))
    AddConnection(CloseButton.MouseButton1Click:Connect(function()
        Dashboard:SetVisible(false)
    end))

    if type(Library.MakeDraggable) == "function" then
        Library:MakeDraggable(Holder, Header, true, false, function()
            return Dashboard.Draggable and Dashboard.Visible
        end)
    end

    local CameraConnection
    local function BindCamera()
        RemoveConnection(CameraConnection)
        local Camera = Workspace.CurrentCamera
        if Camera then
            CameraConnection = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(ClampToViewport)
            AddConnection(CameraConnection)
        end
        task.defer(ClampToViewport)
    end

    AddConnection(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(BindCamera))
    BindCamera()
    Place(Info.Position or Info.Side or "Right")

    if type(Info.Sections) == "table" then
        for _, SectionInfo in Info.Sections do
            local Section = Dashboard:AddSection(SectionInfo)
            if type(SectionInfo.Items) == "table" then
                for _, Item in SectionInfo.Items do
                    Section:Add(Item)
                end
            end
        end
    end

    Library:OnUnload(function()
        Dashboard:Destroy()
    end)

    return Dashboard
end

return DashboardWindow
