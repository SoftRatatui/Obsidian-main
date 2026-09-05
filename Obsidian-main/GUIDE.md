# MonHub UI Guide

Current release: `0.0.1-release-12`

MonHub is a compact Roblox Luau interface library built around a neutral dark palette, consistent spacing, short motion, theme-safe surfaces, and optional visual addons. The core library never loads an addon automatically.

## Quick start

```luau
local RELEASE = "0.0.1-release-12"
local BASE = "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/"

local Library = loadstring(game:HttpGet(BASE .. "Library.lua?monhub=" .. RELEASE))()

if Library.ReleaseVersion ~= RELEASE then
    warn(string.format("MonHub version notice: expected %s, received %s", RELEASE, tostring(Library.ReleaseVersion)))
end

local Window = Library:CreateWindow({
    Title = "MonHub",
    Footer = "v0.0.1",
    Size = UDim2.fromOffset(780, 640),
    Center = true,
    AutoShow = true,
    Resizable = false,
    GlobalSearch = true,
    ToggleKeybind = Enum.KeyCode.RightShift,
})

local Tabs = {
    Home = Window:AddTab({ Name = "Home", Icon = "house" }),
    Visuals = Window:AddTab({ Name = "Visuals", Icon = "eye" }),
    Settings = Window:AddTab({ Name = "Settings", Icon = "settings" }),
}

local Main = Tabs.Home:AddLeftGroupbox("Main", "layout-dashboard")

Main:AddToggle("Enabled", {
    Text = "Enabled",
    Default = false,
    Callback = function(Value)
        print(Value)
    end,
})
```

The version check is informational. Never stop a script only because a cached server returned an older patch.

## Project structure

| File | Purpose |
| --- | --- |
| `Library.lua` | Core window, tabs, controls, design system, addon host, themes, and lifecycle |
| `Library.d.luau` | Luau type declarations |
| `Example.lua` | Complete visual and addon showcase |
| `QuickStart.luau` | Minimal loader |
| `addons/SaveManager.lua` | Config persistence |
| `addons/ThemeManager.lua` | Built-in and custom themes |
| `addons/AssetCatalog.lua` | Complete skin, weapon, map, or asset browser |
| `addons/CollectionModel.lua` | UI-independent collection, selection, favorites, queries, and view bindings |
| `addons/CollectionModel.d.luau` | Collection model types |
| `addons/ImageGallery.lua` | Lightweight paged image grid |
| `addons/ImagePreview.lua` | Large configurable image preview |
| `addons/TextureGallery.lua` | Texture-focused selector |
| `addons/DashboardWindow.lua` | Metrics, text, buttons, and custom widgets |
| `addons/VisualPreview.lua` | Real character viewport preview |
| `addons/FixedR6Preview.lua` | Fixed R6 preview wrapper |
| `addons/CharacterTrail.lua` | Native Roblox Trail controller |
| `addons/TracerPreview.lua` | Optional decorative tracer preview |
| `addons/DrawingESPPreview.lua` | Shared Drawing preview renderer |
| `addons/esp/ESP.lua` | Optional universal ESP runtime |
| `addons/esp/MonHubUI.lua` | Optional universal ESP controls |

## Window

```luau
local Window = Library:CreateWindow({
    Title = "Project name",
    Footer = "v1.0.0",
    Icon = "sparkles",
    Position = UDim2.fromOffset(80, 80),
    Size = UDim2.fromOffset(780, 640),
    Center = true,
    AutoShow = true,
    Resizable = false,
    AlwaysOnTop = false,
    GlobalSearch = true,
    ShowCustomCursor = true,
    ShowCompactLauncher = true,
    CompactLauncherTitle = "Project name",
    ToggleKeybind = Enum.KeyCode.RightShift,
    NotifySide = "Right",
})
```

Useful window methods:

```luau
Window:SetTitle("New title")
Window:SetFooter("v1.0.1")
Window:SetKeybind(Enum.KeyCode.RightControl)
Window:SetSize(UDim2.fromOffset(820, 660))
Window:SetPosition(UDim2.fromOffset(100, 80))
Window:Show()
Window:Hide()
Window:Toggle()
```

The main window is clamped to the active viewport. The compact launcher is also clamped and appears only when the mouse button hides the window. Hiding through the menu keybind does not create the launcher.

## Tabs and groupboxes

```luau
local Combat = Window:AddTab({
    Name = "Combat",
    Icon = "crosshair",
    Description = "Combat controls",
    Order = 1,
})

local Left = Combat:AddLeftGroupbox("Aim", "target")
local Right = Combat:AddRightGroupbox("Filters", "list-filter")

local Custom = Combat:AddGroupbox({
    Side = 1,
    Name = "Custom",
    IconName = "box",
    Collapsed = false,
    DisableCollapsing = false,
})
```

Groupboxes use the same header height, padding, card radius, divider opacity, and animation curve as visual addons.

A tab can also host a single full-width column. This is the right place for a catalog, a gallery, or any wide module, because a half-width groupbox is too narrow for a grid.

```luau
local Skins = Window:AddTab({ Name = "Skins", Icon = "sparkles" })
local Gallery = Skins:AddFullGroupbox("Weapon finishes", "layout-grid")
```

`AddFullGroupbox` switches the tab to a single column and returns a normal groupbox, so every control still works inside it. `Tab:SetFullWidth(false)` restores the two-column layout.

The two columns are measured in whole pixels: the tab splits its own width and gives any leftover pixel to the right column, so both sides land on exact pixel boundaries at any window size.

## Controls

### Label

```luau
Group:AddLabel("Plain text")
Group:AddLabel("Wrapped description", true)
```

### Divider

```luau
Group:AddDivider()
```

### Button

```luau
Group:AddButton({
    Text = "Run action",
    Variant = "Primary",
    Callback = function()
        print("clicked")
    end,
})
```

Supported button variants are `Default`, `Primary`, and `Ghost`.

### Toggle and checkbox

```luau
Library.ForceCheckbox = true

Group:AddToggle("Feature", {
    Text = "Feature",
    Default = false,
    Callback = function(Value)
        print(Value)
    end,
})
```

Set `Library.ForceCheckbox = false` before building controls to use compact switch toggles. The release default uses checkboxes.

### Input

```luau
Group:AddInput("ProfileName", {
    Text = "Profile name",
    Default = "Default",
    Placeholder = "Enter a name",
    ClearTextOnFocus = false,
    Callback = function(Value)
        print(Value)
    end,
})
```

### Slider

```luau
Group:AddSlider("Distance", {
    Text = "Distance",
    Default = 250,
    Min = 0,
    Max = 1000,
    Rounding = 0,
    Suffix = "m",
    Callback = function(Value)
        print(Value)
    end,
})
```

### Dropdown

```luau
Group:AddDropdown("Target", {
    Text = "Target",
    Values = { "Head", "Torso", "Closest" },
    Default = "Head",
    Searchable = true,
    Callback = function(Value)
        print(Value)
    end,
})
```

Use `Multi = true` for multiple values and `SpecialType = "Player"` for a live player selector.

### Color picker

```luau
Group:AddLabel("Accent"):AddColorPicker("Accent", {
    Default = Color3.fromRGB(135, 143, 164),
    Transparency = 0,
    Callback = function(Color, Transparency)
        print(Color, Transparency)
    end,
})
```

### Key picker

```luau
Toggles.Feature:AddKeyPicker("FeatureKey", {
    Default = "G",
    Mode = "Toggle",
    Modes = { "Toggle", "Hold" },
    SyncToggleState = true,
})
```

Configured bindings are saved by `SaveManager`. Entries without a real key are not shown in the keybind list.

### Dependency box

```luau
local Box = Group:AddDependencyBox()
Box:SetupDependencies({
    { Toggles.Feature, true },
})
Box:AddSlider("Strength", {
    Text = "Strength",
    Default = 50,
    Min = 0,
    Max = 100,
})
```

### Custom UI

```luau
Group:AddUIPassthrough("Custom", {
    Instance = CustomFrame,
    Height = 120,
    Visible = true,
})
```

## Design system

`Library.Scheme` stores theme colors. `Library.Design` stores geometry, density, typography, outlines, and motion. Apply design overrides before creating the window.

Radius tokens on bound controls, decorative effects, and menu scrollbar width can also be changed while the UI is open. Spacing, density, and font sizes should still be configured before creation. Explicit addon style overrides and addon `SetCornerRadius` calls retain their own values.

The default appearance has no shadows, navigation accent line, or decorative section dividers. Scrollbars use muted text color. Use these switches to restore individual effects:

```luau
Library:SetDesign({
    Effects = {
        Shadows = false,
        Dividers = false,
        NavigationIndicator = false,
        AccentScrollbars = false,
        ThemeGeometry = false,
    },
    Shell = { ScrollbarThickness = 2 },
    Radius = { Window = 6, Card = 4, Control = 3, Indicator = 2 },
})
```

`ThemeGeometry = false` keeps the chosen radii when changing themes. Set it to `true` only when the theme should also choose geometry. A menu scrollbar thickness of `0` hides its thumb while preserving scrolling. Image addons retain their own scrollbar width.

GUI objects created by the core start with `BorderSizePixel = 0`, including `CanvasGroup`. Borders use an inner `UIStroke` so they stay within the clipping boundary. This uses Roblox's documented [border position support](https://create.roblox.com/docs/reference/engine/enums/BorderStrokePosition). Image addon roots use `CanvasGroup` to clip their children to rounded corners.

### Live palette and appearance controls

The full example includes a collapsed Appearance group. Add it to another project with:

```luau
ThemeManager:SetLibrary(Library)
ThemeManager:CreateAppearanceManager(Settings:AddLeftGroupbox("Appearance", "sliders-horizontal"))
```

It exposes ten palette colors, four radius controls, menu scrollbar width, four decoration switches, reduced motion, and palette reset. Color pickers synchronize when the active theme changes.

```luau
Library:SetPalette({
    AccentColor = Color3.fromRGB(130, 150, 220),
    ElementColor = Color3.fromRGB(28, 30, 36),
})

Library:RegisterTheme("My theme", {
    AccentColor = Color3.fromRGB(130, 150, 220),
    OutlineColor = Color3.fromRGB(46, 48, 55),
}, "Default")
Library:SetTheme("My theme")
```

Palette changes affect the current session. Switching themes restores that theme's palette. When changed individually, `ElementColor` and legacy `MainColor` stay synchronized; provide both to style them separately. `AccentSoftColor` is recalculated after an accent or control surface change unless supplied explicitly. Runtime theme registration updates the theme selector; it does not write a custom theme file.

Custom UI can join the same theme refresh without replacing its existing bindings:

```luau
Library:BindTheme(CustomFrame, { BackgroundColor3 = "SurfaceColor" })
Library:BindTheme(CustomLabel, {
    TextColor3 = "FontColor",
    FontFace = "Font",
})
```

Bindings accept theme token names, functions, and non-string literal values. Invalid bindings are reported in `Library.ThemeErrors` with the object, property, and message after a refresh. Remove a custom object's bindings with `Library:RemoveFromRegistry(Object)` when destroying it.

```luau
Library:SetDesign({
    Spacing = {
        Medium = 9,
        Large = 13,
        Section = 12,
    },
    Radius = {
        Window = 6,
        Card = 4,
        Control = 3,
        Popup = 4,
    },
    Grid = {
        Row = 24,
        LabelRow = 18,
        Indicator = 16,
        IndicatorGap = 9,
        TrackRow = 14,
        Thumb = 10,
    },
    Motion = {
        Scale = 1,
    },
    Addon = {
        Padding = 10,
        Gap = 8,
        CellRadius = 4,
        PreviewRatio = 0.58,
    },
})
```

`Design.Grid` is the geometry every control is measured from. Toggles, color picker rows, and plain labels all occupy `Row`; sliders, dropdowns, and inputs put their caption in `LabelRow` and their control below it. Because the values come from one table, a control never carries its own hardcoded offset and the two columns stay aligned row for row.

Four helpers keep that geometry on whole pixels. Use them instead of raw arithmetic when extending the library:

```luau
Library:Metric("Row", 24)
Library:Snap(Value)
Library:CenterOffset(Outer, Inner)
Library:MatchParity(Outer, Inner)
Library:GlyphSize(Box, Preferred)
```

`CenterOffset` centers on an integer. `MatchParity` grows a size by one pixel when needed so that centering it inside its container cannot land on a half pixel. `GlyphSize` picks an icon size on a clean divisor of the 24px Lucide sprite, which is what keeps small icons such as the checkbox tick from losing strokes.

```luau
local Card, Stroke, Corner = Library:CreateSurface(Parent, {
    Role = "Surface",
    RadiusRole = "Card",
    Outline = true,
    Shadow = false,
})

Library:CreateDivider(Card)
Library:SetReducedMotion(true)
```

`SetReducedMotion(true)` removes motion without changing component behavior. Each addon also accepts `Style = { Motion = false }`.

## Addon mounting

Visual addons support three placement modes.

### Embedded in a groupbox

```luau
local Gallery = Group:AddAddon("Skins", ImageGallery, {
    Height = 330,
    Columns = 3,
    Items = Items,
})
```

### Direct parent

```luau
local Gallery = ImageGallery.Create(Library, {
    Parent = CustomFrame,
    Height = 330,
    Items = Items,
})
```

### Standalone window

```luau
local Gallery, Host = ImageGallery.CreateStandalone(Library, {
    WindowTitle = "Skins",
    WindowSubtitle = "Select a skin",
    WindowWidth = 480,
    WindowHeight = 520,
    Items = Items,
})

Host:SetVisible(true)
Host:Toggle()
```

`ImageGallery`, `ImagePreview`, `TextureGallery`, `TracerPreview`, `VisualPreview`, and `AssetCatalog` expose standalone helpers. `DashboardWindow.Create` is standalone by default and also supports `Group:AddAddon`.

## Generic addon windows

Use one host to display custom modules or multiple addons in a consistent independent window.

```luau
local Host = Library:CreateAddonWindow({
    Title = "Runtime tools",
    Subtitle = "Optional modules",
    Icon = "blocks",
    Width = 440,
    Height = 560,
    Draggable = true,
    Closable = true,
    HideWithMenu = true,
})

local Preview = Host:AddAddon("Preview", ImagePreview, {
    Height = 240,
    Image = "rbxassetid://123456",
})

Host:AddCustom("Custom", CustomFrame, 120)
Host:SetModuleHeight("Preview", 280)
Host:Remove("Custom")
Host:SetSize(480, 600)
Host:SetPosition(UDim2.fromScale(0.75, 0.5))
```

The host owns modules mounted through it. Destroying the host destroys those module controllers and their registered theme objects. Windows are resizable by default; pass `Resizable = false` to disable the grip. Window dimensions are clamped to the viewport.

Standalone visual helpers fill the available height when `Height` is omitted. An explicit `Height` keeps the module at that size and allows the host to scroll. Use `FitHeight = true` with `Host:AddAddon` to opt into height fitting, or `FitHeight = false` to disable it. A controller's minimum height is retained on small screens.

## Collections without UI

Load `addons/CollectionModel.lua` independently. The module does not access `game`, create instances, or load the library. It can run in a plain Luau process. The same model can later drive embedded and independent windows.

```luau
local Skins = CollectionModel.Create({
    Items = {
        { Id = "violet", Name = "Violet", Category = "Rifles", Image = 123456 },
        { Id = "arctic", Name = "Arctic", Category = "Rifles", Image = 123457 },
    },
    Selected = "violet",
})

Skins:Select("arctic")
Skins:SetFavorite("arctic", true)
local Saved = Skins:Query({ FavoritesOnly = true, Sort = "Name" })
local SelectedSkin = Skins:GetSelected()

local Listener = Skins:Subscribe(function(Model)
    local Item = Model:GetSelected()
    print(Item and Item.Id)
end)
```

Selection stores the chosen item. Apply the actual cosmetic through your game's own code, for example in the catalog's `OnAction` callback. A locked item can be inspected; disabled items cannot be selected through the model.

```luau
local Embedded = AssetCatalog.CreateEmbedded(Library, Group, "Skins", {
    Model = Skins,
    Height = 480,
    Layout = "Split",
})

local Detached, Host = AssetCatalog.CreateStandalone(Library, {
    Model = Skins,
    WindowTitle = "Skins",
    WindowWidth = 820,
    HideWithMenu = false,
})
```

Both views share items, favorites, and selection. Each keeps its own search, category, sort, page, and layout. Selection alone does not rebuild item lists. `ImageGallery` accepts the same `Model` option. To attach an existing controller, use `Skins:Bind(Controller)`.

When using a model, update data through `Skins:SetItems`, `AddItem`, `UpdateItem`, and `RemoveItem`. IDs are unique strings or numbers. `SetItems` rejects duplicates before replacing the current collection. Missing IDs receive generated IDs; explicit IDs are preferable for saved data. `GetItems`, `GetItem`, and `Query` return record copies, including copies of tag and badge lists; custom nested metadata remains shared.

Destroying a bound view disconnects its binding. Destroying the model restores the views' original callbacks but leaves the views alive. The model owner should call `Skins:Destroy()` when finished, or register it with `Library:OnUnload`. Call `Listener:Disconnect()` to stop a subscription early. Search and favorite changes are in memory; persistence is the caller's responsibility.

## Asset catalog

`AssetCatalog` is the preferred base for skin changers, weapon selectors, skyboxes, maps, and other image collections. It combines a paged grid with a large selected preview, search, categories, badges, status, price text, primary action, and secondary action.

```luau
local AssetCatalog = loadstring(game:HttpGet(
    BASE .. "addons/AssetCatalog.lua?monhub=" .. RELEASE
))()

local Items = {
    {
        Id = "violet",
        Name = "Violet",
        Subtitle = "Soft animated finish",
        Category = "Rifles",
        Image = 123456,
        Thumbnail = 123457,
        PreviewImage = 123458,
        Rarity = "Rare",
        Status = "Owned",
        Price = "$1,250",
        Tags = { "purple", "rifle" },
        ActionText = "Equip",
    },
}

local Catalog, Host = AssetCatalog.CreateStandalone(Library, {
    WindowTitle = "Skin collection",
    WindowSubtitle = "Search, inspect, and equip",
    WindowWidth = 760,
    WindowHeight = 560,
    Layout = "Split",
    PreviewSide = "Right",
    PreviewRatio = 0.58,
    Columns = 3,
    Rows = 3,
    CellHeight = 104,
    Items = Items,
    Selected = "violet",
    ActionText = "Equip",
    SecondaryActionText = "Inspect",
    OnSelected = function(Source, Item)
        print(Item.Name)
    end,
    OnAction = function(Source, Item)
        print("Equip", Item.Id)
    end,
    OnSecondaryAction = function(Source, Item)
        print("Inspect", Item.Id)
    end,
})
```

Omit `Columns` and the grid picks the column count from the space it actually has, keeping every cell an exact whole number of pixels wide. `MinCellWidth` sets the narrowest a cell may become before a column is dropped:

```luau
local Catalog = AssetCatalog.CreateEmbedded(Library, Gallery, "SkinCatalog", {
    Items = Items,
    Height = 420,
    MinCellWidth = 116,
})
```

Put a skin catalog in a full-width groupbox (`Tab:AddFullGroupbox`) or open it as its own window with `CreateStandalone`. Explicit `Columns` requests a fixed count; it is reduced when necessary to keep cards inside a narrow container. Card widths and outer padding are measured in whole pixels, including when the available width is odd.

The toolbar includes search, categories, saved-item filtering, and name sorting. Below 460 pixels it uses two rows. `Layout = "Grid"` hides the preview; `Split` automatically falls back to `Stack` on narrow containers. The saved filter uses each item's `Favorite` value.

For a narrow groupbox, embedded mode defaults to the stacked layout:

```luau
local Catalog = Group:AddAddon("SkinCatalog", AssetCatalog, {
    Height = 520,
    Layout = "Stack",
    Columns = 3,
    Items = Items,
})
```

Runtime catalog methods:

```luau
Catalog:SetItems(Items)
Catalog:AddItem(Item)
Catalog:RemoveItem(Id)
Catalog:SetSearch("violet")
Catalog:SetCategory("Rifles")
Catalog:SetFavoritesOnly(true)
Catalog:SetSort("Name")
Catalog:SetPage(2)
Catalog:SetColumns(4)
Catalog:SetCellHeight(112)
Catalog:SetLayout("Split", "Left")
Catalog:SetPreviewRatio(0.62)
Catalog:SetPreviewSide("Right")
Catalog:SetScaleType("Fit")
Catalog:SetImagePadding(8)
Catalog:SetPreviewPadding(12)
Catalog:SetImageTransparency(0.1)
Catalog:SetCardTransparency(0.05)
Catalog:SetPreviewTransparency(0)
Catalog:Select("violet")
```

Use thumbnails in the grid and full images only in `PreviewImage`. The catalog creates only `PageSize` card instances and reuses them while searching, filtering, and paging.

## Image gallery and image preview

Use these smaller addons when a complete catalog is unnecessary.

```luau
local Preview = PreviewGroup:AddAddon("SelectedSkin", ImagePreview, {
    Height = 240,
    Title = "Select a skin",
    ScaleType = "Fit",
    ImagePadding = 12,
})

local Gallery = GalleryGroup:AddAddon("Skins", ImageGallery, {
    Height = 340,
    Columns = 4,
    PageSize = 12,
    CellHeight = 88,
    Preview = Preview,
    Items = Items,
})
```

Both addons support asset IDs, full asset strings, tint, scale type, padding, rotation, sprite rectangles, image position, image scale, canvas transparency, outline transparency, and per-item overrides.

## Dashboard

```luau
local DashboardWindow = loadstring(game:HttpGet(
    BASE .. "addons/DashboardWindow.lua?monhub=" .. RELEASE
))()

local Dashboard = DashboardWindow.Create(Library, {
    Title = "Session",
    Width = 340,
    Height = 420,
    Position = "Right",
    Draggable = true,
})

local Runtime = Dashboard:AddSection({ Title = "Runtime", Icon = "activity" })
Runtime:AddText("Current session")
Runtime:AddMetric({
    Label = "Status",
    Value = function()
        return "Running"
    end,
    Interval = 0.25,
})
Runtime:AddButton({
    Text = "Refresh",
    Callback = function()
        Dashboard:Refresh()
    end,
})
```

Dynamic values share one scheduler. It pauses when the dashboard is hidden and stops after the last dynamic widget is removed.

Embedded dashboard:

```luau
local Dashboard = Group:AddAddon("Dashboard", DashboardWindow, {
    Height = 360,
    Title = "Session",
})
```

Standalone dashboard. This routes the module through the shared window host, so its title bar, icon badge, divider, and close button are the same ones the other standalone addons use rather than a second set drawn by the module:

```luau
local Dashboard, Host = DashboardWindow.CreateStandalone(Library, {
    WindowTitle = "Session dashboard",
    WindowSubtitle = "Live values",
    WindowWidth = 380,
    WindowHeight = 460,
})
```

Every visual addon now exposes both `CreateEmbedded` and `CreateStandalone`, so any module can be placed inside the menu or opened as its own window without changing how it looks.

## Character preview

`VisualPreview` clones a real Roblox character into a `ViewportFrame`. It preserves the rig, body colors, clothing, and accessories. Dragging rotates the model and the mouse wheel changes zoom.

```luau
local VisualPreview = loadstring(game:HttpGet(
    BASE .. "addons/VisualPreview.lua?monhub=" .. RELEASE
))()

local Preview = PreviewGroup:AddAddon("Character", VisualPreview, {
    Height = 360,
    Target = game.Players.LocalPlayer,
    Box = true,
    Health = true,
    Distance = true,
    DynamicBoxes = true,
})
```

Pass the production ESP renderer through `Renderer` when the preview must use the exact live ESP logic. The preview itself does not modify the source character.

## Native trail

```luau
local CharacterTrail = loadstring(game:HttpGet(
    BASE .. "addons/CharacterTrail.lua?monhub=" .. RELEASE
))()

local Trail = CharacterTrail.Create(Library, {
    Enabled = false,
    ColorA = Color3.fromRGB(130, 145, 190),
    ColorB = Color3.fromRGB(170, 135, 210),
    TransparencyMin = 0.05,
    TransparencyMax = 0.75,
    WidthStart = 0.8,
    WidthEnd = 0.05,
    Lifetime = 0.35,
})
```

This addon creates a real Roblox `Trail`. No Trail or Attachment instances exist while it is disabled.

## Themes

```luau
local ThemeManager = loadstring(game:HttpGet(
    BASE .. "addons/ThemeManager.lua?monhub=" .. RELEASE
))()

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("MonHub")
ThemeManager:ApplyTheme("Default")
ThemeManager:BuildThemeSection(Tabs.Settings)
```

Built-in themes are `Default`, `Metal`, `Midnight`, `Steel`, `Sage`, and `Ash`. Every core surface and every current visual addon registers its palette properties. Theme changes update the top bar, sidebar, content, controls, addon windows, cards, previews, text, and outlines together.

## Configs

```luau
local SaveManager = loadstring(game:HttpGet(
    BASE .. "addons/SaveManager.lua?monhub=" .. RELEASE
))()

SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("MonHub")
SaveManager:SetSubFolder(tostring(game.PlaceId))
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
```

Create all saved controls before loading the autoload config. Use stable option IDs and do not reuse one ID for different controls.

## Notifications

```luau
Library:Notify({
    Title = "MonHub",
    Description = "Settings saved",
    Time = 3,
    Icon = "check",
})
```

Notifications use the same short motion profile and active theme as the main interface.

## Complete addon API reference

This section is the complete public reference for every addon shipped in `addons`. Constructor settings are passed in the final `Info` table. Methods use colon syntax, for example `Gallery:SetPage(2)`.

All visual addons support three mounting forms where listed:

```lua
local Controller = Addon.Create(Library, Info)
local Embedded = Addon.CreateEmbedded(Library, Groupbox, "UniqueId", Info)
local Standalone, Host = Addon.CreateStandalone(Library, Info)
```

`CreateEmbedded` can also be called through `Groupbox:AddAddon`. Standalone settings shared by visual addons are `WindowTitle`, `WindowSubtitle`, `WindowIcon`, `WindowWidth`, `WindowHeight`, `Position`, `AnchorPoint`, `Draggable`, `Resizable`, `Closable`, `HideWithMenu`, `Visible`, and `FitHeight`.

### AssetCatalog API

`AssetCatalog` is a searchable, paged collection with a large preview and two actions.

| Setting | Purpose |
| --- | --- |
| `Items`, `Model`, `Selected` | Source records, optional shared `CollectionModel`, and initial item ID. |
| `Height`, `Columns`, `Rows`, `PageSize` | Overall height and grid capacity. |
| `MinCellWidth`, `CellHeight`, `Gap`, `Padding` | Responsive grid geometry in pixels. |
| `Layout` | `Split`, `Stack`, or `Grid`. |
| `PreviewSide`, `PreviewRatio`, `SplitMinWidth` | Preview position, split ratio, and responsive breakpoint. |
| `ToolbarHeight`, `CategoryWidth`, `LabelHeight` | Toolbar and text geometry. |
| `ImagePadding`, `PreviewPadding`, `ScaleType` | Card and preview image layout. `ScaleType` accepts `Fit`, `Crop`, `Stretch`, or `Tile`. |
| `ImageTransparency`, `CardTransparency`, `PreviewTransparency`, `BackgroundTransparency` | Independent visual opacity values from `0` to `1`. |
| `SearchPlaceholder`, `EmptyText`, `EmptyTitle`, `EmptySubtitle` | Empty and search text. |
| `Category`, `Sort`, `FavoritesOnly` | Initial filter state. Sort accepts the modes provided by `CollectionModel`. |
| `ActionText`, `SecondaryActionText` | Labels for the preview actions. |
| `OnSelected`, `OnAction`, `OnSecondaryAction`, `Callback` | Selection and action callbacks. |
| `Style` | Per-instance design token overrides. |

Item records accept `Id`, `Name`, `Category`, `Subtitle`, `Image`, `PreviewImage`, `Tags`, `Badges`, `Status`, `Price`, `Favorite`, `Disabled`, `Locked`, `Color`, `ScaleType`, `ImageScale`, `ImageTransparency`, `ImagePosition`, `ImageAnchorPoint`, `RectOffset`, `RectSize`, `ActionText`, and `SecondaryActionText`.

| Method | Result |
| --- | --- |
| `Refresh()` | Rebuilds the current filtered page. |
| `SetItems(items)`, `AddItem(item)`, `RemoveItem(id)` | Replaces or edits collection data. |
| `SetSearch(text)`, `SetCategory(name)`, `SetFavoritesOnly(bool)`, `SetSort(mode)` | Changes filtering and sorting. |
| `SetPage(page)` | Opens a clamped page number. |
| `SetColumns(count)`, `SetMinCellWidth(px)`, `SetCellHeight(px)` | Changes responsive grid geometry. |
| `SetLayout(mode, side)`, `SetPreviewRatio(ratio)`, `SetPreviewSide(side)` | Changes catalog layout without recreating it. |
| `SetScaleType(mode)`, `SetImagePadding(px)`, `SetPreviewPadding(px)` | Changes image fitting. |
| `SetImageTransparency(value)`, `SetCardTransparency(value)`, `SetPreviewTransparency(value)` | Changes opacity live. |
| `Select(id, silent)`, `GetSelected()` | Selects or reads an item. `silent` skips callbacks. |
| `SetVisible(bool)`, `SetHeight(px)`, `Mount(parent)`, `Destroy()` | Controls lifecycle and mounting. |

### ImageGallery API

`ImageGallery` is the lighter grid-only selector. It can bind directly to `ImagePreview` through `Preview` or `BindPreview`.

| Setting | Purpose |
| --- | --- |
| `Items`, `Model`, `Selected`, `Preview` | Items, shared model, initial ID, and preview controller. |
| `Height`, `Columns`, `PageSize`, `MinCellWidth`, `CellHeight`, `Gap` | Gallery and responsive grid geometry. |
| `ImageSize`, `ImagePosition`, `ImageAnchorPoint`, `ImagePadding`, `ImageScale`, `Zoom` | Image bounds and transform. |
| `ScaleType`, `TileSize`, `Rotation` | Roblox image rendering properties. |
| `LabelHeight`, `CornerRadius` | Caption and card corner geometry. |
| `BackgroundTransparency`, `ContainerOutlineTransparency` | Outer surface opacity. |
| `CellTransparency`, `CellOutlineTransparency`, `OutlineTransparency` | Card opacity and stroke. |
| `ImageTransparency`, `ImageBackgroundTransparency` | Image and image-canvas opacity. |
| `Category`, `SearchPlaceholder`, `EmptyText` | Initial filtering text. |
| `ForwardItemStyle` | Forwards compatible per-item style fields to the bound preview. |
| `OnSelected`, `Callback`, `Style`, `Visible` | Callback, style overrides, and initial visibility. |

Methods: `Refresh`, `SetItems`, `AddItem`, `RemoveItem`, `SetSearch`, `SetCategory`, `SetPage`, `NextPage`, `PreviousPage`, `SetColumns`, `SetMinCellWidth`, `SetCellHeight`, `SetScaleType`, `SetImageTransparency`, `SetImageBackgroundTransparency`, `SetBackgroundTransparency`, `SetCellTransparency`, `SetOutlineTransparency`, `SetContainerOutlineTransparency`, `SetImagePadding`, `SetLabelHeight`, `SetImageSize`, `SetImageScale`, `SetImagePosition`, `SetTileSize`, `SetRotation`, `SetCornerRadius`, `Select`, `GetSelected`, `BindPreview`, `SetVisible`, `SetHeight`, `Mount`, and `Destroy`.

### ImagePreview API

| Setting | Purpose |
| --- | --- |
| `Image`, `AssetId`, `Title`, `Subtitle` | Initial image and caption. Numeric asset IDs are normalized automatically. |
| `Height`, `CaptionHeight`, `Caption` | Overall and caption dimensions; `Caption = false` hides it. |
| `ImageSize`, `ImagePosition`, `ImageAnchorPoint`, `ImagePadding`, `ImageScale` | Image layout and zoom. |
| `ScaleType`, `TileSize`, `Rotation`, `ImageColor` | Roblox image rendering properties. |
| `ImageTransparency`, `BackgroundTransparency`, `CanvasTransparency`, `CaptionTransparency` | Independent opacity values. |
| `OutlineTransparency`, `OutlineThickness`, `CornerRadius` | Border geometry. |
| `Shade`, `ShadeTransparency`, `Motion`, `Interactive` | Overlay, transitions, and interaction behavior. |
| `Style`, `Visible` | Style overrides and initial visibility. |

Methods: `SetImage(value, transition)`, `SetTitle`, `SetSubtitle`, `SetImageColor`, `SetImageTransparency`, `SetScaleType`, `SetImageSize`, `SetImageScale`, `SetImagePosition`, `SetImagePadding`, `SetTileSize`, `SetRotation`, `SetBackgroundTransparency`, `SetCanvasTransparency`, `SetCaptionTransparency`, `SetOutlineTransparency`, `SetOutlineThickness`, `SetCornerRadius`, `SetShade(visible, transparency)`, `SetCaptionVisible`, `SetMotion`, `SetHeight`, `SetVisible`, `Mount`, and `Destroy`.

### TextureGallery API

`TextureGallery.DefaultItems` contains the built-in Clean, Soft beam, Lightning, Pulse, Chain, Glitch, Swirl, Neon, Plasma, and Laser presets.

| Setting | Purpose |
| --- | --- |
| `Items`, `Selected` | Texture records and initial ID or record. |
| `Height`, `Columns` | Gallery geometry. |
| `ScaleType`, `ImageScale`, `Zoom` | Texture fitting and zoom. |
| `ImageTransparency`, `PreviewImageTransparency` | Card and large preview image opacity. |
| `CardTransparency`, `PreviewTransparency`, `OutlineTransparency` | Surface opacity. |
| `OnSelected`, `Style`, `Visible` | Selection callback, style overrides, and visibility. |

Texture items accept `Id`, `Name`, `Texture`, `AssetId`, `Image`, `ColorA`, `ColorB`, `ScaleType`, `ImageScale`, `Zoom`, `ImageTransparency`, and `Transparency`. Methods: `SetItems`, `Select`, `GetSelected`, `SetVisible`, `SetColumns`, `SetImageTransparency`, `SetPreviewImageTransparency`, `SetCardTransparency`, `SetPreviewTransparency`, `SetOutlineTransparency`, `SetScaleType`, `SetImageScale`, `Mount`, `SetHeight`, and `Destroy`.

### DashboardWindow API

| Setting | Purpose |
| --- | --- |
| `Title`, `Subtitle`, `Icon`, `Width`, `Height`, `Position`, `Side` | Window identity and geometry. |
| `Draggable`, `Resizable`, `Closable`, `HideWithMenu`, `Visible` | Window behavior. |
| `Sections`, `DefaultSection`, `ShowHeader`, `Style` | Initial content and presentation. |

Create sections with `Dashboard:AddSection({ Title = "Runtime", Icon = "activity" })`. A section supports `AddText`, `AddMetric`, `AddButton`, `AddCustom`, generic `Add`, `SetTitle`, `SetVisible`, and `Destroy`.

- Text settings: `Text`, `Provider`, `Interval`, `TextSize`, and `Wrapped`. Text widgets expose `SetText`, `SetProvider`, `SetVisible`, and `Destroy`.
- Metric settings: `Label`, `Value`, `Provider`, `Interval`, `Format`, and `Fallback`. Metrics expose `SetLabel`, `SetValue`, `SetProvider`, `SetVisible`, and `Destroy`.
- Button settings: `Text`, `Callback` or `Func`, `Enabled`, and `Emphasis`. Buttons expose `SetText`, `SetEnabled`, `SetVisible`, and `Destroy`.
- Custom settings: `Instance`, `Height`, `Build`, and `ClipsDescendants`.

Dashboard methods: `GetDefaultSection`, `Add`, `AddText`, `AddMetric`, `AddButton`, `AddCustom`, `SetTitle`, `SetVisible`, `Toggle`, `SetDraggable`, `SetPosition`, `SetSize`, `Refresh`, `SetHeight`, and `Destroy`.

### VisualPreview API

| Setting | Purpose |
| --- | --- |
| `Target`, `Player` | Character, model, player, or player source. |
| `Width`, `Height`, `Side`, `Alignment`, `Gap`, `Position` | Preview placement and geometry. |
| `Renderer` | Optional shared renderer created by `DrawingESPPreview`. |
| `Enabled`, `Visible`, `ShowHeader`, `BindToTab` | Initial state and tab behavior. |
| `Color`, `GradientColor`, `Gradient`, `Box`, `BoxScale`, `DynamicBoxes` | Box overlay appearance. |
| `NameVisible`, `Distance`, `Team`, `Weapon`, `Health`, `Highlight` | Overlay components. |
| `ChamsFillColor`, `ChamsOutlineColor`, `ChamsFillTransparency`, `ChamsOutlineTransparency` | Highlight appearance. |
| `Style`, `OutlineTransparency` | Style overrides. |

Methods: `SetTarget`, `Rotate`, `SetZoom`, `ResetView`, `GetRendererContext`, `SetEnabled`, `SetColor`, `SetBoxScale`, `SetDynamicBoxes`, `SetBoxStyle`, `SetGradientEnabled`, `SetGradientColor`, `SetOpacity`, `SetPosition`, `SetPanelGap`, `Mount`, `Embed`, `SetBoxVisible`, `SetNameVisible`, `SetDistanceVisible`, `SetTeamVisible`, `SetWeaponVisible`, `SetTracerVisible`, `SetHealthVisible`, `SetHighlightVisible`, `SetChams`, `SetDistance`, and `Destroy`.

### FixedR6Preview API

Call `FixedR6Preview.Create(Library, VisualPreview, DrawingESPPreview, Tab, Info)`. It resolves the selected player's avatar as R6 and mounts a `VisualPreview`.

Settings: `Target`, `Player`, `Renderer`, `Width`, `Height`, `Side`, `Alignment`, `Gap`, `Enabled`, `AutoRefresh`, `ShowHeader`, `Color`, `GradientColor`, `Gradient`, `Box`, `DynamicBoxes`, `NameVisible`, `Distance`, `Health`, `Highlight`, and `Style`. Methods: `SetEnabled`, `SetColors`, `SetGradientEnabled`, `SetPosition`, `Rotate`, `SetZoom`, `RefreshCharacter`, and `Destroy`.

### CharacterTrail API

`CharacterTrail` is UI independent. Call `CharacterTrail.Create(Info)`.

| Setting | Purpose |
| --- | --- |
| `Target`, `AttachmentPart`, `VerticalOffset` | Character/model target and trail attachment. |
| `Enabled`, `Lifetime`, `MinLength`, `MaxLength` | Trail state and lifetime behavior. |
| `ColorStart`, `ColorEnd`, `ColorA`, `ColorB` | Color sequence endpoints. |
| `TransparencyStart`, `TransparencyEnd`, `TransparencyMin`, `TransparencyMax` | Transparency sequence endpoints. |
| `WidthStart`, `WidthEnd`, `AttachmentWidth` | Width curve and attachment spacing. |
| `Texture`, `TextureMode`, `TextureLength` | Texture asset and repetition behavior. |
| `FaceCamera`, `LightEmission`, `LightInfluence`, `Brightness` | Native Roblox `Trail` lighting properties. |

Methods: `SetEnabled`, `SetTarget`, `SetColors`, `SetTransparency`, `SetWidthScale`, `SetAttachmentWidth`, `SetVerticalOffset`, `SetAttachmentPart`, `SetLifetime`, `SetMinLength`, `SetMaxLength`, `SetTexture`, `SetTextureMode`, `SetTextureLength`, `SetFaceCamera`, `SetLight`, `SetBrightness`, `ApplyPreset`, `Refresh`, `GetTrail`, `GetState`, and `Destroy`. Available named presets and textures are exposed as `CharacterTrail.Presets` and `CharacterTrail.TexturePresets`.

### TracerPreview API

Settings: `AssetId` or `Image`, `Name`, `ColorA`, `ColorB`, `Glow`, `Speed`, `Enabled`, `Visible`, `Height`, `BackgroundTransparency`, `OutlineTransparency`, and `Style`, plus the common standalone settings. Methods: `SetAssetId`, `SetColors`, `SetGlow`, `SetSpeed`, `SetEnabled`, `SetName`, `SetHeight`, `SetVisible`, `Mount`, and `Destroy`.

### DrawingESPPreview API

Call `DrawingESPPreview.Create({ Color, GradientColor, Thickness, OutlineThickness, TextSize, Continuous })`. The returned renderer exposes `CreateEntity`, `SetEntityVisible`, `UpdateEntity`, `RemoveEntity`, `AttachPreview`, `UpdatePreview`, `SetPreviewVisible`, `DetachPreview`, `SetColors`, and `Destroy`. `UpdateEntity` receives the renderer state produced by `VisualPreview` or another compatible ESP source.

### UniversalESP API

Load `addons/esp/ESP.lua`, then call `UniversalESP.new(Info)`. `Info.Settings` can contain the settings tree below; top-level settings in `Info` are also accepted. `AutoStart` controls the render connection and `WrapPlayers` registers current and future players.

- General: `Enabled`, `Players`, `NPCs`, `Parts`, `IncludeLocalPlayer`, `AliveCheck`, `TeamCheck`, `TeamColors`, `VisibilityCheck`, `VisibilityInterval`, `MaxDistance`, `TextDistance`, `UpdateRate`, and `TextUpdateRate`.
- `Box`: `Enabled`, `Style`, `Dynamic`, `Scale`, `Thickness`, `Transparency`, `Outline`, `OutlineThickness`, `Fill`, `FillTransparency`, `Gradient`, `Rainbow`, and `RainbowSpeed`.
- `Text`: `Name`, `DisplayName`, `Team`, `Distance`, `Tool`, `Health`, `Category`, `Flags`, `Size`, `RelativeSize`, `Outline`, `Font`, and `Separator`.
- `HealthBar`: `Enabled`, `Position`, `Width`, `Offset`, `Outline`, and `Text`.
- `Tracer`: `Enabled`, `Origin`, `Target`, `Thickness`, `Transparency`, and `Outline`.
- `Skeleton`: `Enabled`, `Thickness`, `Transparency`, `Outline`, and `MaxJoints`.
- `HeadDot`: `Enabled`, `Filled`, `Radius`, `Sides`, `Thickness`, `Transparency`, and `Outline`.
- `OffscreenArrow`: `Enabled`, `Radius`, `Size`, `Filled`, `Transparency`, and `Outline`.
- `Highlight`: `Enabled`, `FillTransparency`, `OutlineTransparency`, `DepthMode`, and `HealthColor`.
- `Colors`: `Enemy`, `Gradient`, `Tracer`, `Skeleton`, `HeadDot`, `Arrow`, `Team`, `NPC`, `Part`, `Visible`, `Occluded`, `Outline`, `Text`, `HealthLow`, `HealthHigh`, `HighlightFill`, and `HighlightOutline`.

Public controller methods: `Get(path)`, `Set(path, value)`, `ApplySettings`, `ApplyPreset` (`Performance`, `Balanced`, or `Quality`), `SetEnabled`, `Start`, `Stop`, `WrapObject`, `GetEntry`, `UnwrapObject`, `WrapPlayers`, `UnwrapPlayers`, `ScanNPCs`, `WatchNPCs`, `SetAutomaticNPCs`, `HideAll`, `CreatePreviewAdapter`, `GetStats`, `Restart`, and `Destroy`.

`WrapObject(object, info)` accepts `Id`, `Kind`, `Name`, `Category`, `Team`, `Tool`, `Flags`, `Color`, `GradientColor`, `MaxDistance`, `TextDistance`, `AllowedVisuals`, and `Predicate`. `WatchNPCs(container, info)` returns a watcher with `Scan()` and `Destroy()`. The preview adapter exposes `AttachPreview`, `UpdatePreview`, `SetPreviewVisible`, `DetachPreview`, and `Destroy`.

### UniversalESP MonHubUI API

Load `addons/esp/MonHubUI.lua` and call `MonHubUI.Mount(Library, Tab, Controller, Info)`. Settings are `Prefix` for unique option IDs, `GeneralTitle`, `Keybind`, `AutoNPCs`, `NPCContainer`, `NPCInfo`, and `OwnController`. The returned handle contains the mounted controls and exposes `Destroy()`. When `OwnController` is true, destroying the panel also destroys the ESP controller.

### CollectionModel API

Create it with `{ Items = {}, Selected = id }`. Item IDs remain stable through filtering and replacement.

| Method | Result |
| --- | --- |
| `GetItems()`, `GetItem(id)`, `GetSelected()` | Returns safe copies of collection data. |
| `SetItems(items)`, `AddItem(item)`, `UpdateItem(id, changes)`, `RemoveItem(id)` | Mutates collection data and updates bound views. |
| `Select(id)`, `SetFavorite(id, bool)` | Changes shared selection or favorite state. |
| `Query(options)` | Filters by `Search`, `Category`, `FavoritesOnly`, and `Sort`. |
| `Subscribe(callback)` | Returns a listener with `Disconnect()`. |
| `Bind(view)` | Synchronizes a compatible catalog/gallery controller and returns a binding. |
| `Destroy()` | Disconnects bindings and listeners. |

### SaveManager API

Call `SetLibrary` first. Use `SetFolder` and optionally `SetSubFolder` before building UI or loading configs.

Methods: `SetLibrary`, `SetLoadingOrder`, `SetIgnoreIndexes`, `IgnoreThemeSettings`, `GetPaths`, `BuildFolderTree`, `CheckFolderTree`, `CheckSubFolder`, `SetFolder`, `SetSubFolder`, `RefreshConfigList`, `SaveJSON`, `Save`, `LoadJSON`, `Load`, `Delete`, `GetAutoloadConfig`, `SaveAutoloadConfig`, `LoadAutoloadConfig`, `DeleteAutoLoadConfig`, and `BuildConfigSection`.

`Save` and `Load` operate on named files. `SaveJSON` and `LoadJSON` operate on serialized text. `SetIgnoreIndexes` excludes control IDs. `SetLoadingOrder(true, ids)` controls callback restore order. `BuildConfigSection(tab, icon)` creates the complete config interface.

### ThemeManager API

Call `SetLibrary` first. Methods: `SyncFromLibrary`, `BeginConfigLoad`, `MarkConfigOptionLoaded`, `EndConfigLoad`, `GetPaths`, `BuildFolderTree`, `CheckFolderTree`, `SetFolder`, `SetDefaultThemeFileName`, `ReloadCustomThemes`, `GetCustomTheme`, `SaveCustomTheme`, `Delete`, `GetDefaultTheme`, `SetDefaultTheme`, `SaveDefault`, `LoadDefault`, `DeleteDefaultTheme`, `ThemeUpdate`, `ApplyTheme`, `RefreshThemeList`, `CreateThemeManager`, `CreateGroupBox`, `CreateAppearanceManager`, `ApplyToTab`, and `ApplyToGroupbox`.

`CreateAppearanceManager` exposes live colors, font, corner radius, motion, shadows, dividers, navigation indicator, geometry binding, and accent scrollbar controls. `ApplyTheme(name)` updates all registered UI and addon bindings immediately. Wrap bulk config restores with `BeginConfigLoad()` and `EndConfigLoad()` to avoid intermediate theme callbacks.

### Addon window host API

`Library:CreateAddonWindow(Info)` returns a host used by all standalone visual addons. Its public methods are `SetVisible(visible, instant)`, `Toggle`, `SetTitle`, `SetSubtitle`, `SetIcon`, `SetSize`, `SetPosition`, `AddCustom`, `AddAddon`, `Remove`, `SetModuleHeight`, and `Destroy`. The host clamps itself to the viewport, follows the active theme, clips addon content, and can hide together with the main menu.

## Performance rules

- Load only the addons used by the project.
- Prefer `AssetCatalog` pagination for large collections.
- Use small thumbnails in grids and full images only for the selected preview.
- Do not create a separate `RenderStepped` connection for every widget.
- Reuse the ESP update loop through a renderer adapter.
- Keep function-backed dashboard values above a `0.1` second interval.
- Destroy temporary windows and previews when their feature is removed.
- Use `Library:OnUnload` for every external connection or instance owner.
- Apply theme and design changes through the registry instead of polling colors.
- Use `SetReducedMotion(true)` when a device struggles with UI animation.

## Cleanup

```luau
Library:OnUnload(function()
    print("cleanup")
end)

Library:Unload()
```

`Unload` disconnects registered signals, stops active tweens, destroys addon controllers registered through the library, restores the cursor state, and removes the interface.

## Release checklist

- [x] Runtime sources and type modules compile with the Luau compiler.
- [x] Collection IDs, atomic updates, selection, filters, bindings, and cleanup pass 12 regression tests.
- [x] Twelve UI contract scenarios cover addon lifecycle and geometry, repeated palette/theme changes, custom theme validation, appearance picker synchronization, texture colors, and live addon corners.
- [x] Examples include a shared skin collection, a separate gallery window, grid mode, favorites, and adjustable gallery height.
- [x] Visual addon cleanup visits its own descendants instead of scanning the whole theme registry.
- [ ] Verify real rendering in Roblox at 480, 780, and 1100 pixel window widths, including odd widths, DPI changes, light and dark themes.
- [ ] Verify live image loading, fonts, touch, gamepad input, viewport previews, rapid tab changes, and full-library unload in Roblox.

The addon contract tests use a small Roblox API mock. They check controller behavior and geometry calculations; they do not render Roblox UI or verify engine text metrics, assets, or input routing.

Run local checks with Luau's compiler and interpreter installed:

```powershell
./tests/check.ps1 -Compiler luau-compile -Runtime luau
```

## Changelog

### 0.0.1-release-12

- Clipped every embedded addon at the passthrough boundary so galleries cannot render above the menu or outside their groupbox.
- Replaced cached canvas roots in image addons with stable clipped frames and kept image/card clipping at every nested viewport.
- Reserved scrollbar space inside menus, dashboards, catalogs, and galleries.
- Added the complete addon API reference with constructor settings, item formats, public methods, and lifecycle calls.

### 0.0.1-release-11

- Removed default engine borders from core GUI objects, moved strokes inside their bounds, and masked image addon corners.
- Replaced outlined divider rectangles with optional single-pixel rules; disabled decorative shadows and the navigation accent line by default.
- Added muted scrollbars, adjustable menu scrollbar width, live appearance controls, palette overrides, custom runtime themes, and composable theme bindings.
- Separated theme colors from geometry. Fixed the old/new radius ordering during design changes and made bound radii update live.
- Registered texture gradients with the theme system while retaining explicit item colors.
- Added theme refresh diagnostics and regression coverage for repeated theme changes and appearance synchronization.

### 0.0.1-release-10

- Added a UI-independent collection model and shared embedded/standalone skin selection.
- Added catalog grid-only mode, saved filtering, sorting, and an adaptive toolbar.
- Replaced fractional gallery geometry with integer card sizes and balanced integer padding; added scrolling to image galleries.
- Added resizable addon windows and optional content height fitting. Fixed module ordering, automatic module IDs, subtitle alignment, and visibility tween cancellation.
- Fixed stale preview data after item replacement, instant image changes racing previous fades, badge registration buildup, and module container cleanup.
- Added dashboard and texture height setters, `Activated` button handling, and local regression checks.
- Corrected package entry paths and refreshed the example and type declarations.

### 0.0.1-release-9

- Rebuilt the default shell with a wider content area, softer card hierarchy, full-width navigation rows, consistent header controls, and unified theme surfaces.
- Expanded the design contract with shell, typography, addon window, gallery cell, and preview tokens.
- Added `Library:CreateAddonWindow` for consistent independent modules with drag, close, clamp, visibility motion, custom content, and addon mounting.
- Added `AssetCatalog` for production skin changers and other image collections.
- Added embedded and standalone placement helpers across visual addons.
- Added embedded dashboard support.
- Unified addon spacing, radii, outlines, type sizes, and motion with the main interface.
- Kept all addons opt-in and preserved existing direct creation paths.
- Updated the complete example and type declarations.
- Replaced the old documentation set with this current release guide.
