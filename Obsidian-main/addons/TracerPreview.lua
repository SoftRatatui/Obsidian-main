local TweenService = game:GetService("TweenService")

local TracerPreview = {}

local function NormalizeAsset(Value)
    if typeof(Value) == "number" then
        return string.format("rbxassetid://%d", Value)
    end
    if typeof(Value) ~= "string" or Value == "" then
        return "rbxasset://textures/particles/sparkles_main.dds"
    end
    local Numeric = tonumber(Value)
    if Numeric then
        return string.format("rbxassetid://%d", Numeric)
    end
    return Value
end

local function AddRegistry(Library, Object, Properties)
    if Library and type(Library.AddToRegistry) == "function" then
        Library:AddToRegistry(Object, Properties)
    end
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

function TracerPreview.Create(Library, Info)
    Info = Info or {}
    local Style = Library and type(Library.GetAddonStyle) == "function" and Library:GetAddonStyle(Info.Style) or {
        Padding = 10,
        Radius = 7,
        ControlRadius = 4,
        OutlineTransparency = 0.5,
        StrokeThickness = 1,
        CaptionSize = 12,
        Motion = true,
    }
    local Height = math.clamp(math.floor(tonumber(Info.Height) or 92), 56, 260)
    local ColorA = typeof(Info.ColorA) == "Color3" and Info.ColorA or Color3.fromRGB(255, 218, 64)
    local ColorB = typeof(Info.ColorB) == "Color3" and Info.ColorB or Color3.fromRGB(255, 246, 168)

    local Root = Instance.new("CanvasGroup")
    Root.Name = "MonHubTracerPreview"
    Root.BackgroundColor3 = Library and (Library.Scheme.SurfaceColor or Library.Scheme.BackgroundColor) or Color3.fromRGB(14, 16, 19)
    Root.BackgroundTransparency = math.clamp(tonumber(Info.BackgroundTransparency) or Style.BackgroundTransparency or 0, 0, 1)
    Root.BorderSizePixel = 0
    Root.ClipsDescendants = true
    Root.Size = UDim2.new(1, 0, 0, Height)
    Root.Visible = Info.Visible ~= false
    AddRegistry(Library, Root, {
        BackgroundColor3 = function()
            return Library.Scheme.SurfaceColor or Library.Scheme.BackgroundColor
        end,
    })

    local RootCorner = Instance.new("UICorner")
    RootCorner.CornerRadius = UDim.new(0, Style.Radius)
    RootCorner.Parent = Root

    local Stroke = Instance.new("UIStroke")
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Color = Library and Library.Scheme.OutlineColor or Color3.fromRGB(48, 53, 62)
    Stroke.Thickness = Style.StrokeThickness
    Stroke.Transparency = math.clamp(tonumber(Info.OutlineTransparency) or Style.OutlineTransparency, 0, 1)
    Stroke.Parent = Root
    AddRegistry(Library, Stroke, { Color = "OutlineColor" })

    local Canvas = Instance.new("Frame")
    Canvas.BackgroundColor3 = Library and Library.Scheme.BackgroundColor or Color3.fromRGB(9, 11, 14)
    Canvas.BorderSizePixel = 0
    Canvas.ClipsDescendants = true
    Canvas.Position = UDim2.fromOffset(Style.Padding, Style.Padding)
    Canvas.Size = UDim2.new(1, -Style.Padding * 2, 1, -(Style.Padding + 20))
    Canvas.Parent = Root
    AddRegistry(Library, Canvas, { BackgroundColor3 = "BackgroundColor" })

    local CanvasCorner = Instance.new("UICorner")
    CanvasCorner.CornerRadius = UDim.new(0, math.max(0, Style.Radius - 1))
    CanvasCorner.Parent = Canvas

    local Grid = Instance.new("Frame")
    Grid.BackgroundTransparency = 1
    Grid.Size = UDim2.fromScale(1, 1)
    Grid.Parent = Canvas

    for Index = 1, 9 do
        local Line = Instance.new("Frame")
        Line.BackgroundColor3 = Library and Library.Scheme.OutlineColor or Color3.fromRGB(48, 53, 62)
        Line.BackgroundTransparency = 0.72
        Line.BorderSizePixel = 0
        Line.Position = UDim2.fromScale(Index / 10, 0)
        Line.Size = UDim2.new(0, 1, 1, 0)
        Line.Parent = Grid
        AddRegistry(Library, Line, { BackgroundColor3 = "OutlineColor" })
    end
    for Index = 1, 3 do
        local Line = Instance.new("Frame")
        Line.BackgroundColor3 = Library and Library.Scheme.OutlineColor or Color3.fromRGB(48, 53, 62)
        Line.BackgroundTransparency = 0.72
        Line.BorderSizePixel = 0
        Line.Position = UDim2.fromScale(0, Index / 4)
        Line.Size = UDim2.new(1, 0, 0, 1)
        Line.Parent = Grid
        AddRegistry(Library, Line, { BackgroundColor3 = "OutlineColor" })
    end

    local Layers = {}
    local LayerSpecs = {
        { Height = 16, Transparency = 0.84 },
        { Height = 8, Transparency = 0.56 },
        { Height = 3, Transparency = 0.02 },
    }
    for Index, Spec in LayerSpecs do
        local Layer = Instance.new("ImageLabel")
        Layer.AnchorPoint = Vector2.new(0, 0.5)
        Layer.BackgroundTransparency = 1
        Layer.Image = NormalizeAsset(Info.AssetId or Info.Image)
        Layer.ImageColor3 = Color3.new(1, 1, 1)
        Layer.ImageTransparency = Spec.Transparency
        Layer.Position = UDim2.new(0, 12, 0.5, 0)
        Layer.ResampleMode = Enum.ResamplerMode.Default
        Layer.ScaleType = Enum.ScaleType.Stretch
        Layer.Size = UDim2.new(1, -24, 0, Spec.Height)
        Layer.ZIndex = Index + 1
        Layer.Parent = Canvas

        local Gradient = Instance.new("UIGradient")
        Gradient.Color = ColorSequence.new(ColorA, ColorB)
        Gradient.Offset = Vector2.new(-0.24, 0)
        Gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.16, 0.72),
            NumberSequenceKeypoint.new(0.42, 0),
            NumberSequenceKeypoint.new(0.68, 0.08),
            NumberSequenceKeypoint.new(0.86, 0.72),
            NumberSequenceKeypoint.new(1, 1),
        })
        Gradient.Parent = Layer

        table.insert(Layers, {
            Image = Layer,
            Gradient = Gradient,
            Tween = nil,
        })
    end

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
    Label.Position = UDim2.new(0, 10, 1, -20)
    Label.Size = UDim2.new(1, -20, 0, 18)
    Label.Text = tostring(Info.Name or "tracer")
    Label.TextColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(145, 151, 161)
    Label.TextSize = Style.CaptionSize
    Label.TextTruncate = Enum.TextTruncate.AtEnd
    Label.TextXAlignment = Enum.TextXAlignment.Center
    Label.Parent = Root
    AddRegistry(Library, Label, {
        FontFace = "Font",
        TextColor3 = "MutedFontColor",
    })

    local Preview = {
        Root = Root,
        Canvas = Canvas,
        Label = Label,
        Layers = Layers,
        Element = nil,
        AssetId = Info.AssetId or Info.Image,
        ColorA = ColorA,
        ColorB = ColorB,
        Glow = math.clamp(tonumber(Info.Glow) or 0.82, 0, 1),
        Speed = math.clamp(tonumber(Info.Speed) or 1.25, 0, 8),
        Enabled = Info.Enabled ~= false,
        Visible = Info.Visible ~= false,
        Height = Height,
        Style = Style,
        Destroyed = false,
    }

    local function StopTweens()
        for _, Layer in Preview.Layers do
            if Layer.Tween then
                pcall(function()
                    Layer.Tween:Cancel()
                    Layer.Tween:Destroy()
                end)
                Layer.Tween = nil
            end
        end
    end

    local function StartTweens()
        StopTweens()
        if Style.Motion == false or not Preview.Enabled or not Preview.Visible or Preview.Speed <= 0 then
            return
        end
        for _, Layer in Preview.Layers do
            Layer.Gradient.Offset = Vector2.new(-0.24, 0)
            Layer.Tween = TweenService:Create(
                Layer.Gradient,
                TweenInfo.new(math.max(0.12, 2 / Preview.Speed), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
                { Offset = Vector2.new(0.24, 0) }
            )
            Layer.Tween:Play()
        end
    end

    function Preview:SetAssetId(AssetId)
        if Preview.Destroyed then
            return
        end
        Preview.AssetId = AssetId
        local Image = NormalizeAsset(AssetId)
        for _, Layer in Preview.Layers do
            Layer.Image.Image = Image
        end
    end

    function Preview:SetColors(First, Second)
        if Preview.Destroyed then
            return
        end
        if typeof(First) == "Color3" then
            Preview.ColorA = First
        end
        if typeof(Second) == "Color3" then
            Preview.ColorB = Second
        end
        local Sequence = ColorSequence.new(Preview.ColorA, Preview.ColorB)
        for _, Layer in Preview.Layers do
            Layer.Gradient.Color = Sequence
        end
    end

    function Preview:SetGlow(Glow)
        if Preview.Destroyed then
            return
        end
        Preview.Glow = math.clamp(tonumber(Glow) or Preview.Glow, 0, 1)
        local Outer = Preview.Layers[1]
        local Middle = Preview.Layers[2]
        Outer.Image.ImageTransparency = 0.98 - Preview.Glow * 0.2
        Middle.Image.ImageTransparency = 0.9 - Preview.Glow * 0.36
    end

    function Preview:SetSpeed(Speed)
        if Preview.Destroyed then
            return
        end
        Preview.Speed = math.clamp(tonumber(Speed) or Preview.Speed, 0, 8)
        StartTweens()
    end

    function Preview:SetEnabled(Enabled)
        if Preview.Destroyed then
            return
        end
        Preview.Enabled = Enabled == true
        for _, Layer in Preview.Layers do
            Layer.Image.Visible = Preview.Enabled
        end
        StartTweens()
    end

    function Preview:SetName(Name)
        if not Preview.Destroyed then
            Label.Text = tostring(Name or "")
        end
    end

    function Preview:SetHeight(NewHeight)
        if Preview.Destroyed then
            return
        end
        Preview.Height = math.clamp(math.floor(tonumber(NewHeight) or Preview.Height), 56, 260)
        Root.Size = UDim2.new(1, 0, 0, Preview.Height)
        if Preview.Element then
            Preview.Element:SetHeight(Preview.Height)
        end
    end

    function Preview:SetVisible(Visible)
        if Preview.Destroyed then
            return
        end
        Preview.Visible = Visible == true
        Root.Visible = Preview.Visible
        if Preview.Element then
            Preview.Element:SetVisible(Preview.Visible)
        end
        StartTweens()
    end

    function Preview:Mount(Parent)
        if Preview.Destroyed or typeof(Parent) ~= "Instance" or not Parent:IsA("GuiBase2d") then
            return false
        end
        Root.Parent = Parent
        return true
    end

    function Preview:Destroy()
        if Preview.Destroyed then
            return
        end
        Preview.Destroyed = true
        StopTweens()
        RemoveRegistryTree(Library, Root)
        if Preview.Element then
            Preview.Element:Destroy()
            Preview.Element = nil
        elseif Root then
            Root:Destroy()
        end
    end

    if typeof(Info.Parent) == "Instance" and Info.Parent:IsA("GuiBase2d") then
        Root.Parent = Info.Parent
    end
    Preview:SetGlow(Preview.Glow)
    Preview:SetEnabled(Preview.Enabled)

    if Library and type(Library.OnUnload) == "function" then
        Library:OnUnload(function()
            Preview:Destroy()
        end)
    end

    return Preview
end

function TracerPreview.CreateEmbedded(Library, Groupbox, Idx, Info)
    assert(type(Groupbox) == "table" and type(Groupbox.AddUIPassthrough) == "function", "TracerPreview requires a groupbox")
    Info = Info or {}
    local Preview = TracerPreview.Create(Library, Info)
    Preview.Element = Groupbox:AddUIPassthrough(Idx or "TracerPreview", {
        Instance = Preview.Root,
        Height = Preview.Height,
        Visible = Preview.Visible,
    })
    return Preview
end

function TracerPreview.CreateStandalone(Library, Info)
    assert(Library and type(Library.CreateAddonWindow) == "function", "TracerPreview standalone mode requires Library:CreateAddonWindow")
    Info = table.clone(Info or {})
    local WindowHeight = tonumber(Info.WindowHeight) or 360
    local Host = Library:CreateAddonWindow({
        Title = Info.WindowTitle or "Tracer preview",
        Subtitle = Info.WindowSubtitle,
        Icon = Info.WindowIcon or "sparkles",
        Width = Info.WindowWidth or 420,
        Height = WindowHeight,
        Position = Info.Position,
        AnchorPoint = Info.AnchorPoint,
        Draggable = Info.Draggable,
        Resizable = Info.Resizable,
        Closable = Info.Closable,
        HideWithMenu = Info.HideWithMenu,
        Visible = Info.Visible,
        Style = Info.Style,
    })
    if Info.FitHeight == nil then
        Info.FitHeight = Info.Height == nil
    end
    Info.Height = Info.Height or math.max(160, WindowHeight - 72)
    local Preview = Host:AddAddon("Preview", TracerPreview, Info)
    Preview.Host = Host
    return Preview, Host
end

TracerPreview.Mount = TracerPreview.CreateEmbedded

return TracerPreview
