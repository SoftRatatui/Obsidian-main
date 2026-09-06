local TweenService = game:GetService("TweenService")

local AssetCatalog = {
    ReleaseVersion = "0.0.1-release-3",
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
    local Number = tonumber(Value)
    if Number then
        return string.format("rbxassetid://%d", Number)
    end
    return Value
end

local function ResolveScaleType(Value)
    if typeof(Value) == "EnumItem" and Value.EnumType == Enum.ScaleType then
        return Value
    end
    local Name = string.lower(tostring(Value or "Fit"))
    if Name == "crop" then
        return Enum.ScaleType.Crop
    elseif Name == "stretch" then
        return Enum.ScaleType.Stretch
    elseif Name == "tile" then
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
        Item = {
            Name = tostring(Item),
            Image = Item,
        }
    end
    if type(Item) ~= "table" then
        return nil
    end
    local Name = tostring(Item.Name or Item.Title or Item.Id or Index)
    local Category = tostring(Item.Category or Item.Group or "All")
    local Image = Item.Image or Item.AssetId or Item.Icon or ""
    local Tags = type(Item.Tags) == "table" and table.concat(Item.Tags, " ") or tostring(Item.Tags or "")
    local Badges = {}
    if type(Item.Badges) == "table" then
        for _, Badge in Item.Badges do
            table.insert(Badges, tostring(Badge))
        end
    end
    if Item.Rarity then
        table.insert(Badges, tostring(Item.Rarity))
    end
    return {
        Id = Item.Id ~= nil and Item.Id or Index,
        Name = Name,
        Subtitle = tostring(Item.Subtitle or Item.Description or ""),
        Category = Category,
        Image = Image,
        Thumbnail = Item.Thumbnail or Item.ThumbnailId or Image,
        PreviewImage = Item.PreviewImage or Item.FullImage or Image,
        Color = typeof(Item.Color) == "Color3" and Item.Color or Color3.new(1, 1, 1),
        AccentColor = typeof(Item.AccentColor) == "Color3" and Item.AccentColor or nil,
        Disabled = Item.Disabled == true,
        Locked = Item.Locked == true,
        Favorite = Item.Favorite == true,
        Price = Item.Price,
        Status = Item.Status,
        Badges = Badges,
        ActionText = Item.ActionText,
        SecondaryActionText = Item.SecondaryActionText,
        OnAction = Item.OnAction,
        OnSecondaryAction = Item.OnSecondaryAction,
        ImageTransparency = tonumber(Item.ImageTransparency or Item.Transparency),
        BackgroundTransparency = tonumber(Item.BackgroundTransparency),
        ScaleType = Item.ScaleType,
        Rotation = tonumber(Item.Rotation),
        ImageScale = tonumber(Item.ImageScale or Item.Zoom),
        ImagePosition = typeof(Item.ImagePosition) == "UDim2" and Item.ImagePosition or nil,
        ImageAnchorPoint = typeof(Item.ImageAnchorPoint) == "Vector2" and Item.ImageAnchorPoint or nil,
        RectOffset = typeof(Item.RectOffset) == "Vector2" and Item.RectOffset or Vector2.zero,
        RectSize = typeof(Item.RectSize) == "Vector2" and Item.RectSize or Vector2.zero,
        SearchText = string.lower(string.format("%s %s %s %s", Name, Category, Tags, tostring(Item.Status or ""))),
        Source = Item,
    }
end

function AssetCatalog.Create(Library, Info)
    Info = Info or {}
    local Style = Library and type(Library.GetAddonStyle) == "function" and Library:GetAddonStyle(Info.Style) or {
        HeaderHeight = 38,
        ControlHeight = 28,
        Padding = 10,
        Gap = 8,
        Radius = 7,
        ControlRadius = 4,
        CellRadius = 6,
        CellPadding = 6,
        OutlineTransparency = 0.5,
        StrokeThickness = 1,
        SelectionThickness = 1,
        TextSize = 14,
        CaptionSize = 12,
        PreviewRatio = 0.58,
        Motion = true,
    }
    local Height = math.clamp(math.floor(tonumber(Info.Height) or 430), 260, 900)
    local LayoutMode = string.lower(tostring(Info.Layout or "Split"))
    local PreviewSide = string.lower(tostring(Info.PreviewSide or "Right"))
    local AutoColumns = Info.Columns == nil
    local Columns = math.clamp(math.floor(tonumber(Info.Columns) or 3), 1, 8)
    local Rows = math.clamp(math.floor(tonumber(Info.Rows) or 3), 1, 8)
    local DefaultPageSize = AutoColumns and math.max(Columns * Rows, 24) or Columns * Rows
    local PageSize = math.clamp(math.floor(tonumber(Info.PageSize) or DefaultPageSize), Columns, 64)
    local CellHeight = math.clamp(math.floor(tonumber(Info.CellHeight) or 104), 64, 220)
    local Gap = math.clamp(math.floor(tonumber(Info.Gap) or Style.Gap), 2, 20)
    local Padding = math.clamp(math.floor(tonumber(Info.Padding) or Style.Padding), 0, 24)
    local ToolbarHeight = math.clamp(math.floor(tonumber(Info.ToolbarHeight) or Style.HeaderHeight), 32, 52)
    local FooterHeight = 28
    local PreviewRatio = math.clamp(tonumber(Info.PreviewRatio) or Style.PreviewRatio, 0.3, 0.8)
    local ImageScaleType = ResolveScaleType(Info.ScaleType)
    local ImageTransparency = math.clamp(tonumber(Info.ImageTransparency) or 0, 0, 1)
    local CardTransparency = math.clamp(tonumber(Info.CardTransparency) or 0, 0, 1)
    local PreviewTransparency = math.clamp(tonumber(Info.PreviewTransparency) or 0, 0, 1)
    local RootTransparency = math.clamp(tonumber(Info.BackgroundTransparency) or 1, 0, 1)
    local LabelHeight = math.clamp(math.floor(tonumber(Info.LabelHeight) or 35), 20, 60)
    local ImagePadding = math.clamp(
        math.floor(tonumber(Info.ImagePadding) or Style.CellPadding),
        0,
        math.max(0, math.min(30, math.floor((CellHeight - LabelHeight - 8) * 0.5)))
    )
    local PreviewPadding = math.clamp(math.floor(tonumber(Info.PreviewPadding) or Padding), 0, 30)

    local Root = Instance.new("Frame")
    Root.Name = "MonHubAssetCatalog"
    Root.BackgroundColor3 = Library and Library.Scheme.BackgroundColor or Color3.fromRGB(17, 19, 22)
    Root.BackgroundTransparency = RootTransparency
    Root.BorderSizePixel = 0
    Root.ClipsDescendants = true
    Root.Size = UDim2.new(1, 0, 0, Height)
    Root.Visible = Info.Visible ~= false
    AddRegistry(Library, Root, { BackgroundColor3 = "BackgroundColor" })

    local RootCorner = Instance.new("UICorner")
    RootCorner.CornerRadius = UDim.new(0, Style.Radius)
    RootCorner.Parent = Root

    local Toolbar = Instance.new("Frame")
    Toolbar.BackgroundColor3 = Library and Library.Scheme.SurfaceColor or Color3.fromRGB(23, 25, 29)
    Toolbar.BackgroundTransparency = 0
    Toolbar.BorderSizePixel = 0
    Toolbar.Size = UDim2.new(1, 0, 0, ToolbarHeight)
    Toolbar.Parent = Root
    AddRegistry(Library, Toolbar, { BackgroundColor3 = "SurfaceColor" })

    local ToolbarCorner = Instance.new("UICorner")
    ToolbarCorner.TopLeftRadius = UDim.new(0, 0)
    ToolbarCorner.TopRightRadius = UDim.new(0, 0)
    ToolbarCorner.BottomLeftRadius = UDim.new(0, Style.Radius)
    ToolbarCorner.BottomRightRadius = UDim.new(0, Style.Radius)
    ToolbarCorner.Parent = Toolbar

    local Category = Instance.new("TextButton")
    Category.AutoButtonColor = false
    Category.BackgroundColor3 = Library and Library.Scheme.ElementColor or Color3.fromRGB(31, 34, 39)
    Category.BorderSizePixel = 0
    Category.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
    Category.Position = UDim2.fromOffset(Padding, math.floor((ToolbarHeight - Style.ControlHeight) * 0.5))
    Category.Size = UDim2.fromOffset(math.clamp(tonumber(Info.CategoryWidth) or 112, 76, 180), Style.ControlHeight)
    Category.Text = "All"
    Category.TextColor3 = Library and Library.Scheme.FontColor or Color3.fromRGB(238, 240, 244)
    Category.TextSize = Style.CaptionSize
    Category.TextTruncate = Enum.TextTruncate.AtEnd
    Category.Parent = Toolbar
    AddRegistry(Library, Category, {
        BackgroundColor3 = "ElementColor",
        FontFace = "Font",
        TextColor3 = "FontColor",
    })

    local CategoryCorner = Instance.new("UICorner")
    CategoryCorner.CornerRadius = UDim.new(0, Style.ControlRadius)
    CategoryCorner.Parent = Category
    local PreferredCategoryWidth = Category.Size.X.Offset

    local Search = Instance.new("TextBox")
    Search.BackgroundColor3 = Library and Library.Scheme.ElementColor or Color3.fromRGB(31, 34, 39)
    Search.BorderSizePixel = 0
    Search.ClearTextOnFocus = false
    Search.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
    Search.PlaceholderColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(146, 151, 160)
    Search.PlaceholderText = tostring(Info.SearchPlaceholder or "Search collection")
    Search.Position = UDim2.fromOffset(Padding + Category.Size.X.Offset + Gap, math.floor((ToolbarHeight - Style.ControlHeight) * 0.5))
    Search.Size = UDim2.new(1, -(Padding * 2 + Category.Size.X.Offset + Gap), 0, Style.ControlHeight)
    Search.Text = ""
    Search.TextColor3 = Library and Library.Scheme.FontColor or Color3.fromRGB(238, 240, 244)
    Search.TextSize = Style.CaptionSize
    Search.TextXAlignment = Enum.TextXAlignment.Left
    Search.Parent = Toolbar
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
    SearchPadding.PaddingLeft = UDim.new(0, 10)
    SearchPadding.PaddingRight = UDim.new(0, 10)
    SearchPadding.Parent = Search

    local function ToolbarButton(Text)
        local Button = Instance.new("TextButton")
        Button.AutoButtonColor = false
        Button.BackgroundColor3 = Library and Library.Scheme.ElementColor or Color3.fromRGB(31, 34, 39)
        Button.BorderSizePixel = 0
        Button.FontFace = Category.FontFace
        Button.Text = Text
        Button.TextColor3 = Category.TextColor3
        Button.TextSize = Style.CaptionSize
        Button.TextTruncate = Enum.TextTruncate.AtEnd
        Button.Parent = Toolbar
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, Style.ControlRadius)
        Corner.Parent = Button
        AddRegistry(Library, Button, { BackgroundColor3 = "ElementColor", TextColor3 = "FontColor", FontFace = "Font" })
        return Button
    end
    local Favorites = ToolbarButton("Saved")
    local Sort = ToolbarButton("Original")

    local Body = Instance.new("Frame")
    Body.BackgroundTransparency = 1
    Body.Position = UDim2.fromOffset(0, ToolbarHeight + Gap)
    Body.Size = UDim2.new(1, 0, 1, -(ToolbarHeight + Gap))
    Body.Parent = Root

    local GridPanel = Instance.new("Frame")
    GridPanel.BackgroundColor3 = Library and Library.Scheme.SurfaceColor or Color3.fromRGB(23, 25, 29)
    GridPanel.BorderSizePixel = 0
    GridPanel.ClipsDescendants = true
    GridPanel.Parent = Body
    AddRegistry(Library, GridPanel, { BackgroundColor3 = "SurfaceColor" })

    local GridCorner = Instance.new("UICorner")
    GridCorner.CornerRadius = UDim.new(0, Style.Radius)
    GridCorner.Parent = GridPanel

    local StrokeToken = Style.Highlight and "AccentColor" or "OutlineColor"
    local StrokeColor = Library and Library.Scheme[StrokeToken] or Color3.fromRGB(52, 57, 66)

    local GridStroke = Instance.new("UIStroke")
    GridStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    GridStroke.Color = StrokeColor
    GridStroke.Thickness = Style.StrokeThickness
    GridStroke.Transparency = Style.OutlineTransparency
    GridStroke.Parent = GridPanel
    AddRegistry(Library, GridStroke, { Color = StrokeToken })

    local GridScroll = Instance.new("ScrollingFrame")
    GridScroll.ClipsDescendants = true
    GridScroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    GridScroll.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    GridScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    GridScroll.BackgroundTransparency = 1
    GridScroll.BorderSizePixel = 0
    GridScroll.CanvasSize = UDim2.fromScale(0, 0)
    GridScroll.Position = UDim2.fromOffset(Padding, Padding)
    GridScroll.ScrollBarImageColor3 = Library and Library.Scheme.AccentColor or Color3.fromRGB(133, 141, 160)
    GridScroll.ScrollBarImageTransparency = 0.45
    GridScroll.ScrollBarThickness = 2
    GridScroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always
    GridScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    GridScroll.Size = UDim2.new(1, -Padding * 2, 1, -(Padding * 2 + FooterHeight))
    GridScroll.Parent = GridPanel
    AddRegistry(Library, GridScroll, { ScrollBarImageColor3 = "AccentColor" })

    local MinCellWidth = math.clamp(math.floor(tonumber(Info.MinCellWidth) or 132), 64, 400)

    local Grid = Instance.new("UIGridLayout")
    Grid.CellPadding = UDim2.fromOffset(Gap, Gap)
    Grid.CellSize = UDim2.fromOffset(MinCellWidth, CellHeight)
    Grid.FillDirectionMaxCells = Columns
    Grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
    Grid.SortOrder = Enum.SortOrder.LayoutOrder
    Grid.Parent = GridScroll
    local GridPadding = Instance.new("UIPadding")
    GridPadding.PaddingTop = UDim.new(0, 1)
    GridPadding.PaddingBottom = UDim.new(0, 1)
    GridPadding.Parent = GridScroll

    local function ResolveGridMetrics()
        local Width = math.floor(GridScroll.AbsoluteSize.X / GetGuiScale(GridScroll)) - GridScroll.ScrollBarThickness - 2
        if Width <= 0 then
            return
        end

        local Count = Columns
        if AutoColumns then
            Count = math.clamp(math.floor((Width + Gap) / (MinCellWidth + Gap)), 1, 8)
        end

        Count = math.clamp(Count, 1, math.max(1, math.floor((Width + Gap) / (48 + Gap))))
        local CellWidth = math.max(1, math.floor((Width - Gap * (Count - 1)) / Count))
        local Remaining = math.max(0, Width - CellWidth * Count - Gap * (Count - 1))
        GridPadding.PaddingLeft = UDim.new(0, 1 + math.floor(Remaining / 2))
        GridPadding.PaddingRight = UDim.new(0, 1 + math.ceil(Remaining / 2))
        Grid.FillDirectionMaxCells = Count
        Grid.CellSize = UDim2.fromOffset(CellWidth, CellHeight)
    end

    ResolveGridMetrics()
    local GridConnection = GridScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(ResolveGridMetrics)

    local Footer = Instance.new("Frame")
    Footer.AnchorPoint = Vector2.new(0, 1)
    Footer.BackgroundTransparency = 1
    Footer.Position = UDim2.fromScale(0, 1)
    Footer.Size = UDim2.new(1, 0, 0, FooterHeight)
    Footer.Parent = GridPanel

    local Previous = Instance.new("TextButton")
    Previous.AutoButtonColor = false
    Previous.BackgroundTransparency = 1
    Previous.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
    Previous.Size = UDim2.fromOffset(54, FooterHeight)
    Previous.Text = "Previous"
    Previous.TextColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(146, 151, 160)
    Previous.TextSize = 11
    Previous.Parent = Footer
    AddRegistry(Library, Previous, { FontFace = "Font", TextColor3 = "MutedFontColor" })

    local PageLabel = Instance.new("TextLabel")
    PageLabel.BackgroundTransparency = 1
    PageLabel.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
    PageLabel.Position = UDim2.fromOffset(54, 0)
    PageLabel.Size = UDim2.new(1, -108, 1, 0)
    PageLabel.Text = "1 / 1"
    PageLabel.TextColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(146, 151, 160)
    PageLabel.TextSize = 11
    PageLabel.Parent = Footer
    AddRegistry(Library, PageLabel, { FontFace = "Font", TextColor3 = "MutedFontColor" })

    local Next = Instance.new("TextButton")
    Next.AnchorPoint = Vector2.new(1, 0)
    Next.AutoButtonColor = false
    Next.BackgroundTransparency = 1
    Next.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
    Next.Position = UDim2.fromScale(1, 0)
    Next.Size = UDim2.fromOffset(54, FooterHeight)
    Next.Text = "Next"
    Next.TextColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(146, 151, 160)
    Next.TextSize = 11
    Next.Parent = Footer
    AddRegistry(Library, Next, { FontFace = "Font", TextColor3 = "MutedFontColor" })

    local PreviewPanel = Instance.new("Frame")
    PreviewPanel.BackgroundColor3 = Library and Library.Scheme.SurfaceColor or Color3.fromRGB(23, 25, 29)
    PreviewPanel.BackgroundTransparency = PreviewTransparency
    PreviewPanel.BorderSizePixel = 0
    PreviewPanel.ClipsDescendants = true
    PreviewPanel.Parent = Body
    AddRegistry(Library, PreviewPanel, { BackgroundColor3 = "SurfaceColor" })

    local PreviewCorner = Instance.new("UICorner")
    PreviewCorner.CornerRadius = UDim.new(0, Style.Radius)
    PreviewCorner.Parent = PreviewPanel

    local PreviewStroke = Instance.new("UIStroke")
    PreviewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    PreviewStroke.Color = StrokeColor
    PreviewStroke.Thickness = Style.StrokeThickness
    PreviewStroke.Transparency = Style.OutlineTransparency
    PreviewStroke.Parent = PreviewPanel
    AddRegistry(Library, PreviewStroke, { Color = StrokeToken })

    local PreviewCanvas = Instance.new("Frame")
    PreviewCanvas.BackgroundColor3 = Library and Library.Scheme.ElementColor or Color3.fromRGB(31, 34, 39)
    PreviewCanvas.BorderSizePixel = 0
    PreviewCanvas.ClipsDescendants = true
    PreviewCanvas.Position = UDim2.fromOffset(PreviewPadding, PreviewPadding)
    PreviewCanvas.Size = UDim2.new(1, -PreviewPadding * 2, 1, -(PreviewPadding * 2 + 112))
    PreviewCanvas.Parent = PreviewPanel
    AddRegistry(Library, PreviewCanvas, { BackgroundColor3 = "ElementColor" })

    local PreviewCanvasCorner = Instance.new("UICorner")
    PreviewCanvasCorner.CornerRadius = UDim.new(0, Style.CellRadius)
    PreviewCanvasCorner.Parent = PreviewCanvas

    local PreviewImageScale = Instance.new("UIScale")
    PreviewImageScale.Scale = 1

    local PreviewImage = Instance.new("ImageLabel")
    PreviewImage.AnchorPoint = Vector2.new(0.5, 0.5)
    PreviewImage.BackgroundTransparency = 1
    PreviewImage.Image = ""
    PreviewImage.ImageColor3 = Color3.new(1, 1, 1)
    PreviewImage.Position = UDim2.fromScale(0.5, 0.5)
    PreviewImage.ScaleType = ImageScaleType
    PreviewImage.Size = UDim2.new(1, -PreviewPadding * 2, 1, -PreviewPadding * 2)
    PreviewImage.Parent = PreviewCanvas
    PreviewImageScale.Parent = PreviewImage

    local PreviewName = Instance.new("TextLabel")
    PreviewName.BackgroundTransparency = 1
    PreviewName.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
    PreviewName.Position = UDim2.new(0, PreviewPadding, 1, -(PreviewPadding + 104))
    PreviewName.Size = UDim2.new(1, -PreviewPadding * 2, 0, 22)
    PreviewName.Text = tostring(Info.EmptyTitle or "Select an item")
    PreviewName.TextColor3 = Library and Library.Scheme.FontColor or Color3.fromRGB(238, 240, 244)
    PreviewName.TextSize = Style.TextSize
    PreviewName.TextTruncate = Enum.TextTruncate.AtEnd
    PreviewName.TextXAlignment = Enum.TextXAlignment.Left
    PreviewName.Parent = PreviewPanel
    AddRegistry(Library, PreviewName, { FontFace = "Font", TextColor3 = "FontColor" })

    local PreviewSubtitle = Instance.new("TextLabel")
    PreviewSubtitle.BackgroundTransparency = 1
    PreviewSubtitle.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
    PreviewSubtitle.Position = UDim2.new(0, PreviewPadding, 1, -(PreviewPadding + 80))
    PreviewSubtitle.Size = UDim2.new(1, -PreviewPadding * 2, 0, 18)
    PreviewSubtitle.Text = tostring(Info.EmptySubtitle or "Choose from the collection")
    PreviewSubtitle.TextColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(146, 151, 160)
    PreviewSubtitle.TextSize = Style.CaptionSize
    PreviewSubtitle.TextTruncate = Enum.TextTruncate.AtEnd
    PreviewSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    PreviewSubtitle.Parent = PreviewPanel
    AddRegistry(Library, PreviewSubtitle, { FontFace = "Font", TextColor3 = "MutedFontColor" })

    local Badges = Instance.new("Frame")
    Badges.BackgroundTransparency = 1
    Badges.Position = UDim2.new(0, PreviewPadding, 1, -(PreviewPadding + 57))
    Badges.Size = UDim2.new(1, -PreviewPadding * 2, 0, 20)
    Badges.Parent = PreviewPanel

    local BadgeLayout = Instance.new("UIListLayout")
    BadgeLayout.FillDirection = Enum.FillDirection.Horizontal
    BadgeLayout.Padding = UDim.new(0, 5)
    BadgeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    BadgeLayout.Parent = Badges

    local Actions = Instance.new("Frame")
    Actions.AnchorPoint = Vector2.new(0, 1)
    Actions.BackgroundTransparency = 1
    Actions.Position = UDim2.new(0, PreviewPadding, 1, -PreviewPadding)
    Actions.Size = UDim2.new(1, -PreviewPadding * 2, 0, Style.ControlHeight)
    Actions.Parent = PreviewPanel

    local ActionLayout = Instance.new("UIListLayout")
    ActionLayout.FillDirection = Enum.FillDirection.Horizontal
    ActionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ActionLayout.Padding = UDim.new(0, Gap)
    ActionLayout.Parent = Actions

    local SecondaryAction = Instance.new("TextButton")
    SecondaryAction.AutoButtonColor = false
    SecondaryAction.BackgroundColor3 = Library and Library.Scheme.ElementColor or Color3.fromRGB(31, 34, 39)
    SecondaryAction.BorderSizePixel = 0
    SecondaryAction.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
    SecondaryAction.Size = UDim2.new(0.5, -Gap * 0.5, 1, 0)
    SecondaryAction.Text = tostring(Info.SecondaryActionText or "Preview")
    SecondaryAction.TextColor3 = Library and Library.Scheme.FontColor or Color3.fromRGB(238, 240, 244)
    SecondaryAction.TextSize = Style.CaptionSize
    SecondaryAction.TextTruncate = Enum.TextTruncate.AtEnd
    SecondaryAction.Visible = Info.SecondaryAction ~= false
    SecondaryAction.Parent = Actions
    AddRegistry(Library, SecondaryAction, {
        BackgroundColor3 = "ElementColor",
        FontFace = "Font",
        TextColor3 = "FontColor",
    })

    local SecondaryCorner = Instance.new("UICorner")
    SecondaryCorner.CornerRadius = UDim.new(0, Style.ControlRadius)
    SecondaryCorner.Parent = SecondaryAction

    local PrimaryAction = Instance.new("TextButton")
    PrimaryAction.AutoButtonColor = false
    PrimaryAction.BackgroundColor3 = Library and Library.Scheme.AccentColor or Color3.fromRGB(133, 141, 160)
    PrimaryAction.BorderSizePixel = 0
    PrimaryAction.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
    PrimaryAction.Size = UDim2.new(0.5, -Gap * 0.5, 1, 0)
    PrimaryAction.Text = tostring(Info.ActionText or "Apply")
    PrimaryAction.TextColor3 = Library and Library.Scheme.BackgroundColor or Color3.fromRGB(17, 19, 22)
    PrimaryAction.TextSize = Style.CaptionSize
    PrimaryAction.TextTruncate = Enum.TextTruncate.AtEnd
    PrimaryAction.Parent = Actions
    if Info.SecondaryAction == false then
        PrimaryAction.Size = UDim2.fromScale(1, 1)
    end
    AddRegistry(Library, PrimaryAction, {
        BackgroundColor3 = "AccentColor",
        FontFace = "Font",
        TextColor3 = "BackgroundColor",
    })

    local function ResolveActionMetrics()
        local Width = math.floor(Actions.AbsoluteSize.X / GetGuiScale(Actions))
        if Width <= 0 then
            return
        end
        if not SecondaryAction.Visible then
            PrimaryAction.Size = UDim2.new(0, Width, 1, 0)
            return
        end
        local Primary = math.max(1, math.floor((Width - Gap) / 2))
        SecondaryAction.Size = UDim2.new(0, Width - Gap - Primary, 1, 0)
        PrimaryAction.Size = UDim2.new(0, Primary, 1, 0)
    end

    ResolveActionMetrics()
    local ActionConnection = Actions:GetPropertyChangedSignal("AbsoluteSize"):Connect(ResolveActionMetrics)

    local PrimaryCorner = Instance.new("UICorner")
    PrimaryCorner.CornerRadius = UDim.new(0, Style.ControlRadius)
    PrimaryCorner.Parent = PrimaryAction

    local Empty = Instance.new("TextLabel")
    Empty.BackgroundTransparency = 1
    Empty.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
    Empty.Position = UDim2.fromOffset(Padding, Padding)
    Empty.Size = UDim2.new(1, -Padding * 2, 1, -(Padding * 2 + FooterHeight))
    Empty.Text = tostring(Info.EmptyText or "No matching items")
    Empty.TextColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(146, 151, 160)
    Empty.TextSize = Style.CaptionSize
    Empty.Visible = false
    Empty.Parent = GridPanel
    AddRegistry(Library, Empty, { FontFace = "Font", TextColor3 = "MutedFontColor" })

    local Catalog = {
        Root = Root,
        Toolbar = Toolbar,
        SearchBox = Search,
        CategoryButton = Category,
        GridPanel = GridPanel,
        PreviewPanel = PreviewPanel,
        PreviewImage = PreviewImage,
        PreviewName = PreviewName,
        PreviewSubtitle = PreviewSubtitle,
        PrimaryAction = PrimaryAction,
        SecondaryAction = SecondaryAction,
        Slots = {},
        Items = {},
        Filtered = {},
        Categories = { "All" },
        Connections = {},
        Badges = {},
        Style = Style,
        Element = nil,
        Host = nil,
        Height = Height,
        Layout = LayoutMode,
        PreviewSide = PreviewSide,
        PreviewRatio = PreviewRatio,
        Reveal = Info.Reveal ~= false,
        RevealStagger = math.clamp(tonumber(Info.RevealStagger) or 0.012, 0, 0.08),
        Columns = Columns,
        Rows = Rows,
        PageSize = PageSize,
        CellHeight = CellHeight,
        Page = 1,
        PageCount = 1,
        Search = "",
        Category = "All",
        SelectedId = nil,
        SelectedItem = nil,
        ImageTransparency = ImageTransparency,
        ImagePadding = ImagePadding,
        PreviewPadding = PreviewPadding,
        ScaleType = ImageScaleType,
        CardTransparency = CardTransparency,
        PreviewTransparency = PreviewTransparency,
        Visible = Info.Visible ~= false,
        Destroyed = false,
        OnSelected = Info.OnSelected or Info.Callback,
        OnAction = Info.OnAction,
        OnSecondaryAction = Info.OnSecondaryAction,
        FavoritesOnly = Info.FavoritesOnly == true,
        Sort = Info.Sort == "Name" and "Name" or "Original",
    }

    local function Motion(Name)
        if Library and type(Library.GetMotion) == "function" then
            return Library:GetMotion(Name)
        end
        return TweenInfo.new(Name == "Hover" and 0.07 or 0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    end

    table.insert(Catalog.Connections, GridConnection)
    table.insert(Catalog.Connections, GridScroll:GetPropertyChangedSignal("ScrollBarThickness"):Connect(ResolveGridMetrics))
    table.insert(Catalog.Connections, ActionConnection)
    local LocalTweens = {}
    local function Play(Object, Key, Properties)
        if LocalTweens[Key] then
            LocalTweens[Key]:Cancel()
            LocalTweens[Key] = nil
        end
        if not Style.Motion then
            for Property, Value in Properties do
                Object[Property] = Value
            end
            return
        end
        if Library and type(Library.PlayTween) == "function" then
            Library:PlayTween(Object, "AssetCatalog" .. tostring(Key), Motion("Hover"), Properties)
            return
        end
        local Tween = TweenService:Create(Object, Motion("Hover"), Properties)
        LocalTweens[Key] = Tween
        Tween.Completed:Once(function()
            if LocalTweens[Key] == Tween then
                LocalTweens[Key] = nil
            end
            Tween:Destroy()
        end)
        Tween:Play()
    end

    local function Call(Callback, ...)
        if type(Callback) ~= "function" then
            return
        end
        if Library and type(Library.SafeCallback) == "function" then
            Library:SafeCallback(Callback, ...)
        else
            task.spawn(Callback, ...)
        end
    end

    local function BindSurfaceHover(Button, GetNormal, GetHover)
        table.insert(Catalog.Connections, Button.MouseEnter:Connect(function()
            if not Catalog.Destroyed and Button.Active then
                Play(Button, "Control" .. Button.Name, { BackgroundColor3 = GetHover() })
            end
        end))
        table.insert(Catalog.Connections, Button.MouseLeave:Connect(function()
            if not Catalog.Destroyed then
                Play(Button, "Control" .. Button.Name, { BackgroundColor3 = GetNormal() })
            end
        end))
    end

    Category.Name = "Category"
    SecondaryAction.Name = "SecondaryAction"
    PrimaryAction.Name = "PrimaryAction"
    BindSurfaceHover(Category, function()
        return Library and Library.Scheme.ElementColor or Color3.fromRGB(31, 34, 39)
    end, function()
        return Library and Library.Scheme.HoverColor or Color3.fromRGB(38, 42, 49)
    end)
    BindSurfaceHover(SecondaryAction, function()
        return Library and Library.Scheme.ElementColor or Color3.fromRGB(31, 34, 39)
    end, function()
        return Library and Library.Scheme.HoverColor or Color3.fromRGB(38, 42, 49)
    end)
    BindSurfaceHover(PrimaryAction, function()
        return Library and Library.Scheme.AccentColor or Color3.fromRGB(133, 141, 160)
    end, function()
        local Accent = Library and Library.Scheme.AccentColor or Color3.fromRGB(133, 141, 160)
        local White = Library and Library.Scheme.WhiteColor or Color3.new(1, 1, 1)
        return Accent:Lerp(White, 0.08)
    end)

    local SplitMinWidth = math.max(360, math.floor(tonumber(Info.SplitMinWidth) or 560))

    local function SetPanelLayout()
        local Available = math.max(1, math.floor(Root.AbsoluteSize.X / GetGuiScale(Root)))
        local Compact = Available < 460
        local ControlsTop = math.floor((ToolbarHeight - Style.ControlHeight) * 0.5)
        local ActualToolbarHeight = ToolbarHeight + (Compact and (Style.ControlHeight + Gap) or 0)
        Toolbar.Size = UDim2.new(1, 0, 0, ActualToolbarHeight)
        Body.Position = UDim2.fromOffset(0, ActualToolbarHeight + Gap)
        Body.Size = UDim2.new(1, 0, 1, -(ActualToolbarHeight + Gap))
        local CategoryWidth = math.min(PreferredCategoryWidth, math.max(48, math.floor(Available * 0.32)))
        Category.Size = UDim2.fromOffset(CategoryWidth, Style.ControlHeight)
        local ActionsWidth = 64 + 76 + Gap
        Search.Position = UDim2.fromOffset(Padding + CategoryWidth + Gap, ControlsTop)
        Search.Size = UDim2.new(1, -(Padding * 2 + CategoryWidth + Gap + (Compact and 0 or ActionsWidth + Gap)), 0, Style.ControlHeight)
        Favorites.Position = Compact and UDim2.fromOffset(Padding, ToolbarHeight) or UDim2.new(1, -(Padding + ActionsWidth), 0, ControlsTop)
        Favorites.Size = UDim2.fromOffset(64, Style.ControlHeight)
        Sort.Position = Compact and UDim2.fromOffset(Padding + 64 + Gap, ToolbarHeight) or UDim2.new(1, -(Padding + 76), 0, ControlsTop)
        Sort.Size = UDim2.fromOffset(76, Style.ControlHeight)
        PreviewPanel.Visible = Catalog.Layout ~= "grid"
        if Catalog.Layout == "grid" then
            Catalog.EffectiveLayout = "grid"
            GridPanel.AnchorPoint = Vector2.zero
            GridPanel.Position = UDim2.fromOffset(0, 0)
            GridPanel.Size = UDim2.fromScale(1, 1)
            return
        end
        local Split = Catalog.Layout == "split"
        if Split then
            local Available = math.floor(Body.AbsoluteSize.X / GetGuiScale(Body))
            if Available > 0 and Available < SplitMinWidth then
                Split = false
            end
        end
        Catalog.EffectiveLayout = Split and "split" or "stack"
        if Split then
            PreviewName.Position = UDim2.new(0, PreviewPadding, 1, -(PreviewPadding + 104))
            PreviewName.Size = UDim2.new(1, -PreviewPadding * 2, 0, 22)
            PreviewSubtitle.Position = UDim2.new(0, PreviewPadding, 1, -(PreviewPadding + 80))
            PreviewSubtitle.Size = UDim2.new(1, -PreviewPadding * 2, 0, 18)
            Badges.Position = UDim2.new(0, PreviewPadding, 1, -(PreviewPadding + 57))
            Badges.Size = UDim2.new(1, -PreviewPadding * 2, 0, 20)
            Actions.Position = UDim2.new(0, PreviewPadding, 1, -PreviewPadding)
            Actions.Size = UDim2.new(1, -PreviewPadding * 2, 0, Style.ControlHeight)
            local Total = math.floor(Body.AbsoluteSize.X / GetGuiScale(Body))
            GridPanel.AnchorPoint = Vector2.zero
            if Total <= 0 then
                local GridRatio = 1 - Catalog.PreviewRatio
                GridPanel.Position = UDim2.fromScale(0, 0)
                GridPanel.Size = UDim2.new(GridRatio, -Gap * 0.5, 1, 0)
                PreviewPanel.Position = UDim2.new(GridRatio, Gap * 0.5, 0, 0)
                PreviewPanel.Size = UDim2.new(Catalog.PreviewRatio, -Gap * 0.5, 1, 0)
            else
                local PreviewWidth = math.clamp(math.floor((Total - Gap) * Catalog.PreviewRatio), 120, Total - Gap - 120)
                local GridWidth = Total - Gap - PreviewWidth
                if Catalog.PreviewSide == "left" then
                    PreviewPanel.Position = UDim2.fromOffset(0, 0)
                    PreviewPanel.Size = UDim2.new(0, PreviewWidth, 1, 0)
                    GridPanel.Position = UDim2.fromOffset(PreviewWidth + Gap, 0)
                    GridPanel.Size = UDim2.new(0, GridWidth, 1, 0)
                else
                    GridPanel.Position = UDim2.fromOffset(0, 0)
                    GridPanel.Size = UDim2.new(0, GridWidth, 1, 0)
                    PreviewPanel.Position = UDim2.fromOffset(GridWidth + Gap, 0)
                    PreviewPanel.Size = UDim2.new(0, PreviewWidth, 1, 0)
                end
            end
            PreviewCanvas.Size = UDim2.new(1, -PreviewPadding * 2, 1, -(PreviewPadding * 2 + 112))
        else
            local PreviewHeight = math.clamp(math.floor((Height - ActualToolbarHeight) * 0.42), 130, 260)
            PreviewPanel.Position = UDim2.fromScale(0, 0)
            PreviewPanel.Size = UDim2.new(1, 0, 0, PreviewHeight)
            GridPanel.AnchorPoint = Vector2.zero
            GridPanel.Position = UDim2.fromOffset(0, PreviewHeight + Gap)
            GridPanel.Size = UDim2.new(1, 0, 1, -(PreviewHeight + Gap))
            local ImageWidth = math.max(1, math.floor(Available * 0.4) - PreviewPadding * 2)
            local TextLeft = ImageWidth + PreviewPadding * 2
            local TextWidth = math.max(1, Available - TextLeft - PreviewPadding)
            PreviewCanvas.Size = UDim2.new(0, ImageWidth, 1, -PreviewPadding * 2)
            PreviewName.Position = UDim2.fromOffset(TextLeft, PreviewPadding)
            PreviewName.Size = UDim2.fromOffset(TextWidth, 22)
            PreviewSubtitle.Position = UDim2.fromOffset(TextLeft, PreviewPadding + 24)
            PreviewSubtitle.Size = UDim2.fromOffset(TextWidth, 34)
            Badges.Position = UDim2.fromOffset(TextLeft, PreviewPadding + 62)
            Badges.Size = UDim2.fromOffset(TextWidth, 20)
            Actions.Position = UDim2.new(0, TextLeft, 1, -PreviewPadding)
            Actions.Size = UDim2.fromOffset(TextWidth, Style.ControlHeight)
        end
    end

    local function CardColor(Slot)
        if not Library then
            return Slot.Selected and Color3.fromRGB(39, 43, 51) or Color3.fromRGB(31, 34, 39)
        end
        if Slot.Selected then
            return Library.Scheme.AccentSoftColor
        elseif Slot.Hovered then
            return Library.Scheme.HoverColor
        end
        return Library.Scheme.ElementColor
    end

    local function UpdateSlotState(Slot, Animated)
        Slot.Selected = Slot.Item ~= nil and Slot.Item.Id == Catalog.SelectedId
        local Color = CardColor(Slot)
        if Animated then
            Play(Slot.Button, "Card" .. Slot.Index, { BackgroundColor3 = Color })
        else
            if Library and type(Library.CancelTween) == "function" then
                Library:CancelTween(Slot.Button, "AssetCatalogCard" .. Slot.Index)
                Library:CancelTween(Slot.ImageScale, "AssetCatalogImage" .. Slot.Index)
            end
            for _, Key in { "Card" .. Slot.Index, "Image" .. Slot.Index } do
                if LocalTweens[Key] then
                    LocalTweens[Key]:Cancel()
                    LocalTweens[Key] = nil
                end
            end
            Slot.Button.BackgroundColor3 = Color
        end
        local ItemAccent = Slot.Item and Slot.Item.AccentColor
        local Outline = (Library and Library.Scheme.OutlineColor) or Color3.fromRGB(52, 57, 66)

        if Slot.Selected then
            Slot.Stroke.Color = ItemAccent or (Library and Library.Scheme.AccentColor) or Color3.fromRGB(133, 141, 160)
            Slot.Stroke.Transparency = 0.08
            Slot.Stroke.Thickness = Style.SelectionThickness
        elseif ItemAccent then
            Slot.Stroke.Color = ItemAccent
            Slot.Stroke.Transparency = math.min(Style.OutlineTransparency, 0.34)
            Slot.Stroke.Thickness = math.max(1, Style.StrokeThickness)
        else
            Slot.Stroke.Color = Outline
            Slot.Stroke.Transparency = Style.OutlineTransparency
            Slot.Stroke.Thickness = Style.StrokeThickness
        end
    end

    local function ClearBadges()
        for _, Badge in Catalog.Badges do
            RemoveRegistryTree(Library, Badge)
            Badge:Destroy()
        end
        table.clear(Catalog.Badges)
    end

    local function AddBadge(Text)
        local Badge = Instance.new("TextLabel")
        Badge.AutomaticSize = Enum.AutomaticSize.X
        Badge.BackgroundColor3 = Library and Library.Scheme.ElementColor or Color3.fromRGB(31, 34, 39)
        Badge.BorderSizePixel = 0
        Badge.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
        Badge.Size = UDim2.fromOffset(0, 20)
        Badge.Text = tostring(Text)
        Badge.TextColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(146, 151, 160)
        Badge.TextSize = 11
        Badge.Parent = Badges
        AddRegistry(Library, Badge, {
            BackgroundColor3 = "ElementColor",
            FontFace = "Font",
            TextColor3 = "MutedFontColor",
        })
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, Style.ControlRadius)
        Corner.Parent = Badge
        local BadgePadding = Instance.new("UIPadding")
        BadgePadding.PaddingLeft = UDim.new(0, 7)
        BadgePadding.PaddingRight = UDim.new(0, 7)
        BadgePadding.Parent = Badge
        table.insert(Catalog.Badges, Badge)
    end

    local function SetPreview(Item, Animated)
        if Library and type(Library.CancelTween) == "function" then
            Library:CancelTween(PreviewImageScale, "AssetCatalogPreview")
        end
        if LocalTweens.Preview then
            LocalTweens.Preview:Cancel()
            LocalTweens.Preview = nil
        end
        Catalog.SelectedItem = Item
        ClearBadges()
        if not Item then
            PreviewImage.Image = ""
            PreviewName.Text = tostring(Info.EmptyTitle or "Select an item")
            PreviewSubtitle.Text = tostring(Info.EmptySubtitle or "Choose from the collection")
            PrimaryAction.Text = tostring(Info.ActionText or "Apply")
            SecondaryAction.Text = tostring(Info.SecondaryActionText or "Preview")
            PrimaryAction.Active = false
            SecondaryAction.Active = false
            PrimaryAction.TextTransparency = 0.58
            SecondaryAction.TextTransparency = 0.58
            return
        end
        PreviewImage.Image = NormalizeAsset(Item.PreviewImage)
        PreviewImage.ImageColor3 = Item.Color
        PreviewImage.ImageTransparency = math.clamp(Item.ImageTransparency or Catalog.ImageTransparency, 0, 1)
        PreviewImage.ScaleType = Item.ScaleType and ResolveScaleType(Item.ScaleType) or ImageScaleType
        PreviewImage.Rotation = Item.Rotation or 0
        PreviewImage.Position = Item.ImagePosition or UDim2.fromScale(0.5, 0.5)
        PreviewImage.AnchorPoint = Item.ImageAnchorPoint or Vector2.new(0.5, 0.5)
        PreviewImage.ImageRectOffset = Item.RectOffset
        PreviewImage.ImageRectSize = Item.RectSize
        PreviewImageScale.Scale = math.clamp(Item.ImageScale or 1, 0.2, 4)
        PreviewName.Text = Item.Name
        local Details = Item.Subtitle
        if Item.Price ~= nil then
            Details = Details ~= "" and Details .. "  |  " .. tostring(Item.Price) or tostring(Item.Price)
        end
        PreviewSubtitle.Text = Details
        PrimaryAction.Text = tostring(Item.ActionText or Info.ActionText or "Apply")
        SecondaryAction.Text = tostring(Item.SecondaryActionText or Info.SecondaryActionText or "Preview")
        PrimaryAction.Active = not Item.Disabled and not Item.Locked
        SecondaryAction.Active = not Item.Disabled
        PrimaryAction.TextTransparency = PrimaryAction.Active and 0 or 0.58
        SecondaryAction.TextTransparency = SecondaryAction.Active and 0 or 0.58
        AddBadge(Item.Category)
        if Item.Status ~= nil then
            AddBadge(Item.Status)
        end
        for Index, Badge in Item.Badges do
            if Index > 2 then
                break
            end
            AddBadge(Badge)
        end
        if Animated and Style.Motion then
            PreviewImageScale.Scale = math.max(0.94, PreviewImageScale.Scale - 0.04)
            Play(PreviewImageScale, "Preview", { Scale = math.clamp(Item.ImageScale or 1, 0.2, 4) })
        end
    end

    local function EmitSelection(Item)
        SetPreview(Item, true)
        Call(Catalog.OnSelected, Item and Item.Source or nil, Item)
    end

    local function CreateSlot(Index)
        local Button = Instance.new("TextButton")
        Button.AutoButtonColor = false
        Button.BackgroundColor3 = Library and Library.Scheme.ElementColor or Color3.fromRGB(31, 34, 39)
        Button.BackgroundTransparency = CardTransparency
        Button.BorderSizePixel = 0
        Button.ClipsDescendants = true
        Button.LayoutOrder = Index
        Button.Text = ""
        Button.Visible = false
        Button.Parent = GridScroll

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, Style.CellRadius)
        Corner.Parent = Button

        local Stroke = Instance.new("UIStroke")
        Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Stroke.Color = Library and Library.Scheme.OutlineColor or Color3.fromRGB(52, 57, 66)
        Stroke.Thickness = Style.StrokeThickness
        Stroke.Transparency = Style.OutlineTransparency
        Stroke.Parent = Button

        local Canvas = Instance.new("Frame")
        Canvas.BackgroundColor3 = Library and Library.Scheme.BackgroundColor or Color3.fromRGB(17, 19, 22)
        Canvas.BackgroundTransparency = 0.18
        Canvas.BorderSizePixel = 0
        Canvas.ClipsDescendants = true
        Canvas.Position = UDim2.fromOffset(ImagePadding, ImagePadding)
        Canvas.Size = UDim2.new(1, -ImagePadding * 2, 1, -(LabelHeight + ImagePadding))
        Canvas.Parent = Button

        local CanvasCorner = Instance.new("UICorner")
        CanvasCorner.CornerRadius = UDim.new(0, math.max(0, Style.CellRadius - 1))
        CanvasCorner.Parent = Canvas

        local ImageScale = Instance.new("UIScale")
        ImageScale.Scale = 1

        local Image = Instance.new("ImageLabel")
        Image.AnchorPoint = Vector2.new(0.5, 0.5)
        Image.BackgroundTransparency = 1
        Image.Position = UDim2.fromScale(0.5, 0.5)
        Image.ScaleType = ImageScaleType
        Image.Size = UDim2.new(1, -ImagePadding * 2, 1, -ImagePadding * 2)
        Image.Parent = Canvas
        ImageScale.Parent = Image

        local Name = Instance.new("TextLabel")
        Name.AnchorPoint = Vector2.new(0, 1)
        Name.BackgroundTransparency = 1
        Name.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
        Name.Position = UDim2.fromScale(0, 1)
        Name.Size = UDim2.new(1, 0, 0, LabelHeight)
        Name.TextColor3 = Library and Library.Scheme.FontColor or Color3.fromRGB(238, 240, 244)
        Name.TextSize = Style.CaptionSize
        Name.TextTruncate = Enum.TextTruncate.AtEnd
        Name.Parent = Button

        local State = Instance.new("TextLabel")
        State.AnchorPoint = Vector2.new(1, 0)
        State.AutomaticSize = Enum.AutomaticSize.X
        State.BackgroundColor3 = Library and Library.Scheme.AccentSoftColor or Color3.fromRGB(39, 43, 51)
        State.BorderSizePixel = 0
        State.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.GothamMedium)
        State.Position = UDim2.new(1, -ImagePadding - 4, 0, ImagePadding + 4)
        State.Size = UDim2.fromOffset(0, 18)
        State.Text = ""
        State.TextColor3 = Library and Library.Scheme.FontColor or Color3.fromRGB(238, 240, 244)
        State.TextSize = 10
        State.Visible = false
        State.Parent = Button

        local StateCorner = Instance.new("UICorner")
        StateCorner.CornerRadius = UDim.new(0, Style.ControlRadius)
        StateCorner.Parent = State

        local StatePadding = Instance.new("UIPadding")
        StatePadding.PaddingLeft = UDim.new(0, 5)
        StatePadding.PaddingRight = UDim.new(0, 5)
        StatePadding.Parent = State

        local Slot = {
            Index = Index,
            Button = Button,
            Stroke = Stroke,
            Canvas = Canvas,
            Image = Image,
            ImageScale = ImageScale,
            Name = Name,
            State = State,
            Item = nil,
            Hovered = false,
            Selected = false,
        }
        Catalog.Slots[Index] = Slot
        AddRegistry(Library, Button, { BackgroundColor3 = function() return CardColor(Slot) end })
        AddRegistry(Library, Stroke, {
            Color = function()
                local ItemAccent = Slot.Item and Slot.Item.AccentColor
                if Slot.Selected then
                    return ItemAccent or Library.Scheme.AccentColor
                end
                return ItemAccent or Library.Scheme.OutlineColor
            end,
        })
        AddRegistry(Library, Canvas, { BackgroundColor3 = "BackgroundColor" })
        AddRegistry(Library, Name, { FontFace = "Font", TextColor3 = "FontColor" })
        AddRegistry(Library, State, { BackgroundColor3 = "AccentSoftColor", FontFace = "Font", TextColor3 = "FontColor" })

        table.insert(Catalog.Connections, Button.MouseEnter:Connect(function()
            if Catalog.Destroyed or not Slot.Item then
                return
            end
            Slot.Hovered = true
            UpdateSlotState(Slot, true)
            Play(ImageScale, "Image" .. Index, { Scale = math.clamp((Slot.Item.ImageScale or 1) + 0.025, 0.2, 4) })
        end))
        table.insert(Catalog.Connections, Button.MouseLeave:Connect(function()
            Slot.Hovered = false
            UpdateSlotState(Slot, true)
            Play(ImageScale, "Image" .. Index, { Scale = Slot.Item and math.clamp(Slot.Item.ImageScale or 1, 0.2, 4) or 1 })
        end))
        table.insert(Catalog.Connections, Button.Activated:Connect(function()
            if not Slot.Item or Slot.Item.Disabled then
                return
            end
            Catalog:Select(Slot.Item.Id)
        end))
    end

    for Index = 1, PageSize do
        CreateSlot(Index)
    end

    local function RebuildCategories()
        local Seen = { All = true }
        local List = { "All" }
        for _, Item in Catalog.Items do
            if Item.Category ~= "" and Item.Category ~= "All" and not Seen[Item.Category] then
                Seen[Item.Category] = true
                table.insert(List, Item.Category)
            end
        end
        Catalog.Categories = List
        if not Seen[Catalog.Category] then
            Catalog.Category = "All"
        end
        Category.Text = Catalog.Category
    end

    local function Refresh()
        if Catalog.Destroyed then
            return
        end
        table.clear(Catalog.Filtered)
        local Query = string.lower(Catalog.Search)
        for _, Item in Catalog.Items do
            local CategoryMatch = Catalog.Category == "All" or Item.Category == Catalog.Category
            local SearchMatch = Query == "" or string.find(Item.SearchText, Query, 1, true) ~= nil
            if CategoryMatch and SearchMatch and (not Catalog.FavoritesOnly or Item.Favorite) then
                table.insert(Catalog.Filtered, Item)
            end
        end
        if Catalog.Sort == "Name" then
            table.sort(Catalog.Filtered, function(A, B)
                if A.Name == B.Name then
                    return tostring(A.Id) < tostring(B.Id)
                end
                return A.Name < B.Name
            end)
        end
        Favorites.Text = Catalog.FavoritesOnly and "Saved ✓" or "Saved"
        Sort.Text = Catalog.Sort
        Catalog.PageCount = math.max(1, math.ceil(#Catalog.Filtered / Catalog.PageSize))
        Catalog.Page = math.clamp(Catalog.Page, 1, Catalog.PageCount)
        PageLabel.Text = string.format("%d / %d  ·  %d", Catalog.Page, Catalog.PageCount, #Catalog.Filtered)
        Empty.Visible = #Catalog.Filtered == 0
        GridScroll.Visible = #Catalog.Filtered > 0
        local Start = (Catalog.Page - 1) * Catalog.PageSize
        for SlotIndex, Slot in Catalog.Slots do
            local Item = Catalog.Filtered[Start + SlotIndex]
            Slot.Item = Item
            Slot.Hovered = false
            Slot.Button.Visible = Item ~= nil
            if Item then
                Slot.Button.Active = not Item.Disabled
                Slot.Image.Image = NormalizeAsset(Item.Thumbnail)
                Slot.Image.ImageColor3 = Item.Color
                local ItemTransparency = math.clamp(Item.ImageTransparency or Catalog.ImageTransparency, 0, 1)
                Slot.Image.ImageTransparency = Item.Disabled and math.max(ItemTransparency, 0.58) or ItemTransparency
                Slot.Image.ScaleType = Item.ScaleType and ResolveScaleType(Item.ScaleType) or ImageScaleType
                Slot.Image.Position = Item.ImagePosition or UDim2.fromScale(0.5, 0.5)
                Slot.Image.AnchorPoint = Item.ImageAnchorPoint or Vector2.new(0.5, 0.5)
                Slot.Image.Rotation = Item.Rotation or 0
                Slot.Image.ImageRectOffset = Item.RectOffset
                Slot.Image.ImageRectSize = Item.RectSize
                Slot.ImageScale.Scale = math.clamp(Item.ImageScale or 1, 0.2, 4)
                Slot.Canvas.BackgroundTransparency = math.clamp(Item.BackgroundTransparency or 0.18, 0, 1)
                Slot.Name.Text = Item.Name
                Slot.Name.TextTransparency = Item.Disabled and 0.58 or 0
                Slot.State.Text = Item.Locked and "Locked" or Item.Favorite and "Saved" or tostring(Item.Status or "")
                Slot.State.Visible = Slot.State.Text ~= ""
            end
            UpdateSlotState(Slot, false)
        end
        Previous.TextTransparency = Catalog.Page > 1 and 0 or 0.6
        Next.TextTransparency = Catalog.Page < Catalog.PageCount and 0 or 0.6

        if Catalog.Reveal and Library and type(Library.RevealText) == "function" and Style.Motion then
            Library:RevealText(GridScroll, { Stagger = Catalog.RevealStagger })
        end
    end

    function Catalog:Refresh()
        Refresh()
        return Catalog
    end

    function Catalog:SetItems(Items)
        table.clear(Catalog.Items)
        if type(Items) == "table" then
            for Index, Item in Items do
                local Normalized = NormalizeItem(Item, Index)
                if Normalized then
                    table.insert(Catalog.Items, Normalized)
                end
            end
        end
        RebuildCategories()
        Catalog.Page = 1
        if Catalog.SelectedId ~= nil then
            local Found
            for _, Item in Catalog.Items do
                if Item.Id == Catalog.SelectedId then
                    Found = Item
                    break
                end
            end
            Catalog.SelectedId = Found and Found.Id or nil
            SetPreview(Found, false)
        end
        Refresh()
        return Catalog
    end

    function Catalog:AddItem(Item)
        if Catalog.Destroyed then
            return nil
        end
        local NextIndex = #Catalog.Items + 1
        for _, Existing in Catalog.Items do
            if type(Existing.Id) == "number" then
                NextIndex = math.max(NextIndex, Existing.Id + 1)
            end
        end
        local Normalized = NormalizeItem(Item, NextIndex)
        if not Normalized then
            return nil
        end
        for _, Existing in Catalog.Items do
            if Existing.Id == Normalized.Id then
                return nil
            end
        end
        table.insert(Catalog.Items, Normalized)
        RebuildCategories()
        Refresh()
        return Normalized
    end

    function Catalog:RemoveItem(Id)
        for Index, Item in Catalog.Items do
            if Item.Id == Id then
                table.remove(Catalog.Items, Index)
                if Catalog.SelectedId == Id then
                    Catalog.SelectedId = nil
                    SetPreview(nil, false)
                end
                RebuildCategories()
                Refresh()
                return true
            end
        end
        return false
    end

    function Catalog:SetSearch(Value)
        Catalog.Search = tostring(Value or "")
        if Search.Text ~= Catalog.Search then
            Search.Text = Catalog.Search
        end
        Catalog.Page = 1
        Refresh()
        return Catalog
    end

    function Catalog:SetCategory(Value)
        local Name = tostring(Value or "All")
        Catalog.Category = table.find(Catalog.Categories, Name) and Name or "All"
        Category.Text = Catalog.Category
        Catalog.Page = 1
        Refresh()
        return Catalog
    end

    function Catalog:SetPage(Value)
        Catalog.Page = math.clamp(math.floor(tonumber(Value) or Catalog.Page), 1, Catalog.PageCount)
        Refresh()
        return Catalog
    end

    function Catalog:SetFavoritesOnly(Value)
        Catalog.FavoritesOnly = Value == true
        Catalog.Page = 1
        Refresh()
        return Catalog
    end

    function Catalog:SetSort(Value)
        Catalog.Sort = Value == "Name" and "Name" or "Original"
        Catalog.Page = 1
        Refresh()
        return Catalog
    end

    function Catalog:SetColumns(Value)
        if Value == nil then
            AutoColumns = true
        else
            AutoColumns = false
            Columns = math.clamp(math.floor(tonumber(Value) or Columns), 1, 8)
            Catalog.Columns = Columns
        end
        ResolveGridMetrics()
        return Catalog
    end

    function Catalog:SetMinCellWidth(Value)
        MinCellWidth = math.clamp(math.floor(tonumber(Value) or MinCellWidth), 64, 400)
        Catalog.MinCellWidth = MinCellWidth
        AutoColumns = true
        ResolveGridMetrics()
        return Catalog
    end

    function Catalog:SetCellHeight(Value)
        Catalog.CellHeight = math.clamp(math.floor(tonumber(Value) or Catalog.CellHeight), 64, 220)
        ImagePadding = math.min(
            ImagePadding,
            math.max(0, math.min(30, math.floor((Catalog.CellHeight - LabelHeight - 8) * 0.5)))
        )
        Catalog.ImagePadding = ImagePadding
        CellHeight = Catalog.CellHeight
        ResolveGridMetrics()
        for _, Slot in Catalog.Slots do
            Slot.Canvas.Position = UDim2.fromOffset(ImagePadding, ImagePadding)
            Slot.Canvas.Size = UDim2.new(1, -ImagePadding * 2, 1, -(LabelHeight + ImagePadding))
            Slot.Image.Size = UDim2.new(1, -ImagePadding * 2, 1, -ImagePadding * 2)
        end
        return Catalog
    end

    function Catalog:SetLayout(Value, Side)
        Catalog.Layout = string.lower(tostring(Value or "Split"))
        if Side ~= nil then
            Catalog.PreviewSide = string.lower(tostring(Side))
        end
        SetPanelLayout()
        return Catalog
    end

    function Catalog:SetPreviewRatio(Value)
        Catalog.PreviewRatio = math.clamp(tonumber(Value) or Catalog.PreviewRatio, 0.3, 0.8)
        SetPanelLayout()
        return Catalog
    end

    function Catalog:SetPreviewSide(Value)
        Catalog.PreviewSide = string.lower(tostring(Value or Catalog.PreviewSide)) == "left" and "left" or "right"
        SetPanelLayout()
        return Catalog
    end

    function Catalog:SetScaleType(Value)
        ImageScaleType = ResolveScaleType(Value)
        Catalog.ScaleType = ImageScaleType
        for _, Slot in Catalog.Slots do
            if Slot.Item and Slot.Item.ScaleType == nil then
                Slot.Image.ScaleType = ImageScaleType
            end
        end
        if Catalog.SelectedItem and Catalog.SelectedItem.ScaleType == nil then
            PreviewImage.ScaleType = ImageScaleType
        end
        return Catalog
    end

    function Catalog:SetImagePadding(Value)
        local Maximum = math.max(0, math.min(30, math.floor((Catalog.CellHeight - LabelHeight - 8) * 0.5)))
        ImagePadding = math.clamp(math.floor(tonumber(Value) or ImagePadding), 0, Maximum)
        Catalog.ImagePadding = ImagePadding
        for _, Slot in Catalog.Slots do
            Slot.Canvas.Position = UDim2.fromOffset(ImagePadding, ImagePadding)
            Slot.Canvas.Size = UDim2.new(1, -ImagePadding * 2, 1, -(LabelHeight + ImagePadding))
            Slot.Image.Size = UDim2.new(1, -ImagePadding * 2, 1, -ImagePadding * 2)
        end
        return Catalog
    end

    function Catalog:SetPreviewPadding(Value)
        PreviewPadding = math.clamp(math.floor(tonumber(Value) or PreviewPadding), 0, 30)
        Catalog.PreviewPadding = PreviewPadding
        PreviewCanvas.Position = UDim2.fromOffset(PreviewPadding, PreviewPadding)
        PreviewImage.Size = UDim2.new(1, -PreviewPadding * 2, 1, -PreviewPadding * 2)
        SetPanelLayout()
        return Catalog
    end

    function Catalog:SetImageTransparency(Value)
        Catalog.ImageTransparency = math.clamp(tonumber(Value) or Catalog.ImageTransparency, 0, 1)
        Refresh()
        SetPreview(Catalog.SelectedItem, false)
        return Catalog
    end

    function Catalog:SetCardTransparency(Value)
        Catalog.CardTransparency = math.clamp(tonumber(Value) or Catalog.CardTransparency, 0, 1)
        for _, Slot in Catalog.Slots do
            Slot.Button.BackgroundTransparency = Catalog.CardTransparency
        end
        return Catalog
    end

    function Catalog:SetPreviewTransparency(Value)
        Catalog.PreviewTransparency = math.clamp(tonumber(Value) or Catalog.PreviewTransparency, 0, 1)
        PreviewPanel.BackgroundTransparency = Catalog.PreviewTransparency
        return Catalog
    end

    function Catalog:Select(Id, Silent)
        local Selected
        for _, Item in Catalog.Items do
            if Item.Id == Id or Item.Source == Id then
                Selected = Item
                break
            end
        end
        Catalog.SelectedId = Selected and Selected.Id or nil
        for _, Slot in Catalog.Slots do
            UpdateSlotState(Slot, true)
        end
        if Silent then
            SetPreview(Selected, false)
        else
            EmitSelection(Selected)
        end
        return Selected and Selected.Source or nil
    end

    function Catalog:GetSelected()
        return Catalog.SelectedItem and Catalog.SelectedItem.Source or nil, Catalog.SelectedItem
    end

    function Catalog:SetVisible(Value)
        Catalog.Visible = Value == true
        Root.Visible = Catalog.Visible
        if Catalog.Element then
            Catalog.Element:SetVisible(Catalog.Visible)
        end
        return Catalog
    end

    function Catalog:SetHeight(Value)
        Catalog.Height = math.clamp(math.floor(tonumber(Value) or Catalog.Height), 260, 900)
        Height = Catalog.Height
        Root.Size = UDim2.new(1, 0, 0, Catalog.Height)
        if Catalog.Element then
            Catalog.Element:SetHeight(Catalog.Height)
        end
        SetPanelLayout()
        return Catalog
    end

    function Catalog:Mount(Parent)
        if Catalog.Destroyed or typeof(Parent) ~= "Instance" or not Parent:IsA("GuiBase2d") then
            return false
        end
        Root.Parent = Parent
        return true
    end

    function Catalog:Destroy()
        if Catalog.Destroyed then
            return
        end
        Catalog.Destroyed = true
        if Catalog.StyleController then
            Catalog.StyleController:Destroy()
            Catalog.StyleController = nil
        end
        for Key, Tween in LocalTweens do
            Tween:Cancel()
            LocalTweens[Key] = nil
        end
        if Library and type(Library.CancelTween) == "function" then
            Library:CancelTween(PreviewImageScale, "AssetCatalogPreview")
            for _, Slot in Catalog.Slots do
                Library:CancelTween(Slot.Button, "AssetCatalogCard" .. Slot.Index)
                Library:CancelTween(Slot.ImageScale, "AssetCatalogImage" .. Slot.Index)
            end
        end
        for _, Connection in Catalog.Connections do
            pcall(function()
                Connection:Disconnect()
            end)
        end
        table.clear(Catalog.Connections)
        ClearBadges()
        RemoveRegistryTree(Library, Root)
        if Catalog.Element then
            Catalog.Element:Destroy()
            Catalog.Element = nil
        elseif Root then
            Root:Destroy()
        end
    end

    local SearchToken = 0
    table.insert(Catalog.Connections, Search:GetPropertyChangedSignal("Text"):Connect(function()
        SearchToken += 1
        local Token = SearchToken
        task.delay(0.08, function()
            if not Catalog.Destroyed and Token == SearchToken then
                Catalog.Search = Search.Text
                Catalog.Page = 1
                Refresh()
            end
        end)
    end))
    table.insert(Catalog.Connections, Category.Activated:Connect(function()
        local Index = table.find(Catalog.Categories, Catalog.Category) or 1
        Catalog:SetCategory(Catalog.Categories[Index % #Catalog.Categories + 1])
    end))
    table.insert(Catalog.Connections, Favorites.Activated:Connect(function()
        Catalog:SetFavoritesOnly(not Catalog.FavoritesOnly)
    end))
    table.insert(Catalog.Connections, Sort.Activated:Connect(function()
        Catalog:SetSort(Catalog.Sort == "Name" and "Original" or "Name")
    end))
    table.insert(Catalog.Connections, Previous.Activated:Connect(function()
        Catalog:SetPage(Catalog.Page - 1)
    end))
    table.insert(Catalog.Connections, Next.Activated:Connect(function()
        Catalog:SetPage(Catalog.Page + 1)
    end))
    table.insert(Catalog.Connections, PrimaryAction.Activated:Connect(function()
        local Item = Catalog.SelectedItem
        if not Item or Item.Disabled or Item.Locked then
            return
        end
        local Callback = type(Item.OnAction) == "function" and Item.OnAction or Catalog.OnAction
        Call(Callback, Item.Source, Item)
    end))
    table.insert(Catalog.Connections, SecondaryAction.Activated:Connect(function()
        local Item = Catalog.SelectedItem
        if not Item or Item.Disabled then
            return
        end
        local Callback = type(Item.OnSecondaryAction) == "function" and Item.OnSecondaryAction or Catalog.OnSecondaryAction
        Call(Callback, Item.Source, Item)
    end))

    if typeof(Info.Parent) == "Instance" and Info.Parent:IsA("GuiObject") then
        Root.Parent = Info.Parent
    end
    SetPanelLayout()
    table.insert(Catalog.Connections, Body:GetPropertyChangedSignal("AbsoluteSize"):Connect(SetPanelLayout))
    Catalog:SetItems(Info.Items or {})
    if Info.Category then
        Catalog:SetCategory(Info.Category)
    end
    if Info.Selected ~= nil then
        Catalog:Select(Info.Selected, true)
    end
    if Info.Model then
        Catalog.ModelBinding = Info.Model:Bind(Catalog)
    end
    if Library and type(Library.OnUnload) == "function" then
        Library:OnUnload(function()
            Catalog:Destroy()
        end)
    end
    if Library and type(Library.BindAddonStyle) == "function" then
        Catalog.StyleController = Library:BindAddonStyle(Root, Style, Info, true)
        function Catalog:SetStyle(Overrides)
            Catalog.StyleController:Set(Overrides)
            return Catalog
        end
        function Catalog:SetMinimal(Enabled)
            Catalog.StyleController:SetMinimal(Enabled)
            return Catalog
        end
        function Catalog:SetHighlighted(Enabled)
            Catalog.StyleController:SetHighlighted(Enabled)
            return Catalog
        end
    end
    return Catalog
end

function AssetCatalog.CreateEmbedded(Library, Groupbox, Idx, Info)
    assert(type(Groupbox) == "table" and type(Groupbox.AddUIPassthrough) == "function", "AssetCatalog requires a groupbox")
    Info = table.clone(Info or {})
    Info.Layout = Info.Layout or "Stack"
    local Catalog = AssetCatalog.Create(Library, Info)
    Catalog.Element = Groupbox:AddUIPassthrough(Idx or "AssetCatalog", {
        Instance = Catalog.Root,
        Height = Catalog.Height,
        Visible = Catalog.Visible,
    })
    return Catalog
end

function AssetCatalog.CreateStandalone(Library, Info)
    assert(Library and type(Library.CreateAddonWindow) == "function", "AssetCatalog standalone mode requires Library:CreateAddonWindow")
    Info = table.clone(Info or {})
    local Host = Library:CreateAddonWindow({
        Title = Info.WindowTitle or "Collection",
        Subtitle = Info.WindowSubtitle or Info.Subtitle,
        Icon = Info.WindowIcon or Info.Icon or "layout-grid",
        Width = Info.WindowWidth or 760,
        Height = Info.WindowHeight or 560,
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
    Info.Height = Info.Height or math.max(300, (Info.WindowHeight or 560) - 74)
    Info.Layout = Info.Layout or "Split"
    local Catalog = Host:AddAddon("Catalog", AssetCatalog, Info)
    Catalog.Host = Host
    return Catalog, Host
end

AssetCatalog.Mount = AssetCatalog.CreateEmbedded

return AssetCatalog
