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

### Typography and font selection

Every label, control, and addon draws with `Library.Scheme.Font`. Text instances register that property, so changing the font updates the whole interface in place with no rebuild.

MonHub ships **Inter Medium** and loads it from `assets/Inter-Medium.ttf` on first run. Inter is the default because it was drawn for user interfaces: it keeps counters open and stems even at the 12 to 14 pixel sizes this library uses, where a display face turns muddy. If the download fails the library falls back to a built-in Roblox face and records the reason in `Library.DefaultFontError`.

`Library.FontPresets` lists the curated faces. Ask for the ones this client can actually build, then switch by name:

```luau
local Names = Library:GetFontNames()

Settings:AddDropdown("InterfaceFont", {
    Text = "Font",
    Values = Names,
    Default = Library.CurrentFontName,
    Callback = function(Value)
        Library:SetFontByName(Value)
    end,
})
```

| Name | Notes |
| --- | --- |
| `Inter` | Bundled default. Best small-size legibility. |
| `Builder Sans` | Roblox's own interface face. Slightly wider than Inter. |
| `Gotham` | The previous default. Geometric, a little softer. |
| `Montserrat` | Wide and round. Suits large titles more than dense rows. |
| `Montserrat Bold` | Bundled bold cut, downloaded on first use. Heavy for dense rows; best when the menu is meant to read as a display piece. |
| `Roboto` | Neutral and compact. |
| `Source Sans` | Humanist, taller x-height. |
| `Ubuntu` | Distinctive, rounder terminals. |
| `Roboto Mono` | Monospaced. Useful for value-heavy readouts. |

`GetFontNames` builds each face behind `pcall` and omits any the client cannot construct, so the dropdown never offers a font that would fail. `SetFontByName` returns `false` for an unknown or unavailable name and leaves the current font untouched.

Presets come in three kinds, and `GetFontNames` handles each so the dropdown only ever offers what this client can build:

- **Bundled** (`Inter`) uses the face the library loads at startup. Listed only when that load succeeded, so a failed download does not leave a dead entry.
- **Family** presets build a Roblox font family behind `pcall`. A client without that family simply omits it.
- **Download** presets (`Montserrat Bold`) fetch a `.ttf` from the repository's `assets/` folder the first time they are selected, then cache the result. `Library:LoadBundledFont(Name)` performs that fetch and returns `(Font?, reason?)`; the outcome is cached in `Library.BundledFontCache`, so a face that fails once is dropped from later listings rather than retried on every open.

Downloaded faces cost one HTTP request the first time and nothing afterwards, which is why they are resolved lazily instead of at startup.

To supply your own face, load it once and set it directly:

```luau
local Face, Reason = Library:LoadCustomFont("MyFont", "https://example.com/MyFont.ttf", 500)
if Face then
    Library:SetThemeFont(Face)
else
    warn("font unavailable:", Reason)
end
```

`SetThemeFont` also stores the face as a theme override, so switching palettes will not replace it.

### Revealing text and images

`Library:RevealText(Root, Info)` fades every text and image inside `Root` in from transparent, one shortly after the next. Use it when a panel's contents change wholesale, such as a gallery turning a page or a module loading a new record. It is the difference between values snapping into place and a panel that reads as filling in.

```luau
Library:RevealText(Panel, {
    Stagger = 0.012,
    Rise = 4,
    Motion = "TextReveal",
})
```

| Field | Meaning |
| --- | --- |
| `Stagger` | Seconds between successive elements, clamped to `0.08`. `0` reveals everything together. |
| `Rise` | Pixels the root lifts from as it fades in, clamped to `12`. `0` disables the movement. |
| `Motion` | Motion token to use. Defaults to `TextReveal`. |

The function walks `Root` and every descendant, keeping any `TextLabel`, `TextButton`, `TextBox`, `ImageLabel`, and `ImageButton`. It records each one's current transparency as the target, sets it to fully transparent, then tweens back to what it recorded.

That recording step is why the call is safe to make repeatedly. Each root carries a token, and starting a reveal cancels any run still in flight and restores its targets first. Without that, a second call landing mid-fade would record the half-faded value as the resting one and the panel would stay dim. `Library:CancelReveal(Root, Restore)` does the same on demand; pass `false` to leave elements where they are instead of snapping them to their targets.

Reduced motion is respected: with `Library:SetReducedMotion(true)`, or `Motion = false` in the call, the function restores every target immediately and returns without animating.

The asset catalog uses this on every refresh. Turn it off, or slow it down, per instance:

```luau
AssetCatalog.CreateEmbedded(Library, Group, "Catalog", {
    Items = Items,
    Reveal = true,
    RevealStagger = 0.02,
})
```

### Module styles: minimal and highlight

Every addon resolves its look through `Library:GetAddonStyle`, so two switches change any module without touching the module itself.

```luau
AssetCatalog.CreateEmbedded(Library, Group, "Catalog", {
    Items = Items,
    Style = { Minimal = true },
})
```

`Minimal = true` strips the module back to its content. The border is removed (`StrokeThickness = 0`, `OutlineTransparency = 1`), padding and gap each lose two pixels, and the radii tighten by one or two. Use it when a module sits inside a groupbox that already provides a frame, so the interface does not draw two boxes around the same thing.

`Highlight = true` does the opposite: it pulls the outline in to `0.12` transparency, forces at least one pixel of stroke, and recolors the border to the accent through `Style.HighlightColor`. Use it to mark the module the user is currently working in, or one that needs attention.

| | `StrokeThickness` | `OutlineTransparency` | Border color |
| --- | --- | --- | --- |
| default | `1` | `0.5` | `OutlineColor` |
| `Minimal` | `0` | `1` | none drawn |
| `Highlight` | `1` | `0.12` | `AccentColor` |

Both are plain style fields, so they compose with everything else and follow the active theme:

```luau
Style = { Highlight = true, Padding = 12, Motion = false }
```

The border color is registered against the accent token rather than a fixed value, so a highlighted module re-colors with the palette instead of keeping a stale accent.

### Reacting to theme changes

`Library.Registry` binds instance properties to scheme tokens and is the mechanism behind every palette and font swap. A property bound to a string resolves that token; a property bound to a function is re-evaluated on each pass, which is how state-dependent colors stay correct:

```luau
Library:AddToRegistry(Indicator, {
    BackgroundColor3 = function()
        return Library:GetContrastColor(Library.Scheme.AccentColor)
    end,
})
```

Anything that computes a color outside the registry needs a hook so it can recompute:

```luau
local Disconnect = Library:OnThemeChanged(function()
    Panel.BackgroundColor3 = Library.Scheme.SurfaceColor
end)
```

`OnThemeChanged` returns a disposer. Call `Library:ApplyTheme()` to run a full pass yourself: it refreshes the registry, calls every control's `UpdateColors`, and then fires the hooks.

Two helpers exist for choosing readable foregrounds. `Library:GetLuminance(Color)` returns relative luminance, and `Library:GetContrastColor(Background)` returns whichever of the scheme's light or dark color has the higher contrast ratio against that background. The checkbox tick uses this, which is why it stays legible on both a pastel accent and a saturated one.

### Motion

`Library.Design.Motion` holds one entry per interaction, each `{ duration, EasingStyle, EasingDirection }`.

Duration is tuned to what the movement is for, not to a single house value. Anything the user drives directly has to answer immediately, or the interface feels like it is lagging behind them; anything that arrives on its own can afford to be seen:

| Token | Duration | Used by |
| --- | --- | --- |
| `TabExit` | `0.05` | The outgoing tab. Nothing is gained by watching it leave. |
| `Fast` | `0.07` | Small state flips. |
| `WindowClose` | `0.08` | Hiding on the keybind. The user has already decided; get out of the way. |
| `TabEnter` | `0.09` | The incoming tab. |
| `Hover` | `0.09` | Pointer feedback. Slower than this reads as lag. |
| `Control` | `0.12` | Toggles, sliders, checkboxes. |
| `Popup` | `0.14` | Dropdowns and menus. |
| `WindowOpen` | `0.15` | Showing the menu. |
| `Dialog` | `0.16` | Modal dialogs. |
| `TextReveal` | `0.16` | Content fading in through `RevealText`. |
| `Notify` | `0.18` | Notifications arriving unprompted, so worth noticing. |
| `NotifyClose` | `0.11` | Notifications leaving. |

```luau
Library:SetDesign({
    Motion = {
        Scale = 1,
        Hover = { 0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
        TabEnter = { 0.09, Enum.EasingStyle.Quint, Enum.EasingDirection.Out },
        TabExit = { 0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
        WindowClose = { 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out },
    },
})
```

Every entry eases `Out`, so motion is fastest at the start and settles at the end. That is what makes a short duration still read as movement rather than a jump; easing `InOut` at these lengths just looks sluggish.

Tab switching also has `Window.TabTransitionTime` (default `0.085`) and `TabSwipeOffset` (default `10`), the pixels the incoming tab travels. Keep the offset modest: a long slide cannot be fast and legible at the same time.

`TabSwipeFrom` chooses where the incoming tab enters from. Alongside `left`, `right`, `top` and `bottom` there is `auto`, the default, which picks the direction from the move itself. Selecting a tab further down the sidebar brings the new page up from the bottom; selecting one higher up brings it down from the top. The motion then agrees with the direction the user just moved, which is what makes switching read as one surface sliding rather than two pages crossfading.

`auto` needs to know where each tab sits, so every tab receives a sequential `Order` at creation when one is not supplied. Passing `Order` yourself still wins:

```luau
Window:AddTab({ Name = "Combat", Icon = "crosshair", Order = 1 })
```

`Scale` multiplies every duration, so `0.5` halves the whole system and `0` removes motion. Tweens are pooled per instance and per slot, so duration does not affect cost: restarting a tween cancels the previous one on that slot instead of stacking. `Library:SetReducedMotion(true)` disables motion without changing any component's behavior.

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

## Addon recipes

The reference below lists every option. This section covers the decisions that actually matter when you place an addon.

### Choosing a mounting mode

Every visual addon exposes `CreateEmbedded` and `CreateStandalone`. They build the same module; only the container differs.

| Situation | Use |
| --- | --- |
| The module is one setting among many | `CreateEmbedded` into a groupbox |
| The module is the point of the tab | `CreateEmbedded` into `Tab:AddFullGroupbox` |
| The user needs it while reading another tab | `CreateStandalone` |
| The user should be able to move it aside | `CreateStandalone` |

Standalone mode routes the module through `Library:CreateAddonWindow`, so its title bar, icon badge, divider, and close button are the shared ones rather than a second set drawn by the module. That is why a standalone dashboard looks like part of the same product instead of a bolted-on panel.

Both modes accept the same configuration table, so you can move a module between them by changing one call.

### A skin changer that does not feel cramped

This is the most common mistake: a grid dropped into a half-width groupbox has room for one or two columns and reads as a list.

```luau
local Skins = Window:AddTab({ Name = "Skins", Icon = "sparkles" })
local Gallery = Skins:AddFullGroupbox("Weapon finishes", "layout-grid")

local Catalog = AssetCatalog.CreateEmbedded(Library, Gallery, "SkinCatalog", {
    Items = Items,
    Height = 430,
    MinCellWidth = 116,
    PreviewRatio = 0.42,
    ActionText = "Equip",
    SecondaryActionText = "Inspect",
    OnAction = function(Item)
        Equip(Item.Id)
    end,
})
```

Three choices carry this layout:

- `AddFullGroupbox` gives the tab a single full-width column. A grid needs the width more than the tab needs two columns.
- Omitting `Columns` lets the grid fit its own column count to the space available and size every cell to a whole number of pixels. `MinCellWidth` is the narrowest a card may get before a column is dropped. Passing `Columns` pins the count and turns that off.
- `PreviewRatio` below `0.5` keeps the grid dominant. The preview panel is a detail view, not the subject.

If the container can become narrow, the catalog falls back from the split layout to the stacked one on its own, so the grid never collapses to a single column. `SplitMinWidth` sets that threshold.

Give items a `Category` and the toolbar filter populates itself. Give them `Tags` and the search box matches those too.

### A grid with no preview panel

`Layout = "Grid"` hides the preview panel and gives the grid the whole body. Use it when the cards themselves are the interface and a detail pane would only take space away from them, which is the usual shape of a skin picker.

```luau
AssetCatalog.CreateEmbedded(Library, Gallery, "Skins", {
    Items = Items,
    Layout = "Grid",
    Height = 470,
    MinCellWidth = 96,
})
```

`Split` and `Stack` both reserve room for the preview; `Grid` does not, so a narrow container fits noticeably more columns.

### Rarity and per-item colors

An item may carry `AccentColor`, and the card border uses it. Unselected cards draw that color at reduced opacity; the selected card draws it at full strength and selection thickness. Items without one fall back to the outline color, so a mixed collection stays readable.

```luau
local RarityColors = {
    ["Mil-Spec"] = Color3.fromRGB(75, 105, 255),
    ["Restricted"] = Color3.fromRGB(136, 71, 255),
    ["Classified"] = Color3.fromRGB(211, 44, 230),
    ["Covert"] = Color3.fromRGB(235, 75, 75),
}

for _, Item in Items do
    Item.AccentColor = RarityColors[Item.Rarity]
end
```

This is what lets a grid read at a glance: the border carries the tier, so the eye sorts the collection before reading a single label.

### Two levels in one gallery

A catalog holds one list, so a drill-down is a matter of swapping that list and giving the user a way back. Put a synthetic card first rather than adding a separate back button, and the whole surface stays a gallery:

```luau
local BackId = "__back__"

local function showWeapons()
    Suppress = true
    Catalog:SetItems(WeaponCards())
    Suppress = false
end

local function showSkins(Weapon)
    local Cards = { { Id = BackId, Name = "All weapons", ActionText = "Back" } }
    for _, Item in Items do
        if Item.ModelName == Weapon then
            table.insert(Cards, Item)
        end
    end
    Suppress = true
    Catalog:SetItems(Cards)
    Suppress = false
end
```

`OnSelected` receives `(Source, Item)` where `Source` is the exact table you supplied and `Item` is the normalized copy, so custom fields such as `IsWeaponCard` survive on `Source` and on `Item.Source`. Branch on those to decide between drilling in and acting on the item.

The `Suppress` flag matters: swapping the list can re-emit a selection, and without the guard the handler would treat that as a click and immediately drill in again.

### Loading a large collection

`SetItems` replaces the whole collection and resets to the first page. For incremental work use the collection helpers instead of rebuilding:

```luau
Catalog:AddItem({ Id = "fade", Name = "Fade", Category = "Knife", Image = 123456 })
Catalog:RemoveItem("fade")
Catalog:SetCategory("Knife")
Catalog:SetSearch("fade")
Catalog:Select("fade")
```

Only `PageSize` cards exist as instances; paging rebinds them rather than creating more. Raising `PageSize` past what fits on screen costs instances without showing anything, so leave it alone unless you also raise `Height`.

Use `rbxthumb://type=Asset&id=<id>&w=150&h=150` for catalog items. It resolves through Roblox's thumbnail service and avoids a full asset download per card.

### Dashboards for live values

A dashboard is for values that change while the user watches. Anything static belongs in a normal groupbox.

```luau
local Dashboard, Host = DashboardWindow.CreateStandalone(Library, {
    WindowTitle = "Session",
    WindowWidth = 380,
})

local Runtime = Dashboard:AddSection({ Title = "Runtime", Icon = "activity" })
Runtime:AddMetric({
    Label = "Framerate",
    Value = function()
        return string.format("%d fps", math.floor(1 / RunService.RenderStepped:Wait()))
    end,
    Interval = 0.5,
})
```

Every dynamic value shares one scheduler. It pauses when the dashboard is hidden and stops after the last dynamic widget is removed, so a closed dashboard costs nothing. Set `Interval` to the slowest rate that still reads as live; `0.5` is enough for most counters and a quarter of the work of `0.125`.

### Configuring an addon's appearance

Addons inherit the design system. Override per instance only when that module genuinely differs:

```luau
local Catalog = AssetCatalog.CreateEmbedded(Library, Group, "Catalog", {
    Items = Items,
    Style = {
        Padding = 12,
        Gap = 10,
        CellRadius = 4,
        Motion = false,
    },
})
```

`Style` is merged over `Library.Design.Addon`, so anything you leave out keeps following the global tokens and the active theme. Prefer `Library:SetDesign({ Addon = { ... } })` when you want the change everywhere, and reserve per-instance `Style` for one-off cases. Setting `Motion = false` disables that module's animation alone.

### Keeping addons cheap

- Create modules when the user first asks for them, not at startup. A gallery that is never opened should not exist.
- Call `Host:SetVisible(false)` rather than destroying and rebuilding a standalone window the user reopens.
- Destroy modules you will not reuse; `Destroy` releases the instances, its registry entries, and its connections.
- Leave `HideWithMenu` at its default so standalone windows follow the menu keybind instead of floating over the game after the user hides the UI.

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
- Made the theme registry hold strong references. It was weak-keyed, so an element's Luau handle could be collected while the element was still on screen, which silently dropped it from the registry and left it on the previous palette after a theme or font change.
- Released registry entries when a notification is destroyed, and added `Library:ReleaseRegistryTree` for the same job elsewhere.
- Added `Library:OnThemeChanged` and `Library:ApplyTheme` so code that computes colors outside the registry can refresh with everything else.
- Added `Library:GetLuminance` and `Library:GetContrastColor`, and drew the checkbox tick with the higher-contrast scheme color instead of always white. A white tick on a pastel accent sat near a 3:1 ratio and read as a faded, broken mark.
- Grew the checkbox tick and centered it on whole pixels.
- Added the curated font catalog: `Library.FontPresets`, `GetFontNames`, `GetFontPreset`, and `SetFontByName`, each face built behind `pcall` so an unavailable one is never offered.
- Lengthened the motion profile so transitions read as movement rather than a jump, without adding per-frame work.
- Replaced the remaining hardcoded and ad-hoc corner radii with design tokens, and expressed the switch pill and knob as fully round instead of magic numbers.
- Rounded every integer field returned by `GetAddonStyle`, so a fractional override can no longer reach an addon's radii, padding, or control heights.
- Centered the dropdown value icon, which sat three pixels above center.
- Removed the window footer's own corner. `MainFrame` is a `CanvasGroup` whose `UICorner` already masks all four window corners, so the footer's radius double-rounded the bottom two and notched its top two into the content. The mask now produces every window corner, which is why all four finally match.
- Gave the asset catalog toolbar bottom-only corners for the same reason.
- Made the checkbox tick's resting scale derive from its glyph size, so the shrunk state lands on a whole pixel instead of `10.5`.
- Replaced anchor-based centering in tabbox headers with a whole-pixel offset, and sized the key box from its container instead of a `0.75` scale.
- Snapped the keybind panel, which centered on the viewport and landed on a half pixel whenever its own height was odd.
- Cut per-frame work in the cursor render step: mouse icon, position, and visibility are now written only when they change.
- Stopped inactive tabs recomputing their column split on every resize frame.

After these changes a sweep of the full example reports zero fractional positions or sizes across all ten tabs and 2,279 visible objects, with the only remaining entries belonging to the mouse cursor, which tracks the pointer by design.
- Fixed `AddFullGroupbox` discarding a tab's right column. Switching a tab to full width hid that column, so any groupbox already placed on the right vanished and left an empty panel behind. Existing right-hand groupboxes are now moved into the single column in layout order, and `AddRightGroupbox` follows the same column while a tab is full width.
- Retuned the motion profile around what each movement is for rather than one duration: tab changes and closing on the keybind are now the quickest things in the interface, while notifications and dialogs stay visible enough to read.
- Added `Library:RevealText` and `Library:CancelReveal` for staggered text and image fade-ins, with a per-root token so overlapping calls cannot capture a mid-fade value as the resting one. The asset catalog reveals its grid on every refresh, controlled by `Reveal` and `RevealStagger`.
- Added the bundled `Montserrat Bold` face and lazy downloaded font presets through `Library:LoadBundledFont`, cached per name so a failed fetch is not retried on every listing.
- Raised the radius tokens one step to Window 8, Card 6, Control 5, Popup 6, Indicator 3.
- Fixed two cursors appearing at once. The render step had been changed to skip redundant property writes by caching the last value it wrote, but the game can re-enable the system cursor on its own; the cache then still believed it was disabled and never corrected it. The step now compares against the live property, so it self-corrects on the next frame while still skipping writes that would change nothing.
- Made the footer rule span the full window. It was inset eight pixels on each side while the top rule ran edge to edge, so the two did not agree and the bottom one stopped short of the sidebar divider. Both now use the same width, color, and opacity.
- Rebuilt the watermark: an accent rule down its leading edge, tighter vertical padding, and the icon and rule both aligned on whole pixels through `AlignIcon`. Pass `Accent = false` to `AddDraggableLabel` for the previous plain look.
- Gave keybind rows motion. A row scales and fades in when it appears (`AnimateIn`), and the indicator pulses when the bind activates (`Pulse`), so a bind firing is visible without watching the list.
- Added `Minimal` and `Highlight` module styles.
- Made the tab swipe directional through `TabSwipeFrom = "auto"`, and gave every tab a sequential `Order` so the direction can be resolved.
- Made an item's `AccentColor` color its card border at all times rather than only while selected, so a collection can carry rarity or tier on the card itself.
- Made `Window:SetCornerRadius` survive a thread that cannot write to instances. Applying a saved config could raise a capability error and abort the load; the call now retries once on the scheduler and warns only if that also fails.

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
