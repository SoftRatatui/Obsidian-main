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
    Version = "1.0.0",
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
    MaxDistance = 2500,
    TextDistance = 600,
    UpdateRate = 60,
    TextUpdateRate = 8,
    Box = {
        Enabled = true,
        Style = "Corner",
        Dynamic = true,
        Scale = 1,
        Thickness = 1,
        Transparency = 1,
        Outline = true,
        OutlineThickness = 3,
        Fill = false,
        FillTransparency = 0.12,
        Gradient = true,
        Rainbow = false,
        RainbowSpeed = 0.12,
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
        RelativeSize = true,
        Outline = true,
        Font = "Plex",
        Separator = "  |  ",
    },
    HealthBar = {
        Enabled = true,
        Position = "Left",
        Width = 2,
        Offset = 5,
        Outline = true,
        Text = false,
    },
    Tracer = {
        Enabled = false,
        Origin = "Bottom",
        Target = "Bottom",
        Thickness = 1,
        Transparency = 1,
        Outline = true,
    },
    Skeleton = {
        Enabled = false,
        Thickness = 1,
        Transparency = 1,
        Outline = true,
        MaxJoints = 24,
    },
    HeadDot = {
        Enabled = false,
        Filled = false,
        Radius = 3,
        Sides = 20,
        Thickness = 1,
        Transparency = 1,
        Outline = true,
    },
    OffscreenArrow = {
        Enabled = false,
        Radius = 190,
        Size = 12,
        Filled = true,
        Transparency = 1,
        Outline = true,
    },
    Highlight = {
        Enabled = false,
        FillTransparency = 0.72,
        OutlineTransparency = 0.08,
        DepthMode = "AlwaysOnTop",
        HealthColor = false,
    },
    Colors = {
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

local function SetText(Object, Text, Position, Color, Size, Font, Outline, OutlineColor, Center, Visible)
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
    Object.Transparency = 1
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

local Controller = {}
Controller.__index = Controller

function UniversalESP.new(Info)
    Info = Info or {}
    local Self = setmetatable({
        Available = UniversalESP.Available,
        Settings = Merge(DeepCopy(Defaults), Info.Settings or Info),
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
        RaycastParams = RaycastParams.new(),
    }, Controller)

    Self.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    Self.RaycastParams.IgnoreWater = true
    Self.Settings.UpdateRate = ClampNumber(Self.Settings.UpdateRate, 60, 5, 240)
    Self.Settings.TextUpdateRate = ClampNumber(Self.Settings.TextUpdateRate, 8, 1, 60)
    Self.Settings.MaxDistance = ClampNumber(Self.Settings.MaxDistance, 2500, 1, 100000)
    Self.Settings.TextDistance = ClampNumber(Self.Settings.TextDistance, 600, 1, 100000)

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
    if self.Settings.TeamCheck and self:_IsSameTeam(Player) then
        return false
    end
    if self.Settings.AliveCheck and Humanoid and Humanoid.Health <= 0 then
        return false
    end
    local Maximum = tonumber(Entry.Info.MaxDistance) or tonumber(self.Settings.MaxDistance) or 2500
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
    return type(Allowed) ~= "table" or Allowed[Name] ~= false
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
    local ColorA = Entry.Info.Color
    if typeof(ColorA) ~= "Color3" then
        if Entry.Kind == "NPC" then
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
    if self.Settings.VisibilityCheck then
        ColorA = Visible and Colors.Visible or Colors.Occluded
    end
    if self.Settings.Box.Rainbow then
        local Speed = ClampNumber(self.Settings.Box.RainbowSpeed, 0.12, 0.01, 3)
        ColorA = Color3.fromHSV((Now * Speed) % 1, 0.72, 1)
    end
    local ColorB = typeof(Entry.Info.GradientColor) == "Color3" and Entry.Info.GradientColor or Colors.Gradient
    if self.Settings.Highlight.HealthColor then
        ColorB = Colors.HealthLow:Lerp(Colors.HealthHigh, Health)
    end
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
    Size *= ClampNumber(self.Settings.Box.Scale, 1, 0.25, 3)
    return CFrameValue, Size
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
        return {
            X = CenterX - Width * 0.5,
            Y = MinimumY,
            Width = Width,
            Height = Height,
            Center = Vector2.new(CenterX, MinimumY + Height * 0.5),
            OnScreen = Top.Z > 0 and Bottom.Z > 0 and CenterX + Width * 0.5 >= 0 and MinimumY + Height >= 0 and CenterX - Width * 0.5 <= Viewport.X and MinimumY <= Viewport.Y,
            Behind = Top.Z <= 0 and Bottom.Z <= 0,
            RootPosition = Camera:WorldToViewportPoint(Root.Position),
        }
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
    return {
        X = MinimumX,
        Y = MinimumY,
        Width = Width,
        Height = Height,
        Center = Vector2.new(MinimumX + Width * 0.5, MinimumY + Height * 0.5),
        Points = Points,
        OnScreen = MaximumX >= 0 and MaximumY >= 0 and MinimumX <= Viewport.X and MinimumY <= Viewport.Y,
        Behind = false,
        RootPosition = Camera:WorldToViewportPoint(Root.Position),
    }
end

function Controller:_GetTextSize(Height)
    local Base = ClampNumber(self.Settings.Text.Size, 13, 8, 32)
    if not self.Settings.Text.RelativeSize then
        return Base
    end
    return math.clamp(math.floor(Base * math.clamp(Height / 180, 0.72, 1.18) + 0.5), 8, 32)
end

function Controller:_RefreshTextCache(Entry, Model, Player, Distance, Now)
    if Now < (Entry.NextTextAt or 0) then
        return
    end
    Entry.NextTextAt = Now + 1 / ClampNumber(self.Settings.TextUpdateRate, 8, 1, 60)
    local Info = Entry.Info
    Entry.TextCache = {
        Name = GetObjectName(Entry.Object, Model, Player, Info, self.Settings.Text.DisplayName),
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

function Controller:_DrawBox(Visual, Bounds, ColorA, ColorB)
    local Settings = self.Settings.Box
    local Enabled = Settings.Enabled == true
    local Style = tostring(Settings.Style or "Corner")
    local OutlineColor = self.Settings.Colors.Outline
    local Thickness = ClampNumber(Settings.Thickness, 1, 0.5, 8)
    local OutlineThickness = math.max(Thickness + 1, ClampNumber(Settings.OutlineThickness, 3, 1, 10))
    local Transparency = ClampNumber(Settings.Transparency, 1, 0, 1)
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
        local CornerWidth = math.max(2, Bounds.Width * 0.28)
        local CornerHeight = math.max(2, Bounds.Height * 0.22)
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
        Visual.Fill.Transparency = ClampNumber(Settings.FillTransparency, 0.12, 0, 1)
        Visual.Fill.Filled = true
        Visual.Fill.Visible = Enabled and Settings.Fill == true and Style ~= "3D"
    end
end

function Controller:_DrawHealth(Visual, Bounds, Health, ColorA, TextSize, Font, AllowText)
    local Settings = self.Settings.HealthBar
    local Enabled = Settings.Enabled == true
    local Position = tostring(Settings.Position or "Left")
    local Offset = ClampNumber(Settings.Offset, 5, 1, 24)
    local Width = ClampNumber(Settings.Width, 2, 1, 8)
    local OutlineColor = self.Settings.Colors.Outline
    local HealthColor = self.Settings.Colors.HealthLow:Lerp(self.Settings.Colors.HealthHigh, Health)
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
    SetLine(Visual.HealthBack, From, To, OutlineColor, Width + 2, 0.92, Enabled and Settings.Outline == true)
    SetLine(Visual.HealthFill, FillFrom, FillTo, HealthColor, Width, 1, Enabled)
    local HealthValue = math.floor(Health * 100 + 0.5)
    SetText(
        Visual.HealthValue,
        tostring(HealthValue),
        Vector2.new(Bounds.X - Offset - 4, Bounds.Y + Bounds.Height * (1 - Health) - TextSize * 0.5),
        HealthColor,
        math.max(8, TextSize - 2),
        Font,
        true,
        OutlineColor,
        true,
        Enabled and Settings.Text == true and AllowText
    )
end

function Controller:_DrawText(Visual, Entry, Bounds, Health, ColorA, ColorB, Distance, AllowText)
    local Settings = self.Settings.Text
    local Cache = Entry.TextCache or {}
    local Size = self:_GetTextSize(Bounds.Height)
    local Font = ResolveDrawingFont(Settings.Font)
    local OutlineColor = self.Settings.Colors.Outline
    local TextColor = self.Settings.Colors.Text
    local TopY = Bounds.Y - Size - 2
    local BottomY = Bounds.Y + Bounds.Height + 2
    local CenterX = Bounds.X + Bounds.Width * 0.5
    local TopIndex = 0
    local BottomIndex = 0

    local function Top(Object, Value, Enabled, Color)
        SetText(Object, Value or "", Vector2.new(CenterX, TopY - TopIndex * (Size + 1)), Color or TextColor, Size, Font, Settings.Outline, OutlineColor, true, AllowText and Enabled)
        if AllowText and Enabled and Value and Value ~= "" then
            TopIndex += 1
        end
    end

    local function Bottom(Object, Value, Enabled, Color)
        SetText(Object, Value or "", Vector2.new(CenterX, BottomY + BottomIndex * (Size + 1)), Color or TextColor, math.max(8, Size - 1), Font, Settings.Outline, OutlineColor, true, AllowText and Enabled)
        if AllowText and Enabled and Value and Value ~= "" then
            BottomIndex += 1
        end
    end

    Top(Visual.Name, Cache.Name, Settings.Name == true, ColorA)
    Top(Visual.Team, Cache.Team ~= "" and string.format("[%s]", Cache.Team) or "", Settings.Team == true, ColorB)
    Top(Visual.Category, Cache.Category, Settings.Category == true, ColorB)
    Bottom(Visual.Distance, string.format("%dm", math.floor(Distance + 0.5)), Settings.Distance == true, ColorB)
    Bottom(Visual.Tool, Cache.Tool, Settings.Tool == true, TextColor)
    Bottom(Visual.Flags, Cache.Flags, Settings.Flags == true, ColorB)
    Bottom(Visual.HealthText, string.format("%d%%", math.floor(Health * 100 + 0.5)), Settings.Health == true, self.Settings.Colors.HealthLow:Lerp(self.Settings.Colors.HealthHigh, Health))
    return Size, Font
end

function Controller:_DrawTracer(Visual, Bounds, ColorA)
    local Settings = self.Settings.Tracer
    local Enabled = Settings.Enabled == true
    local Viewport = self.Camera.ViewportSize
    local Origin
    if Settings.Origin == "Center" then
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
    local Thickness = ClampNumber(Settings.Thickness, 1, 0.5, 8)
    local Transparency = ClampNumber(Settings.Transparency, 1, 0, 1)
    SetLine(Visual.TracerOutline, Origin, Target, self.Settings.Colors.Outline, Thickness + 2, Transparency, Enabled and Settings.Outline == true)
    SetLine(Visual.Tracer, Origin, Target, self.Settings.Colors.Tracer or ColorA, Thickness, Transparency, Enabled)
end

function Controller:_DrawHeadDot(Visual, Model, ColorA)
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
    local Thickness = ClampNumber(Settings.Thickness, 1, 0.5, 8)
    local Position = Vector2.new(Screen.X, Screen.Y)
    local Sides = math.floor(ClampNumber(Settings.Sides, 20, 8, 64))
    SetCircle(Visual.HeadDotOutline, Position, Radius + 1, self.Settings.Colors.Outline, Thickness + 2, Settings.Transparency, Settings.Filled, Sides, Settings.Outline)
    SetCircle(Visual.HeadDot, Position, Radius, self.Settings.Colors.HeadDot or ColorA, Thickness, Settings.Transparency, Settings.Filled, Sides, true)
end

function Controller:_DrawSkeleton(Visual, Entry, Model, ColorA, Now)
    local Settings = self.Settings.Skeleton
    local Joints = Settings.Enabled and self:_UpdateJointCache(Entry, Model, Now) or {}
    local Thickness = ClampNumber(Settings.Thickness, 1, 0.5, 8)
    local Transparency = ClampNumber(Settings.Transparency, 1, 0, 1)
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
            SetLine(Visual.Skeleton[Index], From, To, self.Settings.Colors.Skeleton or ColorA, Thickness, Transparency, true)
        else
            SetVisible(Visual.SkeletonOutline[Index], false)
            SetVisible(Visual.Skeleton[Index], false)
        end
    end
end

function Controller:_DrawArrow(Visual, Root, ColorA, OnScreen)
    local Settings = self.Settings.OffscreenArrow
    if not Settings.Enabled or OnScreen then
        SetVisible(Visual.Arrow, false)
        SetVisible(Visual.ArrowOutline, false)
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
    local Tip = Center + Direction * Radius
    local Perpendicular = Vector2.new(-Direction.Y, Direction.X)
    local Base = Tip - Direction * Size
    local A = Tip
    local B = Base + Perpendicular * Size * 0.58
    local C = Base - Perpendicular * Size * 0.58
    SetTriangle(Visual.ArrowOutline, A, B, C, self.Settings.Colors.Outline, 3, Settings.Transparency, Settings.Filled, Settings.Outline)
    SetTriangle(Visual.Arrow, A, B, C, self.Settings.Colors.Arrow or ColorA, 1, Settings.Transparency, Settings.Filled, true)
end

function Controller:_UpdateHighlight(Entry, Model, Health, ColorA, ColorB, Visible)
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
    Highlight.FillColor = Settings.HealthColor and self.Settings.Colors.HealthLow:Lerp(self.Settings.Colors.HealthHigh, Health) or self.Settings.Colors.HighlightFill or ColorA
    Highlight.OutlineColor = self.Settings.Colors.HighlightOutline or ColorB
    Highlight.FillTransparency = ClampNumber(Settings.FillTransparency, 0.72, 0, 1)
    Highlight.OutlineTransparency = ClampNumber(Settings.OutlineTransparency, 0.08, 0, 1)
    Highlight.Enabled = true
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
    local ColorA, ColorB = self:_ResolveColors(Entry, Player, Health, Visible, Now)
    local Bounds = self:_ProjectBounds(Model, Root)
    if not Bounds then
        HideVisual(Entry.Visual)
        return
    end
    self:_DrawArrow(Entry.Visual, Root, ColorA, Bounds.OnScreen)
    self:_UpdateHighlight(Entry, Model, Health, ColorA, ColorB, Visible)
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
    self:_RefreshTextCache(Entry, Model, Player, Distance, Now)
    local AllowText = Distance <= (tonumber(Entry.Info.TextDistance) or tonumber(self.Settings.TextDistance) or 600)
    if self:_IsVisualAllowed(Entry, "Box") then
        self:_DrawBox(Entry.Visual, Bounds, ColorA, ColorB)
    else
        for _, Name in { "Box", "BoxOutline" } do
            for _, Object in Entry.Visual[Name] do
                SetVisible(Object, false)
            end
        end
        SetVisible(Entry.Visual.Fill, false)
    end
    local TextSize, Font = self:_DrawText(Entry.Visual, Entry, Bounds, Health, ColorA, ColorB, Distance, AllowText)
    if self:_IsVisualAllowed(Entry, "HealthBar") then
        self:_DrawHealth(Entry.Visual, Bounds, Health, ColorA, TextSize, Font, AllowText)
    else
        SetVisible(Entry.Visual.HealthBack, false)
        SetVisible(Entry.Visual.HealthFill, false)
    end
    if self:_IsVisualAllowed(Entry, "Tracer") then
        self:_DrawTracer(Entry.Visual, Bounds, ColorA)
    else
        SetVisible(Entry.Visual.Tracer, false)
        SetVisible(Entry.Visual.TracerOutline, false)
    end
    if self:_IsVisualAllowed(Entry, "HeadDot") then
        self:_DrawHeadDot(Entry.Visual, Model, ColorA)
    else
        SetVisible(Entry.Visual.HeadDot, false)
        SetVisible(Entry.Visual.HeadDotOutline, false)
    end
    if self:_IsVisualAllowed(Entry, "Skeleton") then
        self:_DrawSkeleton(Entry.Visual, Entry, Model, ColorA, Now)
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
    for _, Entry in self.Entries do
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
    self:_DrawBox(Visual, ScreenBounds, ColorA, ColorB)
    local Entry = {
        TextCache = {
            Name = Context.Name or "Preview Player",
            Team = Context.Team or "",
            Tool = Context.Weapon or "",
            Category = Context.Category or "Player",
            Flags = Context.Flags or "",
        },
    }
    local Size, Font = self:_DrawText(Visual, Entry, ScreenBounds, Health, ColorA, ColorB, tonumber(Context.Distance) or 86, true)
    self:_DrawHealth(Visual, ScreenBounds, Health, ColorA, Size, Font, true)
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
    table.clear(self.Connections)
end

Controller.Exit = Controller.Destroy
Controller.Wrap = Controller.WrapObject
Controller.Unwrap = Controller.UnwrapObject
Controller.TrackNPCs = Controller.WatchNPCs

return UniversalESP
