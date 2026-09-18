local TweenService = game:GetService("TweenService")

local ImageGallery = {}

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
    local Key = string.lower(tostring(Value or "Fit"))
    if Key == "crop" then
        return Enum.ScaleType.Crop
    elseif Key == "stretch" then
        return Enum.ScaleType.Stretch
    end
    return Enum.ScaleType.Fit
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

local function NormalizeItem(Item, Index)
    if typeof(Item) == "number" or typeof(Item) == "string" then
        local Name = tostring(Item)
        return {
            Id = Index,
            Name = Name,
            Image = Item,
            Thumbnail = Item,
            PreviewImage = Item,
            Color = Color3.new(1, 1, 1),
            Category = "All",
            Subtitle = "",
            SearchText = string.lower(Name),
            Source = Item,
        }
    end
    if type(Item) ~= "table" then
        return nil
    end
    local Name = tostring(Item.Name or Item.Title or Item.Id or Index)
    local Category = tostring(Item.Category or Item.Group or "All")
    local Tags = type(Item.Tags) == "table" and table.concat(Item.Tags, " ") or tostring(Item.Tags or "")
    local Image = Item.Image or Item.AssetId or Item.Icon or ""
    return {
        Id = Item.Id ~= nil and Item.Id or Index,
        Name = Name,
        Image = Image,
        Thumbnail = Item.Thumbnail or Item.ThumbnailId or Image,
        PreviewImage = Item.PreviewImage or Item.FullImage or Image,
        Color = typeof(Item.Color) == "Color3" and Item.Color or Color3.new(1, 1, 1),
        ImageTransparency = tonumber(Item.ImageTransparency or Item.Transparency),
        ImageBackgroundTransparency = tonumber(Item.ImageBackgroundTransparency or Item.BackgroundTransparency),
        ScaleType = Item.ScaleType,
        ImageSize = typeof(Item.ImageSize) == "UDim2" and Item.ImageSize or nil,
        ImagePosition = typeof(Item.ImagePosition) == "UDim2" and Item.ImagePosition or nil,
        ImageAnchorPoint = typeof(Item.ImageAnchorPoint) == "Vector2" and Item.ImageAnchorPoint or nil,
        ImageScale = tonumber(Item.ImageScale or Item.Zoom),
        TileSize = typeof(Item.TileSize) == "UDim2" and Item.TileSize or nil,
        Rotation = tonumber(Item.Rotation),
        RectOffset = typeof(Item.RectOffset) == "Vector2" and Item.RectOffset or Vector2.zero,
        RectSize = typeof(Item.RectSize) == "Vector2" and Item.RectSize or Vector2.zero,
        Category = Category,
        Subtitle = tostring(Item.Subtitle or Item.Description or ""),
        Disabled = Item.Disabled == true,
        SearchText = string.lower(string.format("%s %s %s", Name, Category, Tags)),
        Source = Item,
    }
end

function ImageGallery.Create(Library, Info)
    Info = Info or {}
    local Style = Library and type(Library.GetAddonStyle) == "function" and Library:GetAddonStyle(Info.Style) or {
        HeaderHeight = 38,
        Padding = 10,
        Gap = 8,
        Radius = 7,
        ControlRadius = 4,
        ControlHeight = 28,
        OutlineTransparency = 0.5,
        StrokeThickness = 1,
        TextSize = 14,
        CaptionSize = 12,
        Motion = true,
    }
    local IsMobile = Library and Library.IsMobile == true
    local HeaderHeight = math.clamp(math.floor(tonumber(Style.HeaderHeight) or 38), 32, 46)
    local ControlHeight = math.clamp(math.floor(tonumber(Style.ControlHeight) or 28), 22, 32)
    if IsMobile then
        ControlHeight = math.max(ControlHeight, 30)
    end
    local Height = math.clamp(math.floor(tonumber(Info.Height) or 344), 180, 780)
    local Columns = math.clamp(math.floor(tonumber(Info.Columns) or 5), 1, 10)
    local MinCellSide = IsMobile and 44 or 48
    local CellHeight = math.max(math.clamp(math.floor(tonumber(Info.CellHeight) or 78), 52, 150), MinCellSide)
    local Gap = math.clamp(math.floor(tonumber(Info.Gap) or Style.Gap), 2, 14)
    local ScaleType = ResolveScaleType(Info.ScaleType)
    local BackgroundTransparency = math.clamp(tonumber(Info.BackgroundTransparency) or Style.BackgroundTransparency or 0, 0, 1)
    local ContainerOutlineTransparency = math.clamp(tonumber(Info.ContainerOutlineTransparency) or Style.OutlineTransparency, 0, 1)
    local CellTransparency = math.clamp(tonumber(Info.CellTransparency) or 0, 0, 1)
    local CellOutlineTransparency = math.clamp(tonumber(Info.OutlineTransparency or Info.CellOutlineTransparency) or Style.OutlineTransparency, 0, 1)
    local ImageTransparency = math.clamp(tonumber(Info.ImageTransparency) or 0, 0, 1)
    local ImageBackgroundTransparency = math.clamp(tonumber(Info.ImageBackgroundTransparency) or 0.08, 0, 1)
    local LabelHeight = math.clamp(math.floor(tonumber(Info.LabelHeight) or 22), 0, 40)
    local ImagePadding = math.clamp(math.floor(tonumber(Info.ImagePadding) or math.max(4, Style.Padding - 3)), 0, math.max(0, CellHeight - LabelHeight - 1))
    local CornerRadius = math.clamp(math.floor(tonumber(Info.CornerRadius) or Style.Radius), 0, 12)
    local ImageSize = typeof(Info.ImageSize) == "UDim2" and Info.ImageSize or UDim2.fromScale(1, 1)
    local ImagePosition = typeof(Info.ImagePosition) == "UDim2" and Info.ImagePosition or UDim2.fromScale(0.5, 0.5)
    local ImageAnchorPoint = typeof(Info.ImageAnchorPoint) == "Vector2" and Info.ImageAnchorPoint or Vector2.new(0.5, 0.5)
    local ImageScale = math.clamp(tonumber(Info.ImageScale or Info.Zoom) or 1, 0.1, 4)
    local TileSize = typeof(Info.TileSize) == "UDim2" and Info.TileSize or UDim2.fromOffset(64, 64)
    local Rotation = tonumber(Info.Rotation) or 0

    local Root = Instance.new("Frame")
    Root.Name = "MonHubImageGallery"
    Root.BackgroundColor3 = Library and (Library.Scheme.SurfaceColor or Library.Scheme.BackgroundColor) or Color3.fromRGB(18, 20, 24)
    Root.BackgroundTransparency = BackgroundTransparency
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
    RootCorner.CornerRadius = UDim.new(0, CornerRadius)
    RootCorner.Parent = Root

    local Stroke = Instance.new("UIStroke")
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Color = Library and Library.Scheme.OutlineColor or Color3.fromRGB(52, 57, 66)
    Stroke.Thickness = Style.StrokeThickness
    Stroke.Transparency = ContainerOutlineTransparency
    Stroke.Parent = Root
    AddRegistry(Library, Stroke, { Color = "OutlineColor" })

    local Header = Instance.new("Frame")
    Header.BackgroundColor3 = Library and (Library.Scheme.RaisedColor or Library.Scheme.SurfaceColor) or Color3.fromRGB(22, 24, 29)
    Header.BorderSizePixel = 0
    Header.Size = UDim2.new(1, 0, 0, HeaderHeight)
    Header.Parent = Root
    AddRegistry(Library, Header, {
        BackgroundColor3 = function()
            return Library.Scheme.RaisedColor or Library.Scheme.SurfaceColor
        end,
    })

    local HeaderLine = Instance.new("Frame")
    HeaderLine.AnchorPoint = Vector2.new(0, 1)
    HeaderLine.BackgroundColor3 = Library and Library.Scheme.OutlineColor or Color3.fromRGB(52, 57, 66)
    HeaderLine.BorderSizePixel = 0
    HeaderLine.Position = UDim2.fromScale(0, 1)
    HeaderLine.Size = UDim2.new(1, 0, 0, 1)
    HeaderLine.BackgroundTransparency = Library and type(Library.GetDesignToken) == "function" and Library:GetDesignToken("Opacity.Divider", 0.56) or 0.56
    HeaderLine.Parent = Header
    AddRegistry(Library, HeaderLine, { BackgroundColor3 = "OutlineColor" })

    local CategoryButton = Instance.new("TextButton")
    CategoryButton.AutoButtonColor = false
    CategoryButton.BackgroundColor3 = Library and Library.Scheme.ElementColor or Color3.fromRGB(29, 32, 38)
    CategoryButton.BorderSizePixel = 0
    CategoryButton.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
    CategoryButton.Position = UDim2.fromOffset(Style.Padding, math.floor((HeaderHeight - ControlHeight) * 0.5))
    CategoryButton.Size = UDim2.fromOffset(104, ControlHeight)
    CategoryButton.Text = "All"
    CategoryButton.TextColor3 = Library and Library.Scheme.FontColor or Color3.fromRGB(232, 235, 240)
    CategoryButton.TextSize = Style.CaptionSize
    CategoryButton.TextTruncate = Enum.TextTruncate.AtEnd
    CategoryButton.Parent = Header
    AddRegistry(Library, CategoryButton, {
        BackgroundColor3 = "ElementColor",
        FontFace = "Font",
        TextColor3 = "FontColor",
    })

    local CategoryCorner = Instance.new("UICorner")
    CategoryCorner.CornerRadius = UDim.new(0, Style.ControlRadius)
    CategoryCorner.Parent = CategoryButton

    local Search = Instance.new("TextBox")
    Search.BackgroundColor3 = Library and Library.Scheme.ElementColor or Color3.fromRGB(29, 32, 38)
    Search.BorderSizePixel = 0
    Search.ClearTextOnFocus = false
    Search.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
    Search.PlaceholderColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(143, 149, 158)
    Search.PlaceholderText = tostring(Info.SearchPlaceholder or "Search assets")
    Search.Position = UDim2.fromOffset(Style.Padding + 110, math.floor((HeaderHeight - ControlHeight) * 0.5))
    Search.Size = UDim2.new(1, -(Style.Padding * 2 + 110), 0, ControlHeight)
    Search.Text = ""
    Search.TextColor3 = Library and Library.Scheme.FontColor or Color3.fromRGB(232, 235, 240)
    Search.TextSize = Style.CaptionSize
    Search.TextXAlignment = Enum.TextXAlignment.Left
    Search.Parent = Header
    AddRegistry(Library, Search, {
        BackgroundColor3 = "ElementColor",
        FontFace = "Font",
        PlaceholderColor3 = "MutedFontColor",
        TextColor3 = "FontColor",
    })

    local SearchCorner = Instance.new("UICorner")
    SearchCorner.CornerRadius = UDim.new(0, Style.ControlRadius)
    SearchCorner.Parent = Search

    local SearchPadding = Instance.new("UIPadding")
    SearchPadding.PaddingLeft = UDim.new(0, 8)
    SearchPadding.PaddingRight = UDim.new(0, 8)
    SearchPadding.Parent = Search

    local GridHolder = Instance.new("ScrollingFrame")
    GridHolder.BackgroundTransparency = 1
    GridHolder.BorderSizePixel = 0
    GridHolder.AutomaticCanvasSize = Enum.AutomaticSize.None
    GridHolder.CanvasSize = UDim2.fromOffset(0, 0)
    GridHolder.CanvasPosition = Vector2.zero
    GridHolder.ScrollBarThickness = 2
    GridHolder.VerticalScrollBarInset = Enum.ScrollBarInset.Always
    GridHolder.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    GridHolder.ScrollBarImageTransparency = 0.45
    GridHolder.ScrollBarImageColor3 = Library and Library.Scheme.AccentColor or Color3.fromRGB(133, 141, 160)
    GridHolder.ScrollingDirection = Enum.ScrollingDirection.Y
    GridHolder.ClipsDescendants = true
    GridHolder.Position = UDim2.fromOffset(Style.Padding, HeaderHeight + Style.Gap)
    GridHolder.Size = UDim2.new(1, -Style.Padding * 2, 1, -(HeaderHeight + Style.Gap * 2))
    GridHolder.Parent = Root
    AddRegistry(Library, GridHolder, { ScrollBarImageColor3 = "AccentColor" })

    local Empty = Instance.new("TextLabel")
    Empty.BackgroundTransparency = 1
    Empty.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
    Empty.Position = UDim2.fromOffset(Style.Padding + 4, HeaderHeight + Style.Gap)
    Empty.Size = UDim2.new(1, -(Style.Padding + 4) * 2, 1, -(HeaderHeight + Style.Gap * 2))
    Empty.Text = tostring(Info.EmptyText or "No matching assets")
    Empty.TextColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(143, 149, 158)
    Empty.TextSize = Style.CaptionSize
    Empty.Visible = false
    Empty.Parent = Root
    AddRegistry(Library, Empty, {
        FontFace = "Font",
        TextColor3 = "MutedFontColor",
    })

    local Gallery = {
        Root = Root,
        SearchBox = Search,
        CategoryButton = CategoryButton,
        Slots = {},
        Items = {},
        Filtered = {},
        Categories = { "All" },
        Connections = {},
        Element = nil,
        Preview = Info.Preview,
        PreviewDefaults = nil,
        ForwardItemStyle = Info.ForwardItemStyle == true,
        SelectedId = nil,
        Search = "",
        Category = "All",
        Page = 1,
        PageCount = 1,
        Columns = Columns,
        EffectiveColumns = Columns,
        ColumnWidths = nil,
        ColumnOffsets = nil,
        Height = Height,
        CellHeight = CellHeight,
        Gap = Gap,
        ScaleType = ScaleType,
        BackgroundTransparency = BackgroundTransparency,
        ContainerOutlineTransparency = ContainerOutlineTransparency,
        CellTransparency = CellTransparency,
        CellOutlineTransparency = CellOutlineTransparency,
        ImageTransparency = ImageTransparency,
        ImageBackgroundTransparency = ImageBackgroundTransparency,
        ImagePadding = ImagePadding,
        LabelHeight = LabelHeight,
        CornerRadius = CornerRadius,
        ImageSize = ImageSize,
        ImagePosition = ImagePosition,
        ImageAnchorPoint = ImageAnchorPoint,
        ImageScale = ImageScale,
        TileSize = TileSize,
        Rotation = Rotation,
        Style = Style,
        Visible = Info.Visible ~= false,
        Destroyed = false,
        OnSelected = Info.OnSelected or Info.Callback,
    }

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
    local AutoColumns = Info.Columns == nil
    local MinCellWidth = math.max(math.clamp(math.floor(tonumber(Info.MinCellWidth) or 112), 48, 400), MinCellSide)

    local function ResolveGridMetrics()
        if Gallery.Destroyed then
            return
        end
        local Width = math.floor(GridHolder.AbsoluteSize.X / GetGuiScale(GridHolder)) - GridHolder.ScrollBarThickness - 2
        if Width <= 0 then
            return
        end
        local Maximum = math.max(1, math.floor((Width + Gap) / (MinCellSide + Gap)))
        local Count = AutoColumns and math.floor((Width + Gap) / (MinCellWidth + Gap)) or Gallery.Columns
        Count = math.clamp(Count, 1, math.min(8, Maximum))
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
    table.insert(Gallery.Connections, GridHolder:GetPropertyChangedSignal("AbsoluteSize"):Connect(ResolveGridMetrics))
    table.insert(Gallery.Connections, GridHolder:GetPropertyChangedSignal("ScrollBarThickness"):Connect(ResolveGridMetrics))

    local LocalTweens = {}
    local function Play(Object, Key, Properties)
        if LocalTweens[Key] then
            LocalTweens[Key]:Cancel()
            LocalTweens[Key] = nil
        end
        if Style.Motion == false then
            for Property, Value in Properties do
                Object[Property] = Value
            end
            return
        end
        local MotionInfo = Library and type(Library.GetMotion) == "function" and Library:GetMotion("Hover") or TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        if Library and type(Library.PlayTween) == "function" then
            Library:PlayTween(Object, "ImageGallery" .. tostring(Key), MotionInfo, Properties)
            return
        end
        local Success, Tween = pcall(function()
            return TweenService:Create(Object, MotionInfo, Properties)
        end)
        if Success and Tween then
            LocalTweens[Key] = Tween
            Tween.Completed:Once(function()
                if LocalTweens[Key] == Tween then
                    LocalTweens[Key] = nil
                end
                pcall(function()
                    Tween:Destroy()
                end)
            end)
            Tween:Play()
        end
    end

    local function CellColor(Slot)
        if Library then
            if Slot.Selected then
                return Library.Scheme.AccentSoftColor or Library.Scheme.AccentColor:Lerp(Library.Scheme.ElementColor, 0.78)
            elseif Slot.Hovered then
                return Library.Scheme.HoverColor or Library.Scheme.ElementColor
            end
            return Library.Scheme.ElementColor
        end
        return Slot.Selected and Color3.fromRGB(43, 54, 70) or Slot.Hovered and Color3.fromRGB(34, 38, 45) or Color3.fromRGB(27, 30, 35)
    end

    local function UpdateSlotState(Slot, Animated)
        Slot.Selected = Slot.Item ~= nil and Gallery.SelectedId ~= nil and Slot.Item.Id == Gallery.SelectedId
        local Color = CellColor(Slot)
        if Animated then
            Play(Slot.Button, Slot.Index, { BackgroundColor3 = Color })
        else
            if Library and type(Library.CancelTween) == "function" then
                Library:CancelTween(Slot.Button, "ImageGallery" .. Slot.Index)
            end
            if LocalTweens[Slot.Index] then
                LocalTweens[Slot.Index]:Cancel()
                LocalTweens[Slot.Index] = nil
            end
            Slot.Button.BackgroundColor3 = Color
        end
        Slot.Stroke.Color = Slot.Selected and (Library and Library.Scheme.AccentColor or Color3.fromRGB(123, 149, 183)) or (Library and Library.Scheme.OutlineColor or Color3.fromRGB(52, 57, 66))
        Slot.Stroke.Transparency = Slot.Selected and math.min(0.08, Gallery.CellOutlineTransparency) or Gallery.CellOutlineTransparency
    end

    local function BindPreview(Item)
        local Preview = Gallery.Preview
        if type(Preview) ~= "table" then
            return
        end
        if Gallery.ForwardItemStyle and not Gallery.PreviewDefaults then
            Gallery.PreviewDefaults = {
                ImageTransparency = tonumber(Preview.ImageTransparency) or 0,
                CanvasTransparency = tonumber(Preview.CanvasTransparency) or 0,
                ScaleType = Preview.ScaleType or Enum.ScaleType.Fit,
                ImageSize = Preview.ImageSize or UDim2.fromScale(1, 1),
                ImagePosition = Preview.ImagePosition or UDim2.fromScale(0.5, 0.5),
                ImageAnchorPoint = Preview.ImageAnchorPoint or Vector2.new(0.5, 0.5),
                ImageScale = tonumber(Preview.ImageScale) or 1,
                TileSize = Preview.TileSize or UDim2.fromOffset(64, 64),
                Rotation = tonumber(Preview.Rotation) or 0,
            }
        end
        local Defaults = Gallery.PreviewDefaults
        if not Item then
            if type(Preview.SetImage) == "function" then
                Preview:SetImage("")
            end
            if type(Preview.SetTitle) == "function" then
                Preview:SetTitle("Select an item")
            end
            if type(Preview.SetSubtitle) == "function" then
                Preview:SetSubtitle("")
            end
            if type(Preview.SetImageColor) == "function" then
                Preview:SetImageColor(Color3.new(1, 1, 1))
            end
            if Defaults then
                if type(Preview.SetImageTransparency) == "function" then
                    Preview:SetImageTransparency(Defaults.ImageTransparency)
                end
                if type(Preview.SetCanvasTransparency) == "function" then
                    Preview:SetCanvasTransparency(Defaults.CanvasTransparency)
                end
                if type(Preview.SetScaleType) == "function" then
                    Preview:SetScaleType(Defaults.ScaleType)
                end
                if type(Preview.SetImageSize) == "function" then
                    Preview:SetImageSize(Defaults.ImageSize)
                end
                if type(Preview.SetImagePosition) == "function" then
                    Preview:SetImagePosition(Defaults.ImagePosition, Defaults.ImageAnchorPoint)
                end
                if type(Preview.SetImageScale) == "function" then
                    Preview:SetImageScale(Defaults.ImageScale)
                end
                if type(Preview.SetTileSize) == "function" then
                    Preview:SetTileSize(Defaults.TileSize)
                end
                if type(Preview.SetRotation) == "function" then
                    Preview:SetRotation(Defaults.Rotation)
                end
            end
            return
        end
        if type(Preview.SetImage) == "function" then
            Preview:SetImage(Item.PreviewImage)
        end
        if type(Preview.SetImageColor) == "function" then
            Preview:SetImageColor(Item.Color)
        end
        if Defaults then
            if type(Preview.SetImageTransparency) == "function" then
                Preview:SetImageTransparency(math.clamp(tonumber(Item.ImageTransparency) or Defaults.ImageTransparency, 0, 1))
            end
            if type(Preview.SetCanvasTransparency) == "function" then
                Preview:SetCanvasTransparency(math.clamp(tonumber(Item.ImageBackgroundTransparency) or Defaults.CanvasTransparency, 0, 1))
            end
            if type(Preview.SetScaleType) == "function" then
                Preview:SetScaleType(Item.ScaleType or Defaults.ScaleType)
            end
            if type(Preview.SetImageSize) == "function" then
                Preview:SetImageSize(Item.ImageSize or Defaults.ImageSize)
            end
            if type(Preview.SetImagePosition) == "function" then
                Preview:SetImagePosition(Item.ImagePosition or Defaults.ImagePosition, Item.ImageAnchorPoint or Defaults.ImageAnchorPoint)
            end
            if type(Preview.SetImageScale) == "function" then
                Preview:SetImageScale(Item.ImageScale or Defaults.ImageScale)
            end
            if type(Preview.SetTileSize) == "function" then
                Preview:SetTileSize(Item.TileSize or Defaults.TileSize)
            end
            if type(Preview.SetRotation) == "function" then
                Preview:SetRotation(Item.Rotation or Defaults.Rotation)
            end
        end
        if type(Preview.SetTitle) == "function" then
            Preview:SetTitle(Item.Name)
        end
        if type(Preview.SetSubtitle) == "function" then
            Preview:SetSubtitle(Item.Subtitle ~= "" and Item.Subtitle or Item.Category)
        end
    end

    local function EmitSelection(Item)
        BindPreview(Item)
        if type(Gallery.OnSelected) == "function" then
            pcall(Gallery.OnSelected, Item and Item.Source or nil, Item)
        end
    end

    local SlotSequence = 0
    local function CreateSlot()
        SlotSequence += 1
        local Index = SlotSequence
        local ConnectionStart = #Gallery.Connections

        local Button = Instance.new("TextButton")
        Button.AutoButtonColor = false
        Button.BackgroundColor3 = Library and Library.Scheme.ElementColor or Color3.fromRGB(27, 30, 35)
        Button.BackgroundTransparency = Gallery.CellTransparency
        Button.BorderSizePixel = 0
        Button.ClipsDescendants = true
        Button.Text = ""
        Button.Visible = false
        Button.Parent = GridHolder

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, Gallery.CornerRadius)
        Corner.Parent = Button

        local CellStroke = Instance.new("UIStroke")
        CellStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        CellStroke.Color = Library and Library.Scheme.OutlineColor or Color3.fromRGB(52, 57, 66)
        CellStroke.Thickness = Style.StrokeThickness
        CellStroke.Transparency = Gallery.CellOutlineTransparency
        CellStroke.Parent = Button

        local ImageViewport = Instance.new("Frame")
        ImageViewport.BackgroundColor3 = Library and Library.Scheme.BackgroundColor or Color3.fromRGB(11, 13, 16)
        ImageViewport.BackgroundTransparency = Gallery.ImageBackgroundTransparency
        ImageViewport.BorderSizePixel = 0
        ImageViewport.ClipsDescendants = true
        ImageViewport.Position = UDim2.fromOffset(Gallery.ImagePadding, Gallery.ImagePadding)
        ImageViewport.Size = UDim2.new(1, -Gallery.ImagePadding * 2, 1, -(Gallery.LabelHeight + Gallery.ImagePadding))
        ImageViewport.Parent = Button
        AddRegistry(Library, ImageViewport, { BackgroundColor3 = "BackgroundColor" })

        local ImageCorner = Instance.new("UICorner")
        ImageCorner.CornerRadius = UDim.new(0, math.max(0, Gallery.CornerRadius - 1))
        ImageCorner.Parent = ImageViewport

        local Image = Instance.new("ImageLabel")
        Image.AnchorPoint = Gallery.ImageAnchorPoint
        Image.BackgroundTransparency = 1
        Image.BorderSizePixel = 0
        Image.Image = ""
        Image.ImageTransparency = Gallery.ImageTransparency
        Image.Position = Gallery.ImagePosition
        Image.Rotation = Gallery.Rotation
        Image.ScaleType = Gallery.ScaleType
        Image.Size = Gallery.ImageSize
        Image.TileSize = Gallery.TileSize
        Image.Parent = ImageViewport

        local Scale = Instance.new("UIScale")
        Scale.Scale = Gallery.ImageScale
        Scale.Parent = Image

        local Name = Instance.new("TextLabel")
        Name.AnchorPoint = Vector2.new(0, 1)
        Name.BackgroundTransparency = 1
        Name.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
        Name.Position = UDim2.fromScale(0, 1)
        Name.Size = UDim2.new(1, 0, 0, Gallery.LabelHeight)
        Name.Text = ""
        Name.TextColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(143, 149, 158)
        Name.TextSize = 10
        Name.TextTruncate = Enum.TextTruncate.AtEnd
        Name.Visible = Gallery.LabelHeight > 0
        Name.Parent = Button
        AddRegistry(Library, Name, {
            FontFace = "Font",
            TextColor3 = "MutedFontColor",
        })

        local Slot = {
            Index = Index,
            Root = Button,
            Button = Button,
            Corner = Corner,
            Viewport = ImageViewport,
            ImageCorner = ImageCorner,
            Image = Image,
            Scale = Scale,
            Name = Name,
            Stroke = CellStroke,
            Item = nil,
            Hovered = false,
            Selected = false,
        }
        Gallery.Slots[Index] = Slot
        AddRegistry(Library, Button, {
            BackgroundColor3 = function()
                return CellColor(Slot)
            end,
        })
        AddRegistry(Library, CellStroke, {
            Color = function()
                return Slot.Selected and Library.Scheme.AccentColor or Library.Scheme.OutlineColor
            end,
        })

        table.insert(Gallery.Connections, Button.MouseEnter:Connect(function()
            if Gallery.Destroyed or not Slot.Item then
                return
            end
            Slot.Hovered = true
            UpdateSlotState(Slot, true)
        end))
        table.insert(Gallery.Connections, Button.MouseLeave:Connect(function()
            if Gallery.Destroyed then
                return
            end
            Slot.Hovered = false
            UpdateSlotState(Slot, true)
        end))
        local DragBinding
        if Info.DraggableItems and Library and type(Library.BindItemDragSource) == "function" then
            DragBinding = Library:BindItemDragSource(Button, function()
                if Gallery.Destroyed or not Slot.Item or Slot.Item.Disabled then return nil end
                return Slot.Item
            end, Info.DragType or "Item")
            table.insert(Gallery.Connections, DragBinding)
        end
        table.insert(Gallery.Connections, Button.Activated:Connect(function()
            if DragBinding and DragBinding.SuppressClick then DragBinding.SuppressClick = false; return end
            if Gallery.Destroyed or not Slot.Item or Slot.Item.Disabled then
                return
            end
            Gallery.SelectedId = Slot.Item.Id
            if VirtualView then
                VirtualView:Refresh()
            end
            EmitSelection(Slot.Item)
        end))

        local SlotConnections = {}
        for Number = ConnectionStart + 1, #Gallery.Connections do
            table.insert(SlotConnections, Gallery.Connections[Number])
        end
        function Slot:Reset()
            self.Item = nil
            self.Hovered = false
            self.Selected = false
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
            if Library and type(Library.CancelTween) == "function" then
                Library:CancelTween(Button, "ImageGallery" .. Index)
            end
            RemoveRegistryTree(Library, Button)
            Button:Destroy()
            Gallery.Slots[Index] = nil
        end
        return Slot
    end

    local function RenderSlot(Slot, Item)
        Slot.Item = Item
        Slot.Hovered = false
        Slot.Button.Visible = Item ~= nil
        if Item then
            Slot.Button.Active = not Item.Disabled
            Slot.Image.Image = ResolveAsset(Item.Thumbnail)
            Slot.Image.ImageColor3 = Item.Color or Color3.new(1, 1, 1)
            local ItemTransparency = math.clamp(tonumber(Item.ImageTransparency) or Gallery.ImageTransparency, 0, 1)
            if Item.Disabled then
                ItemTransparency = math.max(ItemTransparency, 0.58)
            end
            Slot.Image.ImageTransparency = ItemTransparency
            Slot.Viewport.BackgroundTransparency = math.clamp(tonumber(Item.ImageBackgroundTransparency) or Gallery.ImageBackgroundTransparency, 0, 1)
            Slot.Image.ScaleType = Item.ScaleType ~= nil and ResolveScaleType(Item.ScaleType) or Gallery.ScaleType
            Slot.Image.Size = Item.ImageSize or Gallery.ImageSize
            Slot.Image.Position = Item.ImagePosition or Gallery.ImagePosition
            Slot.Image.AnchorPoint = Item.ImageAnchorPoint or Gallery.ImageAnchorPoint
            Slot.Scale.Scale = math.clamp(tonumber(Item.ImageScale) or Gallery.ImageScale, 0.1, 4)
            Slot.Image.TileSize = Item.TileSize or Gallery.TileSize
            Slot.Image.Rotation = Item.Rotation or Gallery.Rotation
            Slot.Image.ImageRectOffset = Item.RectOffset or Vector2.zero
            Slot.Image.ImageRectSize = Item.RectSize or Vector2.zero
            Slot.Name.Text = Item.Name
        else
            Slot.Image.Image = ""
            Slot.Name.Text = ""
        end
        UpdateSlotState(Slot, false)
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
        RenderSlot(Slot, Gallery.Filtered[Index])
    end

    VirtualView = Library and type(Library.CreateVirtualList) == "function" and Library:CreateVirtualList(GridHolder, {
        Count = 0,
        Columns = Gallery.EffectiveColumns,
        RowHeight = Gallery.CellHeight + Gap,
        Gap = Gap,
        Scale = function()
            return GetGuiScale(GridHolder)
        end,
        CreateRow = function()
            return CreateSlot()
        end,
        RenderRow = function(Slot, Index)
            PlaceSlot(Slot, Index)
        end,
    }) or nil
    Gallery.VirtualView = VirtualView

    local function RebuildCategories()
        local Seen = { All = true }
        local Categories = { "All" }
        for _, Item in Gallery.Items do
            if Item.Category ~= "" and Item.Category ~= "All" and not Seen[Item.Category] then
                Seen[Item.Category] = true
                table.insert(Categories, Item.Category)
            end
        end
        Gallery.Categories = Categories
        if not Seen[Gallery.Category] then
            Gallery.Category = "All"
        end
        CategoryButton.Text = Gallery.Category
    end

    local function Refresh(ResetScroll)
        if Gallery.Destroyed then
            return
        end
        table.clear(Gallery.Filtered)
        local Query = string.lower(Gallery.Search)
        for _, Item in Gallery.Items do
            local CategoryMatch = Gallery.Category == "All" or Item.Category == Gallery.Category
            local SearchMatch = Query == "" or string.find(Item.SearchText, Query, 1, true) ~= nil
            if CategoryMatch and SearchMatch then
                table.insert(Gallery.Filtered, Item)
            end
        end

        Gallery.PageCount = 1
        Gallery.Page = 1
        Empty.Visible = #Gallery.Filtered == 0
        GridHolder.Visible = #Gallery.Filtered > 0

        if ResetScroll then
            GridHolder.CanvasPosition = Vector2.zero
        end
        if VirtualView then
            VirtualView:SetCount(#Gallery.Filtered)
        end
    end

    function Gallery:Refresh()
        Refresh(false)
    end

    function Gallery:SetItems(Items)
        if Gallery.Destroyed then
            return
        end
        local ReuseNormalized = Items == Gallery.Items
        if ReuseNormalized then Items = table.clone(Items) end
        table.clear(Gallery.Items)
        if type(Items) == "table" then
            for Index, Item in Items do
                local Normalized = ReuseNormalized and Item or NormalizeItem(Item, Index)
                if Normalized then
                    table.insert(Gallery.Items, Normalized)
                end
            end
        end
        if Gallery.SelectedId ~= nil then
            local Selected
            for _, Item in Gallery.Items do
                if Item.Id == Gallery.SelectedId then
                    Selected = Item
                    break
                end
            end
            if not Selected then
                Gallery.SelectedId = nil
            end
            BindPreview(Selected)
        end
        RebuildCategories()
        Refresh(true)
    end

    function Gallery:AddItem(Item)
        if Gallery.Destroyed then
            return nil
        end
        local NextIndex = #Gallery.Items + 1
        for _, Existing in Gallery.Items do
            if type(Existing.Id) == "number" then
                NextIndex = math.max(NextIndex, Existing.Id + 1)
            end
        end
        local Normalized = NormalizeItem(Item, NextIndex)
        if not Normalized then
            return nil
        end
        for _, Existing in Gallery.Items do
            if Existing.Id == Normalized.Id then
                return nil
            end
        end
        table.insert(Gallery.Items, Normalized)
        RebuildCategories()
        Refresh(true)
        return Normalized
    end

    function Gallery:RemoveItem(Id)
        if Gallery.Destroyed then
            return false
        end
        for Index, Item in Gallery.Items do
            if Item.Id == Id then
                table.remove(Gallery.Items, Index)
                if Gallery.SelectedId == Id then
                    Gallery.SelectedId = nil
                    EmitSelection(nil)
                end
                RebuildCategories()
                Refresh(true)
                return true
            end
        end
        return false
    end

    function Gallery:SetSearch(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.Search = tostring(Value or "")
        if Search.Text ~= Gallery.Search then
            Search.Text = Gallery.Search
        end
        Refresh(true)
    end

    function Gallery:SetCategory(Value)
        if Gallery.Destroyed then
            return
        end
        local Requested = tostring(Value or "All")
        Gallery.Category = table.find(Gallery.Categories, Requested) and Requested or "All"
        CategoryButton.Text = Gallery.Category
        Refresh(true)
    end

    function Gallery:SetPage()
        if Gallery.Destroyed then
            return
        end
        if VirtualView then
            VirtualView:ScrollTo(1)
        end
    end

    function Gallery:NextPage()
        Gallery:SetPage()
    end

    function Gallery:PreviousPage()
        Gallery:SetPage()
    end

    function Gallery:SetColumns(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.Columns = math.clamp(math.floor(tonumber(Value) or Gallery.Columns), 1, 10)
        AutoColumns = Value == nil
        ResolveGridMetrics()
    end

    function Gallery:SetMinCellWidth(Value)
        MinCellWidth = math.max(math.clamp(math.floor(tonumber(Value) or MinCellWidth), 48, 400), MinCellSide)
        AutoColumns = true
        ResolveGridMetrics()
    end

    function Gallery:SetCellHeight(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.CellHeight = math.max(math.clamp(math.floor(tonumber(Value) or Gallery.CellHeight), 52, 150), MinCellSide)
        Gallery.ImagePadding = math.min(Gallery.ImagePadding, math.max(0, Gallery.CellHeight - Gallery.LabelHeight - 1))
        for _, Slot in Gallery.Slots do
            Slot.Viewport.Position = UDim2.fromOffset(Gallery.ImagePadding, Gallery.ImagePadding)
            Slot.Viewport.Size = UDim2.new(1, -Gallery.ImagePadding * 2, 1, -(Gallery.LabelHeight + Gallery.ImagePadding))
        end
        ResolveGridMetrics()
    end

    function Gallery:SetScaleType(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.ScaleType = ResolveScaleType(Value)
        if VirtualView then
            VirtualView:Refresh()
        end
    end

    function Gallery:SetImageTransparency(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.ImageTransparency = math.clamp(tonumber(Value) or Gallery.ImageTransparency, 0, 1)
        if VirtualView then
            VirtualView:Refresh()
        end
    end

    function Gallery:SetImageBackgroundTransparency(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.ImageBackgroundTransparency = math.clamp(tonumber(Value) or Gallery.ImageBackgroundTransparency, 0, 1)
        if VirtualView then
            VirtualView:Refresh()
        end
    end

    function Gallery:SetBackgroundTransparency(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.BackgroundTransparency = math.clamp(tonumber(Value) or Gallery.BackgroundTransparency, 0, 1)
        Root.BackgroundTransparency = Gallery.BackgroundTransparency
    end

    function Gallery:SetCellTransparency(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.CellTransparency = math.clamp(tonumber(Value) or Gallery.CellTransparency, 0, 1)
        for _, Slot in Gallery.Slots do
            Slot.Button.BackgroundTransparency = Gallery.CellTransparency
        end
    end

    function Gallery:SetOutlineTransparency(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.CellOutlineTransparency = math.clamp(tonumber(Value) or Gallery.CellOutlineTransparency, 0, 1)
        for _, Slot in Gallery.Slots do
            UpdateSlotState(Slot, false)
        end
    end

    function Gallery:SetContainerOutlineTransparency(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.ContainerOutlineTransparency = math.clamp(tonumber(Value) or Gallery.ContainerOutlineTransparency, 0, 1)
        Stroke.Transparency = Gallery.ContainerOutlineTransparency
    end

    function Gallery:SetImagePadding(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.ImagePadding = math.clamp(math.floor(tonumber(Value) or Gallery.ImagePadding), 0, math.max(0, Gallery.CellHeight - Gallery.LabelHeight - 1))
        for _, Slot in Gallery.Slots do
            Slot.Viewport.Position = UDim2.fromOffset(Gallery.ImagePadding, Gallery.ImagePadding)
            Slot.Viewport.Size = UDim2.new(1, -Gallery.ImagePadding * 2, 1, -(Gallery.LabelHeight + Gallery.ImagePadding))
        end
    end

    function Gallery:SetLabelHeight(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.LabelHeight = math.clamp(math.floor(tonumber(Value) or Gallery.LabelHeight), 0, 40)
        Gallery.ImagePadding = math.min(Gallery.ImagePadding, math.max(0, Gallery.CellHeight - Gallery.LabelHeight - 1))
        for _, Slot in Gallery.Slots do
            Slot.Viewport.Position = UDim2.fromOffset(Gallery.ImagePadding, Gallery.ImagePadding)
            Slot.Viewport.Size = UDim2.new(1, -Gallery.ImagePadding * 2, 1, -(Gallery.LabelHeight + Gallery.ImagePadding))
            Slot.Name.Size = UDim2.new(1, 0, 0, Gallery.LabelHeight)
            Slot.Name.Visible = Gallery.LabelHeight > 0
        end
    end

    function Gallery:SetImageSize(Value)
        if Gallery.Destroyed or typeof(Value) ~= "UDim2" then
            return
        end
        Gallery.ImageSize = Value
        if VirtualView then
            VirtualView:Refresh()
        end
    end

    function Gallery:SetImageScale(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.ImageScale = math.clamp(tonumber(Value) or Gallery.ImageScale, 0.1, 4)
        if VirtualView then
            VirtualView:Refresh()
        end
    end

    function Gallery:SetImagePosition(Value, AnchorPoint)
        if Gallery.Destroyed or typeof(Value) ~= "UDim2" then
            return
        end
        if AnchorPoint ~= nil and typeof(AnchorPoint) ~= "Vector2" then
            return
        end
        Gallery.ImagePosition = Value
        if AnchorPoint then
            Gallery.ImageAnchorPoint = AnchorPoint
        end
        if VirtualView then
            VirtualView:Refresh()
        end
    end

    function Gallery:SetTileSize(Value)
        if Gallery.Destroyed or typeof(Value) ~= "UDim2" then
            return
        end
        Gallery.TileSize = Value
        if VirtualView then
            VirtualView:Refresh()
        end
    end

    function Gallery:SetRotation(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.Rotation = tonumber(Value) or Gallery.Rotation
        if VirtualView then
            VirtualView:Refresh()
        end
    end

    function Gallery:SetCornerRadius(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.CornerRadius = math.clamp(math.floor(tonumber(Value) or Gallery.CornerRadius), 0, 12)
        Info.CornerRadius = Gallery.CornerRadius
        if Library then Library:RemoveFromRegistry(RootCorner) end
        RootCorner.CornerRadius = UDim.new(0, Gallery.CornerRadius)
        for _, Slot in Gallery.Slots do
            if Library then
                Library:RemoveFromRegistry(Slot.Corner)
                Library:RemoveFromRegistry(Slot.ImageCorner)
            end
            Slot.Corner.CornerRadius = UDim.new(0, Gallery.CornerRadius)
            Slot.ImageCorner.CornerRadius = UDim.new(0, math.max(0, Gallery.CornerRadius - 1))
        end
    end

    function Gallery:Select(Id, Silent)
        if Gallery.Destroyed then
            return nil
        end
        local Selected
        for _, Item in Gallery.Items do
            if Item.Id == Id or Item.Source == Id then
                Selected = Item
                break
            end
        end
        Gallery.SelectedId = Selected and Selected.Id or nil
        if VirtualView then
            VirtualView:Refresh()
        end
        if not Silent then
            EmitSelection(Selected)
        else
            BindPreview(Selected)
        end
        return Selected and Selected.Source or nil
    end

    function Gallery:GetSelected()
        for _, Item in Gallery.Items do
            if Item.Id == Gallery.SelectedId then
                return Item.Source, Item
            end
        end
        return nil
    end

    function Gallery:BindPreview(Preview)
        if Gallery.Destroyed then
            return
        end
        Gallery.Preview = Preview
        Gallery.PreviewDefaults = nil
        local _, Item = Gallery:GetSelected()
        BindPreview(Item)
    end

    function Gallery:SetVisible(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.Visible = Value == true
        Root.Visible = Gallery.Visible
        if Gallery.Element then
            Gallery.Element:SetVisible(Gallery.Visible)
        end
    end

    function Gallery:SetHeight(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.Height = math.clamp(math.floor(tonumber(Value) or Gallery.Height), 180, 780)
        Root.Size = UDim2.new(1, 0, 0, Gallery.Height)
        if Gallery.Element then
            Gallery.Element:SetHeight(Gallery.Height)
        end
    end

    function Gallery:Mount(Parent)
        if Gallery.Destroyed or typeof(Parent) ~= "Instance" or not Parent:IsA("GuiBase2d") then
            return false
        end
        Root.Parent = Parent
        return true
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
        for Key, Tween in LocalTweens do
            Tween:Cancel()
            LocalTweens[Key] = nil
        end
        if Library and type(Library.CancelTween) == "function" then
            for _, Slot in Gallery.Slots do
                Library:CancelTween(Slot.Button, "ImageGallery" .. tostring(Slot.Index))
            end
        end
        for _, Connection in Gallery.Connections do
            pcall(function()
                Connection:Disconnect()
            end)
        end
        table.clear(Gallery.Connections)
        table.clear(Gallery.Slots)
        table.clear(Gallery.Items)
        table.clear(Gallery.Filtered)
        table.clear(ResolvedCache)
        table.clear(ResolvedOrder)
        RemoveRegistryTree(Library, Root)
        if Gallery.Element then
            Gallery.Element:Destroy()
            Gallery.Element = nil
        elseif Root then
            Root:Destroy()
        end
    end

    local SearchSequence = 0
    table.insert(Gallery.Connections, Search:GetPropertyChangedSignal("Text"):Connect(function()
        if Gallery.Destroyed then
            return
        end
        SearchSequence += 1
        local Sequence = SearchSequence
        task.delay(0.08, function()
            if not Gallery.Destroyed and Sequence == SearchSequence then
                Gallery.Search = Search.Text
                Refresh(true)
            end
        end)
    end))

    table.insert(Gallery.Connections, CategoryButton.Activated:Connect(function()
        if Gallery.Destroyed then
            return
        end
        local Index = table.find(Gallery.Categories, Gallery.Category) or 1
        Index = Index % #Gallery.Categories + 1
        Gallery:SetCategory(Gallery.Categories[Index])
    end))

    if typeof(Info.Parent) == "Instance" and Info.Parent:IsA("GuiBase2d") then
        Root.Parent = Info.Parent
    end
    ResolveGridMetrics()
    Gallery:SetItems(Info.Items or {})
    if Info.Category then
        Gallery:SetCategory(Info.Category)
    end
    if Info.Selected ~= nil then
        Gallery:Select(Info.Selected, true)
    end
    if Info.Model then
        Gallery.ModelBinding = Info.Model:Bind(Gallery)
    end

    if Library and type(Library.OnUnload) == "function" then
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

function ImageGallery.CreateEmbedded(Library, Groupbox, Idx, Info)
    assert(type(Groupbox) == "table" and type(Groupbox.AddUIPassthrough) == "function", "ImageGallery requires a groupbox")
    Info = Info or {}
    local Gallery = ImageGallery.Create(Library, Info)
    Gallery.Element = Groupbox:AddUIPassthrough(Idx or "ImageGallery", {
        Instance = Gallery.Root,
        Height = Gallery.Height,
        Visible = Gallery.Visible,
    })
    return Gallery
end

function ImageGallery.CreateStandalone(Library, Info)
    assert(Library and type(Library.CreateAddonWindow) == "function", "ImageGallery standalone mode requires Library:CreateAddonWindow")
    Info = table.clone(Info or {})
    local WindowHeight = tonumber(Info.WindowHeight) or 500
    local Host = Library:CreateAddonWindow({
        Title = Info.WindowTitle or "Gallery",
        Subtitle = Info.WindowSubtitle,
        Icon = Info.WindowIcon or "layout-grid",
        Width = Info.WindowWidth or 480,
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
    local Gallery = Host:AddAddon("Gallery", ImageGallery, Info)
    Gallery.Host = Host
    return Gallery, Host
end

ImageGallery.Mount = ImageGallery.CreateEmbedded

return ImageGallery
