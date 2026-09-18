local MetricsPanel = {
    ReleaseVersion = "0.0.1-release-3",
}

local Dash = "-"

local function NormalizeText(Value, Fallback)
    if Value == nil then
        return Fallback or ""
    end
    return tostring(Value)
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

local function GroupInteger(Value)
    local Text = string.format("%d", Value)
    local Sign = ""
    if string.sub(Text, 1, 1) == "-" then
        Sign = "-"
        Text = string.sub(Text, 2)
    end
    local Grouped = Text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    Grouped = Grouped:gsub("^,", "")
    return Sign .. Grouped
end

local function UsableGroupboxMeta(Meta)
    return type(Meta) == "table"
        and type(Meta.__index) == "table"
        and type(Meta.__index.AddChart) == "function"
        and type(Meta.__index.AddStatRow) == "function"
end

local function ResolveGroupboxMeta(Library, Hint)
    if type(Hint) == "table" then
        local Meta = getmetatable(Hint)
        if UsableGroupboxMeta(Meta) then
            return Meta
        end
    end
    if UsableGroupboxMeta(MetricsPanel.GroupboxMeta) then
        return MetricsPanel.GroupboxMeta
    end
    for _, Tab in Library.Tabs or {} do
        if type(Tab) == "table" then
            local Meta = getmetatable(Tab)
            if UsableGroupboxMeta(Meta) then
                MetricsPanel.GroupboxMeta = Meta
                return Meta
            end
        end
    end
    return nil
end

local function ProbePing()
    local Ok, Players = pcall(game.GetService, game, "Players")
    if Ok and Players then
        local LocalPlayer = Players.LocalPlayer
        if LocalPlayer then
            local Success, Ping = pcall(function()
                return LocalPlayer:GetNetworkPing()
            end)
            if Success and type(Ping) == "number" and Ping >= 0 then
                return Ping * 1000
            end
        end
    end
    local Success, Value = pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if Success and type(Value) == "number" then
        return Value
    end
    return nil
end

local function ProbeMemory()
    local Success, Value = pcall(function()
        return game:GetService("Stats"):GetTotalMemoryUsageMb()
    end)
    if Success and type(Value) == "number" then
        return Value
    end
    return nil
end

local function ProbeInstances()
    local Success, Descendants = pcall(function()
        return game:GetDescendants()
    end)
    if Success and type(Descendants) == "table" then
        return #Descendants
    end
    return nil
end

local function GetReport(Panel)
    local Now = os.clock()
    if Panel.ReportCache and Now - Panel.ReportTime < 0.25 then
        return Panel.ReportCache
    end
    local Success, Report = pcall(function()
        return Panel.Library:Diagnose()
    end)
    if Success and type(Report) == "table" then
        Panel.ReportCache = Report
        Panel.ReportTime = Now
        return Report
    end
    return nil
end

local function FpsApply(Metric, Value)
    local Samples = Metric.Samples
    table.insert(Samples, Value)
    if #Samples > 120 then
        table.remove(Samples, 1)
    end
    if not Metric.ExtraRow then
        return
    end
    local Min, Max, Sum = math.huge, 0, 0
    for _, Sample in Samples do
        if Sample < Min then
            Min = Sample
        end
        if Sample > Max then
            Max = Sample
        end
        Sum += Sample
    end
    local Avg = Sum / math.max(1, #Samples)
    Metric.ExtraRow:SetValue(string.format(
        "%d / %d / %d",
        math.floor(Min + 0.5),
        math.floor(Avg + 0.5),
        math.floor(Max + 0.5)
    ))
end

local BuiltIn = {
    {
        Id = "fps",
        Label = "FPS",
        Section = "Performance",
        Interval = 0.5,
        Sparkline = true,
        ExtraLabel = "min / avg / max",
        OnApply = FpsApply,
        Get = function(Panel)
            if Panel.SmoothDelta <= 0 then
                return nil
            end
            return 1 / Panel.SmoothDelta
        end,
        Format = function(Value)
            return string.format("%d", math.floor(Value + 0.5))
        end,
    },
    {
        Id = "frametime",
        Label = "Frame time",
        Section = "Performance",
        Interval = 0.5,
        Get = function(Panel)
            if Panel.SmoothDelta <= 0 then
                return nil
            end
            return Panel.SmoothDelta * 1000
        end,
        Format = function(Value)
            return string.format("%.1f ms", Value)
        end,
    },
    {
        Id = "ping",
        Label = "Ping",
        Section = "Performance",
        Interval = 1,
        Get = function()
            return ProbePing()
        end,
        Format = function(Value)
            return string.format("%d ms", math.floor(Value + 0.5))
        end,
    },
    {
        Id = "memory",
        Label = "Memory",
        Section = "Memory",
        Interval = 1,
        Get = function()
            return ProbeMemory()
        end,
        Format = function(Value)
            if Value >= 1024 then
                return string.format("%.2f GB", Value / 1024)
            end
            return string.format("%.0f MB", Value)
        end,
    },
    {
        Id = "instances",
        Label = "Instances",
        Section = "Memory",
        Interval = 5,
        Get = function()
            return ProbeInstances()
        end,
        Format = function(Value)
            return GroupInteger(Value)
        end,
    },
    {
        Id = "connections",
        Label = "Connections",
        Section = "Library",
        Interval = 1,
        Get = function(Panel)
            local Report = GetReport(Panel)
            return Report and Report.Connections or nil
        end,
        Format = function(Value)
            return GroupInteger(Value)
        end,
    },
    {
        Id = "tweens",
        Label = "Tweens",
        Section = "Library",
        Interval = 1,
        Get = function(Panel)
            local Report = GetReport(Panel)
            return Report and Report.Tweens or nil
        end,
        Format = function(Value)
            return GroupInteger(Value)
        end,
    },
    {
        Id = "uiinstances",
        Label = "UI instances",
        Section = "Library",
        Interval = 1,
        Get = function(Panel)
            local Report = GetReport(Panel)
            return Report and Report.Instances or nil
        end,
        Format = function(Value)
            return GroupInteger(Value)
        end,
    },
    {
        Id = "queued",
        Label = "Queued builds",
        Section = "Library",
        Interval = 1,
        Get = function(Panel)
            local Report = GetReport(Panel)
            return Report and Report.PendingBuilds or nil
        end,
        Format = function(Value)
            return GroupInteger(Value)
        end,
    },
}

local BuiltInById = {}
for _, Descriptor in BuiltIn do
    BuiltInById[Descriptor.Id] = Descriptor
end

function MetricsPanel.Create(Library, Info)
    assert(Library and type(Library.AddToRegistry) == "function", "MetricsPanel requires an active MonHub library")
    Info = Info or {}
    local Style = Library:GetAddonStyle(Info.Style)
    local Embedded = typeof(Info.Parent) == "Instance" and Info.Parent:IsA("GuiObject")
    local Meta = ResolveGroupboxMeta(Library, Info.ChartHost)

    local Padding = Style.Padding
    local Gap = Style.Gap
    local RowHeight = Library:Metric("Row", Library.IsMobile and 44 or 24)
    local ControlGap = Library:Metric("ControlGap", 6)
    local ChartHeight = Library:Snap(Library.IsMobile and 56 or 46)
    local Height = math.clamp(math.floor(tonumber(Info.Height) or 320), 120, 900)

    local Panel = {
        Library = Library,
        Destroyed = false,
        Visible = Info.Visible ~= false,
        Embedded = Embedded,
        Meta = Meta,
        Style = Style,
        RowHeight = RowHeight,
        ControlGap = ControlGap,
        ChartHeight = ChartHeight,
        Height = Height,
        Sections = {},
        SectionOrder = 0,
        Metrics = {},
        Connections = {},
        TickKey = {},
        TickQueued = false,
        SmoothDelta = 0,
        LastTick = 0,
        Sequence = 0,
        Element = nil,
        Host = nil,
    }

    local Root = Instance.new("Frame")
    Root.Name = "MonHubMetricsPanel"
    Root.BackgroundTransparency = 1
    Root.BorderSizePixel = 0
    Root.Size = Embedded and UDim2.new(1, 0, 0, Height) or UDim2.fromScale(1, 1)
    Root.Visible = Panel.Visible
    Root.Parent = Embedded and Info.Parent or Library.ScreenGui
    Panel.Root = Root

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Name = "Content"
    Scroll.Active = true
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.CanvasSize = UDim2.fromScale(0, 0)
    Scroll.ScrollBarImageColor3 = Library.Scheme.AccentColor
    Scroll.ScrollBarImageTransparency = 0.4
    Scroll.ScrollBarThickness = 2
    Scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    Scroll.Size = UDim2.fromScale(1, 1)
    Scroll.Parent = Root
    Panel.Scroll = Scroll
    Library:AddToRegistry(Scroll, { ScrollBarImageColor3 = "AccentColor" })

    local ScrollPadding = Instance.new("UIPadding")
    ScrollPadding.PaddingBottom = UDim.new(0, Padding)
    ScrollPadding.PaddingLeft = UDim.new(0, Padding)
    ScrollPadding.PaddingRight = UDim.new(0, Padding + 2)
    ScrollPadding.PaddingTop = UDim.new(0, Padding)
    ScrollPadding.Parent = Scroll

    local ScrollLayout = Instance.new("UIListLayout")
    ScrollLayout.Padding = UDim.new(0, Gap)
    ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ScrollLayout.Parent = Scroll
    Panel.ScrollLayout = ScrollLayout

    local function NextId(Kind)
        Panel.Sequence += 1
        return string.format("MetricsPanel/%s/%d", Kind, Panel.Sequence)
    end

    local function IsActive()
        return not Panel.Destroyed and Panel.Visible and Library.Toggled ~= false and Root.Parent ~= nil
    end
    Panel.IsActive = IsActive

    local ScheduleTick
    local function RunTick()
        Panel.TickQueued = false
        if not IsActive() then
            return
        end

        local Now = os.clock()
        local Delta = Now - Panel.LastTick
        Panel.LastTick = Now
        if Delta > 0 and Delta < 0.5 then
            if Panel.SmoothDelta <= 0 then
                Panel.SmoothDelta = Delta
            else
                Panel.SmoothDelta = Panel.SmoothDelta * 0.9 + Delta * 0.1
            end
        end

        for _, Metric in Panel.Metrics do
            if Now >= Metric.NextUpdate then
                Metric.NextUpdate = Now + Metric.Interval
                local Success, Value = pcall(Metric.Get, Panel)
                if Success and type(Value) == "number" and Value == Value and math.abs(Value) < math.huge then
                    if Metric.Row then
                        local Text = tostring(Value)
                        if Metric.Format then
                            local Ok, Formatted = pcall(Metric.Format, Value)
                            if Ok then
                                Text = tostring(Formatted)
                            end
                        end
                        Metric.Row:SetValue(Text)
                    end
                    if Metric.Chart then
                        Metric.Chart:Push(Value)
                    end
                    if Metric.OnApply then
                        pcall(Metric.OnApply, Metric, Value)
                    end
                else
                    if Metric.Row then
                        Metric.Row:SetValue(Dash)
                    end
                    if Metric.ExtraRow then
                        Metric.ExtraRow:SetValue(Dash)
                    end
                end
            end
        end

        ScheduleTick()
    end

    function ScheduleTick()
        if Panel.TickQueued or not IsActive() or next(Panel.Metrics) == nil then
            return
        end
        Panel.TickQueued = true
        Library:QueueFrame(Panel.TickKey, RunTick)
    end
    Panel.ScheduleTick = ScheduleTick

    local function GetSection(Name)
        local Existing = Panel.Sections[Name]
        if Existing then
            return Existing
        end

        Panel.SectionOrder += 1
        local Frame = Instance.new("Frame")
        Frame.Name = "Section"
        Frame.AutomaticSize = Enum.AutomaticSize.Y
        Frame.BackgroundTransparency = 1
        Frame.BorderSizePixel = 0
        Frame.LayoutOrder = Panel.SectionOrder
        Frame.Size = UDim2.new(1, 0, 0, 0)
        Frame.Parent = Scroll

        local FrameLayout = Instance.new("UIListLayout")
        FrameLayout.Padding = UDim.new(0, math.max(2, ControlGap - 2))
        FrameLayout.SortOrder = Enum.SortOrder.LayoutOrder
        FrameLayout.Parent = Frame

        local Header = Instance.new("TextLabel")
        Header.Name = "Header"
        Header.BackgroundTransparency = 1
        Header.FontFace = Library.Scheme.Font
        Header.LayoutOrder = 0
        Header.Size = UDim2.new(1, 0, 0, 18)
        Header.Text = NormalizeText(Name, "Section")
        Header.TextColor3 = Library.Scheme.MutedFontColor
        Header.TextSize = Style.CaptionSize
        Header.TextTruncate = Enum.TextTruncate.AtEnd
        Header.TextXAlignment = Enum.TextXAlignment.Left
        Header.Parent = Frame
        Library:AddToRegistry(Header, { FontFace = "Font", TextColor3 = "MutedFontColor" })

        local Divider = Instance.new("Frame")
        Divider.Name = "Divider"
        Divider.BackgroundColor3 = Library.Scheme.OutlineColor
        Divider.BackgroundTransparency = Library:GetDesignToken("Opacity.Divider", 0.56)
        Divider.BorderSizePixel = 0
        Divider.LayoutOrder = 1
        Divider.Size = UDim2.new(1, 0, 0, 1)
        Divider.Parent = Frame
        Library:AddToRegistry(Divider, { BackgroundColor3 = "OutlineColor" })

        local Body = Instance.new("Frame")
        Body.Name = "Body"
        Body.AutomaticSize = Enum.AutomaticSize.Y
        Body.BackgroundTransparency = 1
        Body.BorderSizePixel = 0
        Body.LayoutOrder = 2
        Body.Size = UDim2.new(1, 0, 0, 0)
        Body.Parent = Frame

        local BodyLayout = Instance.new("UIListLayout")
        BodyLayout.Padding = UDim.new(0, ControlGap)
        BodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
        BodyLayout.Parent = Body

        local Section = {
            Name = Name,
            Frame = Frame,
            Body = Body,
            Order = 0,
            Host = Meta and setmetatable({
                Container = Body,
                Elements = {},
                Tab = type(Info.ChartHost) == "table" and Info.ChartHost.Tab or nil,
                Destroyed = false,
                Resize = function() end,
            }, Meta) or nil,
        }
        Panel.Sections[Name] = Section
        return Section
    end

    local function PlaceControl(Section, Control)
        Section.Order += 1
        if Control and Control.Holder then
            Control.Holder.LayoutOrder = Section.Order
        end
    end

    local function BuildMetric(Descriptor, Options)
        Options = Options or {}
        local SectionName = Options.Section or Descriptor.Section or "Metrics"
        local Section = GetSection(SectionName)
        if not Section.Host then
            return nil
        end

        local Metric = {
            Id = Descriptor.Id,
            Interval = math.clamp(tonumber(Options.Interval or Descriptor.Interval) or 1, 0.1, 60),
            NextUpdate = 0,
            Get = Descriptor.Get,
            Format = Descriptor.Format,
            OnApply = Descriptor.OnApply,
            Samples = {},
        }

        local WantSparkline = Options.Sparkline
        if WantSparkline == nil then
            WantSparkline = Descriptor.Sparkline == true
        end
        if WantSparkline then
            Metric.Chart = Section.Host:AddChart(NextId("Chart"), {
                Kind = "Line",
                Height = ChartHeight,
                Capacity = 120,
                Thickness = 2,
                Color = Options.Color or Descriptor.Color,
            })
            PlaceControl(Section, Metric.Chart)
        end

        Metric.Row = Section.Host:AddStatRow(NextId("Stat"), {
            Text = Options.Label or Descriptor.Label or Descriptor.Id,
            Value = Dash,
            Height = RowHeight,
        })
        PlaceControl(Section, Metric.Row)

        local ExtraLabel = Options.ExtraLabel or Descriptor.ExtraLabel
        if ExtraLabel then
            Metric.ExtraRow = Section.Host:AddStatRow(NextId("Stat"), {
                Text = ExtraLabel,
                Value = Dash,
                Height = RowHeight,
            })
            PlaceControl(Section, Metric.ExtraRow)
        end

        table.insert(Panel.Metrics, Metric)
        return Metric
    end

    local Requested = Info.Metrics
    if type(Requested) ~= "table" then
        Requested = nil
    end

    if Requested then
        for _, Entry in Requested do
            local Descriptor = BuiltInById[string.lower(tostring(Entry))]
            if Descriptor then
                BuildMetric(Descriptor)
            end
        end
    else
        for _, Descriptor in BuiltIn do
            BuildMetric(Descriptor)
        end
    end

    if not Meta then
        local Notice = Instance.new("TextLabel")
        Notice.Name = "Notice"
        Notice.BackgroundTransparency = 1
        Notice.FontFace = Library.Scheme.Font
        Notice.LayoutOrder = 999
        Notice.Size = UDim2.new(1, 0, 0, RowHeight)
        Notice.Text = "Metrics unavailable"
        Notice.TextColor3 = Library.Scheme.MutedFontColor
        Notice.TextSize = Style.CaptionSize
        Notice.TextXAlignment = Enum.TextXAlignment.Left
        Notice.Parent = Scroll
        Library:AddToRegistry(Notice, { FontFace = "Font", TextColor3 = "MutedFontColor" })
    end

    function Panel:AddMetric(Name, MetricInfo)
        assert(not Panel.Destroyed, "MetricsPanel is destroyed")
        MetricInfo = MetricInfo or {}
        assert(type(MetricInfo.Get) == "function", "AddMetric requires a Get function")
        local Descriptor = {
            Id = tostring(Name),
            Label = MetricInfo.Label or tostring(Name),
            Section = MetricInfo.Section or "Custom",
            Interval = MetricInfo.Interval,
            Sparkline = MetricInfo.Sparkline,
            ExtraLabel = MetricInfo.ExtraLabel,
            Color = MetricInfo.Color,
            Get = MetricInfo.Get,
            Format = MetricInfo.Format,
            OnApply = MetricInfo.OnApply,
        }
        local Metric = BuildMetric(Descriptor, Descriptor)
        ScheduleTick()
        return Metric
    end

    function Panel:GetContentHeight()
        local Size = ScrollLayout.AbsoluteContentSize
        return math.max(RowHeight, math.ceil((Size and Size.Y or 0) + Padding * 2))
    end

    function Panel:SetVisible(Value)
        if Panel.Destroyed then
            return Panel
        end
        Panel.Visible = Value == true
        Root.Visible = Panel.Visible
        if Panel.Element then
            Panel.Element:SetVisible(Panel.Visible)
        end
        if Panel.Visible then
            Panel.LastTick = os.clock()
            ScheduleTick()
        end
        return Panel
    end

    function Panel:Toggle()
        return Panel:SetVisible(not Panel.Visible)
    end

    function Panel:Refresh()
        if Panel.Destroyed then
            return Panel
        end
        for _, Metric in Panel.Metrics do
            Metric.NextUpdate = 0
        end
        ScheduleTick()
        return Panel
    end

    function Panel:Destroy()
        if Panel.Destroyed then
            return
        end
        Panel.Destroyed = true
        Panel.TickQueued = false
        for _, Connection in Panel.Connections do
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end
        table.clear(Panel.Connections)
        if Panel.ToggleDisconnect then
            local Disconnect = Panel.ToggleDisconnect
            Panel.ToggleDisconnect = nil
            pcall(Disconnect)
        end
        for _, Metric in Panel.Metrics do
            if Metric.Chart and type(Metric.Chart.Destroy) == "function" then
                pcall(Metric.Chart.Destroy, Metric.Chart)
            end
            if Metric.Row and type(Metric.Row.Destroy) == "function" then
                pcall(Metric.Row.Destroy, Metric.Row)
            end
            if Metric.ExtraRow and type(Metric.ExtraRow.Destroy) == "function" then
                pcall(Metric.ExtraRow.Destroy, Metric.ExtraRow)
            end
        end
        table.clear(Panel.Metrics)
        table.clear(Panel.Sections)
        RemoveRegistryTree(Library, Root)
        if Panel.Element then
            local Element = Panel.Element
            Panel.Element = nil
            Element:Destroy()
        else
            Root:Destroy()
        end
    end

    if type(Library.On) == "function" then
        Panel.ToggleDisconnect = Library:On("Shown", function()
            Panel.LastTick = os.clock()
            ScheduleTick()
        end)
    end

    if type(Library.OnUnload) == "function" then
        Library:OnUnload(function()
            Panel:Destroy()
        end)
    end

    Panel.LastTick = os.clock()
    ScheduleTick()
    return Panel
end

function MetricsPanel.CreateEmbedded(Library, Groupbox, Idx, Info)
    assert(type(Groupbox) == "table" and type(Groupbox.AddUIPassthrough) == "function", "MetricsPanel requires a groupbox")
    Info = table.clone(Info or {})
    local Holder = Instance.new("Frame")
    Holder.BackgroundTransparency = 1
    Holder.Size = UDim2.new(1, 0, 0, math.floor(tonumber(Info.Height) or 320))
    Info.Parent = Holder
    Info.ChartHost = Groupbox
    local Panel = MetricsPanel.Create(Library, Info)
    Panel.Root.Position = UDim2.fromScale(0, 0)
    Panel.Root.Size = UDim2.fromScale(1, 1)
    Panel.Embedded = true
    Panel.Element = Groupbox:AddUIPassthrough(Idx or "Metrics", {
        Instance = Holder,
        Height = Panel.Height,
        Visible = Panel.Visible,
    })
    return Panel
end

function MetricsPanel.CreateStandalone(Library, Info)
    assert(Library and type(Library.CreateAddonWindow) == "function", "MetricsPanel standalone mode requires Library:CreateAddonWindow")
    Info = table.clone(Info or {})
    local WindowHeight = math.clamp(math.floor(tonumber(Info.WindowHeight) or 460), 220, 900)
    local AutoHeight = Info.AutoHeight ~= false and Info.Height == nil
    local Host = Library:CreateAddonWindow({
        Title = Info.WindowTitle or Info.Title or "Metrics",
        Subtitle = Info.WindowSubtitle or Info.Subtitle,
        Icon = Info.WindowIcon or Info.Icon or "activity",
        Width = Info.WindowWidth or 320,
        Height = WindowHeight,
        Position = Info.Position,
        AnchorPoint = Info.AnchorPoint,
        Draggable = Info.Draggable,
        Resizable = Info.Resizable,
        Closable = Info.Closable,
        HideWithMenu = Info.HideWithMenu,
        Visible = Info.Visible,
        Style = Info.Style,
        ShowHeader = false,
    })

    Info.Title = nil
    Info.Subtitle = nil
    Info.Height = Info.Height or math.max(120, WindowHeight - 24)
    Info.FitHeight = AutoHeight
    Info.ShowHeader = false

    local Panel = Host:AddAddon("Metrics", MetricsPanel, Info)
    Panel.Host = Host

    if AutoHeight then
        local Resizing = false
        local MaxHeight = math.max(120, tonumber(Info.MaxContentHeight) or 420)
        local function FitContent()
            if Resizing or Panel.Destroyed or Host.Destroyed then
                return
            end
            Resizing = true
            local ContentHeight = math.min(Panel:GetContentHeight(), MaxHeight)
            Host:SetModuleHeight("Metrics", ContentHeight)
            Host:SetSize(Info.WindowWidth or 320, ContentHeight + Host.Content.Position.Y.Offset + Host.Style.Padding * 2)
            Resizing = false
        end
        table.insert(Panel.Connections, Panel.ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(FitContent))
        FitContent()
    end

    return Panel, Host
end

MetricsPanel.Mount = MetricsPanel.CreateEmbedded

return MetricsPanel
