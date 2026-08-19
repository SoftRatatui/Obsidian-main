local VisualPreview = {}

local function CreatePart(Model, Name, Size, Position, Color)
    local Part = Instance.new("Part")
    Part.Name = Name
    Part.Anchored = true
    Part.CanCollide = false
    Part.CastShadow = false
    Part.Color = Color
    Part.Material = Enum.Material.SmoothPlastic
    Part.Size = Size
    Part.CFrame = CFrame.new(Position)
    Part.TopSurface = Enum.SurfaceType.Smooth
    Part.BottomSurface = Enum.SurfaceType.Smooth
    Part.Parent = Model
    return Part
end

function VisualPreview.CreateR6()
    local Model = Instance.new("Model")
    Model.Name = "MonHubVisualPreviewR6"

    local BodyColor = Color3.fromRGB(226, 231, 238)
    local Torso = CreatePart(Model, "Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), BodyColor)
    local Head = CreatePart(Model, "Head", Vector3.new(2, 1, 1), Vector3.new(0, 4.5, 0), BodyColor)
    CreatePart(Model, "Right Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0), BodyColor)
    CreatePart(Model, "Left Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0), BodyColor)
    CreatePart(Model, "Right Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0), BodyColor)
    CreatePart(Model, "Left Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0), BodyColor)

    local HeadMesh = Instance.new("SpecialMesh")
    HeadMesh.MeshType = Enum.MeshType.Head
    HeadMesh.Scale = Vector3.new(1.18, 1.18, 1.18)
    HeadMesh.Parent = Head

    Model.PrimaryPart = Torso
    return Model
end

local function FocusCamera(Object, Camera)
    local _, Size = Object:GetBoundingBox()
    local Extent = math.max(Size.X, Size.Y, Size.Z)
    local Position = Object:GetPivot().Position + Vector3.new(0, Extent * 0.06, 0)
    Camera.CFrame = CFrame.lookAt(Position + Vector3.new(0, 0, math.max(Extent * 1.9, 5)), Position)
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

local function CreateOverlay(Parent, AccentColor, BaseZIndex)
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

    local InfoTop = CreateText(Overlay, UDim2.new(0.5, 0, 0.33, 0), UDim2.new(0.9, 0, 0, 16), BaseZIndex + 3)
    InfoTop.TextYAlignment = Enum.TextYAlignment.Bottom

    local InfoBottom = CreateText(Overlay, UDim2.new(0.5, 0, 0.79, 0), UDim2.new(0.9, 0, 0, 16), BaseZIndex + 3)
    InfoBottom.TextColor3 = Color3.fromRGB(205, 225, 255)
    InfoBottom.TextSize = 11
    InfoBottom.TextYAlignment = Enum.TextYAlignment.Top

    local HealthBack = Instance.new("Frame")
    HealthBack.AnchorPoint = Vector2.new(1, 0.5)
    HealthBack.BackgroundColor3 = Color3.fromRGB(8, 11, 15)
    HealthBack.BackgroundTransparency = 0.16
    HealthBack.BorderSizePixel = 0
    HealthBack.Position = UDim2.new(0.27, -5, 0.56, 0)
    HealthBack.Size = UDim2.new(0, 3, 0.42, 0)
    HealthBack.ZIndex = BaseZIndex + 2
    HealthBack.Parent = Overlay

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
    ViewportFrame.Ambient = Color3.fromRGB(154, 165, 178)
    ViewportFrame.BackgroundTransparency = 1
    ViewportFrame.LightColor = Color3.fromRGB(238, 244, 252)
    ViewportFrame.LightDirection = Vector3.new(-1, -0.65, -1)
    ViewportFrame.Size = UDim2.fromScale(1, 1)
    ViewportFrame.ZIndex = 11
    ViewportFrame.Parent = Content

    local Camera = Instance.new("Camera")
    Camera.Parent = ViewportFrame
    ViewportFrame.CurrentCamera = Camera

    local Model = VisualPreview.CreateR6()
    Model.Parent = ViewportFrame
    FocusCamera(Model, Camera)

    local Chams = Instance.new("Highlight")
    Chams.Adornee = Model
    Chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Chams.Enabled = false
    Chams.FillColor = Color3.fromRGB(119, 182, 255)
    Chams.FillTransparency = 0.25
    Chams.OutlineColor = Color3.fromRGB(235, 241, 248)
    Chams.OutlineTransparency = 0
    Chams.Parent = Model

    local AccentColor = Info.Color or Library.Scheme.AccentColor
    local Overlay = CreateOverlay(Content, AccentColor, 12)
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
        Distance = tonumber(Info.DistanceValue) or 86,
        Connections = {},
    }
    local VisibilitySequence = 0

    local function UpdateInfoLabels()
        local Top = ""
        if Preview.NameVisible and Preview.TeamVisible then
            Top = "Preview Player [Civilian]"
        elseif Preview.NameVisible then
            Top = "Preview Player"
        elseif Preview.TeamVisible then
            Top = "[Civilian]"
        end

        local Bottom = ""
        if Preview.WeaponVisible and Preview.DistanceVisible then
            Bottom = string.format("Tool | %dm", Preview.Distance)
        elseif Preview.WeaponVisible then
            Bottom = "Tool"
        elseif Preview.DistanceVisible then
            Bottom = string.format("%dm", Preview.Distance)
        end

        Overlay.InfoTop.Text = Top
        Overlay.InfoTop.Visible = Top ~= ""
        Overlay.InfoBottom.Text = Bottom
        Overlay.InfoBottom.Visible = Bottom ~= ""
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
            PositionPanel()
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
    if MainWindow.VisibilityChanged then
        table.insert(Preview.Connections, MainWindow.VisibilityChanged.Event:Connect(UpdateVisibility))
    end
    ConnectProperty(workspace.CurrentCamera, "ViewportSize", PositionPanel)

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
        Overlay.Tracer.BackgroundColor3 = Color
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
        Overlay.Tracer.Visible = Visible == true
    end

    function Preview:SetHealthVisible(Visible)
        Overlay.HealthBack.Visible = Visible == true
    end

    function Preview:SetHighlightVisible(Visible)
        Chams.Enabled = Visible == true
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
        Chams.Enabled = Enabled == true
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
