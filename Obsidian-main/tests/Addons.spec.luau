return function(Modules, Mock)
    local function Count(Registry)
        local Total = 0
        for _ in Registry do
            Total += 1
        end
        return Total
    end
    local HostLibrary = Modules.HostLibrary
    local Host = HostLibrary:CreateAddonWindow({ Subtitle = "Details" })
    assert(Host.Header.Size.Y.Offset == 28 and not Host.SubtitleLabel.Visible)
    local ConnectionCount = #Host.Connections
    Host:SetSubtitle("")
    Host:SetSubtitle("Restored")
    assert(Host.SubtitleLabel.Visible and Host.Header.Size.Y.Offset == 44)
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
    local FlexibleRoot = Mock.Instance.new("Frame")
    local Flexible = Host:AddCustom("flexible", FlexibleRoot, 80)
    assert(Host:GetModule("flexible") == FlexibleRoot and Host:GetModules().flexible == FlexibleRoot)
    assert(Host:SetModuleVisible("flexible", false) and not Flexible.Holder.Visible)
    assert(Host:SetModuleVisible("flexible", true) and Flexible.Holder.Visible)
    assert(Host:SetModuleOrder("flexible", -5) and Flexible.Holder.LayoutOrder == -5)
    assert(Host:SetModuleFitHeight("flexible", true) and Flexible.Holder.Size.Y.Offset > 0)
    assert(Host:SetModuleHighlighted("flexible", true))
    assert(Flexible.HighlightStroke.Transparency == 0.08 and Host:GetModuleStyle("flexible").Highlight)
    assert(Host:SetModuleMinimal("flexible", true) and Host:GetModuleStyle("flexible").Minimal)
    assert(Host:SetModuleHighlighted("flexible", false) and Flexible.HighlightStroke.Transparency == 1)
    assert(not Host:SetModuleStyle("missing", { Highlight = true }))
    Host:SetContentSpacing(12, 6)
    assert(Host.Style.Padding == 12 and Host.Style.Gap == 6)
    Host:Remove(2)
    Host:Remove(3)
    Host:Remove("flexible")
    assert(Count(HostLibrary.Registry) == RegistryCount, "Removed module holders remain registered")
    local Retained = Mock.Instance.new("Frame")
    Host:AddCustom("retained", Retained, 80.8)
    assert(Host.Modules.retained.Holder.Size.Y.Offset == 80)
    local Success = pcall(function()
        Host:AddAddon("retained", { Create = function() error("creation failed") end })
    end)
    assert(not Success and Host:GetModule("retained") == Retained and not Retained.Destroyed, "Failed replacement destroyed the previous module")
    local Detached = Host:Detach("retained", HostLibrary.ScreenGui)
    assert(Detached == Retained and Retained.Parent == HostLibrary.ScreenGui and Host:GetModule("retained") == nil)
    Mock.Workspace.CurrentCamera.ViewportSize = Mock.Vector2.new(320, 240)
    Host:SetSize(900, 800)
    assert(Host.Root.Size.X.Offset == 304 and Host.Root.Size.Y.Offset == 224)
    Mock.Workspace.CurrentCamera.ViewportSize = Mock.Vector2.new(1280, 720)
    Host:SetSize(900, 600)
    assert(Host.Root.Size.X.Offset == 900)
    Host:Destroy()
    assert(not Retained.Destroyed, "Host destroyed a detached module")
    Retained:Destroy()
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
    local Small, SmallHost = Modules.DashboardWindow.CreateStandalone(HostLibrary, { Title = "Spectators", WindowWidth = 240, AutoHeight = true })
    Small:AddMetric({ Label = "player_one", Value = "spectating" })
    assert(not Small.DefaultSection.Header.Visible and Small.DefaultSection.Root.BackgroundTransparency == 1)
    local AnotherSection = Small:AddSection("Other")
    assert(Small.DefaultSection.Header.Visible and AnotherSection.Header.Visible)
    AnotherSection:Destroy()
    assert(not Small.DefaultSection.Header.Visible)
    Small.ContentLayout.AbsoluteContentSize = Mock.Vector2.new(220, 32)
    Small.ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Fire()
    assert(Small.Height == 32 and SmallHost.Root.Size.Y.Offset == 72)
    Small.ContentLayout.AbsoluteContentSize = Mock.Vector2.new(220, 64)
    Small.ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Fire()
    assert(SmallHost.Root.Size.Y.Offset == 104)
    SmallHost:Destroy()
    local Fixed, FixedHost = Modules.DashboardWindow.CreateStandalone(HostLibrary, { WindowHeight = 300 })
    assert(FixedHost.Root.Size.Y.Offset == 300)
    FixedHost:Destroy()
    local ClassicHost = HostLibrary:CreateAddonWindow({ Compact = false, Subtitle = "Details" })
    assert(ClassicHost.Header.Size.Y.Offset == 54 and ClassicHost.SubtitleLabel.Visible)
    ClassicHost:Destroy()
    print("PASS compact addon headers, content-fit dashboards and explicit window sizing")

    local ThemeLibrary = Modules.HostLibrary
    ThemeLibrary.Scheme = {
        AccentColor = Mock.Color3.new(0.2, 0.3, 0.8),
        BackgroundColor = Mock.Color3.new(0.1, 0.1, 0.1),
        ElementColor = Mock.Color3.new(0.2, 0.2, 0.2),
        FontColor = Mock.Color3.new(1, 1, 1),
        OutlineColor = Mock.Color3.new(0.3, 0.3, 0.3),
    }
    local Surface = Mock.Instance.new("Frame")
    ThemeLibrary:BindTheme(Surface, { BackgroundColor3 = "BackgroundColor" })
    ThemeLibrary:BindTheme(Surface, {
        Visible = function()
            return false
        end,
    })
    local Accent = Mock.Instance.new("Frame")
    ThemeLibrary:BindTheme(Accent, {
        BackgroundColor3 = function()
            return ThemeLibrary.Scheme.AccentColor
        end,
    })
    local Stroke = Mock.Instance.new("UIStroke")
    ThemeLibrary:AddToRegistry(Stroke, { Color = "OutlineColor" })
    assert(Stroke.BorderStrokePosition == Mock.Enum.BorderStrokePosition.Inner)
    function ThemeLibrary:RefreshThemeState() end
    for Index = 1, 20 do
        local Color = Mock.Color3.new(Index / 20, 0.4, 0.5)
        ThemeLibrary:SetPalette({ AccentColor = Color, BackgroundColor = Color })
        assert(Accent.BackgroundColor3 == Color and Surface.BackgroundColor3 == Color and not Surface.Visible)
        assert(#ThemeLibrary.ThemeErrors == 0)
    end
    local Before = ThemeLibrary.Scheme.AccentColor
    assert(not pcall(function()
        ThemeLibrary:SetPalette({ AccentColor = Mock.Color3.new(1, 0, 0), Missing = true })
    end))
    assert(ThemeLibrary.Scheme.AccentColor == Before)
    ThemeLibrary.Registry[Stroke].Color = "MissingToken"
    ThemeLibrary:UpdateColorsUsingRegistry()
    assert(#ThemeLibrary.ThemeErrors == 1 and ThemeLibrary.ThemeErrors[1].Property == "Color")
    ThemeLibrary:RemoveFromRegistry(Stroke)
    ThemeLibrary:RemoveFromRegistry(Surface)
    ThemeLibrary:RemoveFromRegistry(Accent)
    print("PASS repeated palette changes, merged bindings, false values and theme diagnostics")

    local Dark = { CornerRadius = 8, Font = {}, BackgroundImage = "", IsLight = false }
    for _, Key in
        {
            "BackgroundColor",
            "MainColor",
            "TopBarColor",
            "SurfaceColor",
            "RaisedColor",
            "ElementColor",
            "HoverColor",
            "AccentColor",
            "AccentSoftColor",
            "OutlineColor",
            "FontColor",
            "MutedFontColor",
            "ShadowColor",
            "RedColor",
            "WarningColor",
            "DestructiveColor",
            "DarkColor",
            "WhiteColor",
        }
    do
        Dark[Key] = Mock.Color3.new(0.2, 0.3, 0.4)
    end
    local Light = table.clone(Dark)
    Light.AccentColor = Mock.Color3.new(0.6, 0.7, 0.8)
    Light.BackgroundColor = Mock.Color3.new(0.95, 0.95, 0.95)
    Light.CornerRadius = 2
    ThemeLibrary.DefaultTheme = "Dark"
    ThemeLibrary.Themes = { Dark = Dark, Light = Light }
    ThemeLibrary.CornerRadius = 6
    function ThemeLibrary:SetFont(Font)
        ThemeLibrary.Scheme.Font = Font
    end
    function ThemeLibrary.Window:SetBackgroundImage() end
    local Panel = Mock.Instance.new("Frame")
    ThemeLibrary:BindTheme(Panel, { BackgroundColor3 = "BackgroundColor" })
    for Index = 1, 20 do
        local Name = Index % 2 == 0 and "Dark" or "Light"
        ThemeLibrary:SetTheme(Name)
        assert(Panel.BackgroundColor3 == ThemeLibrary.Themes[Name].BackgroundColor)
        assert(ThemeLibrary.CornerRadius == 6, "Theme changed geometry")
    end
    ThemeLibrary:RegisterTheme("Custom", { AccentColor = Before }, "Dark")
    ThemeLibrary:SetTheme("Custom")
    assert(ThemeLibrary.CurrentTheme == "Custom" and ThemeLibrary.Scheme.AccentColor == Before)
    assert(not pcall(function()
        ThemeLibrary:RegisterTheme("Invalid", { Missing = true })
    end))
    assert(ThemeLibrary.Themes.Invalid == nil)
    ThemeLibrary:RemoveFromRegistry(Panel)
    print("PASS theme cycling preserves geometry and custom themes validate atomically")

    ThemeLibrary.Options = {}
    local Group = {}
    function Group:AddLabel()
        local Label = {}
        function Label:AddColorPicker(Id, Info)
            local Picker = { Value = Info.Default }
            function Picker:SetValueRGB(Value)
                Picker.Value = Value
                Info.Callback(Value)
            end
            ThemeLibrary.Options[Id] = Picker
            return Label
        end
        return Label
    end
    function Group:AddSlider() end
    function Group:AddToggle() end
    function Group:AddButton() end
    local Manager = Modules.ThemeManager
    Manager:SetLibrary(ThemeLibrary)
    Manager:CreateAppearanceManager(Group)
    local Chosen = Mock.Color3.new(0.8, 0.1, 0.2)
    Manager.PalettePickers.AccentColor:SetValueRGB(Chosen)
    assert(ThemeLibrary.Scheme.AccentColor == Chosen)
    Manager:ApplyTheme("Light")
    assert(Manager.PalettePickers.AccentColor.Value == Light.AccentColor)
    assert(#ThemeLibrary.ThemeErrors == 0)
    print("PASS appearance color pickers synchronize with theme changes without callback loops")

    local Root = Mock.Instance.new("CanvasGroup")
    local Corner = Mock.Instance.new("UICorner")
    Corner.CornerRadius = Mock.UDim.new(0, 4)
    Corner.Parent = Root
    local OriginalGetter = ThemeLibrary.GetDesignToken
    local Radius = 7
    function ThemeLibrary:GetDesignToken(Path, Fallback)
        return Path == "Radius.Card" and Radius or Fallback
    end
    ThemeLibrary:BindAddonStyle(Root, { Radius = 4, CellRadius = 4, ControlRadius = 3 }, {})
    assert(Corner.CornerRadius.Offset == 7)
    Radius = 2
    ThemeLibrary:UpdateColorsUsingRegistry()
    assert(Corner.CornerRadius.Offset == 2)
    ThemeLibrary:RemoveFromRegistry(Corner)
    ThemeLibrary.GetDesignToken = OriginalGetter
    Root:Destroy()
    assert(Count(ThemeLibrary.Registry) == 0)
    print("PASS addon corner bindings update live and release cleanly")
end
