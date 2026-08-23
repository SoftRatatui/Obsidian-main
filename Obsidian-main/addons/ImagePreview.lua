local TweenService = game:GetService("TweenService")

local ImagePreview = {}

local function NormalizeAsset(Value)
    if typeof(Value) == "number" then
        return string.format("rbxassetid://%d", Value)
    end
    if typeof(Value) ~= "string" or Value == "" then
        return ""
    end
    local Numeric = tonumber(Value)
    if Numeric then
        return string.format("rbxassetid://%d", Numeric)
    end
    return Value
end

local function ResolveScaleType(Value)
    if typeof(Value) == "EnumItem" and Value.EnumType == Enum.ScaleType then
        return Value
    end
    local Key = string.lower(tostring(Value or "Fit"))
    if Key == "crop" then
        return Enum.ScaleType.Crop
    elseif Key == "stretch" then
        return Enum.ScaleType.Stretch
    elseif Key == "tile" then
        return Enum.ScaleType.Tile
    end
    return Enum.ScaleType.Fit
end

local function AddRegistry(Library, Object, Properties)
    if Library and type(Library.AddToRegistry) == "function" then
        Library:AddToRegistry(Object, Properties)
    end
end

local function RemoveRegistryTree(Library, Root)
    if not Library or type(Library.RemoveFromRegistry) ~= "function" or type(Library.Registry) ~= "table" or typeof(Root) ~= "Instance" then
        return
    end
    local Owned = {}
    for Object in Library.Registry do
        local Success, Matches = pcall(function()
            return Object == Root or Object:IsDescendantOf(Root)
        end)
        if Success and Matches then
            table.insert(Owned, Object)
        end
    end
    for _, Object in Owned do
        Library:RemoveFromRegistry(Object)
    end
end

function ImagePreview.Create(Library, Info)
    Info = Info or {}
    local Height = math.clamp(math.floor(tonumber(Info.Height) or 260), 96, 720)
    local CaptionHeight = Info.Caption == false and 0 or math.clamp(math.floor(tonumber(Info.CaptionHeight) or 48), 32, 80)
    local Radius = math.clamp(math.floor(tonumber(Info.CornerRadius) or 5), 0, 12)
    local Motion = Info.Motion ~= false
    local TargetTransparency = math.clamp(tonumber(Info.ImageTransparency) or 0, 0, 1)

    local Root = Instance.new("Frame")
    Root.Name = "MonHubImagePreview"
    Root.BackgroundColor3 = Library and (Library.Scheme.SurfaceColor or Library.Scheme.BackgroundColor) or Color3.fromRGB(18, 20, 24)
    Root.BorderSizePixel = 0
    Root.ClipsDescendants = true
    Root.Size = UDim2.new(1, 0, 0, Height)
    Root.Visible = Info.Visible ~= false
    AddRegistry(Library, Root, {
        BackgroundColor3 = function()
            return Library.Scheme.SurfaceColor or Library.Scheme.BackgroundColor
        end,
    })

    if Radius > 0 then
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, Radius)
        Corner.Parent = Root
    end

    local Stroke = Instance.new("UIStroke")
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Color = Library and Library.Scheme.OutlineColor or Color3.fromRGB(52, 57, 66)
    Stroke.Transparency = 0.22
    Stroke.Parent = Root
    AddRegistry(Library, Stroke, { Color = "OutlineColor" })

    local Canvas = Instance.new("Frame")
    Canvas.BackgroundColor3 = Library and Library.Scheme.BackgroundColor or Color3.fromRGB(11, 13, 16)
    Canvas.BorderSizePixel = 0
    Canvas.ClipsDescendants = true
    Canvas.Size = UDim2.new(1, 0, 1, -CaptionHeight)
    Canvas.Parent = Root
    AddRegistry(Library, Canvas, { BackgroundColor3 = "BackgroundColor" })

    local Layers = {}
    for Index = 1, 2 do
        local Layer = Instance.new("ImageLabel")
        Layer.AnchorPoint = Vector2.new(0.5, 0.5)
        Layer.BackgroundTransparency = 1
        Layer.Image = ""
        Layer.ImageColor3 = typeof(Info.ImageColor) == "Color3" and Info.ImageColor or Color3.new(1, 1, 1)
        Layer.ImageTransparency = 1
        Layer.Position = UDim2.fromScale(0.5, 0.5)
        Layer.ScaleType = ResolveScaleType(Info.ScaleType)
        Layer.Size = UDim2.fromScale(1, 1)
        Layer.Visible = Index == 1
        Layer.Parent = Canvas

        local Scale = Instance.new("UIScale")
        Scale.Scale = 1
        Scale.Parent = Layer

        Layers[Index] = {
            Image = Layer,
            Scale = Scale,
        }
    end

    local Shade = Instance.new("Frame")
    Shade.AnchorPoint = Vector2.new(0, 1)
    Shade.BackgroundColor3 = Color3.fromRGB(4, 5, 7)
    Shade.BackgroundTransparency = 0.32
    Shade.BorderSizePixel = 0
    Shade.Position = UDim2.fromScale(0, 1)
    Shade.Size = UDim2.new(1, 0, 0, math.min(72, math.max(42, Height * 0.28)))
    Shade.ZIndex = 3
    Shade.Parent = Canvas

    local ShadeGradient = Instance.new("UIGradient")
    ShadeGradient.Rotation = 90
    ShadeGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0.12),
    })
    ShadeGradient.Parent = Shade

    local Empty = Instance.new("TextLabel")
    Empty.BackgroundTransparency = 1
    Empty.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.Gotham)
    Empty.Position = UDim2.fromOffset(12, 0)
    Empty.Size = UDim2.new(1, -24, 1, 0)
    Empty.Text = tostring(Info.EmptyText or "Select an item")
    Empty.TextColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(143, 149, 158)
    Empty.TextSize = 13
    Empty.TextWrapped = true
    Empty.ZIndex = 2
    Empty.Parent = Canvas
    AddRegistry(Library, Empty, {
        FontFace = "Font",
        TextColor3 = "MutedFontColor",
    })

    local Caption = Instance.new("Frame")
    Caption.BackgroundColor3 = Library and (Library.Scheme.RaisedColor or Library.Scheme.SurfaceColor) or Color3.fromRGB(22, 24, 29)
    Caption.BorderSizePixel = 0
    Caption.Position = UDim2.new(0, 0, 1, -CaptionHeight)
    Caption.Size = UDim2.new(1, 0, 0, CaptionHeight)
    Caption.Visible = CaptionHeight > 0
    Caption.ZIndex = 4
    Caption.Parent = Root
    AddRegistry(Library, Caption, {
        BackgroundColor3 = function()
            return Library.Scheme.RaisedColor or Library.Scheme.SurfaceColor
        end,
    })

    local CaptionLine = Instance.new("Frame")
    CaptionLine.BackgroundColor3 = Library and Library.Scheme.OutlineColor or Color3.fromRGB(52, 57, 66)
    CaptionLine.BorderSizePixel = 0
    CaptionLine.Size = UDim2.new(1, 0, 0, 1)
    CaptionLine.Parent = Caption
    AddRegistry(Library, CaptionLine, { BackgroundColor3 = "OutlineColor" })

    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.Gotham)
    Title.Position = UDim2.fromOffset(12, 5)
    Title.Size = UDim2.new(1, -24, 0, 19)
    Title.Text = tostring(Info.Title or "Preview")
    Title.TextColor3 = Library and Library.Scheme.FontColor or Color3.fromRGB(232, 235, 240)
    Title.TextSize = 13
    Title.TextTruncate = Enum.TextTruncate.AtEnd
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Caption
    AddRegistry(Library, Title, {
        FontFace = "Font",
        TextColor3 = "FontColor",
    })

    local Subtitle = Instance.new("TextLabel")
    Subtitle.BackgroundTransparency = 1
    Subtitle.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.Gotham)
    Subtitle.Position = UDim2.fromOffset(12, 23)
    Subtitle.Size = UDim2.new(1, -24, 0, 18)
    Subtitle.Text = tostring(Info.Subtitle or "")
    Subtitle.TextColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(143, 149, 158)
    Subtitle.TextSize = 11
    Subtitle.TextTruncate = Enum.TextTruncate.AtEnd
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.Parent = Caption
    AddRegistry(Library, Subtitle, {
        FontFace = "Font",
        TextColor3 = "MutedFontColor",
    })

    local Preview = {
        Root = Root,
        Canvas = Canvas,
        Layers = Layers,
        TitleLabel = Title,
        SubtitleLabel = Subtitle,
        EmptyLabel = Empty,
        Element = nil,
        Connections = {},
        Tweens = {},
        CurrentLayer = 1,
        CurrentImage = "",
        ImageColor = typeof(Info.ImageColor) == "Color3" and Info.ImageColor or Color3.new(1, 1, 1),
        ImageTransparency = TargetTransparency,
        Height = Height,
        Visible = Info.Visible ~= false,
        Motion = Motion,
        TransitionSequence = 0,
        Destroyed = false,
    }

    local function StopTween(Key)
        local Tween = Preview.Tweens[Key]
        if Tween then
            pcall(function()
                Tween:Cancel()
                Tween:Destroy()
            end)
            Preview.Tweens[Key] = nil
        end
    end

    local function Play(Object, Key, Duration, Properties)
        StopTween(Key)
        local Success, Tween = pcall(function()
            return TweenService:Create(Object, TweenInfo.new(Duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), Properties)
        end)
        if not Success or not Tween then
            for Property, Value in Properties do
                pcall(function()
                    Object[Property] = Value
                end)
            end
            return nil
        end
        Preview.Tweens[Key] = Tween
        Tween.Completed:Once(function()
            if Preview.Tweens[Key] == Tween then
                Preview.Tweens[Key] = nil
            end
            pcall(function()
                Tween:Destroy()
            end)
        end)
        Tween:Play()
        return Tween
    end

    function Preview:SetImage(Value, Transition)
        if Preview.Destroyed then
            return
        end
        local Asset = NormalizeAsset(Value)
        if Asset == Preview.CurrentImage then
            return
        end
        Preview.CurrentImage = Asset
        Preview.TransitionSequence += 1
        local Sequence = Preview.TransitionSequence
        Empty.Visible = Asset == ""
        local Previous = Preview.Layers[Preview.CurrentLayer]
        local PreviousIndex = Preview.CurrentLayer
        local NextIndex = Preview.CurrentLayer == 1 and 2 or 1
        local Next = Preview.Layers[NextIndex]
        Next.Image.Image = Asset
        Next.Image.ImageColor3 = Preview.ImageColor
        Next.Image.ImageTransparency = 1
        Next.Image.Visible = Asset ~= ""
        Next.Scale.Scale = Preview.Motion and 1.025 or 1

        local Animated = Preview.Motion and Transition ~= false and Asset ~= ""
        if Animated then
            Play(Previous.Image, "PreviousImage", 0.1, { ImageTransparency = 1 })
            Play(Next.Image, "NextImage", 0.14, { ImageTransparency = Preview.ImageTransparency })
            Play(Next.Scale, "NextScale", 0.2, { Scale = 1 })
            task.delay(0.11, function()
                if not Preview.Destroyed and Sequence == Preview.TransitionSequence and Preview.CurrentLayer ~= PreviousIndex then
                    Previous.Image.Visible = false
                end
            end)
        else
            Previous.Image.ImageTransparency = 1
            Previous.Image.Visible = false
            Next.Image.ImageTransparency = Asset == "" and 1 or Preview.ImageTransparency
            Next.Scale.Scale = 1
        end
        Preview.CurrentLayer = NextIndex
    end

    function Preview:SetTitle(Value)
        if not Preview.Destroyed then
            Title.Text = tostring(Value or "")
        end
    end

    function Preview:SetSubtitle(Value)
        if not Preview.Destroyed then
            Subtitle.Text = tostring(Value or "")
        end
    end

    function Preview:SetImageColor(Value)
        if Preview.Destroyed or typeof(Value) ~= "Color3" then
            return
        end
        Preview.ImageColor = Value
        for _, Layer in Preview.Layers do
            Layer.Image.ImageColor3 = Value
        end
    end

    function Preview:SetImageTransparency(Value)
        if Preview.Destroyed then
            return
        end
        Preview.ImageTransparency = math.clamp(tonumber(Value) or Preview.ImageTransparency, 0, 1)
        Preview.Layers[Preview.CurrentLayer].Image.ImageTransparency = Preview.CurrentImage == "" and 1 or Preview.ImageTransparency
    end

    function Preview:SetScaleType(Value)
        if Preview.Destroyed then
            return
        end
        local ScaleType = ResolveScaleType(Value)
        for _, Layer in Preview.Layers do
            Layer.Image.ScaleType = ScaleType
        end
    end

    function Preview:SetMotion(Enabled)
        if not Preview.Destroyed then
            Preview.Motion = Enabled == true
        end
    end

    function Preview:SetHeight(Value)
        if Preview.Destroyed then
            return
        end
        Preview.Height = math.clamp(math.floor(tonumber(Value) or Preview.Height), 96, 720)
        Root.Size = UDim2.new(1, 0, 0, Preview.Height)
        if Preview.Element then
            Preview.Element:SetHeight(Preview.Height)
        end
    end

    function Preview:SetVisible(Value)
        if Preview.Destroyed then
            return
        end
        Preview.Visible = Value == true
        Root.Visible = Preview.Visible
        if Preview.Element then
            Preview.Element:SetVisible(Preview.Visible)
        end
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
        for Key in Preview.Tweens do
            StopTween(Key)
        end
        for _, Connection in Preview.Connections do
            pcall(function()
                Connection:Disconnect()
            end)
        end
        table.clear(Preview.Connections)
        RemoveRegistryTree(Library, Root)
        if Preview.Element then
            Preview.Element:Destroy()
            Preview.Element = nil
        elseif Root then
            Root:Destroy()
        end
    end

    if Info.Interactive ~= false then
        table.insert(Preview.Connections, Canvas.MouseEnter:Connect(function()
            if Preview.Destroyed or not Preview.Motion then
                return
            end
            Play(Preview.Layers[Preview.CurrentLayer].Scale, "Hover", 0.12, { Scale = 1.012 })
        end))
        table.insert(Preview.Connections, Canvas.MouseLeave:Connect(function()
            if Preview.Destroyed then
                return
            end
            Play(Preview.Layers[Preview.CurrentLayer].Scale, "Hover", 0.12, { Scale = 1 })
        end))
    end

    if typeof(Info.Parent) == "Instance" and Info.Parent:IsA("GuiBase2d") then
        Root.Parent = Info.Parent
    end
    Preview:SetImage(Info.Image or Info.AssetId, false)

    if Library and type(Library.OnUnload) == "function" then
        Library:OnUnload(function()
            Preview:Destroy()
        end)
    end

    return Preview
end

function ImagePreview.CreateEmbedded(Library, Groupbox, Idx, Info)
    assert(type(Groupbox) == "table" and type(Groupbox.AddUIPassthrough) == "function", "ImagePreview requires a groupbox")
    Info = Info or {}
    local Preview = ImagePreview.Create(Library, Info)
    Preview.Element = Groupbox:AddUIPassthrough(Idx or "ImagePreview", {
        Instance = Preview.Root,
        Height = Preview.Height,
        Visible = Preview.Visible,
    })
    return Preview
end

return ImagePreview
