local TweenService = game:GetService("TweenService")

local ImageGallery = {}

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
        Category = Category,
        Subtitle = tostring(Item.Subtitle or Item.Description or ""),
        Disabled = Item.Disabled == true,
        SearchText = string.lower(string.format("%s %s %s", Name, Category, Tags)),
        Source = Item,
    }
end

function ImageGallery.Create(Library, Info)
    Info = Info or {}
    local Height = math.clamp(math.floor(tonumber(Info.Height) or 344), 180, 780)
    local Columns = math.clamp(math.floor(tonumber(Info.Columns) or 5), 1, 10)
    local PageSize = math.clamp(math.floor(tonumber(Info.PageSize) or 15), Columns, 60)
    local CellHeight = math.clamp(math.floor(tonumber(Info.CellHeight) or 78), 52, 150)
    local Gap = math.clamp(math.floor(tonumber(Info.Gap) or 6), 2, 14)
    local ScaleType = ResolveScaleType(Info.ScaleType)

    local Root = Instance.new("Frame")
    Root.Name = "MonHubImageGallery"
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

    local Stroke = Instance.new("UIStroke")
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Color = Library and Library.Scheme.OutlineColor or Color3.fromRGB(52, 57, 66)
    Stroke.Transparency = 0.22
    Stroke.Parent = Root
    AddRegistry(Library, Stroke, { Color = "OutlineColor" })

    local Header = Instance.new("Frame")
    Header.BackgroundColor3 = Library and (Library.Scheme.RaisedColor or Library.Scheme.SurfaceColor) or Color3.fromRGB(22, 24, 29)
    Header.BorderSizePixel = 0
    Header.Size = UDim2.new(1, 0, 0, 36)
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
    HeaderLine.Parent = Header
    AddRegistry(Library, HeaderLine, { BackgroundColor3 = "OutlineColor" })

    local CategoryButton = Instance.new("TextButton")
    CategoryButton.AutoButtonColor = false
    CategoryButton.BackgroundColor3 = Library and Library.Scheme.ElementColor or Color3.fromRGB(29, 32, 38)
    CategoryButton.BorderSizePixel = 0
    CategoryButton.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.Gotham)
    CategoryButton.Position = UDim2.fromOffset(7, 6)
    CategoryButton.Size = UDim2.fromOffset(104, 24)
    CategoryButton.Text = "All"
    CategoryButton.TextColor3 = Library and Library.Scheme.FontColor or Color3.fromRGB(232, 235, 240)
    CategoryButton.TextSize = 11
    CategoryButton.TextTruncate = Enum.TextTruncate.AtEnd
    CategoryButton.Parent = Header
    AddRegistry(Library, CategoryButton, {
        BackgroundColor3 = "ElementColor",
        FontFace = "Font",
        TextColor3 = "FontColor",
    })

    local CategoryCorner = Instance.new("UICorner")
    CategoryCorner.CornerRadius = UDim.new(0, 4)
    CategoryCorner.Parent = CategoryButton

    local Search = Instance.new("TextBox")
    Search.BackgroundColor3 = Library and Library.Scheme.ElementColor or Color3.fromRGB(29, 32, 38)
    Search.BorderSizePixel = 0
    Search.ClearTextOnFocus = false
    Search.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.Gotham)
    Search.PlaceholderColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(143, 149, 158)
    Search.PlaceholderText = tostring(Info.SearchPlaceholder or "Search assets")
    Search.Position = UDim2.fromOffset(117, 6)
    Search.Size = UDim2.new(1, -124, 0, 24)
    Search.Text = ""
    Search.TextColor3 = Library and Library.Scheme.FontColor or Color3.fromRGB(232, 235, 240)
    Search.TextSize = 11
    Search.TextXAlignment = Enum.TextXAlignment.Left
    Search.Parent = Header
    AddRegistry(Library, Search, {
        BackgroundColor3 = "ElementColor",
        FontFace = "Font",
        PlaceholderColor3 = "MutedFontColor",
        TextColor3 = "FontColor",
    })

    local SearchCorner = Instance.new("UICorner")
    SearchCorner.CornerRadius = UDim.new(0, 4)
    SearchCorner.Parent = Search

    local SearchPadding = Instance.new("UIPadding")
    SearchPadding.PaddingLeft = UDim.new(0, 8)
    SearchPadding.PaddingRight = UDim.new(0, 8)
    SearchPadding.Parent = Search

    local GridHolder = Instance.new("Frame")
    GridHolder.BackgroundTransparency = 1
    GridHolder.ClipsDescendants = true
    GridHolder.Position = UDim2.fromOffset(7, 43)
    GridHolder.Size = UDim2.new(1, -14, 1, -76)
    GridHolder.Parent = Root

    local Grid = Instance.new("UIGridLayout")
    Grid.CellPadding = UDim2.fromOffset(Gap, Gap)
    Grid.CellSize = UDim2.new(1 / Columns, -math.ceil(Gap * (Columns - 1) / Columns), 0, CellHeight)
    Grid.FillDirectionMaxCells = Columns
    Grid.SortOrder = Enum.SortOrder.LayoutOrder
    Grid.Parent = GridHolder

    local Footer = Instance.new("Frame")
    Footer.AnchorPoint = Vector2.new(0, 1)
    Footer.BackgroundColor3 = Library and (Library.Scheme.RaisedColor or Library.Scheme.SurfaceColor) or Color3.fromRGB(22, 24, 29)
    Footer.BorderSizePixel = 0
    Footer.Position = UDim2.fromScale(0, 1)
    Footer.Size = UDim2.new(1, 0, 0, 27)
    Footer.Parent = Root
    AddRegistry(Library, Footer, {
        BackgroundColor3 = function()
            return Library.Scheme.RaisedColor or Library.Scheme.SurfaceColor
        end,
    })

    local FooterLine = Instance.new("Frame")
    FooterLine.BackgroundColor3 = Library and Library.Scheme.OutlineColor or Color3.fromRGB(52, 57, 66)
    FooterLine.BorderSizePixel = 0
    FooterLine.Size = UDim2.new(1, 0, 0, 1)
    FooterLine.Parent = Footer
    AddRegistry(Library, FooterLine, { BackgroundColor3 = "OutlineColor" })

    local PreviousButton = Instance.new("TextButton")
    PreviousButton.AutoButtonColor = false
    PreviousButton.BackgroundTransparency = 1
    PreviousButton.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.Gotham)
    PreviousButton.Size = UDim2.fromOffset(44, 26)
    PreviousButton.Text = "Prev"
    PreviousButton.TextColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(143, 149, 158)
    PreviousButton.TextSize = 11
    PreviousButton.Parent = Footer
    AddRegistry(Library, PreviousButton, {
        FontFace = "Font",
        TextColor3 = "MutedFontColor",
    })

    local PageLabel = Instance.new("TextLabel")
    PageLabel.BackgroundTransparency = 1
    PageLabel.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.Gotham)
    PageLabel.Position = UDim2.new(0, 44, 0, 0)
    PageLabel.Size = UDim2.new(1, -88, 1, 0)
    PageLabel.Text = "1 / 1"
    PageLabel.TextColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(143, 149, 158)
    PageLabel.TextSize = 11
    PageLabel.Parent = Footer
    AddRegistry(Library, PageLabel, {
        FontFace = "Font",
        TextColor3 = "MutedFontColor",
    })

    local NextButton = Instance.new("TextButton")
    NextButton.AnchorPoint = Vector2.new(1, 0)
    NextButton.AutoButtonColor = false
    NextButton.BackgroundTransparency = 1
    NextButton.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.Gotham)
    NextButton.Position = UDim2.fromScale(1, 0)
    NextButton.Size = UDim2.fromOffset(44, 26)
    NextButton.Text = "Next"
    NextButton.TextColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(143, 149, 158)
    NextButton.TextSize = 11
    NextButton.Parent = Footer
    AddRegistry(Library, NextButton, {
        FontFace = "Font",
        TextColor3 = "MutedFontColor",
    })

    local Empty = Instance.new("TextLabel")
    Empty.BackgroundTransparency = 1
    Empty.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.Gotham)
    Empty.Position = UDim2.fromOffset(12, 43)
    Empty.Size = UDim2.new(1, -24, 1, -76)
    Empty.Text = tostring(Info.EmptyText or "No matching assets")
    Empty.TextColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(143, 149, 158)
    Empty.TextSize = 12
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
        PageLabel = PageLabel,
        Grid = Grid,
        Slots = {},
        Items = {},
        Filtered = {},
        Categories = { "All" },
        Connections = {},
        Element = nil,
        Preview = Info.Preview,
        SelectedId = nil,
        Search = "",
        Category = "All",
        Page = 1,
        PageCount = 1,
        PageSize = PageSize,
        Columns = Columns,
        Height = Height,
        Visible = Info.Visible ~= false,
        Destroyed = false,
        OnSelected = Info.OnSelected or Info.Callback,
    }

    local function Play(Object, Key, Properties)
        if Library and type(Library.PlayTween) == "function" then
            Library:PlayTween(Object, "ImageGallery" .. tostring(Key), TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), Properties)
            return
        end
        local Success, Tween = pcall(function()
            return TweenService:Create(Object, TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), Properties)
        end)
        if Success and Tween then
            Tween.Completed:Once(function()
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
            Slot.Button.BackgroundColor3 = Color
        end
        Slot.Stroke.Color = Slot.Selected and (Library and Library.Scheme.AccentColor or Color3.fromRGB(123, 149, 183)) or (Library and Library.Scheme.OutlineColor or Color3.fromRGB(52, 57, 66))
        Slot.Stroke.Transparency = Slot.Selected and 0.05 or 0.38
    end

    local function BindPreview(Item)
        local Preview = Gallery.Preview
        if type(Preview) ~= "table" then
            return
        end
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
            return
        end
        if type(Preview.SetImage) == "function" then
            Preview:SetImage(Item.PreviewImage)
        end
        if type(Preview.SetImageColor) == "function" then
            Preview:SetImageColor(Item.Color)
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

    for Index = 1, PageSize do
        local Button = Instance.new("TextButton")
        Button.AutoButtonColor = false
        Button.BackgroundColor3 = Library and Library.Scheme.ElementColor or Color3.fromRGB(27, 30, 35)
        Button.BorderSizePixel = 0
        Button.ClipsDescendants = true
        Button.LayoutOrder = Index
        Button.Text = ""
        Button.Visible = false
        Button.Parent = GridHolder

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 4)
        Corner.Parent = Button

        local CellStroke = Instance.new("UIStroke")
        CellStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        CellStroke.Color = Library and Library.Scheme.OutlineColor or Color3.fromRGB(52, 57, 66)
        CellStroke.Transparency = 0.38
        CellStroke.Parent = Button

        local Image = Instance.new("ImageLabel")
        Image.BackgroundColor3 = Library and Library.Scheme.BackgroundColor or Color3.fromRGB(11, 13, 16)
        Image.BorderSizePixel = 0
        Image.Image = ""
        Image.Position = UDim2.fromOffset(5, 5)
        Image.ScaleType = ScaleType
        Image.Size = UDim2.new(1, -10, 1, -27)
        Image.Parent = Button
        AddRegistry(Library, Image, { BackgroundColor3 = "BackgroundColor" })

        local Name = Instance.new("TextLabel")
        Name.AnchorPoint = Vector2.new(0, 1)
        Name.BackgroundTransparency = 1
        Name.FontFace = Library and Library.Scheme.Font or Font.fromEnum(Enum.Font.Gotham)
        Name.Position = UDim2.fromScale(0, 1)
        Name.Size = UDim2.new(1, 0, 0, 22)
        Name.Text = ""
        Name.TextColor3 = Library and Library.Scheme.MutedFontColor or Color3.fromRGB(143, 149, 158)
        Name.TextSize = 10
        Name.TextTruncate = Enum.TextTruncate.AtEnd
        Name.Parent = Button
        AddRegistry(Library, Name, {
            FontFace = "Font",
            TextColor3 = "MutedFontColor",
        })

        local Slot = {
            Index = Index,
            Button = Button,
            Image = Image,
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
        table.insert(Gallery.Connections, Button.Activated:Connect(function()
            if Gallery.Destroyed or not Slot.Item or Slot.Item.Disabled then
                return
            end
            Gallery.SelectedId = Slot.Item.Id
            for _, Other in Gallery.Slots do
                UpdateSlotState(Other, true)
            end
            EmitSelection(Slot.Item)
        end))
    end

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

    local function Refresh()
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

        Gallery.PageCount = math.max(1, math.ceil(#Gallery.Filtered / Gallery.PageSize))
        Gallery.Page = math.clamp(Gallery.Page, 1, Gallery.PageCount)
        PageLabel.Text = string.format("%d / %d  ·  %d", Gallery.Page, Gallery.PageCount, #Gallery.Filtered)
        Empty.Visible = #Gallery.Filtered == 0
        GridHolder.Visible = #Gallery.Filtered > 0

        local Start = (Gallery.Page - 1) * Gallery.PageSize
        for SlotIndex, Slot in Gallery.Slots do
            local Item = Gallery.Filtered[Start + SlotIndex]
            Slot.Item = Item
            Slot.Hovered = false
            Slot.Button.Visible = Item ~= nil
            Slot.Image.Image = Item and NormalizeAsset(Item.Thumbnail) or ""
            Slot.Image.ImageColor3 = Item and Item.Color or Color3.new(1, 1, 1)
            Slot.Image.ImageTransparency = Item and Item.Disabled and 0.58 or 0
            Slot.Name.Text = Item and Item.Name or ""
            UpdateSlotState(Slot, false)
        end

        local HasPrevious = Gallery.Page > 1
        local HasNext = Gallery.Page < Gallery.PageCount
        PreviousButton.TextTransparency = HasPrevious and 0 or 0.55
        NextButton.TextTransparency = HasNext and 0 or 0.55
    end

    function Gallery:Refresh()
        Refresh()
    end

    function Gallery:SetItems(Items)
        if Gallery.Destroyed then
            return
        end
        table.clear(Gallery.Items)
        if type(Items) == "table" then
            for Index, Item in Items do
                local Normalized = NormalizeItem(Item, Index)
                if Normalized then
                    table.insert(Gallery.Items, Normalized)
                end
            end
        end
        if Gallery.SelectedId ~= nil then
            local SelectionExists = false
            for _, Item in Gallery.Items do
                if Item.Id == Gallery.SelectedId then
                    SelectionExists = true
                    break
                end
            end
            if not SelectionExists then
                Gallery.SelectedId = nil
                BindPreview(nil)
            end
        end
        RebuildCategories()
        Gallery.Page = 1
        Refresh()
    end

    function Gallery:AddItem(Item)
        if Gallery.Destroyed then
            return nil
        end
        local Normalized = NormalizeItem(Item, #Gallery.Items + 1)
        if not Normalized then
            return nil
        end
        table.insert(Gallery.Items, Normalized)
        RebuildCategories()
        Refresh()
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
                Refresh()
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
        Gallery.Page = 1
        Refresh()
    end

    function Gallery:SetCategory(Value)
        if Gallery.Destroyed then
            return
        end
        local Requested = tostring(Value or "All")
        Gallery.Category = table.find(Gallery.Categories, Requested) and Requested or "All"
        CategoryButton.Text = Gallery.Category
        Gallery.Page = 1
        Refresh()
    end

    function Gallery:SetPage(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.Page = math.clamp(math.floor(tonumber(Value) or Gallery.Page), 1, Gallery.PageCount)
        Refresh()
    end

    function Gallery:NextPage()
        Gallery:SetPage(Gallery.Page + 1)
    end

    function Gallery:PreviousPage()
        Gallery:SetPage(Gallery.Page - 1)
    end

    function Gallery:SetColumns(Value)
        if Gallery.Destroyed then
            return
        end
        Gallery.Columns = math.clamp(math.floor(tonumber(Value) or Gallery.Columns), 1, 10)
        Grid.FillDirectionMaxCells = Gallery.Columns
        Grid.CellSize = UDim2.new(1 / Gallery.Columns, -math.ceil(Gap * (Gallery.Columns - 1) / Gallery.Columns), 0, CellHeight)
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
        for _, Slot in Gallery.Slots do
            UpdateSlotState(Slot, true)
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
                Gallery.Page = 1
                Refresh()
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
    table.insert(Gallery.Connections, PreviousButton.Activated:Connect(function()
        Gallery:PreviousPage()
    end))
    table.insert(Gallery.Connections, NextButton.Activated:Connect(function()
        Gallery:NextPage()
    end))

    if typeof(Info.Parent) == "Instance" and Info.Parent:IsA("GuiBase2d") then
        Root.Parent = Info.Parent
    end
    Gallery:SetItems(Info.Items or {})
    if Info.Category then
        Gallery:SetCategory(Info.Category)
    end
    if Info.Selected ~= nil then
        Gallery:Select(Info.Selected, true)
    end

    if Library and type(Library.OnUnload) == "function" then
        Library:OnUnload(function()
            Gallery:Destroy()
        end)
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

return ImageGallery
