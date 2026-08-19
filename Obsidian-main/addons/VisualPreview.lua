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

local function CreateMark(Parent, Position, Size, Color, Transparency, ZIndex)
    local Mark = Instance.new("Frame")
    Mark.AnchorPoint = Vector2.new(0.5, 0.5)
    Mark.BackgroundColor3 = Color
    Mark.BackgroundTransparency = Transparency
    Mark.BorderSizePixel = 0
    Mark.Position = Position
    Mark.Size = Size
    Mark.ZIndex = ZIndex
    Mark.Parent = Parent
    return Mark
end

local function CreateOverlay(Parent, AccentColor, BaseZIndex)
    local Overlay = Instance.new("Frame")
    Overlay.Name = "VisualPreviewOverlay"
    Overlay.BackgroundTransparency = 1
    Overlay.Size = UDim2.fromScale(1, 1)
    Overlay.ZIndex = BaseZIndex
    Overlay.Parent = Parent

    local Target = Instance.new("Frame")
    Target.AnchorPoint = Vector2.new(0.5, 0.5)
    Target.BackgroundColor3 = AccentColor
    Target.BackgroundTransparency = 0.93
    Target.BorderSizePixel = 0
    Target.Position = UDim2.new(0.5, 0, 0.5, 0)
    Target.Size = UDim2.new(0.4, 0, 0.58, 0)
    Target.ZIndex = BaseZIndex + 1
    Target.Parent = Overlay

    local TargetCorner = Instance.new("UICorner")
    TargetCorner.CornerRadius = UDim.new(0, 5)
    TargetCorner.Parent = Target

    local Glow = Instance.new("UIStroke")
    Glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Glow.Color = AccentColor
    Glow.Thickness = 1
    Glow.Transparency = 0.58
    Glow.Parent = Target

    local TargetGradient = Instance.new("UIGradient")
    TargetGradient.Enabled = false
    TargetGradient.Rotation = 90
    TargetGradient.Color = ColorSequence.new(AccentColor, Color3.fromRGB(235, 241, 248))
    TargetGradient.Parent = Target

    local Box = Instance.new("Frame")
    Box.AnchorPoint = Vector2.new(0.5, 0.5)
    Box.BackgroundTransparency = 1
    Box.Position = UDim2.new(0.5, 0, 0.5, 0)
    Box.Size = UDim2.new(0.44, 0, 0.62, 0)
    Box.ZIndex = BaseZIndex + 2
    Box.Parent = Overlay

    local FullBox = Instance.new("Frame")
    FullBox.BackgroundTransparency = 1
    FullBox.Size = UDim2.fromScale(1, 1)
    FullBox.Visible = false
    FullBox.ZIndex = BaseZIndex + 3
    FullBox.Parent = Box

    local FullBoxStroke = Instance.new("UIStroke")
    FullBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    FullBoxStroke.Color = AccentColor
    FullBoxStroke.Thickness = 1
    FullBoxStroke.Transparency = 0.08
    FullBoxStroke.Parent = FullBox

    local BoxParts = {}
    local function AddBoxPart(Position, Size)
        local Part = CreateMark(Box, Position, Size, AccentColor, 0.08, BaseZIndex + 3)
        table.insert(BoxParts, Part)
    end

    AddBoxPart(UDim2.new(0, 6, 0, 1), UDim2.fromOffset(18, 2))
    AddBoxPart(UDim2.new(0, 1, 0, 7), UDim2.fromOffset(2, 18))
    AddBoxPart(UDim2.new(1, -6, 0, 1), UDim2.fromOffset(18, 2))
    AddBoxPart(UDim2.new(1, -1, 0, 7), UDim2.fromOffset(2, 18))
    AddBoxPart(UDim2.new(0, 6, 1, -1), UDim2.fromOffset(18, 2))
    AddBoxPart(UDim2.new(0, 1, 1, -7), UDim2.fromOffset(2, 18))
    AddBoxPart(UDim2.new(1, -6, 1, -1), UDim2.fromOffset(18, 2))
    AddBoxPart(UDim2.new(1, -1, 1, -7), UDim2.fromOffset(2, 18))

    local NameMark = CreateMark(Overlay, UDim2.new(0.5, 0, 0.16, 0), UDim2.fromOffset(44, 2), AccentColor, 0.15, BaseZIndex + 3)
    local DistanceMark = CreateMark(Overlay, UDim2.new(0.5, 0, 0.85, 0), UDim2.fromOffset(26, 2), Color3.fromRGB(233, 238, 245), 0.2, BaseZIndex + 3)
    local TeamMark = CreateMark(Overlay, UDim2.new(0.5, 0, 0.12, 0), UDim2.fromOffset(5, 5), AccentColor, 0.08, BaseZIndex + 3)
    local TeamCorner = Instance.new("UICorner")
    TeamCorner.CornerRadius = UDim.new(1, 0)
    TeamCorner.Parent = TeamMark
    local WeaponMark = CreateMark(Overlay, UDim2.new(0.5, 0, 0.81, 0), UDim2.fromOffset(12, 2), AccentColor, 0.16, BaseZIndex + 3)

    local HealthBack = Instance.new("Frame")
    HealthBack.AnchorPoint = Vector2.new(1, 0.5)
    HealthBack.BackgroundColor3 = Color3.fromRGB(8, 11, 15)
    HealthBack.BackgroundTransparency = 0.16
    HealthBack.BorderSizePixel = 0
    HealthBack.Position = UDim2.new(0.275, -5, 0.5, 0)
    HealthBack.Size = UDim2.new(0, 3, 0.58, 0)
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
        Target = Target,
        TargetGradient = TargetGradient,
        Glow = Glow,
        Box = Box,
        BoxParts = BoxParts,
        FullBox = FullBox,
        FullBoxStroke = FullBoxStroke,
        Name = NameMark,
        Distance = DistanceMark,
        Team = TeamMark,
        Weapon = WeaponMark,
        HealthBack = HealthBack,
        Tracer = Tracer,
    }
end

function VisualPreview.Create(Library, Tab, Info)
    assert(Library and Library.AddToRegistry and Library.Window and Library.ScreenGui, "VisualPreview requires an active MonHub library")
    assert(Tab and Tab.Canvas, "VisualPreview requires a regular tab")

    Info = Info or {}

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

    local AccentColor = Info.Color or Library.Scheme.AccentColor
    local Overlay = CreateOverlay(Content, AccentColor, 12)
    local Preview = {
        Holder = Holder,
        Frame = ViewportFrame,
        Camera = Camera,
        Model = Model,
        Overlay = Overlay,
        Side = Info.Side or "Auto",
        Alignment = Info.Alignment or "Center",
        Gap = math.clamp(tonumber(Info.Gap) or 12, 6, 32),
        Color = AccentColor,
        GradientColor = Info.GradientColor or Color3.fromRGB(235, 241, 248),
        Opacity = math.clamp(tonumber(Info.Opacity) or 0.72, 0.2, 1),
        BoxStyle = Info.BoxStyle or "Corners",
        Enabled = false,
        Destroyed = false,
        Connections = {},
    }
    local MainFrame = Library.Window.Frame
    local VisibilitySequence = 0

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

    local function IsDisplayable()
        return Preview.Enabled and Library.Toggled and Library.ActiveTab == Tab and Tab.Canvas.Visible and MainFrame.Visible
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

    table.insert(Preview.Connections, MainFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(PositionPanel))
    table.insert(Preview.Connections, MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(PositionPanel))
    table.insert(Preview.Connections, MainFrame:GetPropertyChangedSignal("Visible"):Connect(QueueVisibilityUpdate))
    table.insert(Preview.Connections, MainFrame:GetPropertyChangedSignal("GroupTransparency"):Connect(QueueVisibilityUpdate))
    table.insert(Preview.Connections, Tab.Canvas:GetPropertyChangedSignal("Visible"):Connect(QueueVisibilityUpdate))
    if Library.Window.VisibilityChanged then
        table.insert(Preview.Connections, Library.Window.VisibilityChanged.Event:Connect(UpdateVisibility))
    end
    if workspace.CurrentCamera then
        table.insert(Preview.Connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(PositionPanel))
    end

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
        Overlay.Target.BackgroundColor3 = Color
        Overlay.Glow.Color = Color
        Overlay.TargetGradient.Color = ColorSequence.new(Preview.Color, Preview.GradientColor)
        Overlay.FullBoxStroke.Color = Color
        Overlay.Name.BackgroundColor3 = Color
        Overlay.Team.BackgroundColor3 = Color
        Overlay.Weapon.BackgroundColor3 = Color
        Overlay.Tracer.BackgroundColor3 = Color
        for _, Part in Overlay.BoxParts do
            Part.BackgroundColor3 = Color
        end
    end

    function Preview:SetBoxStyle(Style)
        local Full = string.lower(tostring(Style)) == "full"
        Preview.BoxStyle = Full and "Full" or "Corners"
        Overlay.FullBox.Visible = Full
        for _, Part in Overlay.BoxParts do
            Part.Visible = not Full
        end
    end

    function Preview:SetGradientEnabled(Enabled)
        Overlay.TargetGradient.Enabled = Enabled == true
    end

    function Preview:SetGradientColor(Color)
        if typeof(Color) ~= "Color3" then
            return
        end

        Preview.GradientColor = Color
        Overlay.TargetGradient.Color = ColorSequence.new(Preview.Color, Preview.GradientColor)
    end

    function Preview:SetOpacity(Opacity)
        Preview.Opacity = math.clamp(tonumber(Opacity) or Preview.Opacity, 0.2, 1)
        Overlay.Target.BackgroundTransparency = 0.99 - Preview.Opacity * 0.085
        Overlay.Glow.Transparency = 0.86 - Preview.Opacity * 0.4
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
        Overlay.Name.Visible = Visible == true
    end

    function Preview:SetDistanceVisible(Visible)
        Overlay.Distance.Visible = Visible == true
    end

    function Preview:SetTeamVisible(Visible)
        Overlay.Team.Visible = Visible == true
    end

    function Preview:SetWeaponVisible(Visible)
        Overlay.Weapon.Visible = Visible == true
    end

    function Preview:SetTracerVisible(Visible)
        Overlay.Tracer.Visible = Visible == true
    end

    function Preview:SetHealthVisible(Visible)
        Overlay.HealthBack.Visible = Visible == true
    end

    function Preview:SetHighlightVisible(Visible)
        Overlay.Target.Visible = Visible == true
    end

    function Preview:SetDistance(Value)
        local NumericValue = tonumber(Value)
        if NumericValue then
            Overlay.Distance.Size = UDim2.fromOffset(math.clamp(math.floor(NumericValue / 20 + 18), 18, 46), 2)
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
    Preview:SetBoxStyle(Info.BoxStyle or "Corners")
    Preview:SetNameVisible(Info.NameVisible ~= false)
    Preview:SetDistanceVisible(Info.Distance ~= false)
    Preview:SetTeamVisible(Info.Team == true)
    Preview:SetWeaponVisible(Info.Weapon == true)
    Preview:SetTracerVisible(Info.Tracer == true)
    Preview:SetHealthVisible(Info.Health ~= false)
    Preview:SetHighlightVisible(Info.Highlight == true)
    Preview:SetGradientColor(Preview.GradientColor)
    Preview:SetGradientEnabled(Info.Gradient == true)
    Preview:SetOpacity(Preview.Opacity)
    Preview:SetPosition(Preview.Side, Preview.Alignment)
    Preview:SetEnabled(Info.Enabled == true)

    return Preview
end

return VisualPreview
