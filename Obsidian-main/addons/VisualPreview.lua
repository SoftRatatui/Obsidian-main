local UserInputService = game:GetService("UserInputService")

local VisualPreview = {}

local function CreatePart(Model, Name, Size, Position, Color, Transparency)
    local Part = Instance.new("Part")
    Part.Name = Name
    Part.Anchored = true
    Part.CanCollide = false
    Part.CastShadow = true
    Part.Color = Color
    Part.Material = Enum.Material.SmoothPlastic
    Part.Size = Size
    Part.CFrame = CFrame.new(Position)
    Part.Transparency = Transparency or 0
    Part.TopSurface = Enum.SurfaceType.Smooth
    Part.BottomSurface = Enum.SurfaceType.Smooth
    Part.Parent = Model
    return Part
end

function VisualPreview.CreateR6()
    local Model = Instance.new("Model")
    Model.Name = "MonHubVisualPreviewR6"

    local White = Color3.fromRGB(244, 248, 252)
    local Root = CreatePart(Model, "HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), White, 1)
    local Torso = CreatePart(Model, "Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), White)
    local Head = CreatePart(Model, "Head", Vector3.new(2, 1, 1), Vector3.new(0, 4.5, 0), White)
    local RightArm = CreatePart(Model, "Right Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0), White)
    local LeftArm = CreatePart(Model, "Left Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0), White)
    local RightLeg = CreatePart(Model, "Right Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0), White)
    local LeftLeg = CreatePart(Model, "Left Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0), White)

    local HeadMesh = Instance.new("SpecialMesh")
    HeadMesh.MeshType = Enum.MeshType.Head
    HeadMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
    HeadMesh.Parent = Head

    local Humanoid = Instance.new("Humanoid")
    Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    Humanoid.NameDisplayDistance = 0
    Humanoid.HealthDisplayDistance = 0
    Humanoid.Parent = Model

    local function CreateJoint(Name, Part0, Part1)
        local Joint = Instance.new("Motor6D")
        Joint.Name = Name
        Joint.Part0 = Part0
        Joint.Part1 = Part1
        Joint.C0 = Part0.CFrame:ToObjectSpace(Part1.CFrame)
        Joint.Parent = Part0
    end

    CreateJoint("RootJoint", Root, Torso)
    CreateJoint("Neck", Torso, Head)
    CreateJoint("Right Shoulder", Torso, RightArm)
    CreateJoint("Left Shoulder", Torso, LeftArm)
    CreateJoint("Right Hip", Torso, RightLeg)
    CreateJoint("Left Hip", Torso, LeftLeg)

    local Platform = CreatePart(
        Model,
        "Platform",
        Vector3.new(4.8, 0.3, 3.2),
        Vector3.new(0, -0.2, 0),
        Color3.fromRGB(25, 38, 52)
    )
    local Light = Instance.new("PointLight")
    Light.Brightness = 0.65
    Light.Color = Color3.fromRGB(170, 205, 234)
    Light.Range = 8
    Light.Parent = Platform

    Model.PrimaryPart = Root
    return Model
end

local function CreateOverlay(Parent, AccentColor)
    local Overlay = Instance.new("Frame")
    Overlay.Name = "VisualPreviewOverlay"
    Overlay.BackgroundTransparency = 1
    Overlay.Size = UDim2.fromScale(1, 1)
    Overlay.ZIndex = 3
    Overlay.Parent = Parent

    local Highlight = Instance.new("Frame")
    Highlight.AnchorPoint = Vector2.new(0.5, 0.5)
    Highlight.BackgroundColor3 = AccentColor
    Highlight.BackgroundTransparency = 0.9
    Highlight.BorderSizePixel = 0
    Highlight.Position = UDim2.new(0.5, 0, 0.52, 0)
    Highlight.Size = UDim2.new(0.34, 0, 0.62, 0)
    Highlight.ZIndex = 3
    Highlight.Parent = Overlay

    local Box = Instance.new("Frame")
    Box.AnchorPoint = Vector2.new(0.5, 0.5)
    Box.BackgroundTransparency = 1
    Box.Position = UDim2.new(0.5, 0, 0.52, 0)
    Box.Size = UDim2.new(0.36, 0, 0.66, 0)
    Box.ZIndex = 4
    Box.Parent = Overlay

    local BoxStroke = Instance.new("UIStroke")
    BoxStroke.Color = AccentColor
    BoxStroke.Thickness = 1.5
    BoxStroke.Parent = Box

    local Name = Instance.new("TextLabel")
    Name.AnchorPoint = Vector2.new(0.5, 1)
    Name.BackgroundTransparency = 1
    Name.Font = Enum.Font.GothamMedium
    Name.Position = UDim2.new(0.5, 0, 0.18, -3)
    Name.Size = UDim2.new(0.82, 0, 0, 16)
    Name.Text = "Preview Player"
    Name.TextColor3 = AccentColor
    Name.TextSize = 12
    Name.TextStrokeColor3 = Color3.fromRGB(9, 13, 18)
    Name.TextStrokeTransparency = 0.35
    Name.TextTruncate = Enum.TextTruncate.AtEnd
    Name.ZIndex = 5
    Name.Parent = Overlay

    local Distance = Instance.new("TextLabel")
    Distance.AnchorPoint = Vector2.new(0.5, 0)
    Distance.BackgroundTransparency = 1
    Distance.Font = Enum.Font.Gotham
    Distance.Position = UDim2.new(0.5, 0, 0.86, 3)
    Distance.Size = UDim2.new(0.82, 0, 0, 14)
    Distance.Text = "86m"
    Distance.TextColor3 = Color3.fromRGB(244, 248, 252)
    Distance.TextSize = 11
    Distance.TextStrokeColor3 = Color3.fromRGB(9, 13, 18)
    Distance.TextStrokeTransparency = 0.45
    Distance.ZIndex = 5
    Distance.Parent = Overlay

    local HealthBack = Instance.new("Frame")
    HealthBack.AnchorPoint = Vector2.new(1, 0.5)
    HealthBack.BackgroundColor3 = Color3.fromRGB(7, 10, 14)
    HealthBack.BorderSizePixel = 0
    HealthBack.Position = UDim2.new(0.3, -4, 0.52, 0)
    HealthBack.Size = UDim2.new(0, 3, 0.66, 0)
    HealthBack.ZIndex = 4
    HealthBack.Parent = Overlay

    local Health = Instance.new("Frame")
    Health.AnchorPoint = Vector2.new(0, 1)
    Health.BackgroundColor3 = Color3.fromRGB(103, 214, 143)
    Health.BorderSizePixel = 0
    Health.Position = UDim2.new(0, 0, 1, 0)
    Health.Size = UDim2.new(1, 0, 0.72, 0)
    Health.ZIndex = 5
    Health.Parent = HealthBack

    local Tracer = Instance.new("Frame")
    Tracer.AnchorPoint = Vector2.new(0.5, 1)
    Tracer.BackgroundColor3 = AccentColor
    Tracer.BorderSizePixel = 0
    Tracer.Position = UDim2.new(0.5, 0, 0.98, 0)
    Tracer.Size = UDim2.new(0, 1, 0.32, 0)
    Tracer.ZIndex = 4
    Tracer.Parent = Overlay

    return {
        Overlay = Overlay,
        Highlight = Highlight,
        Box = Box,
        BoxStroke = BoxStroke,
        Name = Name,
        Distance = Distance,
        HealthBack = HealthBack,
        Tracer = Tracer,
    }
end

local function FocusCamera(Object, Camera)
    local _, Size = Object:GetBoundingBox()
    local Extent = math.max(Size.X, Size.Y, Size.Z)
    local Position = Object:GetPivot().Position + Vector3.new(0, Extent * 0.08, 0)
    Camera.CFrame = CFrame.lookAt(Position + Vector3.new(0, 0, math.max(Extent * 1.8, 5)), Position)
end

function VisualPreview.Create(Library, Tab, Info)
    assert(Library and Library.AddDraggableMenu and Library.Window, "VisualPreview requires an active MonHub library")
    assert(Tab and Tab.Canvas, "VisualPreview requires a regular tab")

    Info = Info or {}

    local Holder, Container, AnimationScale = Library:AddDraggableMenu(Info.Name or "ESP preview")
    Holder.Name = "MonHubVisualPreview"
    Holder.AnchorPoint = Vector2.new(0, 0.5)
    Holder.AutomaticSize = Enum.AutomaticSize.None
    Holder.Size = UDim2.fromOffset(Info.Width or 348, Info.Height or 420)
    Holder.Visible = false
    AnimationScale.Scale = 0.98

    for _, Child in Container:GetChildren() do
        if Child:IsA("UIListLayout") or Child:IsA("UIPadding") then
            Child:Destroy()
        end
    end

    local Content = Instance.new("Frame")
    Content.BackgroundTransparency = 1
    Content.Size = UDim2.fromScale(1, 1)
    Content.Parent = Container

    local ViewportFrame = Instance.new("ViewportFrame")
    ViewportFrame.Active = true
    ViewportFrame.Ambient = Color3.fromRGB(156, 170, 184)
    ViewportFrame.BackgroundColor3 = Library.Scheme.BackgroundColor
    ViewportFrame.BackgroundTransparency = 0.03
    ViewportFrame.LightColor = Color3.fromRGB(238, 246, 255)
    ViewportFrame.LightDirection = Vector3.new(-1, -0.7, -1)
    ViewportFrame.Size = UDim2.fromScale(1, 1)
    ViewportFrame.ZIndex = 1
    ViewportFrame.Parent = Content
    Library:AddToRegistry(ViewportFrame, {
        BackgroundColor3 = "BackgroundColor",
    })

    local Camera = Instance.new("Camera")
    Camera.Parent = ViewportFrame
    ViewportFrame.CurrentCamera = Camera

    local Model = VisualPreview.CreateR6()
    Model.Parent = ViewportFrame
    FocusCamera(Model, Camera)

    local AccentColor = Info.Color or Library.Scheme.AccentColor
    local Overlay = CreateOverlay(Content, AccentColor)
    local Preview = {
        Holder = Holder,
        Frame = ViewportFrame,
        Camera = Camera,
        Model = Model,
        Overlay = Overlay,
        Enabled = false,
        Destroyed = false,
        Connections = {},
    }
    local MainFrame = Library.Window.Frame
    local Dragging = false
    local LastPosition = nil
    local ZoomDistance = math.max(select(2, Model:GetBoundingBox()).Magnitude * 0.78, 5)
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
        local PanelWidth = math.max(Holder.AbsoluteSize.X, Info.Width or 348)
        local ScreenSize = CameraObject.ViewportSize
        local X = MainPosition.X + MainSize.X + 12
        local AnchorPoint = Vector2.new(0, 0.5)

        if X + PanelWidth > ScreenSize.X - 8 then
            X = math.max(8, MainPosition.X - 12)
            AnchorPoint = Vector2.new(1, 0.5)
        end

        Holder.AnchorPoint = AnchorPoint
        Holder.Position = UDim2.fromOffset(math.floor(X + 0.5), math.floor(MainPosition.Y + MainSize.Y / 2 + 0.5))
    end

    local function IsDisplayable()
        return Preview.Enabled and Tab.Canvas.Visible and MainFrame.Visible
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
                Holder.GroupTransparency = 1
                AnimationScale.Scale = 0.98
                Holder.Visible = true
            end
            Library:PlayTween(Holder, "VisualPreviewVisibility", TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                GroupTransparency = 0,
            })
            Library:PlayTween(AnimationScale, "VisualPreviewVisibility", TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Scale = 1,
            })
            return
        end

        if not Holder.Visible then
            return
        end

        local Tween = Library:PlayTween(Holder, "VisualPreviewVisibility", TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            GroupTransparency = 1,
        })
        Library:PlayTween(AnimationScale, "VisualPreviewVisibility", TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
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

    local function Zoom(Amount)
        local TargetDistance = math.clamp(ZoomDistance - Amount, 3.6, 13)
        if TargetDistance == ZoomDistance then
            return
        end

        ZoomDistance = TargetDistance
        local Pivot = Model:GetPivot().Position + Vector3.new(0, 0.3, 0)
        Camera.CFrame = CFrame.lookAt(Pivot + Camera.CFrame.LookVector * -ZoomDistance, Pivot)
    end

    table.insert(Preview.Connections, MainFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(PositionPanel))
    table.insert(Preview.Connections, MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(PositionPanel))
    table.insert(Preview.Connections, MainFrame:GetPropertyChangedSignal("Visible"):Connect(UpdateVisibility))
    table.insert(Preview.Connections, Tab.Canvas:GetPropertyChangedSignal("Visible"):Connect(UpdateVisibility))
    if workspace.CurrentCamera then
        table.insert(Preview.Connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(PositionPanel))
    end
    table.insert(Preview.Connections, ViewportFrame.InputBegan:Connect(function(Input)
        if not Preview.Enabled then
            return
        end

        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            LastPosition = Input.Position
        end
    end))
    table.insert(Preview.Connections, UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end))
    table.insert(Preview.Connections, UserInputService.InputChanged:Connect(function(Input)
        if not Preview.Enabled or not Dragging then
            return
        end

        if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local Delta = Input.Position - LastPosition
        LastPosition = Input.Position
        local Pivot = Model:GetPivot().Position + Vector3.new(0, 0.3, 0)
        local RotationY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -Delta.X * 0.01)
        Camera.CFrame = CFrame.new(Pivot) * RotationY * CFrame.new(-Pivot) * Camera.CFrame
        local RotationX = CFrame.fromAxisAngle(Camera.CFrame.RightVector, -Delta.Y * 0.01)
        local Pitched = CFrame.new(Pivot) * RotationX * CFrame.new(-Pivot) * Camera.CFrame
        if Pitched.UpVector.Y > 0.1 then
            Camera.CFrame = Pitched
        end
    end))
    table.insert(Preview.Connections, ViewportFrame.InputChanged:Connect(function(Input)
        if Preview.Enabled and Input.UserInputType == Enum.UserInputType.MouseWheel then
            Zoom(Input.Position.Z * 1.4)
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

        Overlay.Highlight.BackgroundColor3 = Color
        Overlay.BoxStroke.Color = Color
        Overlay.Name.TextColor3 = Color
        Overlay.Tracer.BackgroundColor3 = Color
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

    function Preview:SetTracerVisible(Visible)
        Overlay.Tracer.Visible = Visible == true
    end

    function Preview:SetHealthVisible(Visible)
        Overlay.HealthBack.Visible = Visible == true
    end

    function Preview:SetHighlightVisible(Visible)
        Overlay.Highlight.Visible = Visible == true
    end

    function Preview:SetDistance(Value)
        Overlay.Distance.Text = string.format("%sm", tostring(Value))
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
    Preview:SetNameVisible(Info.NameVisible ~= false)
    Preview:SetDistanceVisible(Info.Distance ~= false)
    Preview:SetTracerVisible(Info.Tracer == true)
    Preview:SetHealthVisible(Info.Health ~= false)
    Preview:SetHighlightVisible(Info.Highlight == true)
    Preview:SetEnabled(Info.Enabled == true)

    return Preview
end

return VisualPreview
