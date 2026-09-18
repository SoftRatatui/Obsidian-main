local TextureGallery = {
    ReleaseVersion = "0.0.1-release-3",
}

TextureGallery.DefaultItems = {
    { Id = "none", Name = "Clean", Texture = "", ColorA = Color3.fromRGB(168, 181, 199), ColorB = Color3.fromRGB(105, 116, 133) },
    { Id = "beam", Name = "Soft beam", Texture = "rbxassetid://12781852245", ColorA = Color3.fromRGB(126, 174, 216), ColorB = Color3.fromRGB(187, 153, 224) },
    { Id = "lightning", Name = "Lightning", Texture = "rbxassetid://446111271", ColorA = Color3.fromRGB(155, 203, 242), ColorB = Color3.fromRGB(103, 135, 208) },
    { Id = "heartrate", Name = "Pulse", Texture = "rbxassetid://5830549480", ColorA = Color3.fromRGB(111, 204, 181), ColorB = Color3.fromRGB(137, 166, 221) },
    { Id = "chain", Name = "Chain", Texture = "rbxassetid://9632168658", ColorA = Color3.fromRGB(210, 214, 223), ColorB = Color3.fromRGB(125, 133, 148) },
    { Id = "glitch", Name = "Glitch", Texture = "rbxassetid://8089467613", ColorA = Color3.fromRGB(119, 185, 231), ColorB = Color3.fromRGB(198, 132, 220) },
    { Id = "swirl", Name = "Swirl", Texture = "rbxassetid://5638168605", ColorA = Color3.fromRGB(171, 147, 226), ColorB = Color3.fromRGB(105, 164, 213) },
    { Id = "neon", Name = "Neon", Texture = "rbxassetid://6361963422", ColorA = Color3.fromRGB(118, 204, 226), ColorB = Color3.fromRGB(165, 145, 229) },
    { Id = "plasma", Name = "Plasma", Texture = "rbxassetid://8993645509", ColorA = Color3.fromRGB(134, 192, 239), ColorB = Color3.fromRGB(210, 145, 233) },
    { Id = "laser", Name = "Laser", Texture = "rbxassetid://14549123968", ColorA = Color3.fromRGB(233, 144, 159), ColorB = Color3.fromRGB(224, 190, 121) },
}

local function GetGuiScale(Object)
    local Scale = 1
    local Current = Object
    while Current do
        local Component = Current:FindFirstChildOfClass("UIScale")
        if Component then Scale *= Component.Scale end
        Current = Current.Parent
    end
    return math.max(0.01, Scale)
end

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
    local Key = string.lower(tostring(Value or "Stretch"))
    if Key == "fit" then
        return Enum.ScaleType.Fit
    elseif Key == "crop" then
        return Enum.ScaleType.Crop
    elseif Key == "tile" then
        return Enum.ScaleType.Tile
    end
    return Enum.ScaleType.Stretch
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

local function ApplyCorner(Object, Radius)
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, Radius)
    Corner.Parent = Object
    return Corner
end

function TextureGallery.Create(Library, Info)
    assert(Library and type(Library.AddToRegistry) == "function", "TextureGallery requires MonHub Library")
    Info = Info or {}
    local Style = type(Library.GetAddonStyle) == "function" and Library:GetAddonStyle(Info.Style) or {
        Padding = 10,
        Gap = 8,
        Radius = 7,
        ControlRadius = 4,
        OutlineTransparency = 0.5,
        StrokeThickness = 1,
        CaptionSize = 12,
    }

    local IsMobile = Library.IsMobile == true
    local Gap = math.clamp(math.floor(tonumber(Info.Gap) or Style.Gap), 2, 14)
    local CellHeight = math.max(64, IsMobile and 44 or 0)

    local Gallery = {
        Height = math.clamp(tonumber(Info.Height) or 292, 210, 520),
        Columns = math.clamp(math.floor(tonumber(Info.Columns) or 2), 1, 3),
        Items = {},
        Slots = {},
        Selected = nil,
        Visible = Info.Visible ~= false,
        Destroyed = false,
        Connections = {},
        EffectiveColumns = math.clamp(math.floor(tonumber(Info.Columns) or 2), 1, 3),
        ColumnWidths = nil,
        ColumnOffsets = nil,
        CellHeight = CellHeight,
        Gap = Gap,
        PreviewTransparency = math.clamp(tonumber(Info.PreviewTransparency) or 0, 0, 1),
        CardTransparency = math.clamp(tonumber(Info.CardTransparency) or 0, 0, 1),
        ImageTransparency = math.clamp(tonumber(Info.ImageTransparency) or 0.04, 0, 1),
        PreviewImageTransparency = math.clamp(tonumber(Info.PreviewImageTransparency or Info.ImageTransparency) or 0.05, 0, 1),
        ImageScale = math.clamp(tonumber(Info.ImageScale or Info.Zoom) or 1, 0.1, 4),
        OutlineTransparency = math.clamp(tonumber(Info.OutlineTransparency) or Style.OutlineTransparency, 0, 1),
        ScaleType = ResolveScaleType(Info.ScaleType),
        Style = Style,
    }

    local Root = Instance.new("Frame")
    Root.Name = "MonHubTextureGallery"
    Root.BorderSizePixel = 0
    Root.BackgroundTransparency = 1
    Root.Size = UDim2.fromScale(1, 1)
    Root.Visible = Gallery.Visible
    Gallery.Root = Root

    local Preview = Instance.new("Frame")
    Preview.BackgroundColor3 = Library.Scheme.ElementColor
    Preview.BackgroundTransparency = Gallery.PreviewTransparency
    Preview.BorderSizePixel = 0
    Preview.ClipsDescendants = true
    Preview.Size = UDim2.new(1, 0, 0, 76)
    Preview.Parent = Root
    ApplyCorner(Preview, Style.Radius)
    Library:AddToRegistry(Preview, { BackgroundColor3 = "ElementColor" })

    local PreviewStroke = Instance.new("UIStroke")
    PreviewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    PreviewStroke.Color = Library.Scheme.OutlineColor
    PreviewStroke.Thickness = Style.StrokeThickness
    PreviewStroke.Transparency = Gallery.OutlineTransparency
    PreviewStroke.Parent = Preview
    Library:AddToRegistry(PreviewStroke, { Color = "OutlineColor" })

    local PreviewTrack = Instance.new("Frame")
    PreviewTrack.AnchorPoint = Vector2.new(0.5, 0.5)
    PreviewTrack.BackgroundColor3 = Color3.new(1, 1, 1)
    PreviewTrack.BorderSizePixel = 0
    PreviewTrack.Position = UDim2.new(0.5, 0, 0.5, -4)
    PreviewTrack.Size = UDim2.new(1, -28, 0, 7)
    PreviewTrack.Parent = Preview
    ApplyCorner(PreviewTrack, 4)

    local PreviewTrackGradient = Instance.new("UIGradient")
    PreviewTrackGradient.Color = ColorSequence.new(Color3.fromRGB(168, 181, 199), Color3.fromRGB(105, 116, 133))
    PreviewTrackGradient.Parent = PreviewTrack

    local PreviewImage = Instance.new("ImageLabel")
    PreviewImage.AnchorPoint = Vector2.new(0.5, 0.5)
    PreviewImage.BackgroundTransparency = 1
    PreviewImage.Image = ""
    PreviewImage.ImageColor3 = Color3.new(1, 1, 1)
    PreviewImage.ImageTransparency = Gallery.PreviewImageTransparency
    PreviewImage.Position = UDim2.new(0.5, 0, 0.5, -4)
    PreviewImage.ScaleType = Gallery.ScaleType
    PreviewImage.Size = UDim2.new(1, -24, 0, 34)
    PreviewImage.Parent = Preview

    local PreviewScale = Instance.new("UIScale")
    PreviewScale.Scale = Gallery.ImageScale
    PreviewScale.Parent = PreviewImage

    local PreviewGradient = Instance.new("UIGradient")
    PreviewGradient.Color = ColorSequence.new(Color3.fromRGB(168, 181, 199), Color3.fromRGB(105, 116, 133))
    PreviewGradient.Parent = PreviewImage
    local function PreviewColors()
        local Item = Gallery.Selected or {}
        return ColorSequence.new(
            typeof(Item.ColorA) == "Color3" and Item.ColorA or Library.Scheme.AccentColor,
            typeof(Item.ColorB) == "Color3" and Item.ColorB or Library.Scheme.FontColor
        )
    end
    Library:AddToRegistry(PreviewGradient, { Color = PreviewColors })
    Library:AddToRegistry(PreviewTrackGradient, { Color = PreviewColors })

    local PreviewName = Instance.new("TextLabel")
    PreviewName.AnchorPoint = Vector2.new(0.5, 1)
    PreviewName.BackgroundTransparency = 1
    PreviewName.FontFace = Library.Scheme.Font
    PreviewName.Position = UDim2.new(0.5, 0, 1, -7)
    PreviewName.Size = UDim2.new(1, -20, 0, 18)
    PreviewName.Text = "Select texture"
    PreviewName.TextColor3 = Library.Scheme.MutedFontColor
    PreviewName.TextSize = Style.CaptionSize
    PreviewName.Parent = Preview
    Library:AddToRegistry(PreviewName, { FontFace = "Font", TextColor3 = "MutedFontColor" })

    local Grid = Instance.new("ScrollingFrame")
    Grid.ClipsDescendants = true
    Grid.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    Grid.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    Grid.Active = true
    Grid.AutomaticCanvasSize = Enum.AutomaticSize.None
    Grid.BackgroundTransparency = 1
    Grid.BorderSizePixel = 0
    Grid.CanvasSize = UDim2.fromOffset(0, 0)
    Grid.CanvasPosition = Vector2.zero
    Grid.Position = UDim2.fromOffset(0, 86)
    Grid.ScrollBarImageColor3 = Library.Scheme.AccentColor
    Grid.ScrollBarImageTransparency = 0.35
    Grid.ScrollBarThickness = 2
    Grid.VerticalScrollBarInset = Enum.ScrollBarInset.Always
    Grid.ScrollingDirection = Enum.ScrollingDirection.Y
    Grid.Size = UDim2.new(1, 0, 1, -86)
    Grid.Parent = Root
    Library:AddToRegistry(Grid, { ScrollBarImageColor3 = "AccentColor" })

    local ResolvedCache = {}
    local ResolvedOrder = {}
    local function ResolveAsset(Value)
        if Value == nil or Value == "" then
            return ""
        end
        local Cached = ResolvedCache[Value]
        if Cached ~= nil then
            return Cached
        end
        local Result = NormalizeAsset(Value)
        ResolvedCache[Value] = Result
        table.insert(ResolvedOrder, Value)
        if #ResolvedOrder > 128 then
            local Oldest = table.remove(ResolvedOrder, 1)
            ResolvedCache[Oldest] = nil
        end
        return Result
    end

    local VirtualView

    local function ItemColors(Item)
        return typeof(Item.ColorA) == "Color3" and Item.ColorA or Library.Scheme.AccentColor,
            typeof(Item.ColorB) == "Color3" and Item.ColorB or Library.Scheme.FontColor
    end

    local function ResolveGridMetrics()
        if Gallery.Destroyed then
            return
        end
        local Width = math.floor(Grid.AbsoluteSize.X / GetGuiScale(Grid)) - 2 - Grid.ScrollBarThickness
        if Width <= 0 then
            return
        end
        local MinSide = IsMobile and 44 or 64
        local Count = math.clamp(Gallery.Columns, 1, math.max(1, math.floor((Width + Gap) / (MinSide + Gap))))
        Gallery.EffectiveColumns = Count

        local Base = math.max(1, math.floor((Width - Gap * (Count - 1)) / Count))
        local Remainder = math.max(0, Width - Base * Count - Gap * (Count - 1))
        local Widths = {}
        local Offsets = {}
        local Cursor = 0
        for Column = 1, Count do
            local CellWidth = Base + (Column <= Remainder and 1 or 0)
            Widths[Column] = CellWidth
            Offsets[Column] = Cursor
            Cursor += CellWidth + Gap
        end
        Gallery.ColumnWidths = Widths
        Gallery.ColumnOffsets = Offsets

        if VirtualView then
            VirtualView.Columns = Count
            VirtualView.RowHeight = Gallery.CellHeight + Gap
            VirtualView:Refresh()
        end
    end
    table.insert(Gallery.Connections, Grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(ResolveGridMetrics))
    table.insert(Gallery.Connections, Grid:GetPropertyChangedSignal("ScrollBarThickness"):Connect(ResolveGridMetrics))

    local function UpdatePreview()
        local Item = Gallery.Selected
        if not Item then
            PreviewImage.Image = ""
            PreviewScale.Scale = Gallery.ImageScale
            PreviewName.Text = "Select texture"
            PreviewGradient.Color = ColorSequence.new(Library.Scheme.AccentColor, Library.Scheme.MutedFontColor)
            PreviewTrackGradient.Color = PreviewGradient.Color
            return
        end
        PreviewImage.Image = ResolveAsset(Item.Texture or Item.AssetId or Item.Image)
        PreviewScale.Scale = math.clamp(tonumber(Item.PreviewImageScale or Item.ImageScale or Item.Zoom) or Gallery.ImageScale, 0.1, 4)
        PreviewImage.ImageTransparency = math.clamp(tonumber(Item.PreviewImageTransparency or Item.ImageTransparency) or Gallery.PreviewImageTransparency, 0, 1)
        PreviewImage.ScaleType = Item.ScaleType ~= nil and ResolveScaleType(Item.ScaleType) or Gallery.ScaleType
        PreviewName.Text = tostring(Item.Name or Item.Id or "Texture")
        local ColorA, ColorB = ItemColors(Item)
        PreviewGradient.Color = ColorSequence.new(ColorA, ColorB)
        PreviewTrackGradient.Color = PreviewGradient.Color
    end

    local SlotSequence = 0
    local function CreateSlot()
        SlotSequence += 1
        local Index = SlotSequence
        local ConnectionStart = #Gallery.Connections

        local Button = Instance.new("TextButton")
        Button.AutoButtonColor = false
        Button.BackgroundColor3 = Library.Scheme.ElementColor
        Button.BackgroundTransparency = Gallery.CardTransparency
        Button.BorderSizePixel = 0
        Button.ClipsDescendants = true
        Button.Size = UDim2.fromOffset(100, Gallery.CellHeight)
        Button.Text = ""
        Button.Visible = false
        Button.Parent = Grid
        ApplyCorner(Button, Style.Radius)
        Library:AddToRegistry(Button, { BackgroundColor3 = "ElementColor" })

        local Stroke = Instance.new("UIStroke")
        Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Stroke.Color = Library.Scheme.OutlineColor
        Stroke.Thickness = Style.StrokeThickness
        Stroke.Transparency = Gallery.OutlineTransparency
        Stroke.Parent = Button

        local Track = Instance.new("Frame")
        Track.AnchorPoint = Vector2.new(0.5, 0.5)
        Track.BackgroundColor3 = Color3.new(1, 1, 1)
        Track.BorderSizePixel = 0
        Track.Position = UDim2.new(0.5, 0, 0, 23)
        Track.Size = UDim2.new(1, -18, 0, 5)
        Track.Parent = Button
        ApplyCorner(Track, 3)

        local TrackGradient = Instance.new("UIGradient")
        TrackGradient.Parent = Track

        local Image = Instance.new("ImageLabel")
        Image.BackgroundTransparency = 1
        Image.Image = ""
        Image.ImageColor3 = Color3.new(1, 1, 1)
        Image.ImageTransparency = Gallery.ImageTransparency
        Image.Position = UDim2.fromOffset(8, 8)
        Image.ScaleType = Gallery.ScaleType
        Image.Size = UDim2.new(1, -16, 0, 28)
        Image.Parent = Button

        local ImageScale = Instance.new("UIScale")
        ImageScale.Scale = Gallery.ImageScale
        ImageScale.Parent = Image

        local Gradient = Instance.new("UIGradient")
        Gradient.Parent = Image

        local Name = Instance.new("TextLabel")
        Name.AnchorPoint = Vector2.new(0, 1)
        Name.BackgroundTransparency = 1
        Name.FontFace = Library.Scheme.Font
        Name.Position = UDim2.new(0, 8, 1, -5)
        Name.Size = UDim2.new(1, -16, 0, 17)
        Name.Text = ""
        Name.TextColor3 = Library.Scheme.MutedFontColor
        Name.TextSize = Style.CaptionSize
        Name.TextTruncate = Enum.TextTruncate.AtEnd
        Name.TextXAlignment = Enum.TextXAlignment.Left
        Name.Parent = Button

        local Slot = {
            Index = Index,
            Root = Button,
            Button = Button,
            Stroke = Stroke,
            Track = Track,
            TrackGradient = TrackGradient,
            Image = Image,
            Scale = ImageScale,
            Gradient = Gradient,
            Name = Name,
            Item = nil,
        }
        Gallery.Slots[Index] = Slot

        Library:AddToRegistry(Stroke, {
            Color = function()
                return Slot.Item ~= nil and Gallery.Selected == Slot.Item and Library.Scheme.AccentColor or Library.Scheme.OutlineColor
            end,
        })
        Library:AddToRegistry(Name, {
            FontFace = "Font",
            TextColor3 = function()
                return Slot.Item ~= nil and Gallery.Selected == Slot.Item and Library.Scheme.FontColor or Library.Scheme.MutedFontColor
            end,
        })
        Library:AddToRegistry(Gradient, {
            Color = function()
                if not Slot.Item then
                    return ColorSequence.new(Library.Scheme.AccentColor, Library.Scheme.FontColor)
                end
                local ColorA, ColorB = ItemColors(Slot.Item)
                return ColorSequence.new(ColorA, ColorB)
            end,
        })
        Library:AddToRegistry(TrackGradient, {
            Color = function()
                if not Slot.Item then
                    return ColorSequence.new(Library.Scheme.AccentColor, Library.Scheme.FontColor)
                end
                local ColorA, ColorB = ItemColors(Slot.Item)
                return ColorSequence.new(ColorA, ColorB)
            end,
        })

        table.insert(Gallery.Connections, Button.MouseEnter:Connect(function()
            if Gallery.Destroyed then
                return
            end
            Library:PlayTween(Button, "TextureHover" .. Index, Library.HoverTweenInfo or Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.HoverColor,
            })
        end))
        table.insert(Gallery.Connections, Button.MouseLeave:Connect(function()
            if Gallery.Destroyed then
                return
            end
            Library:PlayTween(Button, "TextureHover" .. Index, Library.HoverTweenInfo or Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.ElementColor,
            })
        end))
        table.insert(Gallery.Connections, Button.Activated:Connect(function()
            if Gallery.Destroyed or not Slot.Item then
                return
            end
            Gallery:Select(Slot.Item)
        end))

        local SlotConnections = {}
        for Number = ConnectionStart + 1, #Gallery.Connections do
            table.insert(SlotConnections, Gallery.Connections[Number])
        end
        function Slot:Reset()
            self.Item = nil
            self.Image.Image = ""
            self.Name.Text = ""
        end
        function Slot:Destroy()
            for _, Connection in SlotConnections do
                pcall(function()
                    Connection:Disconnect()
                end)
                local Found = table.find(Gallery.Connections, Connection)
                if Found then
                    table.remove(Gallery.Connections, Found)
                end
            end
            if type(Library.CancelTween) == "function" then
                Library:CancelTween(Button, "TextureHover" .. Index)
            end
            RemoveRegistryTree(Library, Button)
            Button:Destroy()
            Gallery.Slots[Index] = nil
        end
        return Slot
    end

    local function RenderSlot(Slot, Item)
        Slot.Item = Item
        Slot.Button.Visible = Item ~= nil
        if not Item then
            Slot.Image.Image = ""
            Slot.Name.Text = ""
            return
        end
        Slot.Image.Image = ResolveAsset(Item.Texture or Item.AssetId or Item.Image)
        Slot.Image.ImageTransparency = math.clamp(tonumber(Item.ImageTransparency or Item.Transparency) or Gallery.ImageTransparency, 0, 1)
        Slot.Image.ScaleType = Item.ScaleType ~= nil and ResolveScaleType(Item.ScaleType) or Gallery.ScaleType
        Slot.Scale.Scale = math.clamp(tonumber(Item.ImageScale or Item.Zoom) or Gallery.ImageScale, 0.1, 4)
        Slot.Name.Text = tostring(Item.Name or Item.Id or "Texture")
        local ColorA, ColorB = ItemColors(Item)
        local Colors = ColorSequence.new(ColorA, ColorB)
        Slot.Gradient.Color = Colors
        Slot.TrackGradient.Color = Colors
        local Selected = Gallery.Selected == Item
        Slot.Stroke.Color = Selected and Library.Scheme.AccentColor or Library.Scheme.OutlineColor
        Slot.Stroke.Transparency = Selected and math.min(0.06, Gallery.OutlineTransparency) or Gallery.OutlineTransparency
        Slot.Name.TextColor3 = Selected and Library.Scheme.FontColor or Library.Scheme.MutedFontColor
        Slot.Button.BackgroundTransparency = Gallery.CardTransparency
    end

    local function PlaceSlot(Slot, Index)
        local Count = Gallery.EffectiveColumns
        local Column = (Index - 1) % Count
        local Widths = Gallery.ColumnWidths
        local Offsets = Gallery.ColumnOffsets
        local RowIndex = math.floor((Index - 1) / Count)
        if Widths and Offsets and Widths[Column + 1] then
            Slot.Button.Position = UDim2.fromOffset(Offsets[Column + 1], RowIndex * (Gallery.CellHeight + Gap))
            Slot.Button.Size = UDim2.fromOffset(Widths[Column + 1], Gallery.CellHeight)
        end
        RenderSlot(Slot, Gallery.Items[Index])
    end

    VirtualView = Library and type(Library.CreateVirtualList) == "function" and Library:CreateVirtualList(Grid, {
        Count = 0,
        Columns = Gallery.EffectiveColumns,
        RowHeight = Gallery.CellHeight + Gap,
        Gap = Gap,
        Scale = function()
            return GetGuiScale(Grid)
        end,
        CreateRow = function()
            return CreateSlot()
        end,
        RenderRow = function(Slot, Index)
            PlaceSlot(Slot, Index)
        end,
    }) or nil
    Gallery.VirtualView = VirtualView

    local function Refresh(ResetScroll)
        if Gallery.Destroyed then
            return
        end
        if ResetScroll then
            Grid.CanvasPosition = Vector2.zero
        end
        if VirtualView then
            VirtualView:SetCount(#Gallery.Items)
        end
    end

    function Gallery:SetItems(Items)
        if Gallery.Destroyed then
            return Gallery
        end
        Gallery.Items = type(Items) == "table" and table.clone(Items) or {}
        Gallery.Selected = nil
        UpdatePreview()
        Refresh(true)
        return Gallery
    end

    function Gallery:Select(Value, Silent)
        if Gallery.Destroyed then
            return nil
        end
        local Item = nil
        if type(Value) == "table" then
            Item = Value
        else
            for _, Candidate in Gallery.Items do
                if Candidate.Id == Value or Candidate.Name == Value or Candidate.Texture == Value then
                    Item = Candidate
                    break
                end
            end
        end
        if not Item then
            return nil
        end
        Gallery.Selected = Item
        UpdatePreview()
        if VirtualView then
            VirtualView:Refresh()
        end
        if not Silent and type(Info.OnSelected) == "function" then
            Library:SafeCallback(Info.OnSelected, Item, Gallery)
        end
        return Item
    end

    function Gallery:GetSelected()
        return Gallery.Selected
    end

    function Gallery:SetVisible(Visible)
        Gallery.Visible = Visible == true
        Root.Visible = Gallery.Visible
        if Gallery.Element and Gallery.Element.SetVisible then
            Gallery.Element:SetVisible(Gallery.Visible)
        end
        return Gallery
    end

    function Gallery:SetColumns(Columns)
        Gallery.Columns = math.clamp(math.floor(tonumber(Columns) or Gallery.Columns), 1, 3)
        ResolveGridMetrics()
        return Gallery
    end

    function Gallery:SetImageTransparency(Value)
        Gallery.ImageTransparency = math.clamp(tonumber(Value) or Gallery.ImageTransparency, 0, 1)
        if VirtualView then
            VirtualView:Refresh()
        end
        return Gallery
    end

    function Gallery:SetPreviewImageTransparency(Value)
        Gallery.PreviewImageTransparency = math.clamp(tonumber(Value) or Gallery.PreviewImageTransparency, 0, 1)
        UpdatePreview()
        return Gallery
    end

    function Gallery:SetCardTransparency(Value)
        Gallery.CardTransparency = math.clamp(tonumber(Value) or Gallery.CardTransparency, 0, 1)
        for _, Slot in Gallery.Slots do
            Slot.Button.BackgroundTransparency = Gallery.CardTransparency
        end
        return Gallery
    end

    function Gallery:SetPreviewTransparency(Value)
        Gallery.PreviewTransparency = math.clamp(tonumber(Value) or Gallery.PreviewTransparency, 0, 1)
        Preview.BackgroundTransparency = Gallery.PreviewTransparency
        return Gallery
    end

    function Gallery:SetOutlineTransparency(Value)
        Gallery.OutlineTransparency = math.clamp(tonumber(Value) or Gallery.OutlineTransparency, 0, 1)
        PreviewStroke.Transparency = Gallery.OutlineTransparency
        if VirtualView then
            VirtualView:Refresh()
        end
        return Gallery
    end

    function Gallery:SetScaleType(Value)
        Gallery.ScaleType = ResolveScaleType(Value)
        UpdatePreview()
        if VirtualView then
            VirtualView:Refresh()
        end
        return Gallery
    end

    function Gallery:SetImageScale(Value)
        Gallery.ImageScale = math.clamp(tonumber(Value) or Gallery.ImageScale, 0.1, 4)
        PreviewScale.Scale = Gallery.ImageScale
        if VirtualView then
            VirtualView:Refresh()
        end
        return Gallery
    end

    function Gallery:Mount(Parent, Height)
        if Gallery.Destroyed or typeof(Parent) ~= "Instance" or not Parent:IsA("GuiBase2d") then
            return false
        end
        Root.Parent = Parent
        if Height ~= nil then Gallery:SetHeight(Height) end
        return true
    end

    function Gallery:SetHeight(Value)
        if Gallery.Destroyed then
            return Gallery
        end
        Gallery.Height = math.clamp(math.floor(tonumber(Value) or Gallery.Height), 210, 900)
        Root.Size = UDim2.new(1, 0, 0, Gallery.Height)
        if Gallery.Element then
            Gallery.Element:SetHeight(Gallery.Height)
        end
        return Gallery
    end

    function Gallery:Destroy()
        if Gallery.Destroyed then
            return
        end
        Gallery.Destroyed = true
        if VirtualView then
            VirtualView:Destroy()
            VirtualView = nil
            Gallery.VirtualView = nil
        end
        if Gallery.StyleController then
            Gallery.StyleController:Destroy()
            Gallery.StyleController = nil
        end
        for _, Connection in Gallery.Connections do
            pcall(function()
                Connection:Disconnect()
            end)
        end
        table.clear(Gallery.Connections)
        table.clear(Gallery.Slots)
        table.clear(Gallery.Items)
        table.clear(ResolvedCache)
        table.clear(ResolvedOrder)
        RemoveRegistryTree(Library, Root)
        if Gallery.Element and Gallery.Element.Destroy then
            Gallery.Element:Destroy()
            Gallery.Element = nil
        elseif Root then
            Root:Destroy()
        end
    end

    if typeof(Info.Parent) == "Instance" and Info.Parent:IsA("GuiBase2d") then
        Gallery:Mount(Info.Parent, Gallery.Height)
    end
    ResolveGridMetrics()
    Gallery:SetItems(Info.Items or TextureGallery.DefaultItems)
    if Info.Selected ~= nil then
        Gallery:Select(Info.Selected, true)
    elseif Gallery.Items[1] then
        Gallery:Select(Gallery.Items[1], true)
    end

    if type(Library.OnUnload) == "function" then
        Library:OnUnload(function()
            Gallery:Destroy()
        end)
    end

    if Library and type(Library.BindAddonStyle) == "function" then
        Gallery.StyleController = Library:BindAddonStyle(Root, Style, Info, true)
        function Gallery:SetStyle(Overrides)
            Gallery.StyleController:Set(Overrides)
            return Gallery
        end
        function Gallery:SetMinimal(Enabled)
            Gallery.StyleController:SetMinimal(Enabled)
            return Gallery
        end
        function Gallery:SetHighlighted(Enabled)
            Gallery.StyleController:SetHighlighted(Enabled)
            return Gallery
        end
    end
    return Gallery
end

function TextureGallery.CreateEmbedded(Library, Groupbox, Idx, Info)
    assert(type(Groupbox) == "table" and type(Groupbox.AddUIPassthrough) == "function", "TextureGallery requires a groupbox")
    Info = Info or {}
    local Gallery = TextureGallery.Create(Library, Info)
    Gallery.Element = Groupbox:AddUIPassthrough(Idx or "TextureGallery", {
        Instance = Gallery.Root,
        Height = Gallery.Height,
        Visible = Gallery.Visible,
    })
    return Gallery
end

function TextureGallery.CreateStandalone(Library, Info)
    assert(Library and type(Library.CreateAddonWindow) == "function", "TextureGallery standalone mode requires Library:CreateAddonWindow")
    Info = table.clone(Info or {})
    local WindowHeight = tonumber(Info.WindowHeight) or 500
    local Host = Library:CreateAddonWindow({
        Title = Info.WindowTitle or "Textures",
        Subtitle = Info.WindowSubtitle,
        Icon = Info.WindowIcon or "images",
        Width = Info.WindowWidth or 460,
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
    Info.Height = Info.Height or math.max(180, WindowHeight - 72)
    local Gallery = Host:AddAddon("Textures", TextureGallery, Info)
    Gallery.Host = Host
    return Gallery, Host
end

TextureGallery.Mount = TextureGallery.CreateEmbedded

return TextureGallery
