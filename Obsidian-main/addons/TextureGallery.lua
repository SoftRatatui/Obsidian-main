local TextureGallery = {
    ReleaseVersion = "0.0.1-release-6",
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

local function ApplyCorner(Object, Radius)
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, Radius)
    Corner.Parent = Object
    return Corner
end

function TextureGallery.Create(Library, Info)
    assert(Library and type(Library.AddToRegistry) == "function", "TextureGallery requires MonHub Library")
    Info = Info or {}

    local Gallery = {
        Height = math.clamp(tonumber(Info.Height) or 292, 210, 520),
        Columns = math.clamp(math.floor(tonumber(Info.Columns) or 2), 1, 3),
        Items = {},
        Cards = {},
        Selected = nil,
        Visible = Info.Visible ~= false,
        Destroyed = false,
        Connections = {},
    }

    local Root = Instance.new("Frame")
    Root.Name = "MonHubTextureGallery"
    Root.BackgroundTransparency = 1
    Root.Size = UDim2.fromScale(1, 1)
    Root.Visible = Gallery.Visible
    Gallery.Root = Root

    local Preview = Instance.new("Frame")
    Preview.BackgroundColor3 = Library.Scheme.ElementColor
    Preview.BorderSizePixel = 0
    Preview.ClipsDescendants = true
    Preview.Size = UDim2.new(1, 0, 0, 76)
    Preview.Parent = Root
    ApplyCorner(Preview, math.min((Library.CornerRadius or 6) + 1, 8))
    Library:AddToRegistry(Preview, { BackgroundColor3 = "ElementColor" })

    local PreviewStroke = Instance.new("UIStroke")
    PreviewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    PreviewStroke.Color = Library.Scheme.OutlineColor
    PreviewStroke.Transparency = 0.18
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
    PreviewImage.ImageTransparency = 0.05
    PreviewImage.Position = UDim2.new(0.5, 0, 0.5, -4)
    PreviewImage.ScaleType = Enum.ScaleType.Stretch
    PreviewImage.Size = UDim2.new(1, -24, 0, 34)
    PreviewImage.Parent = Preview

    local PreviewGradient = Instance.new("UIGradient")
    PreviewGradient.Color = ColorSequence.new(Color3.fromRGB(168, 181, 199), Color3.fromRGB(105, 116, 133))
    PreviewGradient.Parent = PreviewImage

    local PreviewName = Instance.new("TextLabel")
    PreviewName.AnchorPoint = Vector2.new(0.5, 1)
    PreviewName.BackgroundTransparency = 1
    PreviewName.FontFace = Library.Scheme.Font
    PreviewName.Position = UDim2.new(0.5, 0, 1, -7)
    PreviewName.Size = UDim2.new(1, -20, 0, 18)
    PreviewName.Text = "Select texture"
    PreviewName.TextColor3 = Library.Scheme.MutedFontColor
    PreviewName.TextSize = 12
    PreviewName.Parent = Preview
    Library:AddToRegistry(PreviewName, { FontFace = "Font", TextColor3 = "MutedFontColor" })

    local Grid = Instance.new("ScrollingFrame")
    Grid.Active = true
    Grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Grid.BackgroundTransparency = 1
    Grid.BorderSizePixel = 0
    Grid.CanvasSize = UDim2.fromScale(0, 0)
    Grid.Position = UDim2.fromOffset(0, 86)
    Grid.ScrollBarImageColor3 = Library.Scheme.AccentColor
    Grid.ScrollBarImageTransparency = 0.35
    Grid.ScrollBarThickness = 2
    Grid.ScrollingDirection = Enum.ScrollingDirection.Y
    Grid.Size = UDim2.new(1, 0, 1, -86)
    Grid.Parent = Root
    Library:AddToRegistry(Grid, { ScrollBarImageColor3 = "AccentColor" })

    local GridLayout = Instance.new("UIGridLayout")
    GridLayout.CellPadding = UDim2.fromOffset(8, 8)
    GridLayout.CellSize = UDim2.new(1 / Gallery.Columns, -6, 0, 64)
    GridLayout.FillDirectionMaxCells = Gallery.Columns
    GridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    GridLayout.Parent = Grid

    local GridPadding = Instance.new("UIPadding")
    GridPadding.PaddingBottom = UDim.new(0, 2)
    GridPadding.PaddingLeft = UDim.new(0, 1)
    GridPadding.PaddingRight = UDim.new(0, 3)
    GridPadding.Parent = Grid

    local function DisconnectAll()
        for _, Connection in Gallery.Connections do
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end
        table.clear(Gallery.Connections)
    end

    local function UpdateSelection()
        for Item, Card in Gallery.Cards do
            local Selected = Item == Gallery.Selected
            Card.Stroke.Color = Selected and Library.Scheme.AccentColor or Library.Scheme.OutlineColor
            Card.Stroke.Transparency = Selected and 0 or 0.24
            Card.Name.TextColor3 = Selected and Library.Scheme.FontColor or Library.Scheme.MutedFontColor
        end
        local Item = Gallery.Selected
        if not Item then
            PreviewImage.Image = ""
            PreviewName.Text = "Select texture"
            PreviewGradient.Color = ColorSequence.new(Library.Scheme.AccentColor, Library.Scheme.MutedFontColor)
            PreviewTrackGradient.Color = PreviewGradient.Color
            return
        end
        PreviewImage.Image = NormalizeAsset(Item.Texture or Item.AssetId or Item.Image)
        PreviewName.Text = tostring(Item.Name or Item.Id or "Texture")
        local ColorA = typeof(Item.ColorA) == "Color3" and Item.ColorA or Library.Scheme.AccentColor
        local ColorB = typeof(Item.ColorB) == "Color3" and Item.ColorB or Library.Scheme.FontColor
        PreviewGradient.Color = ColorSequence.new(ColorA, ColorB)
        PreviewTrackGradient.Color = PreviewGradient.Color
    end

    local function ClearCards()
        DisconnectAll()
        for _, Card in Gallery.Cards do
            if Card.Root then
                RemoveRegistryTree(Library, Card.Root)
                Card.Root:Destroy()
            end
        end
        table.clear(Gallery.Cards)
    end

    local function CreateCard(Item, Index)
        local Button = Instance.new("TextButton")
        Button.AutoButtonColor = false
        Button.BackgroundColor3 = Library.Scheme.ElementColor
        Button.BorderSizePixel = 0
        Button.LayoutOrder = Index
        Button.Size = UDim2.fromScale(1, 1)
        Button.Text = ""
        Button.Parent = Grid
        ApplyCorner(Button, math.min(Library.CornerRadius or 6, 6))
        Library:AddToRegistry(Button, { BackgroundColor3 = "ElementColor" })

        local Stroke = Instance.new("UIStroke")
        Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Stroke.Color = Library.Scheme.OutlineColor
        Stroke.Transparency = 0.24
        Stroke.Parent = Button
        Library:AddToRegistry(Stroke, {
            Color = function()
                return Gallery.Selected == Item and Library.Scheme.AccentColor or Library.Scheme.OutlineColor
            end,
        })

        local Track = Instance.new("Frame")
        Track.AnchorPoint = Vector2.new(0.5, 0.5)
        Track.BackgroundColor3 = Color3.new(1, 1, 1)
        Track.BorderSizePixel = 0
        Track.Position = UDim2.new(0.5, 0, 0, 23)
        Track.Size = UDim2.new(1, -18, 0, 5)
        Track.Parent = Button
        ApplyCorner(Track, 3)

        local TrackGradient = Instance.new("UIGradient")
        TrackGradient.Color = ColorSequence.new(
            typeof(Item.ColorA) == "Color3" and Item.ColorA or Library.Scheme.AccentColor,
            typeof(Item.ColorB) == "Color3" and Item.ColorB or Library.Scheme.FontColor
        )
        TrackGradient.Parent = Track

        local Image = Instance.new("ImageLabel")
        Image.BackgroundTransparency = 1
        Image.Image = NormalizeAsset(Item.Texture or Item.AssetId or Item.Image)
        Image.ImageColor3 = Color3.new(1, 1, 1)
        Image.ImageTransparency = 0.04
        Image.Position = UDim2.fromOffset(8, 8)
        Image.ScaleType = Enum.ScaleType.Stretch
        Image.Size = UDim2.new(1, -16, 0, 28)
        Image.Parent = Button

        local Gradient = Instance.new("UIGradient")
        Gradient.Color = ColorSequence.new(
            typeof(Item.ColorA) == "Color3" and Item.ColorA or Library.Scheme.AccentColor,
            typeof(Item.ColorB) == "Color3" and Item.ColorB or Library.Scheme.FontColor
        )
        Gradient.Parent = Image

        local Name = Instance.new("TextLabel")
        Name.AnchorPoint = Vector2.new(0, 1)
        Name.BackgroundTransparency = 1
        Name.FontFace = Library.Scheme.Font
        Name.Position = UDim2.new(0, 8, 1, -5)
        Name.Size = UDim2.new(1, -16, 0, 17)
        Name.Text = tostring(Item.Name or Item.Id or "Texture")
        Name.TextColor3 = Library.Scheme.MutedFontColor
        Name.TextSize = 12
        Name.TextTruncate = Enum.TextTruncate.AtEnd
        Name.TextXAlignment = Enum.TextXAlignment.Left
        Name.Parent = Button
        Library:AddToRegistry(Name, {
            FontFace = "Font",
            TextColor3 = function()
                return Gallery.Selected == Item and Library.Scheme.FontColor or Library.Scheme.MutedFontColor
            end,
        })

        Gallery.Cards[Item] = {
            Root = Button,
            Stroke = Stroke,
            Name = Name,
        }

        table.insert(Gallery.Connections, Button.MouseEnter:Connect(function()
            if Gallery.Destroyed then
                return
            end
            Library:PlayTween(Button, "TextureHover", Library.HoverTweenInfo or Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.HoverColor,
            })
        end))
        table.insert(Gallery.Connections, Button.MouseLeave:Connect(function()
            if Gallery.Destroyed then
                return
            end
            Library:PlayTween(Button, "TextureHover", Library.HoverTweenInfo or Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.ElementColor,
            })
        end))
        table.insert(Gallery.Connections, Button.MouseButton1Click:Connect(function()
            Gallery:Select(Item)
        end))
    end

    function Gallery:SetItems(Items)
        if Gallery.Destroyed then
            return Gallery
        end
        ClearCards()
        Gallery.Items = type(Items) == "table" and table.clone(Items) or {}
        Gallery.Selected = nil
        for Index, Item in Gallery.Items do
            if type(Item) == "table" then
                CreateCard(Item, Index)
            end
        end
        UpdateSelection()
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
        UpdateSelection()
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
        GridLayout.FillDirectionMaxCells = Gallery.Columns
        GridLayout.CellSize = UDim2.new(1 / Gallery.Columns, -6, 0, 64)
        return Gallery
    end

    function Gallery:Mount(Parent, Height)
        if typeof(Parent) ~= "Instance" or not Parent:IsA("GuiBase2d") then
            return false
        end
        Root.Parent = Parent
        Root.Size = UDim2.new(1, 0, 0, math.max(1, tonumber(Height) or Gallery.Height))
        return true
    end

    function Gallery:Destroy()
        if Gallery.Destroyed then
            return
        end
        Gallery.Destroyed = true
        ClearCards()
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

return TextureGallery
