local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Environment = if type(getfenv) == "function" then getfenv() else _G
local DrawingAPI = if type(Environment) == "table" then rawget(Environment, "Drawing") else nil
if type(DrawingAPI) ~= "table" then
    DrawingAPI = rawget(_G, "Drawing")
end

local UniversalESP = {
    Version = "1.1.0",
    Available = type(DrawingAPI) == "table" and type(DrawingAPI.new) == "function",
}

local Defaults = {
    Enabled = false,
    Players = true,
    NPCs = true,
    Parts = true,
    IncludeLocalPlayer = false,
    AliveCheck = true,
    TeamCheck = false,
    TeamColors = false,
    VisibilityCheck = false,
    VisibilityInterval = 0.12,
    OcclusionMode = "Fade",
    MaxDistance = 2500,
    TextDistance = 600,
    MaxRendered = 0,
    SortMode = "Distance",
    FilterMode = "All",
    FilterMatch = "Exact",
    FilterList = {},
    DistanceUnit = "Studs",
    DistanceScale = 1,
    UpdateRate = 60,
    TextUpdateRate = 8,
    Fade = {
        Enabled = false,
        Start = 0.65,
        Minimum = 0.3,
        OccludedMultiplier = 0.55,
    },
    Box = {
        Enabled = true,
        Style = "Corner",
        Dynamic = true,
        Scale = 1,
        ScaleX = 1,
        ScaleY = 1,
        PaddingX = 0,
        PaddingY = 0,
        Thickness = 1,
        Transparency = 1,
        Outline = true,
        OutlineThickness = 3,
        Fill = false,
        FillTransparency = 0.12,
        Gradient = true,
        Rainbow = false,
        RainbowSpeed = 0.12,
        CornerWidth = 0.28,
        CornerHeight = 0.22,
        MinimumSize = 2,
        MaximumSize = 2000,
    },
    Text = {
        Name = true,
        DisplayName = true,
        Team = false,
        Distance = true,
        Tool = true,
        Health = false,
        Category = false,
        Flags = true,
        Size = 13,
        MinimumSize = 8,
        MaximumSize = 32,
        RelativeSize = true,
        Outline = true,
        Font = "Plex",
        NameCase = "Normal",
        MaxNameLength = 32,
        DistanceDecimals = 0,
        TopOffset = 2,
        BottomOffset = 2,
        Spacing = 1,
        TeamBrackets = true,
        ToolBrackets = false,
    },
    HealthBar = {
        Enabled = true,
        Position = "Left",
        Width = 2,
        Offset = 5,
        Outline = true,
        Text = false,
        Transparency = 1,
        BackgroundTransparency = 0.92,
        ColorMode = "Health",
    },
    Tracer = {
        Enabled = false,
        Origin = "Bottom",
        Target = "Bottom",
        Thickness = 1,
        Transparency = 1,
        Outline = true,
        ColorMode = "Custom",
        OriginX = 0.5,
        OriginY = 1,
        TargetOffsetX = 0,
        TargetOffsetY = 0,
        StartPadding = 0,
        EndPadding = 0,
    },
    Skeleton = {
        Enabled = false,
        Thickness = 1,
        Transparency = 1,
        Outline = true,
        MaxJoints = 24,
        ColorMode = "Custom",
    },
    HeadDot = {
        Enabled = false,
        Filled = false,
        Radius = 3,
        Sides = 20,
        Thickness = 1,
        Transparency = 1,
        Outline = true,
        ScaleWithDistance = false,
        MinimumRadius = 2,
        MaximumRadius = 10,
        ColorMode = "Custom",
    },
    OffscreenArrow = {
        Enabled = false,
        Radius = 190,
        Size = 12,
        Filled = true,
        Transparency = 1,
        Outline = true,
        Pulse = false,
        PulseSpeed = 2,
        ShowName = false,
        ShowDistance = true,
        TextSize = 12,
        ColorMode = "Custom",
    },
    Highlight = {
        Enabled = false,
        FillTransparency = 0.72,
        OutlineTransparency = 0.08,
        DepthMode = "AlwaysOnTop",
        HealthColor = false,
        ColorMode = "Custom",
    },
    Crosshair = {
        Enabled = false,
        Position = "Center",
        Size = 8,
        Gap = 5,
        Thickness = 1,
        Transparency = 1,
        Outline = true,
        TStyle = false,
        Rotate = false,
        RotationSpeed = 90,
        Pulse = false,
        PulseSpeed = 2,
        PulseMinimum = 3,
        PulseMaximum = 9,
        CenterDot = true,
        CenterDotRadius = 2,
        CenterDotFilled = true,
    },
    Colors = {
        Mode = "Entity",
        Enemy = Color3.fromRGB(126, 171, 216),
        Gradient = Color3.fromRGB(198, 215, 235),
        Tracer = Color3.fromRGB(126, 171, 216),
        Skeleton = Color3.fromRGB(222, 232, 244),
        HeadDot = Color3.fromRGB(198, 215, 235),
        Arrow = Color3.fromRGB(126, 171, 216),
        Team = Color3.fromRGB(118, 190, 155),
        NPC = Color3.fromRGB(229, 184, 104),
        Part = Color3.fromRGB(185, 151, 229),
        Visible = Color3.fromRGB(128, 210, 168),
        Occluded = Color3.fromRGB(210, 126, 132),
        Outline = Color3.fromRGB(5, 7, 10),
        Text = Color3.fromRGB(235, 239, 244),
        HealthLow = Color3.fromRGB(225, 83, 91),
        HealthHigh = Color3.fromRGB(101, 218, 140),
        HighlightFill = Color3.fromRGB(126, 171, 216),
        HighlightOutline = Color3.fromRGB(222, 232, 244),
        Crosshair = Color3.fromRGB(198, 215, 235),
    },
}

UniversalESP.Defaults = Defaults

local BoxEdges = {
    { 1, 2 },
    { 2, 3 },
    { 3, 4 },
    { 4, 1 },
}

local CubeEdges = {
    { 1, 2 },
    { 2, 3 },
    { 3, 4 },
    { 4, 1 },
    { 5, 6 },
    { 6, 7 },
    { 7, 8 },
    { 8, 5 },
    { 1, 5 },
    { 2, 6 },
    { 3, 7 },
    { 4, 8 },
}

local function DeepCopy(Value, Seen)
    if type(Value) ~= "table" then
        return Value
    end
    Seen = Seen or {}
    if Seen[Value] then
        return Seen[Value]
    end
    local Result = {}
    Seen[Value] = Result
    for Key, Item in Value do
        Result[DeepCopy(Key, Seen)] = DeepCopy(Item, Seen)
    end
    return Result
end

local function Merge(Target, Source)
    if type(Source) ~= "table" then
        return Target
    end
    for Key, Value in Source do
        if type(Value) == "table" and type(Target[Key]) == "table" and typeof(Value) ~= "Color3" then
            Merge(Target[Key], Value)
        else
            Target[Key] = Value
        end
    end
    return Target
end

local function ClampNumber(Value, Default, Minimum, Maximum)
    Value = tonumber(Value)
    if not Value then
        return Default
    end
    return math.clamp(Value, Minimum, Maximum)
end

local function NewDrawing(Type)
    if not UniversalESP.Available then
        return nil
    end
    local Success, Object = pcall(DrawingAPI.new, Type)
    if not Success then
        return nil
    end
    pcall(function()
        Object.Visible = false
    end)
    return Object
end

local function RemoveDrawing(Object)
    if not Object then
        return
    end
    pcall(function()
        if type(Object.Remove) == "function" then
            Object:Remove()
        elseif type(Object.Destroy) == "function" then
            Object:Destroy()
        end
    end)
end

local function SetVisible(Object, Visible)
    if Object then
        Object.Visible = Visible == true
    end
end

local function ResolveDrawingFont(Name)
    local Fonts = type(DrawingAPI) == "table" and DrawingAPI.Fonts or nil
    if type(Fonts) == "table" then
        return Fonts[Name] or Fonts.Plex or Fonts.UI or 2
    end
    local Values = {
        UI = 0,
        System = 1,
        Plex = 2,
        Monospace = 3,
    }
    return Values[Name] or 2
end

local function IsDescendantOf(Object, Parent)
    return Object and Parent and Object:IsDescendantOf(Parent)
end

local function GetRoot(Model)
    if not Model then
        return nil
    end
    if Model:IsA("BasePart") then
        return Model
    end
    if not Model:IsA("Model") then
        return nil
    end
    return Model:FindFirstChild("HumanoidRootPart")
        or Model.PrimaryPart
        or Model:FindFirstChild("UpperTorso")
        or Model:FindFirstChild("Torso")
        or Model:FindFirstChild("Head")
        or Model:FindFirstChildWhichIsA("BasePart")
end

local function GetHumanoid(Model)
    return Model and Model:IsA("Model") and Model:FindFirstChildOfClass("Humanoid") or nil
end

local function GetTool(Model)
    if not Model or not Model:IsA("Model") then
        return ""
    end
    local Tool = Model:FindFirstChildOfClass("Tool")
    return Tool and Tool.Name or ""
end

local function GetPlayerFromObject(Object)
    if typeof(Object) ~= "Instance" then
        return nil
    end
    if Object:IsA("Player") then
        return Object
    end
    if Object:IsA("Model") then
        return Players:GetPlayerFromCharacter(Object)
    end
    local Model = Object:FindFirstAncestorOfClass("Model")
    return Model and Players:GetPlayerFromCharacter(Model) or nil
end

local function ResolveModel(Object)
    if typeof(Object) ~= "Instance" then
        return nil
    end
    if Object:IsA("Player") then
        return Object.Character
    end
    if Object:IsA("Model") or Object:IsA("BasePart") then
        return Object
    end
    return Object:FindFirstAncestorOfClass("Model")
end

local function GetObjectName(Object, Model, Player, Info, DisplayName)
    if type(Info.Name) == "function" then
        local Success, Result = pcall(Info.Name, Object, Model, Player)
        if Success and Result ~= nil then
            return tostring(Result)
        end
    elseif Info.Name ~= nil then
        return tostring(Info.Name)
    end
    if Player then
        return DisplayName and Player.DisplayName or Player.Name
    end
    return Model and Model.Name or Object.Name
end

local function ResolveFlags(Info, Object, Model, Player)
    local Flags = Info.Flags
    if type(Flags) == "function" then
        local Success, Result = pcall(Flags, Object, Model, Player)
        if Success then
            Flags = Result
        else
            Flags = nil
        end
    end
    if type(Flags) == "table" then
        local Output = {}
        for _, Value in Flags do
            if Value ~= nil and tostring(Value) ~= "" then
                table.insert(Output, tostring(Value))
            end
        end
        return table.concat(Output, " ")
    end
    return Flags and tostring(Flags) or ""
end

local function ResolveTeam(Player, Info)
    if Info.Team ~= nil then
        if type(Info.Team) == "function" then
            local Success, Result = pcall(Info.Team, Player)
            return Success and tostring(Result or "") or ""
        end
        return tostring(Info.Team)
    end
    if not Player then
        return ""
    end
    return Player.Team and Player.Team.Name or Player.TeamColor.Name
end

local function CreateLineSet(Count)
    local Lines = {}
    local Outlines = {}
    for Index = 1, Count do
        Lines[Index] = NewDrawing("Line")
        Outlines[Index] = NewDrawing("Line")
    end
    return Lines, Outlines
end

local function CreateVisual(MaxJoints)
    local Box, BoxOutline = CreateLineSet(12)
    local Skeleton, SkeletonOutline = CreateLineSet(MaxJoints)
    return {
        Box = Box,
        BoxOutline = BoxOutline,
        Skeleton = Skeleton,
        SkeletonOutline = SkeletonOutline,
        Fill = NewDrawing("Square"),
        Name = NewDrawing("Text"),
        Team = NewDrawing("Text"),
        Distance = NewDrawing("Text"),
        Tool = NewDrawing("Text"),
        HealthText = NewDrawing("Text"),
        HealthValue = NewDrawing("Text"),
        Category = NewDrawing("Text"),
        Flags = NewDrawing("Text"),
        HealthBack = NewDrawing("Line"),
        HealthFill = NewDrawing("Line"),
        Tracer = NewDrawing("Line"),
        TracerOutline = NewDrawing("Line"),
        HeadDot = NewDrawing("Circle"),
        HeadDotOutline = NewDrawing("Circle"),
        Arrow = NewDrawing("Triangle"),
        ArrowOutline = NewDrawing("Triangle"),
        ArrowText = NewDrawing("Text"),
    }
end

local function HideVisual(Visual)
    for _, CollectionName in { "Box", "BoxOutline", "Skeleton", "SkeletonOutline" } do
        for _, Object in Visual[CollectionName] do
            SetVisible(Object, false)
        end
    end
    for _, Name in {
        "Fill",
        "Name",
        "Team",
        "Distance",
        "Tool",
        "HealthText",
        "HealthValue",
        "Category",
        "Flags",
        "HealthBack",
        "HealthFill",
        "Tracer",
        "TracerOutline",
        "HeadDot",
        "HeadDotOutline",
        "Arrow",
        "ArrowOutline",
        "ArrowText",
    } do
        SetVisible(Visual[Name], false)
    end
end

local function DestroyVisual(Visual)
    if not Visual then
        return
    end
    for _, CollectionName in { "Box", "BoxOutline", "Skeleton", "SkeletonOutline" } do
        for _, Object in Visual[CollectionName] do
            RemoveDrawing(Object)
        end
    end
    for Name, Object in Visual do
        if type(Object) ~= "table" then
            RemoveDrawing(Object)
        end
    end
end

local function SetLine(Line, From, To, Color, Thickness, Transparency, Visible)
    if not Line then
        return
    end
    Line.From = From
    Line.To = To
    Line.Color = Color
    Line.Thickness = Thickness
    Line.Transparency = Transparency
    Line.Visible = Visible == true
end

local function SetText(Object, Text, Position, Color, Size, Font, Outline, OutlineColor, Center, Visible, Transparency)
    if not Object then
        return
    end
    Object.Text = Text
    Object.Position = Position
    Object.Color = Color
    Object.Size = Size
    Object.Font = Font
    Object.Center = Center == true
    Object.Outline = Outline == true
    Object.OutlineColor = OutlineColor
    Object.Transparency = Transparency or 1
    Object.Visible = Visible == true and Text ~= ""
end

local function SetCircle(Object, Position, Radius, Color, Thickness, Transparency, Filled, Sides, Visible)
    if not Object then
        return
    end
    Object.Position = Position
    Object.Radius = Radius
    Object.Color = Color
    Object.Thickness = Thickness
    Object.Transparency = Transparency
    Object.Filled = Filled == true
    Object.NumSides = Sides
    Object.Visible = Visible == true
end

local function SetTriangle(Object, A, B, C, Color, Thickness, Transparency, Filled, Visible)
    if not Object then
        return
    end
    Object.PointA = A
    Object.PointB = B
    Object.PointC = C
    Object.Color = Color
    Object.Thickness = Thickness
    Object.Transparency = Transparency
    Object.Filled = Filled == true
    Object.Visible = Visible == true
end

local function ReadPath(Table, Path)
    local Current = Table
    for Segment in string.gmatch(Path, "[^%.]+") do
        if type(Current) ~= "table" then
            return nil
        end
        Current = Current[Segment]
    end
    return Current
end

local function WritePath(Table, Path, Value)
    local Segments = {}
    for Segment in string.gmatch(Path, "[^%.]+") do
        table.insert(Segments, Segment)
    end
    local Current = Table
    for Index = 1, #Segments - 1 do
        local Segment = Segments[Index]
        if type(Current[Segment]) ~= "table" then
            Current[Segment] = {}
        end
        Current = Current[Segment]
    end
    Current[Segments[#Segments]] = Value
end

local function NormalizeToken(Value)
    return string.lower((tostring(Value or ""):gsub("^%s+", ""):gsub("%s+$", "")))
end

local function CreateCrosshairVisual()
    local Lines, Outlines = CreateLineSet(4)
    return {
        Lines = Lines,
        Outlines = Outlines,
        Dot = NewDrawing("Circle"),
        DotOutline = NewDrawing("Circle"),
    }
end

local function HideCrosshair(Visual)
    if not Visual then
        return
    end
    for _, Object in Visual.Lines do
        SetVisible(Object, false)
    end
    for _, Object in Visual.Outlines do
        SetVisible(Object, false)
    end
    SetVisible(Visual.Dot, false)
    SetVisible(Visual.DotOutline, false)
end

local function DestroyCrosshair(Visual)
    if not Visual then
        return
    end
    for _, Object in Visual.Lines do
        RemoveDrawing(Object)
    end
    for _, Object in Visual.Outlines do
        RemoveDrawing(Object)
    end
    RemoveDrawing(Visual.Dot)
    RemoveDrawing(Visual.DotOutline)
end

local Controller = {}
Controller.__index = Controller

function UniversalESP.new(Info)
    Info = Info or {}
    local SettingsInput = Info.Settings
    if type(SettingsInput) ~= "table" then
        SettingsInput = DeepCopy(Info)
        SettingsInput.AutoStart = nil
        SettingsInput.WrapPlayers = nil
        SettingsInput.CategoryStyles = nil
    end
    local Self = setmetatable({
        Available = UniversalESP.Available,
        Settings = Merge(DeepCopy(Defaults), SettingsInput),
        Entries = {},
        ObjectEntries = setmetatable({}, { __mode = "k" }),
        Connections = {},
        Watchers = {},
        PreviewEntities = setmetatable({}, { __mode = "k" }),
        Camera = Workspace.CurrentCamera,
        LocalPlayer = Players.LocalPlayer,
        Running = false,
        Destroyed = false,
        FrameAccumulator = 0,
        NextId = 0,
        LastError = nil,
        AutoNPCWatcher = nil,
        CategoryStyles = {},
        IgnoredObjects = setmetatable({}, { __mode = "k" }),
        CrosshairVisual = nil,
        RaycastParams = RaycastParams.new(),
    }, Controller)

    Self.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    Self.RaycastParams.IgnoreWater = true
    Self.Settings.UpdateRate = ClampNumber(Self.Settings.UpdateRate, 60, 5, 240)
    Self.Settings.TextUpdateRate = ClampNumber(Self.Settings.TextUpdateRate, 8, 1, 60)
    Self.Settings.MaxDistance = ClampNumber(Self.Settings.MaxDistance, 2500, 1, 100000)
    Self.Settings.TextDistance = ClampNumber(Self.Settings.TextDistance, 600, 1, 100000)
    Self.Settings.MaxRendered = math.floor(ClampNumber(Self.Settings.MaxRendered, 0, 0, 1000))
    Self:SetFilterList(Self.Settings.FilterList)
    if type(Info.CategoryStyles) == "table" then
        for Category, Style in Info.CategoryStyles do
            Self:SetCategoryStyle(Category, Style)
        end
    end

    if Info.AutoStart ~= false then
        Self:Start()
    end
    if Info.WrapPlayers == true then
        Self:WrapPlayers()
    end
    return Self
end

function Controller:_GiveConnection(Connection)
    table.insert(self.Connections, Connection)
    return Connection
end

function Controller:_Disconnect(Connection)
    if not Connection then
        return
    end
    pcall(function()
        Connection:Disconnect()
    end)
    local Index = table.find(self.Connections, Connection)
    if Index then
        table.remove(self.Connections, Index)
    end
end

function Controller:_CreateId()
    self.NextId += 1
    return string.format("MonHubESP_%d", self.NextId)
end

function Controller:Get(Path)
    return ReadPath(self.Settings, Path)
end

function Controller:Set(Path, Value)
    assert(type(Path) == "string" and Path ~= "", "Path must be a non-empty string.")
    WritePath(self.Settings, Path, Value)
    if Path == "UpdateRate" then
        self.Settings.UpdateRate = ClampNumber(Value, 60, 5, 240)
    elseif Path == "TextUpdateRate" then
        self.Settings.TextUpdateRate = ClampNumber(Value, 8, 1, 60)
    elseif Path == "MaxDistance" then
        self.Settings.MaxDistance = ClampNumber(Value, 2500, 1, 100000)
    elseif Path == "TextDistance" then
        self.Settings.TextDistance = ClampNumber(Value, 600, 1, 100000)
    elseif Path == "MaxRendered" then
        self.Settings.MaxRendered = math.floor(ClampNumber(Value, 0, 0, 1000))
    elseif Path == "FilterList" then
        self:SetFilterList(Value)
    elseif Path == "Enabled" and Value ~= true then
        self:HideAll()
        self.IdleHidden = true
    elseif Path == "Enabled" then
        self.IdleHidden = false
    end
    return Value
end

function Controller:ApplySettings(Settings)
    Merge(self.Settings, Settings or {})
    self.Settings.UpdateRate = ClampNumber(self.Settings.UpdateRate, 60, 5, 240)
    self.Settings.TextUpdateRate = ClampNumber(self.Settings.TextUpdateRate, 8, 1, 60)
    self.Settings.MaxRendered = math.floor(ClampNumber(self.Settings.MaxRendered, 0, 0, 1000))
    self:SetFilterList(self.Settings.FilterList)
    return self.Settings
end

function Controller:ApplyPreset(Name)
    Name = tostring(Name or "Balanced")
    if Name == "Performance" then
        self:ApplySettings({
            UpdateRate = 30,
            TextUpdateRate = 4,
            VisibilityCheck = false,
            Box = { Dynamic = false },
            Skeleton = { Enabled = false },
            HeadDot = { Enabled = false },
            Highlight = { Enabled = false },
        })
    elseif Name == "Quality" then
        self:ApplySettings({
            UpdateRate = 120,
            TextUpdateRate = 12,
            VisibilityCheck = true,
            Box = { Dynamic = true },
        })
    else
        self:ApplySettings({
            UpdateRate = 60,
            TextUpdateRate = 8,
            VisibilityCheck = false,
            Box = { Dynamic = true },
        })
    end
    return self.Settings
end

function Controller:SetEnabled(Enabled)
    self:Set("Enabled", Enabled == true)
end

function Controller:SetCategoryStyle(Category, Style)
    Category = tostring(Category or "")
    if Category == "" then
        return nil
    end
    if type(Style) ~= "table" then
        self.CategoryStyles[Category] = nil
        return nil
    end
    self.CategoryStyles[Category] = DeepCopy(Style)
    return self.CategoryStyles[Category]
end

function Controller:GetCategoryStyle(Category)
    return self.CategoryStyles[tostring(Category or "")]
end

function Controller:SetIgnored(Object, Ignored)
    if typeof(Object) == "Instance" then
        self.IgnoredObjects[Object] = Ignored == true or nil
    end
end

function Controller:SetFilterList(Values)
    local Result = {}
    if type(Values) == "string" then
        for Token in string.gmatch(Values, "[^,;\n]+") do
            local Normalized = NormalizeToken(Token)
            if Normalized ~= "" then
                Result[Normalized] = true
            end
        end
    elseif type(Values) == "table" then
        for Key, Value in Values do
            local Token = type(Key) == "number" and Value or Key
            local Enabled = type(Key) == "number" or Value == true
            local Normalized = NormalizeToken(Token)
            if Enabled and Normalized ~= "" then
                Result[Normalized] = true
            end
        end
    end
    self.Settings.FilterList = Result
    return Result
end

function Controller:_GetStyle(Entry)
    local Category = Entry.Info.Category
    return Category and self.CategoryStyles[tostring(Category)] or nil
end

function Controller:_MatchesFilter(Entry, Player)
    local Mode = tostring(self.Settings.FilterMode or "All")
    if Mode == "All" then
        return true
    end
    local List = self.Settings.FilterList
    if type(List) ~= "table" then
        return Mode ~= "Whitelist"
    end
    local Matches = false
    local MatchMode = tostring(self.Settings.FilterMatch or "Exact")
    local Values = {
        Entry.Id,
        Entry.Object and Entry.Object.Name,
        Player and Player.Name,
        Player and Player.DisplayName,
        Player and Player.UserId,
        Entry.Info.Category,
    }
    for _, Value in Values do
        if Value ~= nil then
            local Candidate = NormalizeToken(Value)
            if MatchMode == "Contains" or MatchMode == "Prefix" then
                for Token in List do
                    local Found = MatchMode == "Prefix" and Candidate:sub(1, #Token) == Token or string.find(Candidate, Token, 1, true) ~= nil
                    if Found then
                        Matches = true
                        break
                    end
                end
            else
                Matches = List[Candidate] == true
            end
            if Matches then
                break
            end
        end
    end
    return Mode == "Whitelist" and Matches or Mode == "Blacklist" and not Matches or true
end

function Controller:_FormatName(Name)
    Name = tostring(Name or "")
    local Maximum = math.floor(ClampNumber(self.Settings.Text.MaxNameLength, 32, 1, 128))
    if #Name > Maximum then
        Name = Name:sub(1, math.max(1, Maximum - 1)) .. "…"
    end
    local Mode = tostring(self.Settings.Text.NameCase or "Normal")
    if Mode == "Upper" then
        return string.upper(Name)
    elseif Mode == "Lower" then
        return string.lower(Name)
    end
    return Name
end

function Controller:_FormatDistance(Distance)
    local Scale = ClampNumber(self.Settings.DistanceScale, 1, 0.0001, 10000)
    local Unit = tostring(self.Settings.DistanceUnit or "Studs")
    local Suffix = "st"
    local Multiplier = 1
    if Unit == "Meters" then
        Multiplier = 0.28
        Suffix = "m"
    elseif Unit == "Feet" then
        Multiplier = 0.918635
        Suffix = "ft"
    end
    local Decimals = math.floor(ClampNumber(self.Settings.Text.DistanceDecimals, 0, 0, 3))
    local Format = "%0." .. tostring(Decimals) .. "f%s"
    return string.format(Format, Distance * Scale * Multiplier, Suffix)
end

function Controller:_ResolveOpacity(Distance, Maximum, Visible)
    local Fade = self.Settings.Fade
    local Opacity = 1
    if Fade.Enabled then
        local Start = math.clamp(tonumber(Fade.Start) or 0.65, 0, 0.99)
        local Ratio = math.clamp(Distance / math.max(Maximum, 1), 0, 1)
        if Ratio > Start then
            local Progress = (Ratio - Start) / math.max(1 - Start, 0.01)
            Opacity = 1 - Progress * (1 - math.clamp(tonumber(Fade.Minimum) or 0.3, 0, 1))
        end
    end
    if self.Settings.VisibilityCheck and self.Settings.OcclusionMode == "Fade" and not Visible then
        Opacity *= math.clamp(tonumber(Fade.OccludedMultiplier) or 0.55, 0, 1)
    end
    return math.clamp(Opacity, 0, 1)
end

function Controller:_ResolveVisualColor(Mode, Custom, ColorA, ColorB, Health, Visible, Now)
    Mode = tostring(Mode or "Custom")
    if Mode == "Primary" then
        return ColorA
    elseif Mode == "Gradient" then
        return ColorB
    elseif Mode == "Health" then
        return self.Settings.Colors.HealthLow:Lerp(self.Settings.Colors.HealthHigh, Health)
    elseif Mode == "Visibility" then
        return Visible and self.Settings.Colors.Visible or self.Settings.Colors.Occluded
    elseif Mode == "Rainbow" then
        local Speed = ClampNumber(self.Settings.Box.RainbowSpeed, 0.12, 0.01, 3)
        return Color3.fromHSV((Now * Speed) % 1, 0.72, 1)
    end
    return typeof(Custom) == "Color3" and Custom or ColorA
end

function Controller:_ResolveEntry(Entry)
    local Object = Entry.Object
    if not Object or not Object.Parent then
        return nil
    end
    local Player = Object:IsA("Player") and Object or Entry.Player
    local Model = Player and Player.Character or ResolveModel(Object)
    if not Model or not Model.Parent then
        return nil
    end
    local Root = GetRoot(Model)
    if not Root or not Root.Parent then
        return nil
    end
    local Humanoid = GetHumanoid(Model)
    Entry.Player = Player or GetPlayerFromObject(Model)
    Entry.Model = Model
    Entry.Root = Root
    Entry.Humanoid = Humanoid
    return Model, Root, Humanoid, Entry.Player
end

function Controller:_ClassAllowed(Entry)
    if Entry.Kind == "Player" then
        return self.Settings.Players == true
    elseif Entry.Kind == "NPC" then
        return self.Settings.NPCs == true
    end
    return self.Settings.Parts == true
end

function Controller:_IsSameTeam(Player)
    local LocalPlayer = self.LocalPlayer
    return Player and LocalPlayer and Player ~= LocalPlayer and Player.Team ~= nil and Player.Team == LocalPlayer.Team
end

function Controller:_IsAllowed(Entry, Model, Humanoid, Player, Distance)
    if not self.Settings.Enabled or not self:_ClassAllowed(Entry) then
        return false
    end
    if Player == self.LocalPlayer and not self.Settings.IncludeLocalPlayer then
        return false
    end
    if self.IgnoredObjects[Entry.Object] or self.IgnoredObjects[Model] then
        return false
    end
    if not self:_MatchesFilter(Entry, Player) then
        return false
    end
    if self.Settings.TeamCheck and self:_IsSameTeam(Player) then
        return false
    end
    if self.Settings.AliveCheck and Humanoid and Humanoid.Health <= 0 then
        return false
    end
    local Style = self:_GetStyle(Entry)
    local Maximum = tonumber(Entry.Info.MaxDistance) or Style and tonumber(Style.MaxDistance) or tonumber(self.Settings.MaxDistance) or 2500
    if Distance > Maximum then
        return false
    end
    if type(Entry.Info.Predicate) == "function" then
        local Success, Result = pcall(Entry.Info.Predicate, Entry.Object, Model, Player, Distance)
        if not Success or Result ~= true then
            return false
        end
    end
    return true
end

function Controller:_IsVisualAllowed(Entry, Name)
    local Allowed = Entry.Info.AllowedVisuals
    local Style = self:_GetStyle(Entry)
    local StyleAllowed = Style and Style.AllowedVisuals
    return (type(Allowed) ~= "table" or Allowed[Name] ~= false) and (type(StyleAllowed) ~= "table" or StyleAllowed[Name] ~= false)
end

function Controller:_CheckVisible(Entry, Root, Model, Now)
    if not self.Settings.VisibilityCheck then
        return true
    end
    if Now < (Entry.NextVisibilityAt or 0) then
        return Entry.VisibleFromCamera ~= false
    end
    Entry.NextVisibilityAt = Now + ClampNumber(self.Settings.VisibilityInterval, 0.12, 0.02, 2)
    local Camera = self.Camera
    local Origin = Camera and Camera.CFrame.Position
    if not Origin then
        return true
    end
    local Filter = {}
    if self.LocalPlayer and self.LocalPlayer.Character then
        table.insert(Filter, self.LocalPlayer.Character)
    end
    self.RaycastParams.FilterDescendantsInstances = Filter
    local Result = Workspace:Raycast(Origin, Root.Position - Origin, self.RaycastParams)
    Entry.VisibleFromCamera = not Result or IsDescendantOf(Result.Instance, Model)
    return Entry.VisibleFromCamera
end

function Controller:_ResolveColors(Entry, Player, Health, Visible, Now)
    local Colors = self.Settings.Colors
    local Style = self:_GetStyle(Entry)
    local ColorA = Entry.Info.Color or Style and Style.Color
    if typeof(ColorA) ~= "Color3" then
        local Mode = tostring(Colors.Mode or "Entity")
        if Mode == "Health" then
            ColorA = Colors.HealthLow:Lerp(Colors.HealthHigh, Health)
        elseif Mode == "Rainbow" then
            local Speed = ClampNumber(self.Settings.Box.RainbowSpeed, 0.12, 0.01, 3)
            ColorA = Color3.fromHSV((Now * Speed) % 1, 0.72, 1)
        elseif Mode == "Visibility" then
            ColorA = Visible and Colors.Visible or Colors.Occluded
        elseif Mode == "Team" and Player and Player.TeamColor then
            ColorA = Player.TeamColor.Color
        elseif Mode == "Static" then
            ColorA = Colors.Enemy
        elseif Entry.Kind == "NPC" then
            ColorA = Colors.NPC
        elseif Entry.Kind == "Part" then
            ColorA = Colors.Part
        elseif self.Settings.TeamColors and Player and Player.TeamColor then
            ColorA = Player.TeamColor.Color
        elseif self:_IsSameTeam(Player) then
            ColorA = Colors.Team
        else
            ColorA = Colors.Enemy
        end
    end
    if self.Settings.VisibilityCheck and Colors.Mode == "Visibility" then
        ColorA = Visible and Colors.Visible or Colors.Occluded
    end
    if self.Settings.VisibilityCheck and self.Settings.OcclusionMode == "Color" then
        ColorA = Visible and Colors.Visible or Colors.Occluded
    end
    if self.Settings.Box.Rainbow then
        local Speed = ClampNumber(self.Settings.Box.RainbowSpeed, 0.12, 0.01, 3)
        ColorA = Color3.fromHSV((Now * Speed) % 1, 0.72, 1)
    end
    local ColorB = typeof(Entry.Info.GradientColor) == "Color3" and Entry.Info.GradientColor or Style and Style.GradientColor or Colors.Gradient
    return ColorA, ColorB
end

function Controller:_GetBounds(Model, Root)
    local CFrameValue
    local Size
    if Model:IsA("Model") then
        local Success, ResultCFrame, ResultSize = pcall(Model.GetBoundingBox, Model)
        if Success then
            CFrameValue = ResultCFrame
            Size = ResultSize
        end
    end
    if not CFrameValue then
        CFrameValue = Root.CFrame
        Size = Root.Size
        if Model:IsA("Model") then
            Size = Vector3.new(math.max(Size.X, 2.5), math.max(Size.Y, 5), math.max(Size.Z, 2.5))
        end
    end
    local Scale = ClampNumber(self.Settings.Box.Scale, 1, 0.25, 3)
    local ScaleX = ClampNumber(self.Settings.Box.ScaleX, 1, 0.25, 3)
    local ScaleY = ClampNumber(self.Settings.Box.ScaleY, 1, 0.25, 3)
    local PaddingX = ClampNumber(self.Settings.Box.PaddingX, 0, 0, 20)
    local PaddingY = ClampNumber(self.Settings.Box.PaddingY, 0, 0, 20)
    Size = Vector3.new(Size.X * Scale * ScaleX + PaddingX * 2, Size.Y * Scale * ScaleY + PaddingY * 2, Size.Z * Scale * ScaleX + PaddingX * 2)
    return CFrameValue, Size
end

function Controller:_FinalizeBounds(Bounds)
    if not Bounds or not Bounds.Width or not Bounds.Height then
        return Bounds
    end
    local Minimum = ClampNumber(self.Settings.Box.MinimumSize, 2, 1, 100)
    local Maximum = ClampNumber(self.Settings.Box.MaximumSize, 2000, Minimum, 10000)
    local Center = Bounds.Center or Vector2.new(Bounds.X + Bounds.Width * 0.5, Bounds.Y + Bounds.Height * 0.5)
    Bounds.Width = math.clamp(Bounds.Width, Minimum, Maximum)
    Bounds.Height = math.clamp(Bounds.Height, Minimum, Maximum)
    Bounds.X = Center.X - Bounds.Width * 0.5
    Bounds.Y = Center.Y - Bounds.Height * 0.5
    Bounds.Center = Center
    return Bounds
end

function Controller:_ProjectBounds(Model, Root)
    local Camera = self.Camera
    if not Camera then
        return nil
    end
    local BoxCFrame, Size = self:_GetBounds(Model, Root)
    if not self.Settings.Box.Dynamic and self.Settings.Box.Style ~= "3D" then
        local Top = Camera:WorldToViewportPoint(BoxCFrame:PointToWorldSpace(Vector3.new(0, Size.Y * 0.5, 0)))
        local Bottom = Camera:WorldToViewportPoint(BoxCFrame:PointToWorldSpace(Vector3.new(0, -Size.Y * 0.5, 0)))
        local Height = math.abs(Bottom.Y - Top.Y)
        local Width = Height * 0.56
        local CenterX = (Top.X + Bottom.X) * 0.5
        local MinimumY = math.min(Top.Y, Bottom.Y)
        local Viewport = Camera.ViewportSize
        return self:_FinalizeBounds({
            X = CenterX - Width * 0.5,
            Y = MinimumY,
            Width = Width,
            Height = Height,
            Center = Vector2.new(CenterX, MinimumY + Height * 0.5),
            OnScreen = Top.Z > 0 and Bottom.Z > 0 and CenterX + Width * 0.5 >= 0 and MinimumY + Height >= 0 and CenterX - Width * 0.5 <= Viewport.X and MinimumY <= Viewport.Y,
            Behind = Top.Z <= 0 and Bottom.Z <= 0,
            RootPosition = Camera:WorldToViewportPoint(Root.Position),
        })
    end
    local Half = Size * 0.5
    local LocalCorners = {
        Vector3.new(-Half.X, Half.Y, -Half.Z),
        Vector3.new(Half.X, Half.Y, -Half.Z),
        Vector3.new(Half.X, -Half.Y, -Half.Z),
        Vector3.new(-Half.X, -Half.Y, -Half.Z),
        Vector3.new(-Half.X, Half.Y, Half.Z),
        Vector3.new(Half.X, Half.Y, Half.Z),
        Vector3.new(Half.X, -Half.Y, Half.Z),
        Vector3.new(-Half.X, -Half.Y, Half.Z),
    }
    local Points = {}
    local MinimumX = math.huge
    local MinimumY = math.huge
    local MaximumX = -math.huge
    local MaximumY = -math.huge
    local FrontCount = 0
    for Index, Offset in LocalCorners do
        local Screen, OnScreen = Camera:WorldToViewportPoint(BoxCFrame:PointToWorldSpace(Offset))
        local Point = Vector2.new(Screen.X, Screen.Y)
        Points[Index] = Point
        if Screen.Z > 0 then
            FrontCount += 1
            MinimumX = math.min(MinimumX, Screen.X)
            MinimumY = math.min(MinimumY, Screen.Y)
            MaximumX = math.max(MaximumX, Screen.X)
            MaximumY = math.max(MaximumY, Screen.Y)
        end
    end
    if FrontCount == 0 then
        return {
            OnScreen = false,
            Behind = true,
            RootPosition = Camera:WorldToViewportPoint(Root.Position),
        }
    end
    local Viewport = Camera.ViewportSize
    local Width = MaximumX - MinimumX
    local Height = MaximumY - MinimumY
    return self:_FinalizeBounds({
        X = MinimumX,
        Y = MinimumY,
        Width = Width,
        Height = Height,
        Center = Vector2.new(MinimumX + Width * 0.5, MinimumY + Height * 0.5),
        Points = Points,
        OnScreen = MaximumX >= 0 and MaximumY >= 0 and MinimumX <= Viewport.X and MinimumY <= Viewport.Y,
        Behind = false,
        RootPosition = Camera:WorldToViewportPoint(Root.Position),
    })
end

function Controller:_GetTextSize(Height)
    local Minimum = ClampNumber(self.Settings.Text.MinimumSize, 8, 6, 32)
    local Maximum = ClampNumber(self.Settings.Text.MaximumSize, 32, Minimum, 48)
    local Base = ClampNumber(self.Settings.Text.Size, 13, Minimum, Maximum)
    if not self.Settings.Text.RelativeSize then
        return Base
    end
    return math.clamp(math.floor(Base * math.clamp(Height / 180, 0.72, 1.18) + 0.5), Minimum, Maximum)
end

function Controller:_RefreshTextCache(Entry, Model, Player, Distance, Now)
    if Now < (Entry.NextTextAt or 0) then
        return
    end
    Entry.NextTextAt = Now + 1 / ClampNumber(self.Settings.TextUpdateRate, 8, 1, 60)
    local Info = Entry.Info
    Entry.TextCache = {
        Name = self:_FormatName(GetObjectName(Entry.Object, Model, Player, Info, self.Settings.Text.DisplayName)),
        Team = ResolveTeam(Player, Info),
        Tool = GetTool(Model),
        Category = Info.Category and tostring(Info.Category) or Entry.Kind,
        Flags = ResolveFlags(Info, Entry.Object, Model, Player),
        Distance = math.floor(Distance + 0.5),
    }
    if type(Info.Tool) == "function" then
        local Success, Result = pcall(Info.Tool, Entry.Object, Model, Player)
        if Success then
            Entry.TextCache.Tool = tostring(Result or "")
        end
    elseif Info.Tool ~= nil then
        Entry.TextCache.Tool = tostring(Info.Tool)
    end
end

function Controller:_UpdateJointCache(Entry, Model, Now)
    if Entry.JointModel == Model and Now < (Entry.NextJointAt or 0) then
        return Entry.Joints
    end
    Entry.JointModel = Model
    Entry.NextJointAt = Now + 0.75
    Entry.Joints = {}
    local Maximum = math.floor(ClampNumber(self.Settings.Skeleton.MaxJoints, 24, 2, 40))
    if Model:IsA("Model") then
        for _, Descendant in Model:GetDescendants() do
            if Descendant:IsA("Motor6D") and Descendant.Part0 and Descendant.Part1 then
                table.insert(Entry.Joints, { Descendant.Part0, Descendant.Part1 })
                if #Entry.Joints >= Maximum then
                    break
                end
            end
        end
    end
    return Entry.Joints
end

function Controller:_DrawBox(Visual, Bounds, ColorA, ColorB, Opacity)
    local Settings = self.Settings.Box
    local Enabled = Settings.Enabled == true
    local Style = tostring(Settings.Style or "Corner")
    local OutlineColor = self.Settings.Colors.Outline
    local Thickness = ClampNumber(Settings.Thickness, 1, 0.5, 8)
    local OutlineThickness = math.max(Thickness + 1, ClampNumber(Settings.OutlineThickness, 3, 1, 10))
    local Transparency = ClampNumber(Settings.Transparency, 1, 0, 1) * Opacity
    local TopLeft = Vector2.new(Bounds.X, Bounds.Y)
    local TopRight = Vector2.new(Bounds.X + Bounds.Width, Bounds.Y)
    local BottomRight = Vector2.new(Bounds.X + Bounds.Width, Bounds.Y + Bounds.Height)
    local BottomLeft = Vector2.new(Bounds.X, Bounds.Y + Bounds.Height)
    local Points = { TopLeft, TopRight, BottomRight, BottomLeft }
    local Segments = {}

    if Enabled and Style == "3D" and Bounds.Points then
        for _, Edge in CubeEdges do
            table.insert(Segments, { Bounds.Points[Edge[1]], Bounds.Points[Edge[2]] })
        end
    elseif Enabled and Style == "Corner" then
        local CornerWidth = math.max(2, Bounds.Width * ClampNumber(Settings.CornerWidth, 0.28, 0.05, 0.5))
        local CornerHeight = math.max(2, Bounds.Height * ClampNumber(Settings.CornerHeight, 0.22, 0.05, 0.5))
        Segments = {
            { TopLeft, TopLeft + Vector2.new(CornerWidth, 0) },
            { TopLeft, TopLeft + Vector2.new(0, CornerHeight) },
            { TopRight, TopRight - Vector2.new(CornerWidth, 0) },
            { TopRight, TopRight + Vector2.new(0, CornerHeight) },
            { BottomRight, BottomRight - Vector2.new(CornerWidth, 0) },
            { BottomRight, BottomRight - Vector2.new(0, CornerHeight) },
            { BottomLeft, BottomLeft + Vector2.new(CornerWidth, 0) },
            { BottomLeft, BottomLeft - Vector2.new(0, CornerHeight) },
        }
    elseif Enabled then
        for _, Edge in BoxEdges do
            table.insert(Segments, { Points[Edge[1]], Points[Edge[2]] })
        end
    end

    for Index = 1, 12 do
        local Segment = Segments[Index]
        local Visible = Segment ~= nil
        if Visible then
            local MiddleY = (Segment[1].Y + Segment[2].Y) * 0.5
            local Ratio = math.clamp((MiddleY - Bounds.Y) / math.max(Bounds.Height, 1), 0, 1)
            local Color = Settings.Gradient and ColorA:Lerp(ColorB, Ratio) or ColorA
            SetLine(Visual.BoxOutline[Index], Segment[1], Segment[2], OutlineColor, OutlineThickness, Transparency, Settings.Outline == true)
            SetLine(Visual.Box[Index], Segment[1], Segment[2], Color, Thickness, Transparency, true)
        else
            SetVisible(Visual.BoxOutline[Index], false)
            SetVisible(Visual.Box[Index], false)
        end
    end

    if Visual.Fill then
        Visual.Fill.Position = TopLeft
        Visual.Fill.Size = Vector2.new(Bounds.Width, Bounds.Height)
        Visual.Fill.Color = ColorA:Lerp(ColorB, 0.5)
        Visual.Fill.Transparency = ClampNumber(Settings.FillTransparency, 0.12, 0, 1) * Opacity
        Visual.Fill.Filled = true
        Visual.Fill.Visible = Enabled and Settings.Fill == true and Style ~= "3D"
    end
end

function Controller:_DrawHealth(Visual, Bounds, Health, ColorA, ColorB, TextSize, Font, AllowText, Visible, Now, Opacity)
    local Settings = self.Settings.HealthBar
    local Enabled = Settings.Enabled == true
    local Position = tostring(Settings.Position or "Left")
    local Offset = ClampNumber(Settings.Offset, 5, 1, 24)
    local Width = ClampNumber(Settings.Width, 2, 1, 8)
    local OutlineColor = self.Settings.Colors.Outline
    local HealthColor = self:_ResolveVisualColor(Settings.ColorMode, ColorA, ColorA, ColorB, Health, Visible, Now)
    local From
    local To
    local FillFrom
    local FillTo
    if Position == "Right" then
        From = Vector2.new(Bounds.X + Bounds.Width + Offset, Bounds.Y + Bounds.Height)
        To = Vector2.new(From.X, Bounds.Y)
        FillFrom = From
        FillTo = Vector2.new(From.X, Bounds.Y + Bounds.Height * (1 - Health))
    elseif Position == "Top" then
        From = Vector2.new(Bounds.X, Bounds.Y - Offset)
        To = Vector2.new(Bounds.X + Bounds.Width, From.Y)
        FillFrom = From
        FillTo = Vector2.new(Bounds.X + Bounds.Width * Health, From.Y)
    elseif Position == "Bottom" then
        From = Vector2.new(Bounds.X, Bounds.Y + Bounds.Height + Offset)
        To = Vector2.new(Bounds.X + Bounds.Width, From.Y)
        FillFrom = From
        FillTo = Vector2.new(Bounds.X + Bounds.Width * Health, From.Y)
    else
        From = Vector2.new(Bounds.X - Offset, Bounds.Y + Bounds.Height)
        To = Vector2.new(From.X, Bounds.Y)
        FillFrom = From
        FillTo = Vector2.new(From.X, Bounds.Y + Bounds.Height * (1 - Health))
    end
    SetLine(Visual.HealthBack, From, To, OutlineColor, Width + 2, ClampNumber(Settings.BackgroundTransparency, 0.92, 0, 1) * Opacity, Enabled and Settings.Outline == true)
    SetLine(Visual.HealthFill, FillFrom, FillTo, HealthColor, Width, ClampNumber(Settings.Transparency, 1, 0, 1) * Opacity, Enabled)
    local HealthValue = math.floor(Health * 100 + 0.5)
    local ValuePosition
    if Position == "Right" then
        ValuePosition = Vector2.new(Bounds.X + Bounds.Width + Offset + 5, Bounds.Y + Bounds.Height * (1 - Health) - TextSize * 0.5)
    elseif Position == "Top" then
        ValuePosition = Vector2.new(Bounds.X + Bounds.Width * Health, Bounds.Y - Offset - TextSize - 2)
    elseif Position == "Bottom" then
        ValuePosition = Vector2.new(Bounds.X + Bounds.Width * Health, Bounds.Y + Bounds.Height + Offset + 2)
    else
        ValuePosition = Vector2.new(Bounds.X - Offset - 5, Bounds.Y + Bounds.Height * (1 - Health) - TextSize * 0.5)
    end
    SetText(
        Visual.HealthValue,
        tostring(HealthValue),
        ValuePosition,
        HealthColor,
        math.max(8, TextSize - 2),
        Font,
        true,
        OutlineColor,
        true,
        Enabled and Settings.Text == true and AllowText,
        Opacity
    )
end

function Controller:_DrawText(Visual, Entry, Bounds, Health, ColorA, ColorB, Distance, AllowText, Opacity)
    local Settings = self.Settings.Text
    local Cache = Entry.TextCache or {}
    local Size = self:_GetTextSize(Bounds.Height)
    local Font = ResolveDrawingFont(Settings.Font)
    local OutlineColor = self.Settings.Colors.Outline
    local TextColor = self.Settings.Colors.Text
    local TopY = Bounds.Y - Size - ClampNumber(Settings.TopOffset, 2, 0, 30)
    local BottomY = Bounds.Y + Bounds.Height + ClampNumber(Settings.BottomOffset, 2, 0, 30)
    local Spacing = ClampNumber(Settings.Spacing, 1, 0, 12)
    local CenterX = Bounds.X + Bounds.Width * 0.5
    local TopIndex = 0
    local BottomIndex = 0

    local function Top(Object, Value, Enabled, Color)
        SetText(Object, Value or "", Vector2.new(CenterX, TopY - TopIndex * (Size + Spacing)), Color or TextColor, Size, Font, Settings.Outline, OutlineColor, true, AllowText and Enabled, Opacity)
        if AllowText and Enabled and Value and Value ~= "" then
            TopIndex += 1
        end
    end

    local function Bottom(Object, Value, Enabled, Color)
        SetText(Object, Value or "", Vector2.new(CenterX, BottomY + BottomIndex * (Size + Spacing)), Color or TextColor, math.max(8, Size - 1), Font, Settings.Outline, OutlineColor, true, AllowText and Enabled, Opacity)
        if AllowText and Enabled and Value and Value ~= "" then
            BottomIndex += 1
        end
    end

    local Team = Cache.Team or ""
    local Tool = Cache.Tool or ""
    if Settings.TeamBrackets and Team ~= "" then
        Team = string.format("[%s]", Team)
    end
    if Settings.ToolBrackets and Tool ~= "" then
        Tool = string.format("[%s]", Tool)
    end
    Top(Visual.Name, Cache.Name, Settings.Name == true and self:_IsVisualAllowed(Entry, "Name"), ColorA)
    Top(Visual.Team, Team, Settings.Team == true and self:_IsVisualAllowed(Entry, "Team"), ColorB)
    Top(Visual.Category, Cache.Category, Settings.Category == true and self:_IsVisualAllowed(Entry, "Category"), ColorB)
    Bottom(Visual.Distance, self:_FormatDistance(Distance), Settings.Distance == true and self:_IsVisualAllowed(Entry, "Distance"), ColorB)
    Bottom(Visual.Tool, Tool, Settings.Tool == true and self:_IsVisualAllowed(Entry, "Tool"), TextColor)
    Bottom(Visual.Flags, Cache.Flags, Settings.Flags == true and self:_IsVisualAllowed(Entry, "Flags"), ColorB)
    Bottom(Visual.HealthText, string.format("%d%%", math.floor(Health * 100 + 0.5)), Settings.Health == true and self:_IsVisualAllowed(Entry, "HealthText"), self.Settings.Colors.HealthLow:Lerp(self.Settings.Colors.HealthHigh, Health))
    return Size, Font
end

function Controller:_DrawTracer(Visual, Bounds, ColorA, ColorB, Health, Visible, Now, Opacity)
    local Settings = self.Settings.Tracer
    local Enabled = Settings.Enabled == true
    local Viewport = self.Camera.ViewportSize
    local Origin
    if Settings.Origin == "Custom" then
        Origin = Vector2.new(Viewport.X * ClampNumber(Settings.OriginX, 0.5, 0, 1), Viewport.Y * ClampNumber(Settings.OriginY, 1, 0, 1))
    elseif Settings.Origin == "Center" then
        Origin = Viewport * 0.5
    elseif Settings.Origin == "Mouse" then
        Origin = UserInputService:GetMouseLocation()
    elseif Settings.Origin == "Top" then
        Origin = Vector2.new(Viewport.X * 0.5, 0)
    else
        Origin = Vector2.new(Viewport.X * 0.5, Viewport.Y)
    end
    local Target
    if Settings.Target == "Center" then
        Target = Bounds.Center
    elseif Settings.Target == "Top" then
        Target = Vector2.new(Bounds.Center.X, Bounds.Y)
    else
        Target = Vector2.new(Bounds.Center.X, Bounds.Y + Bounds.Height)
    end
    Target += Vector2.new(ClampNumber(Settings.TargetOffsetX, 0, -100, 100), ClampNumber(Settings.TargetOffsetY, 0, -100, 100))
    local Direction = Target - Origin
    if Direction.Magnitude > 0.001 then
        local Unit = Direction.Unit
        local MaximumPadding = Direction.Magnitude * 0.48
        Origin += Unit * ClampNumber(Settings.StartPadding, 0, 0, MaximumPadding)
        Target -= Unit * ClampNumber(Settings.EndPadding, 0, 0, MaximumPadding)
    end
    local Thickness = ClampNumber(Settings.Thickness, 1, 0.5, 8)
    local Transparency = ClampNumber(Settings.Transparency, 1, 0, 1) * Opacity
    local Color = self:_ResolveVisualColor(Settings.ColorMode, self.Settings.Colors.Tracer, ColorA, ColorB, Health, Visible, Now)
    SetLine(Visual.TracerOutline, Origin, Target, self.Settings.Colors.Outline, Thickness + 2, Transparency, Enabled and Settings.Outline == true)
    SetLine(Visual.Tracer, Origin, Target, Color, Thickness, Transparency, Enabled)
end

function Controller:_DrawHeadDot(Visual, Model, ColorA, ColorB, Health, Visible, Now, Distance, Opacity)
    local Settings = self.Settings.HeadDot
    local Head = Model:IsA("Model") and Model:FindFirstChild("Head") or nil
    if not Settings.Enabled or not Head or not Head:IsA("BasePart") then
        SetVisible(Visual.HeadDot, false)
        SetVisible(Visual.HeadDotOutline, false)
        return
    end
    local Screen, OnScreen = self.Camera:WorldToViewportPoint(Head.Position)
    if not OnScreen or Screen.Z <= 0 then
        SetVisible(Visual.HeadDot, false)
        SetVisible(Visual.HeadDotOutline, false)
        return
    end
    local Radius = ClampNumber(Settings.Radius, 3, 1, 20)
    if Settings.ScaleWithDistance then
        Radius = Radius * math.clamp(120 / math.max(Distance, 1), 0.35, 2)
    end
    Radius = math.clamp(Radius, ClampNumber(Settings.MinimumRadius, 2, 1, 40), ClampNumber(Settings.MaximumRadius, 10, 1, 60))
    local Thickness = ClampNumber(Settings.Thickness, 1, 0.5, 8)
    local Position = Vector2.new(Screen.X, Screen.Y)
    local Sides = math.floor(ClampNumber(Settings.Sides, 20, 8, 64))
    local Transparency = ClampNumber(Settings.Transparency, 1, 0, 1) * Opacity
    local Color = self:_ResolveVisualColor(Settings.ColorMode, self.Settings.Colors.HeadDot, ColorA, ColorB, Health, Visible, Now)
    SetCircle(Visual.HeadDotOutline, Position, Radius + 1, self.Settings.Colors.Outline, Thickness + 2, Transparency, Settings.Filled, Sides, Settings.Outline)
    SetCircle(Visual.HeadDot, Position, Radius, Color, Thickness, Transparency, Settings.Filled, Sides, true)
end

function Controller:_DrawSkeleton(Visual, Entry, Model, ColorA, ColorB, Health, Visible, Now, Opacity)
    local Settings = self.Settings.Skeleton
    local Joints = Settings.Enabled and self:_UpdateJointCache(Entry, Model, Now) or {}
    local Thickness = ClampNumber(Settings.Thickness, 1, 0.5, 8)
    local Transparency = ClampNumber(Settings.Transparency, 1, 0, 1) * Opacity
    local Color = self:_ResolveVisualColor(Settings.ColorMode, self.Settings.Colors.Skeleton, ColorA, ColorB, Health, Visible, Now)
    for Index = 1, #Visual.Skeleton do
        local Joint = Joints[Index]
        local Visible = false
        local From
        local To
        if Joint and Joint[1].Parent and Joint[2].Parent then
            local A, AVisible = self.Camera:WorldToViewportPoint(Joint[1].Position)
            local B, BVisible = self.Camera:WorldToViewportPoint(Joint[2].Position)
            Visible = AVisible and BVisible and A.Z > 0 and B.Z > 0
            From = Vector2.new(A.X, A.Y)
            To = Vector2.new(B.X, B.Y)
        end
        if Visible then
            SetLine(Visual.SkeletonOutline[Index], From, To, self.Settings.Colors.Outline, Thickness + 2, Transparency, Settings.Outline == true)
            SetLine(Visual.Skeleton[Index], From, To, Color, Thickness, Transparency, true)
        else
            SetVisible(Visual.SkeletonOutline[Index], false)
            SetVisible(Visual.Skeleton[Index], false)
        end
    end
end

function Controller:_DrawArrow(Visual, Entry, Root, ColorA, ColorB, Health, Visible, Distance, OnScreen, Now, Opacity)
    local Settings = self.Settings.OffscreenArrow
    if not Settings.Enabled or OnScreen then
        SetVisible(Visual.Arrow, false)
        SetVisible(Visual.ArrowOutline, false)
        SetVisible(Visual.ArrowText, false)
        return
    end
    local Camera = self.Camera
    local Viewport = Camera.ViewportSize
    local Center = Viewport * 0.5
    local Relative = Camera.CFrame:PointToObjectSpace(Root.Position)
    local Direction = Vector2.new(Relative.X, -Relative.Y)
    if Relative.Z > 0 then
        Direction = -Direction
    end
    if Direction.Magnitude < 0.001 then
        Direction = Vector2.new(0, -1)
    else
        Direction = Direction.Unit
    end
    local Radius = math.min(ClampNumber(Settings.Radius, 190, 30, 1000), math.min(Viewport.X, Viewport.Y) * 0.45)
    local Size = ClampNumber(Settings.Size, 12, 4, 40)
    if Settings.Pulse then
        Size *= 1 + math.sin(Now * ClampNumber(Settings.PulseSpeed, 2, 0.1, 12) * math.pi * 2) * 0.12
    end
    local Tip = Center + Direction * Radius
    local Perpendicular = Vector2.new(-Direction.Y, Direction.X)
    local Base = Tip - Direction * Size
    local A = Tip
    local B = Base + Perpendicular * Size * 0.58
    local C = Base - Perpendicular * Size * 0.58
    local Transparency = ClampNumber(Settings.Transparency, 1, 0, 1) * Opacity
    local Color = self:_ResolveVisualColor(Settings.ColorMode, self.Settings.Colors.Arrow, ColorA, ColorB, Health, Visible, Now)
    SetTriangle(Visual.ArrowOutline, A, B, C, self.Settings.Colors.Outline, 3, Transparency, Settings.Filled, Settings.Outline)
    SetTriangle(Visual.Arrow, A, B, C, Color, 1, Transparency, Settings.Filled, true)
    local Text = ""
    local Cache = Entry.TextCache or {}
    if Settings.ShowName and Cache.Name and Cache.Name ~= "" then
        Text = Cache.Name
    end
    if Settings.ShowDistance then
        Text = Text ~= "" and Text .. " " .. self:_FormatDistance(Distance) or self:_FormatDistance(Distance)
    end
    SetText(Visual.ArrowText, Text, Base - Direction * (ClampNumber(Settings.TextSize, 12, 8, 24) + 2), Color, ClampNumber(Settings.TextSize, 12, 8, 24), ResolveDrawingFont(self.Settings.Text.Font), true, self.Settings.Colors.Outline, true, Text ~= "", Transparency)
end

function Controller:_UpdateHighlight(Entry, Model, Health, ColorA, ColorB, Visible, Now, Opacity)
    local Settings = self.Settings.Highlight
    local Enabled = Settings.Enabled == true and self:_IsVisualAllowed(Entry, "Highlight") and Model:IsA("Model")
    if not Enabled then
        if Entry.Highlight then
            Entry.Highlight.Enabled = false
        end
        return
    end
    if not Entry.Highlight then
        local Highlight = Instance.new("Highlight")
        Highlight.Name = "MonHubESPHighlight"
        Highlight.Parent = Workspace
        Entry.Highlight = Highlight
    end
    local Highlight = Entry.Highlight
    Highlight.Adornee = Model
    Highlight.DepthMode = Settings.DepthMode == "Occluded" and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
    local FillColor = Settings.HealthColor and self.Settings.Colors.HealthLow:Lerp(self.Settings.Colors.HealthHigh, Health) or self:_ResolveVisualColor(Settings.ColorMode, self.Settings.Colors.HighlightFill, ColorA, ColorB, Health, Visible, Now)
    Highlight.FillColor = FillColor
    Highlight.OutlineColor = self.Settings.Colors.HighlightOutline or ColorB
    Highlight.FillTransparency = 1 - (1 - ClampNumber(Settings.FillTransparency, 0.72, 0, 1)) * Opacity
    Highlight.OutlineTransparency = 1 - (1 - ClampNumber(Settings.OutlineTransparency, 0.08, 0, 1)) * Opacity
    Highlight.Enabled = true
end

function Controller:_RenderCrosshair(Now)
    local Settings = self.Settings.Crosshair
    if not Settings.Enabled then
        HideCrosshair(self.CrosshairVisual)
        return
    end
    if not self.CrosshairVisual then
        self.CrosshairVisual = CreateCrosshairVisual()
    end
    local Visual = self.CrosshairVisual
    local Viewport = self.Camera.ViewportSize
    local Center = Settings.Position == "Mouse" and UserInputService:GetMouseLocation() or Viewport * 0.5
    local Size = ClampNumber(Settings.Size, 8, 1, 60)
    local Gap = ClampNumber(Settings.Gap, 5, 0, 40)
    if Settings.Pulse then
        local Minimum = ClampNumber(Settings.PulseMinimum, 3, 0, 40)
        local Maximum = ClampNumber(Settings.PulseMaximum, 9, Minimum, 60)
        local Alpha = (math.sin(Now * ClampNumber(Settings.PulseSpeed, 2, 0.1, 12) * math.pi * 2) + 1) * 0.5
        Gap = Minimum + (Maximum - Minimum) * Alpha
    end
    local Angle = Settings.Rotate and math.rad((Now * ClampNumber(Settings.RotationSpeed, 90, -720, 720)) % 360) or 0
    local Directions = {
        Vector2.new(0, -1),
        Vector2.new(1, 0),
        Vector2.new(0, 1),
        Vector2.new(-1, 0),
    }
    local Color = self.Settings.Colors.Crosshair
    local Thickness = ClampNumber(Settings.Thickness, 1, 0.5, 8)
    local Transparency = ClampNumber(Settings.Transparency, 1, 0, 1)
    for Index, Direction in Directions do
        local Rotated = Vector2.new(Direction.X * math.cos(Angle) - Direction.Y * math.sin(Angle), Direction.X * math.sin(Angle) + Direction.Y * math.cos(Angle))
        local From = Center + Rotated * Gap
        local To = Center + Rotated * (Gap + Size)
        local Enabled = not (Settings.TStyle and Index == 1)
        SetLine(Visual.Outlines[Index], From, To, self.Settings.Colors.Outline, Thickness + 2, Transparency, Settings.Outline and Enabled)
        SetLine(Visual.Lines[Index], From, To, Color, Thickness, Transparency, Enabled)
    end
    local Radius = ClampNumber(Settings.CenterDotRadius, 2, 1, 12)
    SetCircle(Visual.DotOutline, Center, Radius + 1, self.Settings.Colors.Outline, Thickness + 2, Transparency, Settings.CenterDotFilled, 24, Settings.CenterDot and Settings.Outline)
    SetCircle(Visual.Dot, Center, Radius, Color, Thickness, Transparency, Settings.CenterDotFilled, 24, Settings.CenterDot)
end

function Controller:_RenderEntry(Entry, Now)
    local Model, Root, Humanoid, Player = self:_ResolveEntry(Entry)
    if not Model then
        HideVisual(Entry.Visual)
        if Entry.Highlight then
            Entry.Highlight.Enabled = false
        end
        return
    end
    local Camera = self.Camera
    local Distance = (Camera.CFrame.Position - Root.Position).Magnitude
    if not self:_IsAllowed(Entry, Model, Humanoid, Player, Distance) then
        HideVisual(Entry.Visual)
        if Entry.Highlight then
            Entry.Highlight.Enabled = false
        end
        return
    end
    local Health = Humanoid and Humanoid.MaxHealth > 0 and math.clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1) or 1
    local Visible = self:_CheckVisible(Entry, Root, Model, Now)
    if self.Settings.VisibilityCheck and self.Settings.OcclusionMode == "Hide" and not Visible then
        HideVisual(Entry.Visual)
        if Entry.Highlight then
            Entry.Highlight.Enabled = false
        end
        return
    end
    local ColorA, ColorB = self:_ResolveColors(Entry, Player, Health, Visible, Now)
    local Style = self:_GetStyle(Entry)
    local Maximum = tonumber(Entry.Info.MaxDistance) or Style and tonumber(Style.MaxDistance) or tonumber(self.Settings.MaxDistance) or 2500
    local Opacity = self:_ResolveOpacity(Distance, Maximum, Visible)
    self:_RefreshTextCache(Entry, Model, Player, Distance, Now)
    local Bounds = self:_ProjectBounds(Model, Root)
    if not Bounds then
        HideVisual(Entry.Visual)
        return
    end
    if self:_IsVisualAllowed(Entry, "OffscreenArrow") then
        self:_DrawArrow(Entry.Visual, Entry, Root, ColorA, ColorB, Health, Visible, Distance, Bounds.OnScreen, Now, Opacity)
    else
        SetVisible(Entry.Visual.Arrow, false)
        SetVisible(Entry.Visual.ArrowOutline, false)
        SetVisible(Entry.Visual.ArrowText, false)
    end
    self:_UpdateHighlight(Entry, Model, Health, ColorA, ColorB, Visible, Now, Opacity)
    if not Bounds.OnScreen then
        for _, Name in { "Box", "BoxOutline", "Skeleton", "SkeletonOutline" } do
            for _, Object in Entry.Visual[Name] do
                SetVisible(Object, false)
            end
        end
        for _, Name in { "Fill", "Name", "Team", "Distance", "Tool", "HealthText", "HealthValue", "Category", "Flags", "HealthBack", "HealthFill", "Tracer", "TracerOutline", "HeadDot", "HeadDotOutline" } do
            SetVisible(Entry.Visual[Name], false)
        end
        return
    end
    local AllowText = Distance <= (tonumber(Entry.Info.TextDistance) or tonumber(self.Settings.TextDistance) or 600)
    if self:_IsVisualAllowed(Entry, "Box") then
        self:_DrawBox(Entry.Visual, Bounds, ColorA, ColorB, Opacity)
    else
        for _, Name in { "Box", "BoxOutline" } do
            for _, Object in Entry.Visual[Name] do
                SetVisible(Object, false)
            end
        end
        SetVisible(Entry.Visual.Fill, false)
    end
    local TextSize, Font = self:_DrawText(Entry.Visual, Entry, Bounds, Health, ColorA, ColorB, Distance, AllowText, Opacity)
    if self:_IsVisualAllowed(Entry, "HealthBar") then
        self:_DrawHealth(Entry.Visual, Bounds, Health, ColorA, ColorB, TextSize, Font, AllowText, Visible, Now, Opacity)
    else
        SetVisible(Entry.Visual.HealthBack, false)
        SetVisible(Entry.Visual.HealthFill, false)
        SetVisible(Entry.Visual.HealthValue, false)
    end
    if self:_IsVisualAllowed(Entry, "Tracer") then
        self:_DrawTracer(Entry.Visual, Bounds, ColorA, ColorB, Health, Visible, Now, Opacity)
    else
        SetVisible(Entry.Visual.Tracer, false)
        SetVisible(Entry.Visual.TracerOutline, false)
    end
    if self:_IsVisualAllowed(Entry, "HeadDot") then
        self:_DrawHeadDot(Entry.Visual, Model, ColorA, ColorB, Health, Visible, Now, Distance, Opacity)
    else
        SetVisible(Entry.Visual.HeadDot, false)
        SetVisible(Entry.Visual.HeadDotOutline, false)
    end
    if self:_IsVisualAllowed(Entry, "Skeleton") then
        self:_DrawSkeleton(Entry.Visual, Entry, Model, ColorA, ColorB, Health, Visible, Now, Opacity)
    else
        for _, Name in { "Skeleton", "SkeletonOutline" } do
            for _, Object in Entry.Visual[Name] do
                SetVisible(Object, false)
            end
        end
    end
end

function Controller:_Render(DeltaTime)
    if self.Destroyed or not self.Running then
        return
    end
    self.FrameAccumulator += DeltaTime
    local Step = 1 / ClampNumber(self.Settings.UpdateRate, 60, 5, 240)
    if self.FrameAccumulator < Step then
        return
    end
    self.FrameAccumulator %= Step
    self.Camera = Workspace.CurrentCamera or self.Camera
    if not self.Camera then
        return
    end
    if not self.Settings.Enabled then
        if not self.IdleHidden then
            self.IdleHidden = true
            self:HideAll()
        end
        return
    end
    self.IdleHidden = false
    local Now = os.clock()
    self:_RenderCrosshair(Now)
    local MaximumRendered = math.floor(ClampNumber(self.Settings.MaxRendered, 0, 0, 1000))
    if MaximumRendered == 0 then
        for _, Entry in self.Entries do
            local Success, Error = pcall(self._RenderEntry, self, Entry, Now)
            if not Success then
                self.LastError = tostring(Error)
                HideVisual(Entry.Visual)
            end
        end
        return
    end
    local Candidates = {}
    for _, Entry in self.Entries do
        local Model, Root, Humanoid, Player = self:_ResolveEntry(Entry)
        local Distance = Root and (self.Camera.CFrame.Position - Root.Position).Magnitude or math.huge
        if Model and self:_IsAllowed(Entry, Model, Humanoid, Player, Distance) then
            table.insert(Candidates, {
                Entry = Entry,
                Distance = Distance,
                Priority = tonumber(Entry.Info.Priority) or 0,
                Name = NormalizeToken(Entry.Object and Entry.Object.Name),
            })
        else
            HideVisual(Entry.Visual)
            if Entry.Highlight then
                Entry.Highlight.Enabled = false
            end
        end
    end
    if MaximumRendered > 0 and #Candidates > MaximumRendered then
        local Mode = tostring(self.Settings.SortMode or "Distance")
        table.sort(Candidates, function(A, B)
            if Mode == "Priority" and A.Priority ~= B.Priority then
                return A.Priority > B.Priority
            elseif Mode == "Name" and A.Name ~= B.Name then
                return A.Name < B.Name
            end
            return A.Distance < B.Distance
        end)
    end
    for Index, Candidate in Candidates do
        local Entry = Candidate.Entry
        if MaximumRendered > 0 and Index > MaximumRendered then
            HideVisual(Entry.Visual)
            if Entry.Highlight then
                Entry.Highlight.Enabled = false
            end
            continue
        end
        local Success, Error = pcall(self._RenderEntry, self, Entry, Now)
        if not Success then
            self.LastError = tostring(Error)
            HideVisual(Entry.Visual)
        end
    end
end

function Controller:Start()
    if self.Destroyed or self.Running then
        return self
    end
    self.Running = true
    self.RenderConnection = self:_GiveConnection(RunService.RenderStepped:Connect(function(DeltaTime)
        self:_Render(DeltaTime)
    end))
    return self
end

function Controller:Stop()
    if not self.Running then
        return self
    end
    self.Running = false
    self:_Disconnect(self.RenderConnection)
    self.RenderConnection = nil
    self:HideAll()
    return self
end

function Controller:WrapObject(Object, Info)
    assert(typeof(Object) == "Instance", "Object must be a Roblox Instance.")
    if self.ObjectEntries[Object] then
        return self.ObjectEntries[Object].Id
    end
    Info = Info or {}
    local Player = GetPlayerFromObject(Object)
    local Model = ResolveModel(Object)
    local Kind = Info.Kind
    if not Kind then
        if Player then
            Kind = "Player"
        elseif Model and Model:IsA("Model") and GetHumanoid(Model) then
            Kind = "NPC"
        else
            Kind = "Part"
        end
    end
    local Id = tostring(Info.Id or self:_CreateId())
    if self.Entries[Id] then
        self:UnwrapObject(Id)
    end
    local Entry = {
        Id = Id,
        Object = Object,
        Player = Player,
        Model = Model,
        Kind = Kind,
        Info = Info,
        Visual = CreateVisual(math.floor(ClampNumber(self.Settings.Skeleton.MaxJoints, 24, 2, 40))),
        TextCache = {},
        NextTextAt = 0,
        NextVisibilityAt = 0,
        NextJointAt = 0,
    }
    self.Entries[Id] = Entry
    self.ObjectEntries[Object] = Entry
    return Id
end

function Controller:GetEntry(ObjectOrId)
    if typeof(ObjectOrId) == "Instance" then
        return self.ObjectEntries[ObjectOrId]
    end
    return self.Entries[tostring(ObjectOrId)]
end

function Controller:UnwrapObject(ObjectOrId)
    local Entry = self:GetEntry(ObjectOrId)
    if not Entry then
        return false
    end
    self.Entries[Entry.Id] = nil
    if Entry.Object then
        self.ObjectEntries[Entry.Object] = nil
    end
    DestroyVisual(Entry.Visual)
    if Entry.Highlight then
        Entry.Highlight:Destroy()
    end
    return true
end

function Controller:WrapPlayers(Info)
    Info = Info or {}
    for _, Player in Players:GetPlayers() do
        if Player ~= self.LocalPlayer or self.Settings.IncludeLocalPlayer then
            self:WrapObject(Player, Merge(DeepCopy(Info), { Kind = "Player" }))
        end
    end
    if not self.PlayerAddedConnection then
        self.PlayerAddedConnection = self:_GiveConnection(Players.PlayerAdded:Connect(function(Player)
            if Player ~= self.LocalPlayer or self.Settings.IncludeLocalPlayer then
                self:WrapObject(Player, Merge(DeepCopy(Info), { Kind = "Player" }))
            end
        end))
        self.PlayerRemovingConnection = self:_GiveConnection(Players.PlayerRemoving:Connect(function(Player)
            self:UnwrapObject(Player)
        end))
    end
    return self
end

function Controller:UnwrapPlayers()
    local Pending = {}
    for _, Entry in self.Entries do
        if Entry.Kind == "Player" then
            table.insert(Pending, Entry.Id)
        end
    end
    for _, Id in Pending do
        self:UnwrapObject(Id)
    end
    self:_Disconnect(self.PlayerAddedConnection)
    self:_Disconnect(self.PlayerRemovingConnection)
    self.PlayerAddedConnection = nil
    self.PlayerRemovingConnection = nil
    return self
end

function Controller:ScanNPCs(Container, Info)
    Container = Container or Workspace
    Info = Info or {}
    local Count = 0
    for _, Descendant in Container:GetDescendants() do
        if Descendant:IsA("Model") and GetHumanoid(Descendant) and not Players:GetPlayerFromCharacter(Descendant) then
            local Allowed = true
            if type(Info.Predicate) == "function" then
                local Success, Result = pcall(Info.Predicate, Descendant)
                Allowed = Success and Result == true
            end
            if Allowed and not self.ObjectEntries[Descendant] then
                local EntryInfo = DeepCopy(Info)
                EntryInfo.Kind = "NPC"
                self:WrapObject(Descendant, EntryInfo)
                Count += 1
            end
        end
    end
    return Count
end

function Controller:WatchNPCs(Container, Info)
    Container = Container or Workspace
    Info = Info or {}
    local Watcher = {
        Container = Container,
        Info = Info,
        Connections = {},
        Controller = self,
        Destroyed = false,
    }

    function Watcher:Scan()
        if self.Destroyed then
            return 0
        end
        return self.Controller:ScanNPCs(self.Container, self.Info)
    end

    function Watcher:Destroy()
        if self.Destroyed then
            return
        end
        self.Destroyed = true
        for _, Connection in self.Connections do
            pcall(function()
                Connection:Disconnect()
            end)
        end
        table.clear(self.Connections)
        local Index = table.find(self.Controller.Watchers, self)
        if Index then
            table.remove(self.Controller.Watchers, Index)
        end
    end

    table.insert(Watcher.Connections, Container.DescendantAdded:Connect(function(Descendant)
        if Descendant:IsA("Humanoid") then
            local Model = Descendant.Parent
            if Model and Model:IsA("Model") and not Players:GetPlayerFromCharacter(Model) then
                local Allowed = true
                if type(Info.Predicate) == "function" then
                    local Success, Result = pcall(Info.Predicate, Model)
                    Allowed = Success and Result == true
                end
                if Allowed then
                    local EntryInfo = DeepCopy(Info)
                    EntryInfo.Kind = "NPC"
                    self:WrapObject(Model, EntryInfo)
                end
            end
        end
    end))
    table.insert(Watcher.Connections, Container.DescendantRemoving:Connect(function(Descendant)
        if Descendant:IsA("Model") and self.ObjectEntries[Descendant] and self.ObjectEntries[Descendant].Kind == "NPC" then
            self:UnwrapObject(Descendant)
        end
    end))
    table.insert(self.Watchers, Watcher)
    Watcher:Scan()
    return Watcher
end

function Controller:SetAutomaticNPCs(Enabled, Container, Info)
    if self.AutoNPCWatcher then
        self.AutoNPCWatcher:Destroy()
        self.AutoNPCWatcher = nil
    end
    if Enabled then
        self.AutoNPCWatcher = self:WatchNPCs(Container or Workspace, Info or {})
    end
    return self.AutoNPCWatcher
end

function Controller:HideAll()
    for _, Entry in self.Entries do
        HideVisual(Entry.Visual)
        if Entry.Highlight then
            Entry.Highlight.Enabled = false
        end
    end
    for _, Visual in self.PreviewEntities do
        HideVisual(Visual)
    end
    HideCrosshair(self.CrosshairVisual)
end

function Controller:_RenderPreview(Visual, Context, UseContext)
    if type(Context) ~= "table" or type(Context.Bounds) ~= "table" or Context.Visible ~= true then
        HideVisual(Visual)
        return
    end
    local Bounds = Context.Bounds
    local X = tonumber(Bounds.AbsoluteX or Bounds.X)
    local Y = tonumber(Bounds.AbsoluteY or Bounds.Y)
    local Width = tonumber(Bounds.Width)
    local Height = tonumber(Bounds.Height)
    if not X or not Y or not Width or not Height or Width <= 0 or Height <= 0 then
        HideVisual(Visual)
        return
    end
    local ScreenBounds = {
        X = X,
        Y = Y,
        Width = Width,
        Height = Height,
        Center = Vector2.new(X + Width * 0.5, Y + Height * 0.5),
        OnScreen = true,
    }
    local ColorA = typeof(Context.Color) == "Color3" and Context.Color or self.Settings.Colors.Enemy
    local ColorB = typeof(Context.GradientColor) == "Color3" and Context.GradientColor or self.Settings.Colors.Gradient
    local Health = math.clamp(tonumber(Context.Health) or 1, 0, 1)
    self:_DrawBox(Visual, ScreenBounds, ColorA, ColorB, 1)
    local Entry = {
        Info = {},
        TextCache = {
            Name = Context.Name or "Preview Player",
            Team = Context.Team or "",
            Tool = Context.Weapon or "",
            Category = Context.Category or "Player",
            Flags = Context.Flags or "",
        },
    }
    local Size, Font = self:_DrawText(Visual, Entry, ScreenBounds, Health, ColorA, ColorB, tonumber(Context.Distance) or 86, true, 1)
    self:_DrawHealth(Visual, ScreenBounds, Health, ColorA, ColorB, Size, Font, true, true, os.clock(), 1)
    if UseContext then
        if Context.BoxVisible == false then
            for _, Name in { "Box", "BoxOutline" } do
                for _, Object in Visual[Name] do
                    SetVisible(Object, false)
                end
            end
            SetVisible(Visual.Fill, false)
        end
        if Context.NameVisible == false then
            SetVisible(Visual.Name, false)
        end
        if Context.TeamVisible == false then
            SetVisible(Visual.Team, false)
        end
        if Context.DistanceVisible == false then
            SetVisible(Visual.Distance, false)
        end
        if Context.WeaponVisible == false then
            SetVisible(Visual.Tool, false)
        end
        if Context.HealthVisible == false then
            SetVisible(Visual.HealthBack, false)
            SetVisible(Visual.HealthFill, false)
            SetVisible(Visual.HealthValue, false)
        end
    end
    SetVisible(Visual.Tracer, false)
    SetVisible(Visual.TracerOutline, false)
    SetVisible(Visual.HeadDot, false)
    SetVisible(Visual.HeadDotOutline, false)
    SetVisible(Visual.Arrow, false)
    SetVisible(Visual.ArrowOutline, false)
    SetVisible(Visual.ArrowText, false)
    for _, Name in { "Skeleton", "SkeletonOutline" } do
        for _, Object in Visual[Name] do
            SetVisible(Object, false)
        end
    end
end

function Controller:CreatePreviewAdapter(Info)
    Info = Info or {}
    local Owner = self
    local Adapter = {
        Continuous = true,
        UseContext = Info.UseContext == true,
    }

    function Adapter:AttachPreview(Preview, Context)
        local Visual = Owner.PreviewEntities[Preview]
        if not Visual then
            Visual = CreateVisual(math.floor(ClampNumber(Owner.Settings.Skeleton.MaxJoints, 24, 2, 40)))
            Owner.PreviewEntities[Preview] = Visual
        end
        Owner:_RenderPreview(Visual, Context, self.UseContext)
        return Visual
    end

    function Adapter:UpdatePreview(Preview, Context)
        local Visual = Owner.PreviewEntities[Preview]
        if Visual then
            local Success, Error = pcall(Owner._RenderPreview, Owner, Visual, Context, self.UseContext)
            if not Success then
                Owner.LastError = tostring(Error)
                HideVisual(Visual)
            end
        end
    end

    function Adapter:SetPreviewVisible(Preview, Visible)
        local Visual = Owner.PreviewEntities[Preview]
        if Visual and not Visible then
            HideVisual(Visual)
        end
    end

    function Adapter:DetachPreview(Preview)
        local Visual = Owner.PreviewEntities[Preview]
        Owner.PreviewEntities[Preview] = nil
        DestroyVisual(Visual)
    end

    function Adapter:Destroy()
        for Preview, Visual in Owner.PreviewEntities do
            Owner.PreviewEntities[Preview] = nil
            DestroyVisual(Visual)
        end
    end

    return Adapter
end

function Controller:GetStats()
    local Stats = {
        Total = 0,
        Players = 0,
        NPCs = 0,
        Parts = 0,
        Running = self.Running,
        Enabled = self.Settings.Enabled,
        Available = self.Available,
        LastError = self.LastError,
    }
    for _, Entry in self.Entries do
        Stats.Total += 1
        if Entry.Kind == "Player" then
            Stats.Players += 1
        elseif Entry.Kind == "NPC" then
            Stats.NPCs += 1
        else
            Stats.Parts += 1
        end
    end
    return Stats
end

function Controller:Restart(Rebuild)
    self:Stop()
    if Rebuild then
        local Objects = {}
        for _, Entry in self.Entries do
            table.insert(Objects, { Entry.Object, DeepCopy(Entry.Info) })
        end
        local Ids = {}
        for Id in self.Entries do
            table.insert(Ids, Id)
        end
        for _, Id in Ids do
            self:UnwrapObject(Id)
        end
        for _, Data in Objects do
            if Data[1] and Data[1].Parent then
                self:WrapObject(Data[1], Data[2])
            end
        end
    end
    self:Start()
    return self
end

function Controller:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    self:Stop()
    local Connections = table.clone(self.Connections)
    for _, Connection in Connections do
        self:_Disconnect(Connection)
    end
    local Watchers = table.clone(self.Watchers)
    for _, Watcher in Watchers do
        Watcher:Destroy()
    end
    local Ids = {}
    for Id in self.Entries do
        table.insert(Ids, Id)
    end
    for _, Id in Ids do
        self:UnwrapObject(Id)
    end
    for Preview, Visual in self.PreviewEntities do
        self.PreviewEntities[Preview] = nil
        DestroyVisual(Visual)
    end
    DestroyCrosshair(self.CrosshairVisual)
    self.CrosshairVisual = nil
    table.clear(self.Connections)
end

Controller.Exit = Controller.Destroy
Controller.Wrap = Controller.WrapObject
Controller.Unwrap = Controller.UnwrapObject
Controller.TrackNPCs = Controller.WatchNPCs

return UniversalESP
