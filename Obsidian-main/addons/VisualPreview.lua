local VisualPreview = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local function ResolveCharacter(Source)
    if type(Source) == "function" then
        local Success, Result = pcall(Source)
        if Success then
            return ResolveCharacter(Result)
        end
        return nil
    end

    if typeof(Source) ~= "Instance" then
        return nil
    end

    if Source:IsA("Player") then
        return Source.Character
    end

    if Source:IsA("Model") then
        return Source
    end

    return nil
end

local function CloneCharacter(Source)
    local Character = ResolveCharacter(Source)
    if not Character or not Character.Parent then
        return nil
    end

    local PreviousArchivable = Character.Archivable
    Character.Archivable = true
    local Success, Clone = pcall(function()
        return Character:Clone()
    end)
    Character.Archivable = PreviousArchivable

    if not Success or not Clone then
        return nil
    end

    for _, Object in Clone:GetDescendants() do
        if Object:IsA("Script") or Object:IsA("LocalScript") or Object:IsA("ModuleScript") then
            Object:Destroy()
        elseif Object:IsA("BasePart") then
            Object.Anchored = true
            Object.CanCollide = false
            Object.CastShadow = false
        elseif Object:IsA("Humanoid") then
            Object.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            Object.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        end
    end

    return Clone
end

local function FocusCamera(Object, Camera, Yaw, Pitch, Zoom)
    local _, Size = Object:GetBoundingBox()
    local Extent = math.max(Size.X, Size.Y, Size.Z)
    local Position = Object:GetPivot().Position + Vector3.new(0, Extent * 0.06, 0)
    local Rotation = CFrame.fromOrientation(Pitch or 0, Yaw or 0, 0)
    local Distance = math.max(Extent * (Zoom or 1.9), 5)
    Camera.CFrame = CFrame.lookAt(Position - Rotation.LookVector * Distance, Position)
end

local function CreateText(Parent, Position, Size, ZIndex)
    local Label = Instance.new("TextLabel")
    Label.AnchorPoint = Vector2.new(0.5, 0.5)
    Label.BackgroundTransparency = 1
    Label.FontFace = Font.fromEnum(Enum.Font.Gotham)
    Label.Position = Position
    Label.Size = Size
    Label.TextColor3 = Color3.fromRGB(245, 247, 250)
    Label.TextSize = 12
    Label.TextStrokeColor3 = Color3.fromRGB(8, 10, 14)
    Label.TextStrokeTransparency = 0.2
    Label.TextTruncate = Enum.TextTruncate.AtEnd
    Label.ZIndex = ZIndex
    Label.Parent = Parent
    return Label
end

local function CreateOverlay(Parent, AccentColor, BaseZIndex, Renderer)
    if type(Renderer) == "function" then
        local Success, Result = pcall(Renderer, Parent)
        if Success and type(Result) == "table" and typeof(Result.Container) == "Instance" then
            local Container = Result.Container
            Container.AnchorPoint = Vector2.new(0.5, 0.5)
            Container.BackgroundTransparency = 1
            Container.Position = UDim2.new(0.5, 0, 0.56, 0)
            Container.Size = UDim2.new(0.42, 0, 0.43, 0)
            Container.ZIndex = BaseZIndex + 2

            for _, Object in Container:GetDescendants() do
                if Object:IsA("GuiObject") then
                    Object.ZIndex = BaseZIndex + 3
                end
            end

            return {
                Overlay = Container,
                Container = Container,
                Box = Result.BoxFrame,
                BoxStroke = Result.BoxStroke,
                BoxGradient = Result.BoxGradient,
                InfoTop = Result.InfoTop,
                InfoBottom = Result.InfoBottom,
                HealthBack = Result.HealthBack,
                HealthFill = Result.HealthFill,
            }
        end
    end

    local Overlay = Instance.new("Frame")
    Overlay.Name = "VisualPreviewOverlay"
    Overlay.BackgroundTransparency = 1
    Overlay.Size = UDim2.fromScale(1, 1)
    Overlay.ZIndex = BaseZIndex
    Overlay.Parent = Parent

    local Box = Instance.new("Frame")
    Box.AnchorPoint = Vector2.new(0.5, 0.5)
    Box.BackgroundTransparency = 1
    Box.Position = UDim2.new(0.5, 0, 0.56, 0)
    Box.Size = UDim2.new(0.46, 0, 0.42, 0)
    Box.ZIndex = BaseZIndex + 2
    Box.Parent = Overlay

    local BoxStroke = Instance.new("UIStroke")
    BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    BoxStroke.Color = AccentColor
    BoxStroke.Thickness = 1
    BoxStroke.Transparency = 0.04
    BoxStroke.Parent = Box

    local BoxGradient = Instance.new("UIGradient")
    BoxGradient.Enabled = false
    BoxGradient.Rotation = 90
    BoxGradient.Color = ColorSequence.new(AccentColor, AccentColor)
    BoxGradient.Parent = BoxStroke

    local InfoTop = CreateText(Box, UDim2.new(0.5, 0, 0, -4), UDim2.new(1.7, 0, 0, 16), BaseZIndex + 3)
    InfoTop.AnchorPoint = Vector2.new(0.5, 1)

    local InfoBottom = CreateText(Box, UDim2.new(0.5, 0, 1, 4), UDim2.new(1.7, 0, 0, 16), BaseZIndex + 3)
    InfoBottom.AnchorPoint = Vector2.new(0.5, 0)
    InfoBottom.TextColor3 = Color3.fromRGB(205, 225, 255)
    InfoBottom.TextSize = 11

    local HealthBack = Instance.new("Frame")
    HealthBack.AnchorPoint = Vector2.new(1, 0.5)
    HealthBack.BackgroundColor3 = Color3.fromRGB(8, 11, 15)
    HealthBack.BackgroundTransparency = 0.16
    HealthBack.BorderSizePixel = 0
    HealthBack.Position = UDim2.new(0, -5, 0.5, 0)
    HealthBack.Size = UDim2.new(0, 3, 1, 0)
    HealthBack.ZIndex = BaseZIndex + 2
    HealthBack.Parent = Box

    local Health = Instance.new("Frame")
    Health.AnchorPoint = Vector2.new(0, 1)
    Health.BackgroundColor3 = Color3.fromRGB(109, 214, 151)
    Health.BorderSizePixel = 0
    Health.Position = UDim2.new(0, 0, 1, 0)
    Health.Size = UDim2.new(1, 0, 0.72, 0)
    Health.ZIndex = BaseZIndex + 3
    Health.Parent = HealthBack

    local Tracer = Instance.new("Frame")
    Tracer.AnchorPoint = Vector2.new(0.5, 1)
    Tracer.BackgroundColor3 = AccentColor
    Tracer.BorderSizePixel = 0
    Tracer.Position = UDim2.new(0.5, 0, 0.98, 0)
    Tracer.Size = UDim2.new(0, 1, 0.28, 0)
    Tracer.ZIndex = BaseZIndex + 2
    Tracer.Parent = Overlay

    local TracerGradient = Instance.new("UIGradient")
    TracerGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.35, 0.34),
        NumberSequenceKeypoint.new(1, 0.12),
    })
    TracerGradient.Parent = Tracer

    return {
        Overlay = Overlay,
        Box = Box,
        BoxStroke = BoxStroke,
        BoxGradient = BoxGradient,
        InfoTop = InfoTop,
        InfoBottom = InfoBottom,
        HealthBack = HealthBack,
        HealthFill = Health,
        Tracer = Tracer,
    }
end

function VisualPreview.Create(Library, Tab, Info)
    assert(Library and Library.AddToRegistry and Library.ScreenGui, "VisualPreview requires an active MonHub library")
    assert(Tab, "VisualPreview requires a regular tab")

    Info = Info or {}
    local MainWindow = Info.Window or Library.Window
    assert(MainWindow and MainWindow.Frame, "VisualPreview requires a window with a frame")
    local MainFrame = MainWindow.Frame
    local TabCanvas = Tab.Canvas

    local Holder = Instance.new("Frame")
    Holder.Name = "MonHubVisualPreview"
    Holder.AnchorPoint = Vector2.new(0, 0.5)
    Holder.BackgroundColor3 = Library.Scheme.BackgroundColor
    Holder.BorderSizePixel = 0
    Holder.ClipsDescendants = true
    Holder.Position = UDim2.fromOffset(8, 8)
    Holder.Size = UDim2.fromOffset(Info.Width or 300, Info.Height or 420)
    Holder.Visible = false
    Holder.ZIndex = 10
    Holder.Parent = Library.ScreenGui
    Library:AddToRegistry(Holder, {
        BackgroundColor3 = "BackgroundColor",
    })

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, Library.CornerRadius)
    Corner.Parent = Holder

    local Outline = Instance.new("UIStroke")
    Outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Outline.Color = Library.Scheme.OutlineColor
    Outline.Thickness = 1
    Outline.Parent = Holder
    Library:AddToRegistry(Outline, {
        Color = "OutlineColor",
    })

    local AnimationScale = Instance.new("UIScale")
    AnimationScale.Scale = 0.98
    AnimationScale.Parent = Holder

    local Header = Instance.new("TextLabel")
    Header.BackgroundTransparency = 1
    Header.FontFace = Library.Scheme.Font
    Header.Position = UDim2.fromOffset(12, 0)
    Header.Size = UDim2.new(1, -24, 0, 34)
    Header.Text = Info.Name or "ESP preview"
    Header.TextColor3 = Library.Scheme.FontColor
    Header.TextSize = 14
    Header.TextXAlignment = Enum.TextXAlignment.Left
    Header.ZIndex = 12
    Header.Parent = Holder
    Library:AddToRegistry(Header, {
        FontFace = "Font",
        TextColor3 = "FontColor",
    })

    local HeaderLine = Instance.new("Frame")
    HeaderLine.BackgroundColor3 = Library.Scheme.OutlineColor
    HeaderLine.BorderSizePixel = 0
    HeaderLine.Position = UDim2.fromOffset(0, 34)
    HeaderLine.Size = UDim2.new(1, 0, 0, 1)
    HeaderLine.ZIndex = 12
    HeaderLine.Parent = Holder
    Library:AddToRegistry(HeaderLine, {
        BackgroundColor3 = "OutlineColor",
    })

    local Content = Instance.new("Frame")
    Content.BackgroundColor3 = Library:GetBetterColor(Library.Scheme.BackgroundColor, 2)
    Content.BorderSizePixel = 0
    Content.Position = UDim2.fromOffset(0, 35)
    Content.Size = UDim2.new(1, 0, 1, -35)
    Content.ZIndex = 11
    Content.Parent = Holder
    Library:AddToRegistry(Content, {
        BackgroundColor3 = function()
            return Library:GetBetterColor(Library.Scheme.BackgroundColor, 2)
        end,
    })

    local ViewportFrame = Instance.new("ViewportFrame")
    ViewportFrame.Ambient = Library.Scheme.OutlineColor:Lerp(Library.Scheme.FontColor, 0.42)
    ViewportFrame.Active = true
    ViewportFrame.BackgroundTransparency = 1
    ViewportFrame.LightColor = Library.Scheme.FontColor
    ViewportFrame.LightDirection = Vector3.new(-1, -0.65, -1)
    ViewportFrame.Size = UDim2.fromScale(1, 1)
    ViewportFrame.ZIndex = 11
    ViewportFrame.Parent = Content
    Library:AddToRegistry(ViewportFrame, {
        Ambient = function()
            return Library.Scheme.OutlineColor:Lerp(Library.Scheme.FontColor, 0.42)
        end,
        LightColor = "FontColor",
    })

    local Camera = Instance.new("Camera")
    Camera.Parent = ViewportFrame
    ViewportFrame.CurrentCamera = Camera

    local Model

    local Chams = Instance.new("Highlight")
    Chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Chams.Enabled = false
    Chams.FillColor = Color3.fromRGB(119, 182, 255)
    Chams.FillTransparency = 0.25
    Chams.OutlineColor = Color3.fromRGB(235, 241, 248)
    Chams.OutlineTransparency = 0
    Chams.Parent = ViewportFrame

    local AccentColor = Info.Color or Library.Scheme.AccentColor
    local Overlay = CreateOverlay(Content, AccentColor, 12, Info.Renderer)
    local Preview = {
        Holder = Holder,
        Frame = ViewportFrame,
        Camera = Camera,
        Model = Model,
        Overlay = Overlay,
        Chams = Chams,
        Side = Info.Side or "Auto",
        Alignment = Info.Alignment or "Center",
        Gap = math.clamp(tonumber(Info.Gap) or 12, 6, 32),
        Color = AccentColor,
        GradientColor = Info.GradientColor or AccentColor,
        Enabled = false,
        Destroyed = false,
        NameVisible = Info.NameVisible ~= false,
        TeamVisible = Info.Team == true,
        DistanceVisible = Info.Distance ~= false,
        WeaponVisible = Info.Weapon == true,
        Distance = nil,
        TargetName = "",
        TeamName = "",
        WeaponName = "",
        Target = nil,
        TargetConnection = nil,
        ChamsEnabled = false,
        BoxScale = math.clamp(tonumber(Info.BoxScale) or 92, 70, 115),
        DynamicBoxes = Info.DynamicBoxes == true,
        Yaw = 0,
        Pitch = 0,
        Zoom = 1.9,
        Connections = {},
    }

    if Overlay.InfoTop then
        Library:AddToRegistry(Overlay.InfoTop, {
            FontFace = "Font",
            TextColor3 = "FontColor",
            TextStrokeColor3 = "DarkColor",
        })
    end
    if Overlay.InfoBottom then
        Library:AddToRegistry(Overlay.InfoBottom, {
            FontFace = "Font",
            TextColor3 = function()
                return Library.Scheme.FontColor:Lerp(Library.Scheme.AccentColor, 0.16)
            end,
            TextStrokeColor3 = "DarkColor",
        })
    end
    if Overlay.HealthBack then
        Library:AddToRegistry(Overlay.HealthBack, {
            BackgroundColor3 = function()
                return Library.Scheme.DarkColor:Lerp(Library.Scheme.BackgroundColor, 0.2)
            end,
        })
    end
    local VisibilitySequence = 0

    local function UpdateInfoLabels()
        local Top = ""
        if Preview.NameVisible and Preview.TeamVisible then
            Top = string.format("%s [%s]", Preview.TargetName, Preview.TeamName)
        elseif Preview.NameVisible then
            Top = Preview.TargetName
        elseif Preview.TeamVisible then
            Top = Preview.TeamName ~= "" and string.format("[%s]", Preview.TeamName) or ""
        end

        local Bottom = ""
        local DistanceText = Preview.Distance and string.format("%dm", Preview.Distance) or ""
        if Preview.WeaponVisible and Preview.DistanceVisible and Preview.WeaponName ~= "" and DistanceText ~= "" then
            Bottom = string.format("%s | %s", Preview.WeaponName, DistanceText)
        elseif Preview.WeaponVisible then
            Bottom = Preview.WeaponName
        elseif Preview.DistanceVisible then
            Bottom = DistanceText
        end

        Overlay.InfoTop.Text = Top
        Overlay.InfoTop.Visible = Top ~= ""
        Overlay.InfoBottom.Text = Bottom
        Overlay.InfoBottom.Visible = Bottom ~= ""
    end

    local function UpdateTargetInfo(Character)
        local Player = Character and Players:GetPlayerFromCharacter(Character)
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        local CameraObject = workspace.CurrentCamera
        Preview.TargetName = Player and Player.DisplayName or Character and Character.Name or ""
        Preview.TeamName = Player and Player.Team and Player.Team.Name or ""
        local Tool = Character and Character:FindFirstChildOfClass("Tool")
        Preview.WeaponName = Tool and Tool.Name or ""
        Preview.Distance = Root and CameraObject and math.max(0, math.floor((Root.Position - CameraObject.CFrame.Position).Magnitude + 0.5)) or nil
        if Overlay.HealthFill and Humanoid then
            local Health = math.clamp(Humanoid.Health / math.max(Humanoid.MaxHealth, 100), 0, 1)
            Overlay.HealthFill.Size = UDim2.new(1, 0, Health, 0)
            Overlay.HealthFill.BackgroundColor3 = Color3.fromHSV(Health * 0.33, 0.9, 1)
        end
        UpdateInfoLabels()
    end

    local function IsR6(ModelObject)
        local Humanoid = ModelObject and ModelObject:FindFirstChildOfClass("Humanoid")
        return Humanoid and Humanoid.RigType == Enum.HumanoidRigType.R6
    end

    local function ProjectPoint(Point, ContentSize)
        local CameraPoint = Camera.CFrame:PointToObjectSpace(Point)
        local Depth = -CameraPoint.Z
        if Depth <= 0.1 then
            return nil
        end

        local PixelScale = ContentSize.Y / (2 * Depth * math.tan(math.rad(Camera.FieldOfView * 0.5)))
        return ContentSize.X * 0.5 + CameraPoint.X * PixelScale, ContentSize.Y * 0.5 - CameraPoint.Y * PixelScale, Depth
    end

    local function UpdateOverlayBounds()
        local Root = Model and (Model:FindFirstChild("HumanoidRootPart") or Model.PrimaryPart)
        local ContentSize = Content.AbsoluteSize
        if not Root or ContentSize.X <= 0 or ContentSize.Y <= 0 then
            return
        end

        local CenterX, CenterY, Depth = ProjectPoint(Root.Position, ContentSize)
        if not CenterX then
            return
        end

        local TanFov = math.tan(math.rad(Camera.FieldOfView * 0.5)) * 2
        local RawHeight = (5 * (Preview.BoxScale / 100) * ContentSize.Y) / (Depth * TanFov)
        local Height = math.clamp(RawHeight, 4, ContentSize.Y * 1.15)
        local Width = math.max(Height * 0.58, 4)

        if Preview.DynamicBoxes then
            local BoundsFrame, BoundsSize = Model:GetBoundingBox()
            local HalfX = BoundsSize.X * 0.5
            local HalfY = BoundsSize.Y * 0.5
            local HalfZ = BoundsSize.Z * 0.5
            local MinimumX, MinimumY = math.huge, math.huge
            local MaximumX, MaximumY = -math.huge, -math.huge
            local Count = 0

            for X = -1, 1, 2 do
                for Y = -1, 1, 2 do
                    for Z = -1, 1, 2 do
                        local Point = BoundsFrame:PointToWorldSpace(Vector3.new(HalfX * X, HalfY * Y, HalfZ * Z))
                        local ScreenX, ScreenY = ProjectPoint(Point, ContentSize)
                        if ScreenX then
                            MinimumX = math.min(MinimumX, ScreenX)
                            MinimumY = math.min(MinimumY, ScreenY)
                            MaximumX = math.max(MaximumX, ScreenX)
                            MaximumY = math.max(MaximumY, ScreenY)
                            Count += 1
                        end
                    end
                end
            end

            local DynamicWidth = MaximumX - MinimumX
            local DynamicHeight = MaximumY - MinimumY
            if Count >= 4 and DynamicWidth >= 3 and DynamicHeight >= 3 then
                local SafeHeight = math.clamp(DynamicHeight, RawHeight * 0.64, RawHeight * 1.14)
                local SafeWidth = math.clamp(DynamicWidth, SafeHeight * 0.32, SafeHeight * 0.72)
                CenterX = MinimumX + DynamicWidth * 0.5
                CenterY = MinimumY + DynamicHeight * 0.5
                Width = math.max(4, SafeWidth)
                Height = math.max(4, SafeHeight)
            end
        end

        local TargetBox = Overlay.Container or Overlay.Box
        TargetBox.Position = UDim2.fromOffset(math.floor(CenterX + 0.5), math.floor(CenterY + 0.5))
        TargetBox.Size = UDim2.fromOffset(math.floor(Width + 0.5), math.floor(Height + 0.5))
    end

    local function UpdateCamera()
        if Model then
            FocusCamera(Model, Camera, Preview.Yaw, Preview.Pitch, Preview.Zoom)
            UpdateOverlayBounds()
        end
    end

    function Preview:SetTarget(Source)
        if Preview.TargetConnection then
            Preview.TargetConnection:Disconnect()
            Preview.TargetConnection = nil
        end

        if Model then
            Model:Destroy()
            Model = nil
        end

        local Character = ResolveCharacter(Source)
        local Clone = CloneCharacter(Character)
        Preview.Target = Source
        Preview.Model = Clone
        Model = Clone
        Chams.Adornee = Clone
        Chams.Enabled = Preview.ChamsEnabled and IsR6(Clone)

        if Clone then
            Clone.Parent = ViewportFrame
            UpdateCamera()
        end

        UpdateTargetInfo(Character)

        if typeof(Source) == "Instance" and Source:IsA("Player") then
            Preview.TargetConnection = Source.CharacterAdded:Connect(function()
                Preview:SetTarget(Source)
            end)
        end

        return Clone ~= nil
    end

    function Preview:Rotate(DeltaX, DeltaY)
        Preview.Yaw -= (tonumber(DeltaX) or 0) * 0.012
        Preview.Pitch = math.clamp(Preview.Pitch - (tonumber(DeltaY) or 0) * 0.012, -1.15, 1.15)
        UpdateCamera()
    end

    function Preview:SetZoom(Zoom)
        Preview.Zoom = math.clamp(tonumber(Zoom) or Preview.Zoom, 1.2, 3.2)
        UpdateCamera()
    end

    function Preview:ResetView()
        Preview.Yaw = 0
        Preview.Pitch = 0
        Preview.Zoom = 1.9
        UpdateCamera()
    end

    local function PositionPanel()
        if Preview.Destroyed or not Holder.Parent then
            return
        end

        local CameraObject = workspace.CurrentCamera
        if not CameraObject or not MainFrame.Parent then
            return
        end

        local MainPosition = MainFrame.AbsolutePosition
        local MainSize = MainFrame.AbsoluteSize
        local PanelWidth = math.max(Holder.AbsoluteSize.X, Info.Width or 300)
        local PanelHeight = math.max(Holder.AbsoluteSize.Y, Info.Height or 420)
        local ScreenSize = CameraObject.ViewportSize
        local Gap = Preview.Gap
        local Side = string.lower(tostring(Preview.Side))
        local Alignment = string.lower(tostring(Preview.Alignment))
        local UseLeft = Side == "left"

        if Side == "auto" then
            UseLeft = MainPosition.X + MainSize.X + Gap + PanelWidth > ScreenSize.X - 8
        elseif Side == "right" and MainPosition.X + MainSize.X + Gap + PanelWidth > ScreenSize.X - 8 then
            UseLeft = MainPosition.X - Gap - PanelWidth >= 8
        end

        local AnchorX = UseLeft and 1 or 0
        local X = UseLeft and MainPosition.X - Gap or MainPosition.X + MainSize.X + Gap
        local AnchorY = 0.5
        local Y = MainPosition.Y + MainSize.Y * 0.5

        if Alignment == "top" then
            AnchorY = 0
            Y = MainPosition.Y
        elseif Alignment == "bottom" then
            AnchorY = 1
            Y = MainPosition.Y + MainSize.Y
        end

        local MinimumX = 8 + PanelWidth * AnchorX
        local MaximumX = ScreenSize.X - 8 - PanelWidth * (1 - AnchorX)
        local MinimumY = 8 + PanelHeight * AnchorY
        local MaximumY = ScreenSize.Y - 8 - PanelHeight * (1 - AnchorY)
        X = math.clamp(X, math.min(MinimumX, MaximumX), math.max(MinimumX, MaximumX))
        Y = math.clamp(Y, math.min(MinimumY, MaximumY), math.max(MinimumY, MaximumY))

        Holder.AnchorPoint = Vector2.new(AnchorX, AnchorY)
        Holder.Position = UDim2.fromOffset(math.floor(X + 0.5), math.floor(Y + 0.5))
    end

    local function IsTabVisible()
        if typeof(TabCanvas) ~= "Instance" or not TabCanvas:IsA("GuiObject") then
            return true
        end

        return TabCanvas.Visible
    end

    local function IsMainVisible()
        if typeof(MainFrame) ~= "Instance" or not MainFrame:IsA("GuiObject") then
            return false
        end

        return MainFrame.Visible
    end

    local function IsDisplayable()
        return Preview.Enabled and Library.Toggled and Library.ActiveTab == Tab and IsTabVisible() and IsMainVisible()
    end

    local function UpdateVisibility()
        if Preview.Destroyed then
            return
        end

        VisibilitySequence += 1
        local Sequence = VisibilitySequence
        local Visible = IsDisplayable()

        if Visible then
            UpdateTargetInfo(ResolveCharacter(Preview.Target))
            PositionPanel()
            UpdateCamera()
            if not Holder.Visible then
                AnimationScale.Scale = 0.98
                Holder.Visible = true
            end
            Library:PlayTween(AnimationScale, "VisualPreviewVisibility", TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Scale = 1,
            })
            return
        end

        if not Holder.Visible then
            return
        end

        local Tween = Library:PlayTween(AnimationScale, "VisualPreviewVisibility", TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Scale = 0.98,
        })

        if not Tween then
            Holder.Visible = false
            return
        end

        Tween.Completed:Once(function(State)
            if State == Enum.PlaybackState.Completed and Sequence == VisibilitySequence and not IsDisplayable() then
                Holder.Visible = false
            end
        end)
    end

    local VisibilityUpdateQueued = false
    local function QueueVisibilityUpdate()
        if VisibilityUpdateQueued then
            return
        end

        VisibilityUpdateQueued = true
        task.defer(function()
            VisibilityUpdateQueued = false
            UpdateVisibility()
        end)
    end

    local function ConnectProperty(Object, Property, Callback)
        if typeof(Object) ~= "Instance" then
            return
        end

        local Success, Signal = pcall(Object.GetPropertyChangedSignal, Object, Property)
        if Success and Signal then
            table.insert(Preview.Connections, Signal:Connect(Callback))
        end
    end

    ConnectProperty(MainFrame, "AbsolutePosition", PositionPanel)
    ConnectProperty(MainFrame, "AbsoluteSize", PositionPanel)
    ConnectProperty(MainFrame, "Visible", QueueVisibilityUpdate)
    ConnectProperty(MainFrame, "GroupTransparency", QueueVisibilityUpdate)
    ConnectProperty(TabCanvas, "Visible", QueueVisibilityUpdate)
    ConnectProperty(Content, "AbsoluteSize", UpdateCamera)
    if MainWindow.VisibilityChanged then
        table.insert(Preview.Connections, MainWindow.VisibilityChanged.Event:Connect(UpdateVisibility))
    end
    ConnectProperty(workspace.CurrentCamera, "ViewportSize", PositionPanel)

    local Rotating = false
    local LastPointerPosition
    table.insert(Preview.Connections, ViewportFrame.InputBegan:Connect(function(Input)
        if not Holder.Visible then
            return
        end

        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Rotating = true
            LastPointerPosition = Input.Position
        end
    end))
    table.insert(Preview.Connections, ViewportFrame.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseWheel and Holder.Visible then
            Preview:SetZoom(Preview.Zoom - Input.Position.Z * 0.12)
        end
    end))
    table.insert(Preview.Connections, UserInputService.InputChanged:Connect(function(Input)
        if not Rotating or not Holder.Visible then
            return
        end

        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
            local Position = Input.Position
            if LastPointerPosition then
                Preview:Rotate(Position.X - LastPointerPosition.X, Position.Y - LastPointerPosition.Y)
            end
            LastPointerPosition = Position
        end
    end))
    table.insert(Preview.Connections, UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Rotating = false
            LastPointerPosition = nil
        end
    end))
    local NextTargetUpdate = 0
    table.insert(Preview.Connections, RunService.Heartbeat:Connect(function()
        if Preview.Destroyed or not Holder.Visible or not Preview.Enabled then
            return
        end

        local Now = os.clock()
        if Now >= NextTargetUpdate then
            NextTargetUpdate = Now + 0.25
            UpdateTargetInfo(ResolveCharacter(Preview.Target))
        end
    end))

    function Preview:SetEnabled(Enabled)
        Preview.Enabled = Enabled == true
        Overlay.Overlay.Visible = Preview.Enabled
        UpdateVisibility()
    end

    function Preview:SetColor(Color)
        if typeof(Color) ~= "Color3" then
            return
        end

        Preview.Color = Color
        Overlay.BoxStroke.Color = Color
        Overlay.BoxGradient.Color = ColorSequence.new(Preview.Color, Preview.GradientColor)
        if Overlay.Tracer then
            Overlay.Tracer.BackgroundColor3 = Color
        end
    end

    function Preview:SetBoxScale(Scale)
        Preview.BoxScale = math.clamp(tonumber(Scale) or Preview.BoxScale, 70, 115)
        UpdateOverlayBounds()
    end

    function Preview:SetDynamicBoxes(Enabled)
        Preview.DynamicBoxes = Enabled == true
        UpdateOverlayBounds()
    end

    function Preview:SetBoxStyle()
        Overlay.Box.Visible = true
    end

    function Preview:SetGradientEnabled(Enabled)
        Overlay.BoxGradient.Enabled = Enabled == true
    end

    function Preview:SetGradientColor(Color)
        if typeof(Color) ~= "Color3" then
            return
        end

        Preview.GradientColor = Color
        Overlay.BoxGradient.Color = ColorSequence.new(Preview.Color, Preview.GradientColor)
    end

    function Preview:SetOpacity()
    end

    function Preview:SetPosition(Side, Alignment)
        local NormalizedSide = string.lower(tostring(Side or Preview.Side))
        local NormalizedAlignment = string.lower(tostring(Alignment or Preview.Alignment))
        Preview.Side = NormalizedSide == "left" and "Left" or NormalizedSide == "right" and "Right" or "Auto"
        Preview.Alignment = NormalizedAlignment == "top" and "Top" or NormalizedAlignment == "bottom" and "Bottom" or "Center"
        PositionPanel()
    end

    function Preview:SetPanelGap(Gap)
        Preview.Gap = math.clamp(tonumber(Gap) or Preview.Gap, 6, 32)
        PositionPanel()
    end

    function Preview:SetBoxVisible(Visible)
        Overlay.Box.Visible = Visible == true
    end

    function Preview:SetNameVisible(Visible)
        Preview.NameVisible = Visible == true
        UpdateInfoLabels()
    end

    function Preview:SetDistanceVisible(Visible)
        Preview.DistanceVisible = Visible == true
        UpdateInfoLabels()
    end

    function Preview:SetTeamVisible(Visible)
        Preview.TeamVisible = Visible == true
        UpdateInfoLabels()
    end

    function Preview:SetWeaponVisible(Visible)
        Preview.WeaponVisible = Visible == true
        UpdateInfoLabels()
    end

    function Preview:SetTracerVisible(Visible)
        if Overlay.Tracer then
            Overlay.Tracer.Visible = Visible == true
        end
    end

    function Preview:SetHealthVisible(Visible)
        Overlay.HealthBack.Visible = Visible == true
    end

    function Preview:SetHighlightVisible(Visible)
        Preview.ChamsEnabled = Visible == true
        Chams.Enabled = Preview.ChamsEnabled and IsR6(Model)
    end

    function Preview:SetChams(Enabled, FillColor, OutlineColor, FillTransparency, OutlineTransparency)
        if typeof(FillColor) == "Color3" then
            Chams.FillColor = FillColor
        end
        if typeof(OutlineColor) == "Color3" then
            Chams.OutlineColor = OutlineColor
        end
        Chams.FillTransparency = math.clamp(tonumber(FillTransparency) or Chams.FillTransparency, 0, 1)
        Chams.OutlineTransparency = math.clamp(tonumber(OutlineTransparency) or Chams.OutlineTransparency, 0, 1)
        Preview.ChamsEnabled = Enabled == true
        Chams.Enabled = Preview.ChamsEnabled and IsR6(Model)
    end

    function Preview:SetDistance(Value)
        local NumericValue = tonumber(Value)
        if NumericValue then
            Preview.Distance = math.max(0, math.floor(NumericValue + 0.5))
            UpdateInfoLabels()
        end
    end

    function Preview:Destroy()
        if Preview.Destroyed then
            return
        end

        Preview.Destroyed = true
        if Preview.TargetConnection then
            Preview.TargetConnection:Disconnect()
            Preview.TargetConnection = nil
        end
        for _, Connection in Preview.Connections do
            Connection:Disconnect()
        end
        table.clear(Preview.Connections)
        if Holder then
            Holder:Destroy()
        end
    end

    Library:OnUnload(function()
        Preview:Destroy()
    end)

    Preview:SetTarget(Info.Target or Info.Player or Players.LocalPlayer)
    Preview:SetBoxVisible(Info.Box ~= false)
    Preview:SetNameVisible(Preview.NameVisible)
    Preview:SetDistanceVisible(Preview.DistanceVisible)
    Preview:SetTeamVisible(Preview.TeamVisible)
    Preview:SetWeaponVisible(Preview.WeaponVisible)
    Preview:SetTracerVisible(Info.Tracer == true)
    Preview:SetHealthVisible(Info.Health ~= false)
    Preview:SetChams(Info.Highlight == true, Info.ChamsFillColor, Info.ChamsOutlineColor, Info.ChamsFillTransparency, Info.ChamsOutlineTransparency)
    Preview:SetGradientColor(Preview.GradientColor)
    Preview:SetGradientEnabled(Info.Gradient == true)
    Preview:SetPosition(Preview.Side, Preview.Alignment)
    Preview:SetEnabled(Info.Enabled == true)

    return Preview
end

return VisualPreview
