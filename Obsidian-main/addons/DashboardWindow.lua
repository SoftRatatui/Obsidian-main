local Workspace = game:GetService("Workspace")

local DashboardWindow = {
    ReleaseVersion = "0.0.1-release-3",
}

local function ApplyCorner(Object, Radius)
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, Radius)
    Corner.Parent = Object
    return Corner
end

local function RemoveRegistryTree(Library, Root)
    if not Library or type(Library.RemoveFromRegistry) ~= "function" or typeof(Root) ~= "Instance" then
        return
    end
    for _, Object in Root:GetDescendants() do
        Library:RemoveFromRegistry(Object)
    end
    Library:RemoveFromRegistry(Root)
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
    local Compact = Info.Compact ~= false
    local Style = type(Library.GetAddonStyle) == "function" and Library:GetAddonStyle(Info.Style) or {
        HeaderHeight = 38,
        Padding = 10,
        Gap = 8,
        Radius = 7,
        ControlRadius = 4,
        ControlHeight = 28,
        OutlineTransparency = 0.5,
        StrokeThickness = 1,
        TextSize = 14,
        CaptionSize = 12,
        Motion = true,
    }
    local Embedded = typeof(Info.Parent) == "Instance" and Info.Parent:IsA("GuiObject")

    local Dashboard = {
        Destroyed = false,
        Visible = Info.Visible ~= false,
        Draggable = Info.Draggable ~= false,
        Width = math.clamp(math.floor(tonumber(Info.Width) or 320), 240, 620),
        Height = math.clamp(math.floor(tonumber(Info.Height) or 360), Compact and 24 or 180, 760),
        Sections = {},
        Dynamic = {},
        Connections = {},
        TickKey = {},
        TickQueued = false,
        VisibilityRevision = 0,
        WidgetSequence = 0,
        ChartHost = type(Info.ChartHost) == "table" and Info.ChartHost or nil,
        SectionOrder = 0,
        DefaultSection = nil,
        Style = Style,
        Embedded = Embedded,
        Element = nil,
    }

    local Holder = Instance.new("Frame")
    Holder.Name = "MonHubDashboardWindow"
    Holder.Active = true
    Holder.BackgroundColor3 = Library.Scheme.BackgroundColor
    Holder.BorderSizePixel = 0
    Holder.ClipsDescendants = true
    Holder.Size = Embedded and UDim2.new(1, 0, 0, Dashboard.Height) or UDim2.fromOffset(Dashboard.Width, Dashboard.Height)
    Holder.Visible = Dashboard.Visible
    Holder.ZIndex = Embedded and Info.Parent.ZIndex or 40
    Holder.Parent = Embedded and Info.Parent or Library.ScreenGui
    Dashboard.Root = Holder
    ApplyCorner(Holder, Style.Radius)
    Library:AddToRegistry(Holder, { BackgroundColor3 = "BackgroundColor" })
    if not Embedded and type(Library.AddSoftShadow) == "function" then
        local ShadowTransparency = type(Library.GetDesignToken) == "function" and Library:GetDesignToken("Opacity.Shadow", 0.44) or 0.44
        Library:AddSoftShadow(Holder, 22, ShadowTransparency, UDim2.fromOffset(0, 5))
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

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.TopLeftRadius = UDim.new(0, Style.Radius)
    HeaderCorner.TopRightRadius = UDim.new(0, Style.Radius)
    HeaderCorner.BottomLeftRadius = UDim.new(0, 0)
    HeaderCorner.BottomRightRadius = UDim.new(0, 0)
    HeaderCorner.Parent = Header

    local HeaderLine = Instance.new("Frame")
    HeaderLine.AnchorPoint = Vector2.new(0, 1)
    HeaderLine.BackgroundColor3 = Library.Scheme.OutlineColor
    HeaderLine.BackgroundTransparency = type(Library.GetDesignToken) == "function" and Library:GetDesignToken("Opacity.Divider", 0.56) or 0.56
    HeaderLine.BorderSizePixel = 0
    HeaderLine.Position = UDim2.new(0, Style.Padding, 1, 0)
    HeaderLine.Size = UDim2.new(1, -Style.Padding * 2, 0, 1)
    HeaderLine.ZIndex = 42
    HeaderLine.Parent = Header
    Library:AddToRegistry(HeaderLine, { BackgroundColor3 = "OutlineColor" })

    local HeaderIconData = Library:GetCustomIcon(Info.Icon or "layout-dashboard")
    local HeaderIconHolder = Instance.new("Frame")
    HeaderIconHolder.AnchorPoint = Vector2.new(0, 0.5)
    HeaderIconHolder.BackgroundColor3 = Library:GetAccentSurfaceColor(0.18)
    HeaderIconHolder.BorderSizePixel = 0
    HeaderIconHolder.Position = UDim2.fromOffset(Style.Padding, Style.HeaderHeight * 0.5)
    HeaderIconHolder.Size = UDim2.fromOffset(26, 26)
    HeaderIconHolder.ZIndex = 42
    HeaderIconHolder.Parent = Header
    ApplyCorner(HeaderIconHolder, Style.ControlRadius)
    Library:AddToRegistry(HeaderIconHolder, {
        BackgroundColor3 = function()
            return Library:GetAccentSurfaceColor(0.18)
        end,
    })

    local HeaderIcon = Instance.new("ImageLabel")
    HeaderIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    HeaderIcon.BackgroundTransparency = 1
    HeaderIcon.Image = HeaderIconData and HeaderIconData.Url or ""
    HeaderIcon.ImageColor3 = Library.Scheme.AccentColor
    HeaderIcon.ImageRectOffset = HeaderIconData and HeaderIconData.ImageRectOffset or Vector2.zero
    HeaderIcon.ImageRectSize = HeaderIconData and HeaderIconData.ImageRectSize or Vector2.zero
    HeaderIcon.Position = UDim2.fromScale(0.5, 0.5)
    HeaderIcon.Size = UDim2.fromOffset(16, 16)
    HeaderIcon.ZIndex = 43
    HeaderIcon.Parent = HeaderIconHolder
    Library:AddToRegistry(HeaderIcon, { ImageColor3 = "AccentColor" })

    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.FontFace = Library.Scheme.Font
    Title.Position = UDim2.fromOffset(Style.Padding + 36, 0)
    Title.Size = UDim2.new(1, -(Style.Padding * 2 + 72), 1, 0)
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
    CloseButton.AnchorPoint = Vector2.new(1, 0.5)
    CloseButton.AutoButtonColor = false
    CloseButton.BackgroundColor3 = Library.Scheme.ElementColor
    CloseButton.BackgroundTransparency = 1
    CloseButton.BorderSizePixel = 0
    CloseButton.Image = ""
    CloseButton.Position = UDim2.new(1, -Style.Padding, 0.5, 0)
    CloseButton.Size = UDim2.fromOffset(28, 28)
    CloseButton.Visible = not Embedded and Info.Closable ~= false
    CloseButton.ZIndex = 43
    CloseButton.Parent = Header
    ApplyCorner(CloseButton, Style.ControlRadius)
    Library:AddToRegistry(CloseButton, {
        BackgroundColor3 = "ElementColor",
    })

    local CloseIcon = Instance.new("ImageLabel")
    CloseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    CloseIcon.BackgroundTransparency = 1
    CloseIcon.Image = CloseIconData and CloseIconData.Url or ""
    CloseIcon.ImageColor3 = Library.Scheme.MutedFontColor
    CloseIcon.ImageRectOffset = CloseIconData and CloseIconData.ImageRectOffset or Vector2.zero
    CloseIcon.ImageRectSize = CloseIconData and CloseIconData.ImageRectSize or Vector2.zero
    CloseIcon.Position = UDim2.fromScale(0.5, 0.5)
    CloseIcon.Size = UDim2.fromOffset(15, 15)
    CloseIcon.ZIndex = 44
    CloseIcon.Parent = CloseButton
    Library:AddToRegistry(CloseIcon, { ImageColor3 = "MutedFontColor" })

    local Content = Instance.new("ScrollingFrame")
    Content.ClipsDescendants = true
    Content.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    Content.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
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
    if Info.ShowHeader == false or Embedded and Info.ShowHeader ~= true then
        Header.Visible = false
        Content.Position = UDim2.fromScale(0, 0)
        Content.Size = UDim2.fromScale(1, 1)
    end

    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingBottom = UDim.new(0, Compact and 0 or Style.Padding)
    ContentPadding.PaddingLeft = UDim.new(0, Compact and 0 or Style.Padding)
    ContentPadding.PaddingRight = UDim.new(0, Compact and 2 or Style.Padding + 2)
    ContentPadding.PaddingTop = UDim.new(0, Compact and 0 or Style.Padding)
    ContentPadding.Parent = Content

    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Padding = UDim.new(0, Style.Gap)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Parent = Content
    Dashboard.ContentLayout = ContentLayout

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
        if Dashboard.Destroyed or Dashboard.Fading or not Holder.Parent then
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

    local function IsActive()
        return not Dashboard.Destroyed and Dashboard.Visible and Library.Toggled ~= false
    end
    Dashboard.IsActive = IsActive

    local ScheduleTick
    local function RunTick()
        Dashboard.TickQueued = false
        if not IsActive() or next(Dashboard.Dynamic) == nil then
            return
        end
        local Now = os.clock()
        for Widget, State in Dashboard.Dynamic do
            if Now >= State.NextUpdate then
                ApplyDynamic(Widget, State, false)
            end
        end
        ScheduleTick()
    end

    function ScheduleTick()
        if Dashboard.TickQueued or not IsActive() or next(Dashboard.Dynamic) == nil then
            return
        end
        Dashboard.TickQueued = true
        Library:QueueFrame(Dashboard.TickKey, RunTick)
    end
    Dashboard.ScheduleTick = ScheduleTick

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
        ScheduleTick()
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
            if type(Widget.OnDestroy) == "function" then
                pcall(Widget.OnDestroy, Widget)
            end
            local Index = table.find(Section.Widgets, Widget)
            if Index then
                table.remove(Section.Widgets, Index)
            end
            RemoveRegistryTree(Library, Root)
            Root:Destroy()
        end

        return Widget
    end

    local function DeriveChartHost(Container)
        local Source = Dashboard.ChartHost
        if type(Source) ~= "table" or Source.Destroyed then
            return nil
        end
        local Meta = getmetatable(Source)
        if type(Meta) ~= "table" then
            return nil
        end
        return setmetatable({
            Container = Container,
            Elements = {},
            Tab = Source.Tab,
            Destroyed = false,
            Resize = function() end,
        }, Meta)
    end

    local function NextWidgetId(Prefix)
        Dashboard.WidgetSequence += 1
        return string.format("Dashboard/%s/%d", Prefix, Dashboard.WidgetSequence)
    end

    local ActiveFader
    local function ClearFader()
        local Fader = ActiveFader
        if not Fader then
            return
        end
        ActiveFader = nil
        Dashboard.Fading = false
        Library:CancelTween(Fader, "DashboardFade")
        if Holder.Parent == Fader then
            Holder.Parent = Fader.Parent
            Holder.Position = Fader.Position
        end
        Fader:Destroy()
    end

    local function BeginFade(FromTransparency)
        ClearFader()
        local Fader = Instance.new("CanvasGroup")
        Fader.Name = "DashboardFade"
        Fader.Active = false
        Fader.BackgroundTransparency = 1
        Fader.BorderSizePixel = 0
        Fader.ClipsDescendants = false
        Fader.Position = Holder.Position
        Fader.Size = Holder.Size
        Fader.ZIndex = Holder.ZIndex
        Fader.GroupTransparency = FromTransparency
        Fader.Parent = Holder.Parent
        Holder.Position = UDim2.fromOffset(0, 0)
        Holder.Parent = Fader
        ActiveFader = Fader
        Dashboard.Fading = true
        return Fader
    end

    local function UpdateSectionHeaders()
        for _, Section in Dashboard.Sections do
            if Section.Header then
                Section.Header.Visible = Section.HeaderRequested and Info.HideSectionHeaders ~= true
                    and not (Info.HideSingleSectionHeader and #Dashboard.Sections == 1)
            end
        end
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
        Root.BackgroundTransparency = Compact and 1 or 0
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
        Stroke.Transparency = Compact and 1 or Style.OutlineTransparency
        Stroke.Parent = Root
        Library:AddToRegistry(Stroke, { Color = "OutlineColor" })

        local RootLayout = Instance.new("UIListLayout")
        RootLayout.Padding = UDim.new(0, 0)
        RootLayout.SortOrder = Enum.SortOrder.LayoutOrder
        RootLayout.Parent = Root

        local SectionHeader = Instance.new("Frame")
        SectionHeader.BackgroundColor3 = Library.Scheme.RaisedColor
        SectionHeader.BackgroundTransparency = Compact and 1 or 0.46
        SectionHeader.LayoutOrder = 0
        SectionHeader.Size = UDim2.new(1, 0, 0, SectionInfo.ShowTitle == false and 0 or 32)
        SectionHeader.Visible = SectionInfo.ShowTitle ~= false
        SectionHeader.ZIndex = 43
        SectionHeader.Parent = Root
        Section.Header = SectionHeader
        Section.HeaderRequested = SectionInfo.ShowTitle ~= false and SectionInfo.ShowHeader ~= false
        SectionHeader.Visible = Section.HeaderRequested and Info.HideSectionHeaders ~= true
        Library:AddToRegistry(SectionHeader, { BackgroundColor3 = "RaisedColor" })

        local SectionIconData = Library:GetCustomIcon(SectionInfo.Icon or SectionInfo.IconName)
        if SectionIconData then
            local SectionIcon = Instance.new("ImageLabel")
            SectionIcon.BackgroundTransparency = 1
            SectionIcon.Image = SectionIconData.Url
            SectionIcon.ImageColor3 = Library.Scheme.AccentColor
            SectionIcon.ImageRectOffset = SectionIconData.ImageRectOffset
            SectionIcon.ImageRectSize = SectionIconData.ImageRectSize
            SectionIcon.Position = UDim2.fromOffset(Style.Padding, 8)
            SectionIcon.Size = UDim2.fromOffset(16, 16)
            SectionIcon.ZIndex = 44
            SectionIcon.Parent = SectionHeader
            Library:AddToRegistry(SectionIcon, { ImageColor3 = "AccentColor" })
        end

        local SectionTitle = Instance.new("TextLabel")
        SectionTitle.BackgroundTransparency = 1
        SectionTitle.FontFace = Library.Scheme.Font
        SectionTitle.Position = UDim2.fromOffset(SectionIconData and Style.Padding + 24 or Style.Padding, 0)
        SectionTitle.Size = UDim2.new(1, SectionIconData and -(Style.Padding * 2 + 24) or -Style.Padding * 2, 1, -1)
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
        SectionLine.BackgroundColor3 = Library.Scheme.OutlineColor
        SectionLine.BackgroundTransparency = type(Library.GetDesignToken) == "function" and Library:GetDesignToken("Opacity.Divider", 0.56) or 0.56
        SectionLine.BorderSizePixel = 0
        SectionLine.Position = UDim2.new(0, Style.Padding, 1, 0)
        SectionLine.Size = UDim2.new(1, -Style.Padding * 2, 0, 1)
        SectionLine.ZIndex = 44
        SectionLine.Parent = SectionHeader
        Library:AddToRegistry(SectionLine, { BackgroundColor3 = "OutlineColor" })

        local Body = Instance.new("Frame")
        Body.AutomaticSize = Enum.AutomaticSize.Y
        Body.BackgroundTransparency = 1
        Body.LayoutOrder = 1
        Body.Size = UDim2.new(1, 0, 0, 0)
        Body.ZIndex = 43
        Body.Parent = Root

        local BodyPadding = Instance.new("UIPadding")
        BodyPadding.PaddingBottom = UDim.new(0, Compact and 3 or Style.Padding)
        BodyPadding.PaddingLeft = UDim.new(0, Compact and 0 or Style.Padding + 1)
        BodyPadding.PaddingRight = UDim.new(0, Compact and 0 or Style.Padding + 1)
        BodyPadding.PaddingTop = UDim.new(0, Compact and 3 or Style.Padding)
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
                ValueLabel.Text = NormalizeText(MetricValue, MetricInfo.Fallback or "-")
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
            Widget:GiveConnection(Button.Activated:Connect(function()
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

        local function MakeHostWidget(Prefix, RowHeight, Order, Build)
            local Widget = {}
            local Row = Instance.new("Frame")
            Row.BackgroundTransparency = 1
            Row.ClipsDescendants = true
            Row.LayoutOrder = tonumber(Order) or Section:NextOrder()
            Row.Size = UDim2.new(1, 0, 0, RowHeight)
            Row.ZIndex = 43
            Row.Parent = Body

            local Host = DeriveChartHost(Row)
            local Control = Host and Build(Host, NextWidgetId(Prefix)) or nil
            if not Control then
                local Notice = Instance.new("TextLabel")
                Notice.BackgroundTransparency = 1
                Notice.FontFace = Library.Scheme.Font
                Notice.Size = UDim2.fromScale(1, 1)
                Notice.Text = "Chart unavailable"
                Notice.TextColor3 = Library.Scheme.MutedFontColor
                Notice.TextSize = 12
                Notice.TextTruncate = Enum.TextTruncate.AtEnd
                Notice.TextXAlignment = Enum.TextXAlignment.Left
                Notice.ZIndex = 44
                Notice.Parent = Row
                Library:AddToRegistry(Notice, { FontFace = "Font", TextColor3 = "MutedFontColor" })
                return AttachWidgetLifecycle(Section, Widget, Row), nil
            end
            Widget.Control = Control
            function Widget.OnDestroy()
                if type(Control.Destroy) == "function" then
                    pcall(Control.Destroy, Control)
                end
            end
            AttachWidgetLifecycle(Section, Widget, Row)
            return Widget, Control
        end

        function Section:AddChart(Value)
            local ChartInfo = type(Value) == "table" and Value or {}
            local RowHeight = math.floor(math.clamp(tonumber(ChartInfo.Height) or (Library.IsMobile and 120 or 100), 24, 480))
            local Widget, Control = MakeHostWidget("Chart", RowHeight, ChartInfo.Order, function(Host, Id)
                return Host:AddChart(Id, {
                    Kind = ChartInfo.Kind == "Bar" and "Bar" or "Line",
                    Height = RowHeight,
                    Capacity = ChartInfo.Capacity,
                    Color = ChartInfo.Color,
                    Min = ChartInfo.Min,
                    Max = ChartInfo.Max,
                    Thickness = ChartInfo.Thickness,
                    Values = type(ChartInfo.Values) == "table" and ChartInfo.Values or nil,
                })
            end)
            if not Control then
                return Widget
            end
            local function Apply(Sample)
                if type(Sample) == "table" then
                    Control:SetValues(Sample)
                elseif type(Sample) == "number" and Sample == Sample and math.abs(Sample) < math.huge then
                    Control:Push(Sample)
                end
            end
            function Widget:Push(Sample)
                UnregisterDynamic(Widget)
                Apply(Sample)
                return Widget
            end
            function Widget:SetValues(Values)
                UnregisterDynamic(Widget)
                if type(Values) == "table" then
                    Control:SetValues(Values)
                end
                return Widget
            end
            function Widget:SetProvider(Provider, Interval)
                RegisterDynamic(Widget, Provider, Interval or ChartInfo.Interval, Apply, ChartInfo.ErrorText)
                return Widget
            end
            local Provider = ChartInfo.Provider or ChartInfo.Value
            if type(Provider) == "function" then
                Widget:SetProvider(Provider, ChartInfo.Interval)
            end
            return Widget
        end

        function Section:AddBarChart(Value)
            local ChartInfo = type(Value) == "table" and table.clone(Value) or {}
            ChartInfo.Kind = "Bar"
            return Section:AddChart(ChartInfo)
        end

        function Section:AddSparkline(Value)
            local ChartInfo = type(Value) == "table" and table.clone(Value) or {}
            ChartInfo.Kind = "Line"
            ChartInfo.Height = math.floor(math.clamp(tonumber(ChartInfo.Height) or (Library.IsMobile and 44 or 34), 24, 120))
            ChartInfo.Thickness = tonumber(ChartInfo.Thickness) or 2
            return Section:AddChart(ChartInfo)
        end

        function Section:AddStat(Value)
            local StatInfo = type(Value) == "table" and Value or { Text = tostring(Value) }
            local RowHeight = math.floor(math.clamp(tonumber(StatInfo.Height) or (Library.IsMobile and 30 or 24), 18, 80))
            local Widget, Control = MakeHostWidget("Stat", RowHeight, StatInfo.Order, function(Host, Id)
                return Host:AddStatRow(Id, {
                    Text = StatInfo.Label or StatInfo.Text,
                    Value = "",
                    Height = RowHeight,
                    LabelRatio = StatInfo.LabelRatio,
                })
            end)
            if not Control then
                return Widget
            end
            local function Apply(StatValue)
                if type(StatInfo.Format) == "function" then
                    local Ok, Formatted = pcall(StatInfo.Format, StatValue, Widget, Dashboard)
                    if Ok then
                        StatValue = Formatted
                    end
                end
                Control:SetValue(NormalizeText(StatValue, StatInfo.Fallback or "-"))
            end
            function Widget:SetLabel(Text)
                Control:SetText(NormalizeText(Text, "Value"))
                return Widget
            end
            function Widget:SetValue(StatValue)
                UnregisterDynamic(Widget)
                Apply(StatValue)
                return Widget
            end
            function Widget:SetProvider(Provider, Interval)
                RegisterDynamic(Widget, Provider, Interval or StatInfo.Interval, Apply, StatInfo.ErrorText)
                return Widget
            end
            local Provider = StatInfo.Provider
            if Provider == nil then
                Provider = StatInfo.Value
            end
            if type(Provider) == "function" then
                Widget:SetProvider(Provider, StatInfo.Interval)
            elseif Provider ~= nil then
                Apply(Provider)
            end
            return Widget
        end

        function Section:AddProgress(Value)
            local ProgressInfo = type(Value) == "table" and Value or {}
            local RowHeight = math.floor(math.clamp(tonumber(ProgressInfo.Height) or (Library.IsMobile and 38 or 30), 22, 80))
            local Widget, Control = MakeHostWidget("Progress", RowHeight, ProgressInfo.Order, function(Host, Id)
                return Host:AddProgressBar(Id, {
                    Text = ProgressInfo.Label or ProgressInfo.Text,
                    Min = ProgressInfo.Min,
                    Max = ProgressInfo.Max,
                    Value = tonumber(ProgressInfo.Value),
                    Color = ProgressInfo.Color,
                    Height = RowHeight,
                    LabelRatio = ProgressInfo.LabelRatio,
                    ShowValue = ProgressInfo.ShowValue,
                })
            end)
            if not Control then
                return Widget
            end
            local function Apply(ProgressValue)
                local Number = tonumber(ProgressValue)
                if Number and Number == Number and math.abs(Number) < math.huge then
                    Control:SetValue(Number)
                end
            end
            function Widget:SetLabel(Text)
                Control:SetText(NormalizeText(Text, "Progress"))
                return Widget
            end
            function Widget:SetRange(Min, Max)
                Control:SetRange(Min, Max)
                return Widget
            end
            function Widget:SetValue(ProgressValue)
                UnregisterDynamic(Widget)
                Apply(ProgressValue)
                return Widget
            end
            function Widget:SetProvider(Provider, Interval)
                RegisterDynamic(Widget, Provider, Interval or ProgressInfo.Interval, Apply, ProgressInfo.ErrorText)
                return Widget
            end
            local Provider = ProgressInfo.Provider or ProgressInfo.Value
            if type(Provider) == "function" then
                Widget:SetProvider(Provider, ProgressInfo.Interval)
            end
            return Widget
        end

        function Section:AddLog(Value)
            local LogInfo = type(Value) == "table" and Value or {}
            local RowHeight = math.floor(math.clamp(tonumber(LogInfo.Height) or (Library.IsMobile and 160 or 120), 40, 480))
            local DefaultLevel = NormalizeText(LogInfo.Level, "Info")
            local Widget, Control = MakeHostWidget("Log", RowHeight, LogInfo.Order, function(Host, Id)
                return Host:AddLog(Id, {
                    Height = RowHeight,
                    Capacity = LogInfo.Capacity,
                    AutoScroll = LogInfo.AutoScroll,
                })
            end)
            if not Control then
                return Widget
            end
            local function AppendOne(Entry)
                if type(Entry) == "table" then
                    Control:Append(Entry.Level or DefaultLevel, Entry.Message or Entry.Text or "")
                elseif Entry ~= nil then
                    Control:Append(DefaultLevel, tostring(Entry))
                end
            end
            local function Apply(Sample)
                if Sample == nil then
                    return
                end
                if type(Sample) == "table" and Sample.Message == nil and Sample.Text == nil and Sample.Level == nil then
                    for _, Line in Sample do
                        AppendOne(Line)
                    end
                else
                    AppendOne(Sample)
                end
            end
            function Widget:Append(Level, Message)
                if Message == nil then
                    AppendOne(Level)
                else
                    Control:Append(NormalizeText(Level, DefaultLevel), NormalizeText(Message, ""))
                end
                return Widget
            end
            function Widget:Clear()
                Control:Clear()
                return Widget
            end
            function Widget:SetLevel(Level)
                Control:SetLevel(Level)
                return Widget
            end
            function Widget:SetProvider(Provider, Interval)
                RegisterDynamic(Widget, Provider, Interval or LogInfo.Interval, Apply, LogInfo.ErrorText)
                return Widget
            end
            local Provider = LogInfo.Provider or LogInfo.Value
            if type(Provider) == "function" then
                Widget:SetProvider(Provider, LogInfo.Interval)
            elseif type(LogInfo.Entries) == "table" then
                for _, Line in LogInfo.Entries do
                    AppendOne(Line)
                end
            end
            return Widget
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
            elseif Kind == "chart" or Kind == "line" or Kind == "linechart" then
                return Section:AddChart(Value)
            elseif Kind == "bar" or Kind == "barchart" then
                return Section:AddBarChart(Value)
            elseif Kind == "sparkline" or Kind == "spark" then
                return Section:AddSparkline(Value)
            elseif Kind == "statrow" or Kind == "staterow" then
                return Section:AddStat(Value)
            elseif Kind == "progress" or Kind == "progressbar" then
                return Section:AddProgress(Value)
            elseif Kind == "log" or Kind == "logs" then
                return Section:AddLog(Value)
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
                UpdateSectionHeaders()
            end
            if Dashboard.DefaultSection == Section then
                Dashboard.DefaultSection = nil
            end
            RemoveRegistryTree(Library, Root)
            Root:Destroy()
        end

        table.insert(Dashboard.Sections, Section)
        UpdateSectionHeaders()
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

    function Dashboard:AddChart(Value)
        return Dashboard:GetDefaultSection():AddChart(Value)
    end

    function Dashboard:AddBarChart(Value)
        return Dashboard:GetDefaultSection():AddBarChart(Value)
    end

    function Dashboard:AddSparkline(Value)
        return Dashboard:GetDefaultSection():AddSparkline(Value)
    end

    function Dashboard:AddStat(Value)
        return Dashboard:GetDefaultSection():AddStat(Value)
    end

    function Dashboard:AddProgress(Value)
        return Dashboard:GetDefaultSection():AddProgress(Value)
    end

    function Dashboard:AddLog(Value)
        return Dashboard:GetDefaultSection():AddLog(Value)
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
            if NewVisible and not Dashboard.Embedded then
                task.defer(ClampToViewport)
            end
            return Dashboard
        end
        Dashboard.Visible = NewVisible
        if Dashboard.Element and NewVisible then
            Dashboard.Element:SetVisible(true)
        end
        Dashboard.VisibilityRevision += 1
        local Revision = Dashboard.VisibilityRevision
        local Animate = Style.Motion ~= false and not Dashboard.Embedded and Library.Animations and Library.Animations.ToggleWindow
        if NewVisible then
            ClearFader()
            Holder.Visible = true
            if Animate then
                local Fader = BeginFade(1)
                local Tween = Library:PlayTween(Fader, "DashboardFade", Library:GetMotion("Fast"), {
                    GroupTransparency = 0,
                })
                if Tween then
                    Tween.Completed:Once(function()
                        if ActiveFader == Fader then
                            ClearFader()
                            task.defer(ClampToViewport)
                        end
                    end)
                else
                    ClearFader()
                end
            end
            if not Dashboard.Embedded then
                task.defer(ClampToViewport)
            end
            Dashboard:Refresh()
            ScheduleTick()
        elseif Animate then
            local Fader = BeginFade(0)
            local function Finish()
                ClearFader()
                if not Dashboard.Destroyed and not Dashboard.Visible and Dashboard.VisibilityRevision == Revision then
                    Holder.Visible = false
                    if Dashboard.Element then
                        Dashboard.Element:SetVisible(false)
                    end
                end
            end
            local Tween = Library:PlayTween(Fader, "DashboardFade", Library:GetMotion("Fast"), {
                GroupTransparency = 1,
            })
            if Tween then
                Tween.Completed:Once(function()
                    if ActiveFader == Fader then
                        Finish()
                    end
                end)
            else
                Finish()
            end
        else
            ClearFader()
            Holder.Visible = false
            if Dashboard.Element then
                Dashboard.Element:SetVisible(false)
            end
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
        if not Dashboard.Destroyed and not Dashboard.Embedded then
            Place(Value)
        end
        return Dashboard
    end

    function Dashboard:SetSize(Width, Height)
        if Dashboard.Destroyed then
            return Dashboard
        end
        Dashboard.Width = math.clamp(math.floor(tonumber(Width) or Dashboard.Width), 240, 620)
        Dashboard.Height = math.clamp(math.floor(tonumber(Height) or Dashboard.Height), Compact and 24 or 180, 760)
        Holder.Size = Dashboard.Embedded and UDim2.new(1, 0, 0, Dashboard.Height) or UDim2.fromOffset(Dashboard.Width, Dashboard.Height)
        if Dashboard.Element then
            Dashboard.Element:SetHeight(Dashboard.Height)
        elseif not Dashboard.Embedded then
            task.defer(ClampToViewport)
        end
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

    function Dashboard:GetContentHeight()
        return math.max(24, math.ceil((ContentLayout.AbsoluteContentSize and ContentLayout.AbsoluteContentSize.Y or 0) + (Compact and 0 or Style.Padding * 2)))
    end

    function Dashboard:SetHeight(Value)
        return Dashboard:SetSize(Dashboard.Width, Value)
    end

    function Dashboard:Destroy()
        if Dashboard.Destroyed then
            return
        end
        Dashboard.Destroyed = true
        ClearFader()
        Library:CancelTween(CloseButton, "DashboardCloseHover")
        Library:CancelTween(CloseIcon, "DashboardCloseIconHover")
        Dashboard.TickQueued = false
        if Dashboard.ToggleDisconnect then
            local Disconnect = Dashboard.ToggleDisconnect
            Dashboard.ToggleDisconnect = nil
            pcall(Disconnect)
        end
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
        if Dashboard.Element then
            local Element = Dashboard.Element
            Dashboard.Element = nil
            Element:Destroy()
        elseif Holder then
            Holder:Destroy()
        end
    end

    AddConnection(CloseButton.MouseEnter:Connect(function()
        if not Dashboard.Destroyed then
            Library:PlayTween(CloseButton, "DashboardCloseHover", Library.HoverTweenInfo or Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.HoverColor,
                BackgroundTransparency = 0,
            })
            Library:PlayTween(CloseIcon, "DashboardCloseIconHover", Library.HoverTweenInfo or Library.TweenInfo, {
                ImageColor3 = Library.Scheme.FontColor,
            })
        end
    end))
    AddConnection(CloseButton.MouseLeave:Connect(function()
        if not Dashboard.Destroyed then
            Library:PlayTween(CloseButton, "DashboardCloseHover", Library.HoverTweenInfo or Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.ElementColor,
                BackgroundTransparency = 1,
            })
            Library:PlayTween(CloseIcon, "DashboardCloseIconHover", Library.HoverTweenInfo or Library.TweenInfo, {
                ImageColor3 = Library.Scheme.MutedFontColor,
            })
        end
    end))
    AddConnection(CloseButton.Activated:Connect(function()
        Dashboard:SetVisible(false)
    end))

    if not Embedded and type(Library.MakeDraggable) == "function" then
        Library:MakeDraggable(Holder, Header, true, false, function()
            return Dashboard.Draggable and Dashboard.Visible and not Dashboard.Fading
        end)
    end

    if type(Library.On) == "function" then
        Dashboard.ToggleDisconnect = Library:On("Shown", function()
            ScheduleTick()
        end)
    end

    if not Embedded then
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
    end

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

function DashboardWindow.CreateEmbedded(Library, Groupbox, Idx, Info)
    assert(type(Groupbox) == "table" and type(Groupbox.AddUIPassthrough) == "function", "DashboardWindow requires a groupbox")
    Info = table.clone(Info or {})
    local Holder = Instance.new("Frame")
    Holder.BackgroundTransparency = 1
    Holder.Size = UDim2.new(1, 0, 0, tonumber(Info.Height) or 360)
    Info.Parent = Holder
    Info.ChartHost = Groupbox
    local Dashboard = DashboardWindow.Create(Library, Info)
    Dashboard.Root.Position = UDim2.fromScale(0, 0)
    Dashboard.Root.Size = UDim2.fromScale(1, 1)
    Dashboard.Embedded = true
    Dashboard.Element = Groupbox:AddUIPassthrough(Idx or "Dashboard", {
        Instance = Holder,
        Height = Dashboard.Height,
        Visible = Dashboard.Visible,
    })
    return Dashboard
end

function DashboardWindow.CreateStandalone(Library, Info)
    assert(Library and type(Library.CreateAddonWindow) == "function", "DashboardWindow standalone mode requires Library:CreateAddonWindow")
    Info = table.clone(Info or {})
    local Compact = Info.Compact ~= false
    local AutoHeight = Info.AutoHeight == true or (Info.AutoHeight == nil and Info.WindowHeight == nil and Info.Height == nil)
    local HostStyle = table.clone(type(Info.Style) == "table" and Info.Style or {})
    if Compact and HostStyle.Padding == nil then HostStyle.Padding = 6 end
    if Compact and HostStyle.Radius == nil then HostStyle.Radius = 1 end
    local WindowHeight = math.clamp(math.floor(tonumber(Info.WindowHeight) or 460), 220, 900)
    local Host = Library:CreateAddonWindow({
        Title = Info.WindowTitle or Info.Title or "Dashboard",
        Subtitle = Info.WindowSubtitle or Info.Subtitle,
        Icon = Info.WindowIcon or Info.Icon or "layout-dashboard",
        Width = Info.WindowWidth or 380,
        Height = WindowHeight,
        Position = Info.Position,
        AnchorPoint = Info.AnchorPoint,
        Draggable = Info.Draggable,
        Resizable = Info.Resizable,
        Closable = Info.Closable,
        HideWithMenu = Info.HideWithMenu,
        Visible = Info.Visible,
        Style = HostStyle,
        Compact = Compact,
        ShowIcon = Info.ShowIcon,
        ShowSubtitle = Info.ShowSubtitle,
    })

    Info.Title = nil
    Info.Subtitle = nil
    if Info.FitHeight == nil then
        Info.FitHeight = Info.Height == nil
    end
    Info.Height = Info.Height or math.max(180, WindowHeight - 74)
    Info.ShowHeader = false
    if Info.HideSectionHeaders == nil then Info.HideSingleSectionHeader = Compact end
    if AutoHeight then Info.FitHeight = false end

    local Dashboard = Host:AddAddon("Dashboard", DashboardWindow, Info)
    Dashboard.Host = Host
    if AutoHeight then
        local Resizing = false
        local function FitContent()
            if Resizing or Dashboard.Destroyed or Host.Destroyed then return end
            Resizing = true
            local Height = math.min(Dashboard:GetContentHeight(), math.max(24, tonumber(Info.MaxContentHeight) or 400))
            Host:SetModuleHeight("Dashboard", Height)
            Host:SetSize(Info.WindowWidth or 380, Height + Host.Content.Position.Y.Offset + (HostStyle.Padding or 10) * 2)
            Resizing = false
        end
        table.insert(Dashboard.Connections, Dashboard.ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(FitContent))
        FitContent()
    end
    return Dashboard, Host
end

DashboardWindow.Mount = DashboardWindow.CreateEmbedded

return DashboardWindow
