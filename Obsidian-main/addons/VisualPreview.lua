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
        Health = Health,
        Tracer = Tracer,
    }
end

function VisualPreview.Create(Tab, Info)
    Info = Info or {}

    local Group = Tab:AddRightGroupbox(Info.Name or "ESP preview", Info.Icon or "scan-eye")
    local Viewport = Group:AddViewport(Info.Id or "VisualPreviewViewport", {
        Object = VisualPreview.CreateR6(),
        Clone = false,
        AutoFocus = true,
        Interactive = true,
        Height = Info.Height or 286,
    })
    local AccentColor = Info.Color or Color3.fromRGB(119, 166, 209)
    local Overlay = CreateOverlay(Viewport.Box, AccentColor)
    local Preview = {
        Group = Group,
        Viewport = Viewport,
        Overlay = Overlay,
        Enabled = false,
    }

    function Preview:SetEnabled(Enabled)
        Preview.Enabled = Enabled == true
        Overlay.Overlay.Visible = Preview.Enabled
        Group:SetVisible(Preview.Enabled)
        if Group.Tab and Group.Tab.Resize then
            Group.Tab:Resize()
        end
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
        if Preview.Group then
            Preview.Group:Destroy()
        end
    end

    Preview:SetEnabled(Info.Enabled == true)
    Preview:SetBoxVisible(Info.Box ~= false)
    Preview:SetNameVisible(Info.NameVisible ~= false)
    Preview:SetDistanceVisible(Info.Distance ~= false)
    Preview:SetTracerVisible(Info.Tracer == true)
    Preview:SetHealthVisible(Info.Health ~= false)
    Preview:SetHighlightVisible(Info.Highlight == true)

    return Preview
end

return VisualPreview
