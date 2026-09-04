# MonHub UI Guide

Current release: `0.0.1-release-9`

MonHub is a compact Roblox Luau interface library built around a neutral dark palette, consistent spacing, short motion, theme-safe surfaces, and optional visual addons. The core library never loads an addon automatically.

## Quick start

```luau
local RELEASE = "0.0.1-release-9"
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

The host owns only modules mounted through it. Destroying the host destroys those module controllers and their registered theme objects.

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

This is the layout to use for a skin changer. Put it in a full-width groupbox (`Tab:AddFullGroupbox`) so the grid has room to breathe, or open it as its own window with `CreateStandalone`. Passing an explicit `Columns` pins the count instead and turns the automatic fitting off.

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

- `Library.ReleaseVersion` reports `0.0.1-release-9`.
- Version mismatch is a warning and never blocks startup.
- The default theme updates the top bar, sidebar, content, controls, and addons.
- Menu open and close motion remains short.
- Tabs switch without font replacement or delayed visibility.
- The compact launcher stays inside the viewport.
- The watermark starts inside the viewport.
- Empty keybinds do not appear in the keybind list.
- Every optional addon works embedded and in its documented direct or standalone mode.
- Large galleries render only their current page.
- `Library:Unload()` removes every owned instance and connection.

## Changelog

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
