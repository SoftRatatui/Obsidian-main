return function(Modules, Mock)
    local Items = {
        { Id = "a", Name = "Alpha", Image = 1, Favorite = true, Badges = { "Rare" } },
        { Id = "b", Name = "Beta", Image = 2, Category = "Other" },
    }
    local function Find(Root, Class, Text)
        for _, Object in Root:GetDescendants() do
            if Object.ClassName == Class and (Text == nil or Object.Text == Text) then
                return Object
            end
        end
        error("Missing " .. Class .. " " .. tostring(Text))
    end
    local function Count(Registry)
        local Total = 0
        for _ in Registry do
            Total += 1
        end
        return Total
    end
    local Library = Mock.Library()
    local Catalog = Modules.AssetCatalog.Create(Library, { Items = Items })
    Catalog:Select("a")
    local RegistrySize = Count(Library.Registry)
    for _ = 1, 30 do
        Catalog:Select("a")
    end
    assert(Count(Library.Registry) == RegistrySize, "Badge registry grows after selection")
    Catalog:SetFavoritesOnly(true)
    assert(#Catalog.Filtered == 1 and Catalog.Filtered[1].Id == "a")
    Catalog:SetFavoritesOnly(false)
    Catalog:SetSort("Name")
    assert(Catalog.Filtered[1].Name == "Alpha")
    Catalog:SetLayout("Grid")
    assert(Catalog.EffectiveLayout == "grid")
    Catalog:SetLayout("Split")
    Catalog:SetHeight(340)
    Catalog:Destroy()
    Catalog:Destroy()
    assert(Count(Library.Registry) == 0, "Catalog registry remains after destruction")
    Modules.AssetCatalog.Create(nil, { Items = Items }):Destroy()
    print("PASS catalog creation, filtering, selection cleanup and standalone fallback")

    local Gallery = Modules.ImageGallery.Create(Library, { Items = Items, Columns = 8 })
    local Grid = Find(Gallery.Root, "UIGridLayout")
    Grid.Parent.AbsoluteSize = Mock.Vector2.new(211, 180)
    Grid.Parent:GetPropertyChangedSignal("AbsoluteSize"):Fire()
    local Used = Grid.CellSize.X.Offset * Grid.FillDirectionMaxCells
        + Grid.CellPadding.X.Offset * (Grid.FillDirectionMaxCells - 1)
    assert(Grid.CellSize.X.Scale == 0 and Used <= 209, "Gallery cards overflow a narrow container")
    assert(Grid.Parent.ClassName == "ScrollingFrame", "Gallery rows cannot scroll")
    Gallery:SetColumns(nil)
    Gallery:SetMinCellWidth(100)
    Gallery:Destroy()
    assert(Count(Library.Registry) == 0, "Gallery registry remains after destruction")
    print("PASS gallery integer sizing, responsive columns, scrolling and cleanup")

    local Texture = Modules.TextureGallery.Create(Library, { Items = Items })
    Texture:SetItems(Items)
    local TextureGrid = Find(Texture.Root, "UIGridLayout")
    TextureGrid.Parent.AbsoluteSize = Mock.Vector2.new(219, 180)
    TextureGrid.Parent:GetPropertyChangedSignal("AbsoluteSize"):Fire()
    assert(TextureGrid.CellSize.X.Scale == 0 and TextureGrid.CellSize.X.Offset < 219)
    Texture:SetHeight(500)
    assert(Texture.Height == 500)
    Texture:Destroy()
    assert(Count(Library.Registry) == 0, "Texture registry remains after destruction")
    print("PASS texture grid survives item replacement and supports height changes")

    local Preview = Modules.ImagePreview.Create(Library, { Image = 1 })
    Preview:SetImage(2)
    Preview:SetImage(3, false)
    assert(Preview.Layers[Preview.CurrentLayer].Image.Image == "rbxassetid://3")
    assert(next(Preview.Tweens) == nil, "Immediate image replacement leaves active fades")
    Preview:Destroy()
    assert(Count(Library.Registry) == 0, "Preview registry remains after destruction")
    print("PASS image preview immediate replacement cancels older transitions")

    local Model = Modules.CollectionModel.Create({ Items = Items })
    local A = Modules.AssetCatalog.Create(Library, { Model = Model })
    local B = Modules.ImageGallery.Create(Library, { Model = Model })
    A:Select("a")
    assert(Model:GetSelected().Id == "a" and B.SelectedId == "a")
    B:Select("b")
    assert(Model:GetSelected().Id == "b" and A.SelectedId == "b")
    Model:RemoveItem("b")
    assert(A:GetSelected() == nil and B:GetSelected() == nil)
    A:Destroy()
    assert(A.CollectionBinding == nil)
    Model:SetFavorite("a", false)
    Model:Destroy()
    B:Destroy()
    assert(Count(Library.Registry) == 0)
    print("PASS shared model synchronizes real catalog and gallery controllers")

    local HostLibrary = Modules.HostLibrary
    local Host = HostLibrary:CreateAddonWindow({ Subtitle = "Details" })
    local ConnectionCount = #Host.Connections
    Host:SetSubtitle("")
    Host:SetSubtitle("Restored")
    assert(Host.SubtitleLabel.Visible and Host.Header.Size.Y.Offset == 54)
    Host:SetVisible(false)
    Host:SetVisible(true, true)
    assert(Host.Root.Visible and Host.Root.GroupTransparency == 0 and Host.Scale.Scale == 1)
    HostLibrary.Window.VisibilityChanged.Event:Fire(false)
    assert(not Host.Root.Visible)
    HostLibrary.Window.VisibilityChanged.Event:Fire(true)
    assert(Host.Root.Visible)
    local RegistryCount = Count(HostLibrary.Registry)
    Host:AddCustom(2, Mock.Instance.new("Frame"), 90)
    local Automatic = Host:AddCustom(nil, Mock.Instance.new("Frame"), 90)
    assert(Host.Modules[2] ~= Automatic and Host.Modules[3] == Automatic)
    Host:Remove(2)
    Host:Remove(3)
    assert(Count(HostLibrary.Registry) == RegistryCount, "Removed module holders remain registered")
    Mock.Workspace.CurrentCamera.ViewportSize = Mock.Vector2.new(320, 240)
    Host:SetSize(900, 800)
    assert(Host.Root.Size.X.Offset == 304 and Host.Root.Size.Y.Offset == 224)
    Mock.Workspace.CurrentCamera.ViewportSize = Mock.Vector2.new(1280, 720)
    Host:SetSize(900, 600)
    assert(Host.Root.Size.X.Offset == 900)
    Host:Destroy()
    assert(Count(HostLibrary.Registry) == 0 and #Host.Connections == 0 and ConnectionCount > 0)
    print("PASS addon host visibility, module identity, viewport sizing and cleanup")

    local Dashboard = Modules.DashboardWindow.Create(HostLibrary, { Visible = false })
    Dashboard:SetHeight(480)
    assert(Dashboard.Height == 480 and Dashboard.Root.Size.Y.Offset == 480)
    local Metric = Dashboard:AddMetric({ Label = "Items", Value = 2 })
    Metric:SetValue(3)
    Metric:Destroy()
    Dashboard:Destroy()
    assert(Count(HostLibrary.Registry) == 0)
    print("PASS dashboard height, metric lifecycle and cleanup")
end
