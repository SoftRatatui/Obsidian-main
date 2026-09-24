# MonHub UI Guide

Current release: `0.0.1-release-3`

The release identifier is intentionally fixed. Library updates keep `0.0.1-release-3` unless the project owner explicitly requests another version.

Always update Library, Example, SaveManager, ThemeManager, and the addons you use together to the latest repository revision. Patches can share this release identifier. Restart the script after updating. See [README.md](README.md) for the current fixes, config setup, recovery instructions, and troubleshooting.

MonHub is a compact Roblox Luau interface library built around a neutral dark palette, consistent spacing, short motion, theme-safe surfaces, and optional visual addons. The core library never loads an addon automatically.

## Config callback scheduling and load reports

Loading the same control value no longer runs its callbacks again. Comparison includes color transparency, key modifiers, hidden data and multi-dropdown membership. `report.Unchanged` counts matching controls; `Applied` counts applied entries, including adapters and layout entries. Adapters still run because their state and side effects belong to the adapter. Initialize application state once when creating controls; do not use repeated config loading as an action button.

```lua
local ok, message, report = SaveManager:Load("default")
if not ok then warn(message) end
for _, entry in SaveManager:GetSlowCallbacks(0.05) do
    print(entry.Id, math.round(entry.Seconds * 1000), "ms")
end
```

`CallbackTimings` is sorted from slowest to fastest and contains `Id`, `Seconds` and `Success` for synchronous callbacks invoked through `Library:SafeCallback`. Durations include time spent yielding. Callback and Changed handlers receive separate entries, even when their option ID matches. `GetSlowCallbacks(seconds)` returns copies of completed entries from the latest load, sorted by duration; the default threshold is 0.05 seconds. Direct custom setter work and adapter execution are not callback timings.

Callbacks remain synchronous by default so existing dependencies and rollback retain their order. Mark independent handlers explicitly:

```lua
Group:AddToggle("RefreshPreview", {
    Text = "Preview",
    Default = false,
    ConfigCallbackMode = "Background",
    Callback = function(enabled)
        UpdatePreview(enabled)
    end,
})
```

`SaveManager:SetCallbackMode("Background")` sets the default for options without an override; `"Sync"` restores the original policy. An option with `ConfigCallbackMode = "Sync"` stays synchronous even when the default is Background. Theme controls always stay synchronous.

Background jobs are queued only after successful option, adapter and theme application. Failed transactions discard them. `OnConfigLoaded` means stored values and adapters have been applied, not that background jobs have finished. `report.BackgroundCallbacks` is a live list with `Id`, `Status` (Pending, Running, Completed, Failed or Cancelled), and, after completion, `Seconds` and optional `Error`. Inspect it after your background work finishes. Errors in these jobs do not roll back an already completed load. Jobs that have not started are cancelled when the library is unloaded; already running work remains the application's responsibility. Repeated loads can overlap background work, so use cancellation tokens in long-running handlers. Background scheduling does not make CPU-bound work run in parallel; break large work into bounded steps.

## AssetCatalog selection, pager and card updates

```lua
local catalog = Group:AddAddon("Assets", AssetCatalog, {
    Items = {
        { Id = "first", Name = "First", Image = 123 },
        { Id = "second", Name = "Second", Image = 456 },
    },
    MultiSelect = true,
    ShowPager = false,
    OnSelected = function(items, normalizedItems)
        print(#items, "selected")
    end,
})
catalog:SetSelected({ "first", "second" }, true)
local items, normalizedItems = catalog:GetSelected()
catalog:SetItemState("first", { Status = "Ready", Favorite = true })
```

With `MultiSelect = true`, clicking a card or calling `Select(id)` toggles its selection. `SetSelected(ids, silent?)` replaces it; an empty array clears it. `GetSelected()` returns new arrays of source records and normalized records in catalog item order. Callback arguments use the same arrays. Treat the records as read-only and use `SetItemState` for edits. Selection survives search, pagination and item replacement when IDs still exist; removed or disabled IDs are removed from the selection. Programmatic selection rejects disabled items. Without MultiSelect, the original single-item API and callback signature remain unchanged. `CollectionModel` currently owns a single selection, so combining it with MultiSelect is rejected explicitly.

`ShowPager = false` always hides the footer. `true` always shows it. Omit it for automatic hiding when there is one page. `SetShowPager(nil)` restores automatic behavior. The grid reclaims the footer space. Hiding the footer does not disable pagination: use `SetPage`, `NextPage` and `PreviousPage`, or choose an appropriate `PageSize` for your view.

`SetItemState(id, patch)` returns true when the ID exists, otherwise false. It accepts the same item fields as `Items`, except that `Id` stays fixed. Use false to clear boolean fields and an empty string to clear Status. Updating Status, Disabled, Locked, Favorite, colors or imagery updates the visible matching card and its preview without replacing card instances. Changes that affect active filters, names, categories or sorting refresh the filtered view. Source tables supplied by the caller are not modified. Selection callbacks are not emitted for state patches; read GetSelected afterward if a patch disables a selected item.

## Runtime display controls

```lua
local status = Group:AddStatRow("Processed", {
    Text = "Processed", Value = "0 items", LabelRatio = 0.55,
})
local progress = Group:AddProgressBar("WorkProgress", {
    Text = "Completed", Min = 0, Max = 100, Value = 0, ShowValue = true,
})
status:SetValue("25 items")
progress:SetValue(25)
progress:SetRange(0, 200)
```

StatRow puts the label and value in separate columns and truncates long text instead of allowing overlap. Options: `Text` (defaults to the ID), `Value`, `Height` (22), `LabelRatio` (0.55, clamped to 0.1..0.9), and `Visible` (true). Methods: `SetText`, `SetValue`, `SetVisible`, `SetHeight`, `Destroy`.

ProgressBar adds `Min` (0), `Max` (100), `Value` (Min), `ShowValue` (true), and optional `Color`; its default height is 30. It uses the library font and theme accent unless Color is supplied. `SetValue` clamps finite values to the range; `SetRange(min, max)` requires a finite increasing range and reclamps the current value. Updates are immediate, so frequent progress reports do not accumulate tweens. It also supports `SetText`, `SetVisible`, `SetHeight` and `Destroy`. Both controls display runtime data and are not saved as configuration options.

## Numeric input and player usernames

```lua
local amount = Group:AddInput("Amount", {
    Text = "Amount", Default = "12000", Numeric = true,
    Min = 0, Max = 1000000, ThousandsSeparator = true,
})
print(amount:GetNumber())
Group:AddDropdown("SelectedPlayer", {
    Text = "Player", SpecialType = "Player", PlayerValue = "Name",
    ExcludeLocalPlayer = true, EnablePlayerImages = true,
})
```

Numeric inputs accept Min and Max independently. `ThousandsSeparator = true` displays comma grouping outside editing. Value and config data remain plain numeric strings; `GetNumber()` returns a number or nil for empty input. Bounded or formatted numeric inputs commit when focus leaves the field, including a mobile tap outside. They do not clamp incomplete text while typing. Programmatic SetValue clamps immediately. Invalid text restores the last valid value. Existing unbounded inputs keep their original live-edit behavior. `AllowEmpty` still controls empty input.

`PlayerValue = "Name"` stores Roblox usernames, not display names or Player instances. It works with Multi and avatar images. Omit it to retain the existing Player-instance API. Player additions and removals refresh the list. Only current players are valid dropdown entries; loading a saved username that is absent follows the existing stale-value fallback and is reported in AdjustedIds. Use a hidden option or a separate catalog when offline names must remain selected.

## Menu state, hidden tabs and authorized UI creation

`Library:IsMenuOpen()` returns a boolean and returns false after unload. `Tab:SetVisible(false)` hides its sidebar button and active content, closes its popups and selects another visible tab when available. If all tabs are hidden, no tab content is shown. Hidden tabs cannot be opened through Show; call SetVisible(true) first. Hidden lazy tabs do not build just because Show was called. Config persistence can still build lazy controls when necessary.

`Library:TryCreateWindow(info)` returns `window` on success, or `nil, message` when CreateWindow raises an error. It does not grant permissions, move work into a privileged thread, or guarantee recovery of partially created UI. Create UI from an authorized client context. If the caller lacks a Roblox capability, correct the caller or environment before retrying; a task.defer/task.spawn wrapper is not a permissions fix.


## Contents

- [Quick start](#quick-start) and [Standards](#standards)
- [Window](#window), [tabs and groupboxes](#tabs-and-groupboxes), [controls](#controls), and [design system](#design-system)
- [Addon mounting](#addon-mounting), [generic addon windows](#generic-addon-windows), and [collections without UI](#collections-without-ui)
- [Asset catalog](#asset-catalog), [image gallery and preview](#image-gallery-and-image-preview), [dashboard](#dashboard), and [character preview](#character-preview)
- [Themes](#themes), [configs](#configs), [notifications](#notifications), and [watermark](#watermark)
- [Addon recipes](#addon-recipes), [complete API reference](#complete-addon-api-reference), and [release checklist](#release-checklist)
- [Runtime and advanced API](#runtime-and-advanced-api): reactivity, performance, declarative builder, registry, search, sub-tabs, touch, diagnostics, new controls, and performance numbers

## Quick start

```luau
local RELEASE = "0.0.1-release-3"
local CACHE = RELEASE .. "-configs-2-" .. tostring(os.time())
local BASE = "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/"

local Library = loadstring(game:HttpGet(BASE .. "Library.lua?monhub=" .. CACHE, false))()

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

## Standards

These rules form the supported way to build a reliable MonHub interface.

### Initialization order

1. Load `Library.lua` and verify `Library.ReleaseVersion`.
2. Load only the addon modules the project uses.
3. Create one window, its tabs, groupboxes, controls, and addon controllers.
4. Choose the ThemeManager folder, then call `ThemeManager:SetLibrary(Library)` before creating theme controls.
5. Call `SaveManager:SetLibrary(Library)`, choose its folder, and register module adapters.
6. Build the config section after every saved control exists.
7. Call `LoadAutoloadConfig()` last.

Missing controls or adapters are skipped for compatibility when other entries can be restored. If none of the saved entries match the current UI, loading fails with an initialization error. The load report includes `Applied`, `Skipped`, `Missing`, and `MissingIds`; autoload also returns `Status` and, when loaded, `ConfigName`.

### Stable IDs and state

- Give every toggle, slider, dropdown, input, color picker, key picker, passthrough, and config adapter a unique ID that never changes between releases.
- Never reuse an ID for a different control type. Existing user configs identify state by type and ID.
- Keep gameplay state in a controller or model. UI callbacks should call controller methods instead of owning the feature state.
- Use `CollectionModel` when embedded and standalone views must share items, favorites, and selection.
- Register non-control state with `SaveManager:RegisterAdapter`. This covers addon layout, selected presets, module visibility, and project-specific settings.

### Layout and visual quality

Text measurement failures, including mobile `Temp read failed` errors, fall back to built-in font metrics and then a conservative UTF-8 estimate. Temporary measurements expire after five seconds, allowing the next request to retry the original font. Custom font loading verifies that the text service can read the face before assigning it; failed startup font loading keeps the built-in Gotham face. These fallbacks preserve layout availability but approximate metrics can differ from the selected font. Update all components together and test the result on the target device.

- Use `AddFullGroupbox` for catalogs, galleries, and other wide content. Half-width columns are intended for ordinary controls.
- Size custom GUI in whole pixels. Avoid fractional offsets, strokes wider than the available padding, and negative bounds unless the direct parent clips descendants.
- Let one instance own each visible corner. The window root owns the four window corners; a groupbox root owns its card corners; headers and footers stay inside those masks and must not add another full-size rounded layer.
- Keep child surfaces one physical pixel inside a stroked window edge. This prevents two anti-aliased fills from competing for the same corner pixel.
- Navigation rows use the full sidebar width. Put spacing inside the label and icon, not around the selected background. Change `Shell.NavigationInset` only when an intentionally inset navigation style is required.
- Keep dividers away from rounded edges. A groupbox divider begins and ends at its horizontal content padding rather than touching the outline.
- Mount custom content through `AddUIPassthrough`, `Groupbox:AddAddon`, or `Library:CreateAddonWindow`; these containers handle clipping and cleanup.
- Use `MinCellWidth` instead of a fixed column count when a gallery must respond to different window widths.
- Use `Library:SetPalette`, `SetTheme`, `SetDesign`, `BindTheme`, or `BindAddonStyle` for theme-dependent properties. Raw colors are suitable only for content-specific colors such as item rarity.
- Keep one strong owner for each addon controller and call `Destroy()` when that feature is removed.

### Callbacks and performance

- Keep UI callbacks short. Move yielding work, HTTP requests, and expensive scans into a controller task.
- Reuse one data model and one render loop instead of polling the same state from every widget.
- Use paged catalogs for large item collections and load large preview assets only for the selected item.
- Dashboard providers should normally use intervals of at least `0.1` seconds.
- Register external connections and instances with `Library:OnUnload`, or let an addon controller own and destroy them.
- Prefer `SetReducedMotion(true)` on constrained devices rather than removing state feedback.

### Module selection

| Need | Module |
| --- | --- |
| Skin, weapon, map, vehicle, or inventory browser | `AssetCatalog` |
| Small paged thumbnail selector | `ImageGallery` |
| Large selected image or inspect panel | `ImagePreview` |
| Beam, trail, or texture preset chooser | `TextureGallery` |
| Shared collection state without UI | `CollectionModel` |
| Movable metrics and action panel | `DashboardWindow` |
| Character model and ESP inspection | `VisualPreview` or `FixedR6Preview` |
| Native character trail effect | `CharacterTrail` |
| Decorative tracer configuration | `TracerPreview` |
| Live ESP runtime | `addons/esp/ESP.lua` with `MonHubUI.lua` |
| Persistent controls and module state | `SaveManager` |
| Built-in themes and live appearance editing | `ThemeManager` |

### Config reliability

- Use a project-specific root folder and a place or profile subfolder.
- Treat config names as file names: no slashes, reserved characters, `.`/`..`, or the reserved name `autoload`.
- Keep `LoadAutoloadConfig()` after all setup. It returns `true` when no autoload is configured, so first launch is not an error.
- Check the boolean and error returned by every direct `Save`, `Load`, `Delete`, and autoload operation.
- Call `IgnoreThemeSettings()` when theme choice belongs to the user rather than to each gameplay config.
- Do not edit the generated `schema` field. Newer unsupported schema versions are rejected before any state changes.
- Config writes are staged and read back before replacement. Failed loads restore the pre-load snapshot when possible.
- Temporary and backup files retain supported extensions: `Main.pending.json`, `Main.backup.json`, `autoload.pending.txt`, and `autoload.backup.txt`. They are excluded from the config list. Names ending in `.pending` or `.backup` are reserved.
- `Set as autoload` chooses an existing saved config. Use `Overwrite config` to persist later UI changes; assigning autoload does not enable continuous autosave.
- Callback errors return failure and trigger rollback. Removed controls are a separate compatibility case and appear in the report. A callback that starts external asynchronous work must handle its own cleanup.

### Cleanup

`Library:Unload()` is the final owner. It closes UI, stops registered tweens and signals, and destroys registered addons. Custom services, Drawing objects, and controllers created outside the library still need an `OnUnload` callback or their own explicit `Destroy()` call.

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

Dropdown values occupy the full control height and align vertically in the center. Long labels use engine text truncation within the space before the arrow, preserving UTF-8 text. The value, label, search field, and popup rows fit the selected font's measured line height without changing the control geometry. Custom font metrics can differ; unusually tall faces reduce their text size within the existing row. Pixel fonts still look sharpest at whole-number text sizes and 100% DPI.

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
| `Inter 28pt Medium` | Medium cut of Inter from the external font catalog. |
| `Inter 28pt SemiBold` | Heavier Inter cut for headings and emphasized values. |
| `Minecraftia` | Pixel face suited to Minecraft-style panels and labels. |
| `Proggy Tiny` | Compact bitmap-style face for dense technical readouts. |
| `Verdana` | Familiar, wide interface face with clear small text. |
| `Tahoma 8px` | Small pixel-oriented Tahoma cut. Use whole-number text sizes. |
| `Smallest Pixel 7` | Very compact pixel face for short labels and counters. |
| `Tahoma Bold` | Bold Tahoma cut for headings and strong status labels. |
| `Roboto` | Neutral and compact. |
| `Source Sans` | Humanist, taller x-height. |
| `Ubuntu` | Distinctive, rounder terminals. |
| `Roboto Mono` | Monospaced. Useful for value-heavy readouts. |

`GetFontNames` builds each face behind `pcall` and omits any the client cannot construct, so the dropdown never offers a font that would fail. `SetFontByName` returns `false` for an unknown or unavailable name and leaves the current font untouched.

Presets come in three kinds, and `GetFontNames` handles each so the dropdown only ever offers what this client can build:

- **Bundled** (`Inter`) uses the face the library loads at startup. Listed only when that load succeeded, so a failed download does not leave a dead entry.
- **Family** presets build a Roblox font family behind `pcall`. A client without that family simply omits it.
- **Download** presets fetch a `.ttf` the first time they are selected, then cache the result. `Montserrat Bold` comes from this repository. The eight additional faces come from the supplied [font catalog](https://github.com/i77lhm/storage/tree/main/fonts). `Library:LoadBundledFont(Name)` performs the fetch and returns `(Font?, reason?)`; the outcome is cached in `Library.BundledFontCache`, so a face that fails once is dropped from later listings rather than retried on every open.

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

Four independent chrome fields give precise control when `Minimal` is too broad:

| Field | Default | Effect |
| --- | --- | --- |
| `ShowBackground` | `true` | Keeps or removes the module root fill. |
| `ShowOutline` | `true` | Keeps or removes only the root stroke. |
| `ShowShadow` | `true` | Controls the shadow of a standalone addon window. `Minimal` disables it. |
| `ShowHeader` | `true` | Controls the shared standalone window header. Pass `false` for a content-only floating module. |

Use a content-only module inside an existing surface like this:

```luau
local Gallery = ImageGallery.CreateEmbedded(Library, Groupbox, "Skins", {
    Items = Items,
    Style = {
        Minimal = true,
        ShowBackground = false,
        Padding = 4,
        Gap = 6,
    },
})
```

Visual addons expose `SetStyle`, `SetMinimal`, and `SetHighlighted`. These methods change the existing root and its registered theme bindings; they do not destroy the controller, reset selection, or rebuild image items.

```luau
Gallery:SetMinimal(true)
Gallery:SetHighlighted(true)
Gallery:SetStyle({
    ShowBackground = true,
    ShowOutline = true,
    Radius = 4,
    SelectionThickness = 2,
})
```

`SetMinimal(false)` and `SetHighlighted(false)` restore the normal style derived from the instance's original overrides. A highlighted border always resolves its accent again during a theme update. Use highlighting for current selection, validation attention, a drag target, or the module that receives keyboard input. Do not use it on every module at once because then it stops communicating state.

For modules mounted in a generic addon window, the host provides the same operation by ID:

```luau
Host:SetModuleMinimal("Gallery", true)
Host:SetModuleHighlighted("Preview", true)
Host:SetModuleHighlighted("Preview", true, Color3.fromRGB(108, 190, 255))
Host:SetModuleStyle("Gallery", {
    Minimal = false,
    ShowOutline = true,
    Radius = 5,
})

local EffectiveStyle = Host:GetModuleStyle("Gallery")
```

Packaged visual addons draw the highlight with their existing root stroke. Custom modules use one inner stroke on the transparent, clipped host holder. The two paths are exclusive, so enabling a highlight does not stack coincident borders or let a stroke escape the window. `SetModuleStyle` forwards the style to visual addon controllers that support live styling. Custom GUI modules still receive host-level background, outline, radius, minimal, and highlight behavior.

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
ThemeManager:SetFolder("MonHub")
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

Persist the current palette and choose a startup theme with the ThemeManager filesystem API:

```luau
local Saved, SaveError = ThemeManager:SaveCustomTheme("Ocean")
if Saved then
    ThemeManager:SaveDefault("Ocean")
else
    warn(SaveError)
end

ThemeManager:ReloadCustomThemes()
ThemeManager:LoadDefault()
```

Call `SetFolder` before `SetLibrary`, because initialization scans `<folder>/themes` and applies the saved startup theme. Custom theme files use schema validation and verified temporary writes. The persistence controls appear in `CreateThemeManager` when the executor exposes `isfolder`, `isfile`, `listfiles`, `makefolder`, `readfile`, `writefile`, and `delfile`.

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
Host:SetModuleHighlighted("Preview", true)
Host:SetModuleMinimal("Custom", true)
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

ThemeManager:SetFolder("MonHub")
ThemeManager:SetLibrary(Library)
ThemeManager:ApplyTheme("Default")
ThemeManager:ApplyToTab(Tabs.Settings)
ThemeManager:CreateAppearanceManager(Tabs.Settings:AddRightGroupbox("Appearance", "sliders-horizontal"))
```

Built-in themes are `Default`, `Metal`, `Midnight`, `Steel`, `Sage`, `Ash`, `Dusk`, `Dawn`, and `Honey`. Every core surface and every current visual addon registers its palette properties. Theme changes update the top bar, sidebar, content, controls, addon windows, cards, previews, text, and outlines together.

### Warm and dusk themes

Three palettes sit beside the dark defaults:

| Theme | Kind | Accent | Body text contrast |
|---|---|---|---|
| `Dusk` | dark, violet night | soft rose | 12.5:1 |
| `Dawn` | light, warm paper | dusty rose | 8.3:1 |
| `Honey` | light, cream | deep amber | 9.3:1 |

Aliases: `dusk`, `rosepine`, `dawn`, `rose`, `pink`, `light`, `honey`, `amber`.

The light themes follow the rules that keep a light UI calm: text is a soft plum
or brown rather than black, the background is warm paper rather than white, and
raised panels are lighter than the window behind them. Muted text stays above
4.5:1 and the accents above 3:1 against their panels.

A palette whose background is bright is treated as light automatically, whether
it arrives through `SetTheme` or a `SetPalette` preview. On light themes,
inactive tab labels and unchecked toggle labels dim less (see
`Library:GetIdleTransparency`), because dimming dark text toward a light
background loses contrast much faster than dimming light text on a dark one.

`Library:GetIdleTransparency(Base?)` returns `Base` (default `0.5`) on dark
themes and `Base * 0.55` on light ones. Use it for any resting-state text or icon
you dim with transparency.

## Configs

```luau
local SaveManager = loadstring(game:HttpGet(
    BASE .. "addons/SaveManager.lua?monhub=" .. CACHE, false
))()

SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("MonHub")
SaveManager:SetSubFolder(tostring(game.PlaceId))
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
```

Create all saved controls before loading the autoload config. Use stable option IDs and do not reuse one ID for different controls.

Register UI-independent module state before autoload:

```luau
SaveManager:RegisterAdapter("SkinCatalog", {
    Save = function()
        return {
            Selected = Catalog:GetSelected() and Catalog:GetSelected().Id,
            Layout = Catalog.Layout,
        }
    end,
    Validate = function(Value)
        return type(Value) == "table" and type(Value.Layout) == "string", "invalid catalog state"
    end,
    Load = function(Value)
        Catalog:SetLayout(Value.Layout)
        Catalog:Select(Value.Selected, true)
    end,
})
```

`Load` and `LoadJSON` return `success, errorMessage, report`. `report.Applied`, `report.Skipped`, and `report.Total` make version compatibility visible without treating missing optional controls as a fatal error. Values are validated before changes begin. If a control callback or adapter fails during loading, the manager restores the snapshot taken immediately before the load and includes any rollback failure in `errorMessage`.

## Notifications

The default is a small toast with a quiet outline, 12px title, 11px description, and no permanent decoration. Accent bars, progress bars, icons, and close buttons are opt-in. Cards use a short fade and three-pixel vertical movement without scaling the text.

```luau
Library:SetNotificationOptions({
    Side = "Right",
    Width = 260,
    Margin = 8,
    Gap = 5,
    Padding = 7,
    CornerRadius = 4,
    TitleTextSize = 12,
    DescriptionTextSize = 11,
    MaxVisible = 4,
    DefaultDuration = 3.5,
    Accent = false,
    ShowProgress = false,
    Dismissible = false,
})

Library:Notify({
    Title = "Saved",
    Description = "Your changes are ready.",
    Time = 3,
    Icon = "circle-check",
})
```

| Setting | Range and behavior |
| --- | --- |
| `Width` | 160 to 520 local pixels; reduced when necessary to fit the viewport and DPI. |
| `TitleTextSize` / `DescriptionTextSize` | 9 to 20 pixels. `TextSize` remains a compatibility shortcut: it sets the title and makes the description one pixel smaller. |
| `Padding` | 4 to 24 pixels inside the card. |
| `CornerRadius` | 0 to 18 pixels. |
| `Margin` / `Gap` | Screen margin 0 to 40; stack gap 0 to 24. |
| `MaxVisible` | 1 to 20. The oldest cards also close when the stack exceeds the viewport height. This includes persistent cards. |
| `DefaultDuration` | Nonnegative seconds; `Time` overrides this per notification. |
| `Accent` / `ShowProgress` / `Dismissible` | Enable the leading accent, progress track, or close button. |

Changes to the library font or global appearance update open cards. Notification text binds directly to `Library.Scheme.Font`; RichText is disabled so content cannot silently replace its weight or styling. A card's explicit `Width`, text sizes, `Padding`, `CornerRadius`, `Accent`, `ShowProgress`, or `Dismissible` override remains in effect. The duration of an existing card is not restarted by appearance changes.

`Variant` accepts `Default`, `Success`, `Warning`, `Error`, and `Danger`. Warning and error variants choose a corresponding accent palette color; success uses a green accent; use `Icon` and `IconColor` to add an explicit status symbol. `AccentColor`, `TitleColor`, and `DescriptionColor` override colors. `BigIcon` uses a 24px icon instead of the compact 16px icon. Optional `SoundId` and `Volume` play a sound once; volume defaults to 1 and is limited to 0 to 10.

The returned controller supports `ChangeTitle(text)`, `ChangeDescription(text)`, `ChangeStep(number)` / `SetProgress(number)`, `Resize()`, and `Destroy(instant?)`. A title or description can be added after creation or cleared with an empty string. Calls after destruction do nothing. `Library:ClearNotifications()` also removes cards that are already fading out.

```luau
local Notice = Library:Notify({
    Title = "Loading assets",
    Description = "0 / 3",
    Steps = 3,
    Persist = true,
    ShowProgress = true,
})
Notice:SetProgress(1)
Notice:ChangeDescription("1 / 3")
Notice:SetProgress(3)
Notice:ChangeTitle("Assets loaded")
Notice:Destroy()
```

`Steps` must be a finite positive number. Progress starts at zero and is clamped to that range; it is never overwritten by the lifetime timer. Use `Persist = true` when the task itself decides when to close the card. Alternatively, pass an `Instance` as `Time` to close the notification when that object is destroyed. Closing the notification never destroys the caller's object. Timers, connections, and theme bindings are released on dismissal and library unload.

## Watermark

The default watermark is a single compact text strip without an icon or accent. It keeps a subtle outline and independent horizontal and vertical spacing.

### Segmented watermark

`Library:SetWatermarkSegments(Segments)` replaces the single text strip with a
row of segments, each an optional Lucide icon plus text, split by thin vertical
dividers.

```luau
Library:SetWatermarkVisibility(true)
Library:SetWatermarkSegments({
    { Icon = "swords", Text = "MonHub", Accent = true },
    { Icon = "terminal", Text = "{executor}" },
    { Icon = "wifi", Text = "{ping} ms" },
    { Icon = "gauge", Text = "{fps} FPS" },
})
```

Each segment is a table or a plain string:

| Field | Type | Default | Meaning |
|---|---|---|---|
| `Text` | string | `""` | Text with `{token}` substitutions, resolved on every refresh |
| `Icon` | string? | none | Lucide icon name or asset id, drawn at 16px |
| `Accent` | boolean? | `false` | Draws icon and text in the accent colour; use it for the hub name only |

- Tokens are the same ones `SetWatermarkFormat` uses (`fps`, `ping`, `time`,
  `date`, `player`, `game`, `version`, `executor`, plus any added with
  `RegisterWatermarkToken`). Only segments whose text actually changed are
  rewritten.
- Setting segments clears any format string, and `SetWatermarkFormat` clears
  segments. `SetWatermarkSegments(nil)` or an empty list returns to the plain
  strip.
- It applies 5px vertical padding, 10px horizontal padding and a 5px radius.
  Call `SetWatermarkOptions` afterwards to change them.
- Dragging, side placement and screen clamping work exactly as before, because
  the segments live inside the same draggable label.

### Refresh behaviour

The watermark refreshes about four times a second while it is visible,
**including when the menu is closed**, since that is when FPS and ping matter.
It stops only when the watermark itself is hidden. Earlier builds stopped it
together with the menu, which froze the numbers during play.

`{fps}` counts rendered frames. A counter runs only while the watermark is
visible and its text contains `{fps}`, and it is disconnected otherwise. Without
the counter it falls back to `workspace:GetRealPhysicsFPS()`, which is the
physics rate and sits near 60 regardless of the real frame rate.

`{executor}` returns `identifyexecutor()` when the executor provides it, and an
empty string otherwise.

```luau
Library:SetWatermarkOptions({
    Text = "MonHub   ·   144 FPS   ·   24 ms",
    Icon = "",
    IconPosition = "left",
    Side = "Left",
    Margin = 8,
    Draggable = true,
    Visible = true,
    TextSize = 13,
    BackgroundTransparency = 0,
    OutlineTransparency = 0.5,
    CornerRadius = 5,
    Padding = 6,
    HorizontalPadding = 10,
    Accent = false,
    AccentWidth = 2,
    Scale = 1,
})
```

| Setting | Range and behavior |
| --- | --- |
| `TextSize` | Whole pixels, 9 to 28. |
| `Padding` / `HorizontalPadding` | Vertical padding 2 to 20; horizontal padding 4 to 32. |
| `Margin` | 0 to 40 pixels. Changing it restores placement at the selected side. |
| `CornerRadius` | 0 to 16 pixels. |
| `BackgroundTransparency` / `OutlineTransparency` | 0 is opaque, 1 is invisible. |
| `Accent` / `AccentWidth` | Optional marker, 1 to 4 pixels wide. It can be enabled after creation. |
| `Scale` | 0.5 to 2, multiplied by the library DPI scale. |
| `TextColor` / `BackgroundColor` / `AccentColor` | A `Color3` or scheme key such as `"FontColor"`; scheme keys follow theme changes. |
| `Icon` / `IconPosition` | Asset or icon name; use `""` to clear it, and `"left"` or `"right"` to position it. |
| `Position` | Explicit `UDim2` placement. It takes precedence over side placement in the same call. |

Use `SetWatermark(text)` for frequent FPS and ping updates; unchanged text is not assigned again. `SetWatermarkOptions` changes appearance or behavior. `SetWatermarkSide`, `SetWatermarkDraggable`, and `SetWatermarkVisibility` remain available. Long text truncates at the available viewport width, and icons align in local coordinates at any DPI.

`AddDraggableLabel` uses the same geometry and accepts `Padding`, `HorizontalPadding`, `Scale`, `CornerRadius`, `Accent`, `AccentWidth`, `TextColor`, `AccentColor`, and `OutlineTransparency` in its constructor or `SetStyle` method. Destroy labels when they are no longer needed so their theme and scale registrations are released.

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
| `SetStyle(overrides)`, `SetMinimal(bool)`, `SetHighlighted(bool)` | Changes root chrome while preserving catalog state. |
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

Methods: `Refresh`, `SetItems`, `AddItem`, `RemoveItem`, `SetSearch`, `SetCategory`, `SetPage`, `NextPage`, `PreviousPage`, `SetColumns`, `SetMinCellWidth`, `SetCellHeight`, `SetScaleType`, `SetImageTransparency`, `SetImageBackgroundTransparency`, `SetBackgroundTransparency`, `SetCellTransparency`, `SetOutlineTransparency`, `SetContainerOutlineTransparency`, `SetImagePadding`, `SetLabelHeight`, `SetImageSize`, `SetImageScale`, `SetImagePosition`, `SetTileSize`, `SetRotation`, `SetCornerRadius`, `SetStyle`, `SetMinimal`, `SetHighlighted`, `Select`, `GetSelected`, `BindPreview`, `SetVisible`, `SetHeight`, `Mount`, and `Destroy`.

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

Methods: `SetImage(value, transition)`, `SetTitle`, `SetSubtitle`, `SetImageColor`, `SetImageTransparency`, `SetScaleType`, `SetImageSize`, `SetImageScale`, `SetImagePosition`, `SetImagePadding`, `SetTileSize`, `SetRotation`, `SetBackgroundTransparency`, `SetCanvasTransparency`, `SetCaptionTransparency`, `SetOutlineTransparency`, `SetOutlineThickness`, `SetCornerRadius`, `SetShade(visible, transparency)`, `SetCaptionVisible`, `SetMotion`, `SetStyle`, `SetMinimal`, `SetHighlighted`, `SetHeight`, `SetVisible`, `Mount`, and `Destroy`.

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

Texture items accept `Id`, `Name`, `Texture`, `AssetId`, `Image`, `ColorA`, `ColorB`, `ScaleType`, `ImageScale`, `Zoom`, `ImageTransparency`, and `Transparency`. Methods: `SetItems`, `Select`, `GetSelected`, `SetVisible`, `SetColumns`, `SetImageTransparency`, `SetPreviewImageTransparency`, `SetCardTransparency`, `SetPreviewTransparency`, `SetOutlineTransparency`, `SetScaleType`, `SetImageScale`, `SetStyle`, `SetMinimal`, `SetHighlighted`, `Mount`, `SetHeight`, and `Destroy`.

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

Methods: `SetLibrary`, `SetLoadingOrder`, `SetIgnoreIndexes`, `IgnoreThemeSettings`, `RegisterAdapter`, `UnregisterAdapter`, `GetPaths`, `BuildFolderTree`, `CheckFolderTree`, `CheckSubFolder`, `SetFolder`, `SetSubFolder`, `RefreshConfigList`, `SaveJSON`, `Save`, `LoadJSON`, `Load`, `Delete`, `GetAutoloadConfig`, `SaveAutoloadConfig`, `LoadAutoloadConfig`, `DeleteAutoLoadConfig`, and `BuildConfigSection`.

`SaveJSON` returns `json, success, error`. `Load`, `LoadJSON`, and `LoadAutoloadConfig` return `success, error, report`. Other file mutations return `success, error`. Check these results instead of treating a completed call as success. `LastLoadReport` retains the last application report. `SaveManager:Notify(message, title, variant)` creates a structured library notification.

Default restoration order is Input, Dropdown, Slider, ColorPicker, Toggle, KeyPicker, Groupbox, Custom. Explicit IDs or types supplied to `SetLoadingOrder` run first. Multi-select values use a JSON array of selected values; legacy selection maps are also accepted. Groupbox identity includes its tab, and numeric and string IDs remain distinct.

`Save` and `Load` operate on named files. `SaveJSON` and `LoadJSON` operate on serialized text. `SetIgnoreIndexes(ids, true)` replaces the ignore set; omitting the second argument extends it. `SetLoadingOrder(true, idsOrTypes)` controls callback restore order. `RegisterAdapter` adds serializable state that is independent of a built-in control. `BuildConfigSection(tab, icon)` creates the complete config interface.

### ThemeManager API

Call `SetLibrary` first. Methods: `SyncFromLibrary`, `BeginConfigLoad`, `MarkConfigOptionLoaded`, `EndConfigLoad`, `GetPaths`, `BuildFolderTree`, `CheckFolderTree`, `SetFolder`, `SetDefaultThemeFileName`, `ReloadCustomThemes`, `GetCustomTheme`, `SaveCustomTheme`, `Delete`, `GetDefaultTheme`, `SetDefaultTheme`, `SaveDefault`, `LoadDefault`, `DeleteDefaultTheme`, `ThemeUpdate`, `ApplyTheme`, `RefreshThemeList`, `CreateThemeManager`, `CreateGroupBox`, `CreateAppearanceManager`, `ApplyToTab`, and `ApplyToGroupbox`.

`CreateAppearanceManager` exposes live colors, font, corner radius, motion, shadows, dividers, navigation indicator, geometry binding, and accent scrollbar controls. `ApplyTheme(name)` updates all registered UI and addon bindings immediately. Wrap bulk config restores with `BeginConfigLoad()` and `EndConfigLoad()` to avoid intermediate theme callbacks.

Call `SetFolder` before `SetLibrary` when custom persistence is used. `SaveCustomTheme(name)` writes the active palette, `ReloadCustomThemes()` discovers saved JSON themes, `SaveDefault(name)` selects the startup theme, and `LoadDefault()` applies it. Built-in names are protected case-insensitively and cannot be overwritten by custom files.

### Addon window host API

`Library:CreateAddonWindow(Info)` returns a host used by all standalone visual addons. Its public methods are `SetVisible(visible, instant)`, `Toggle`, `SetTitle`, `SetSubtitle`, `SetIcon`, `SetSize`, `SetPosition`, `AddCustom`, `AddAddon`, `GetModule`, `GetModules`, `GetModuleStyle`, `Detach`, `Remove`, `SetModuleHeight`, `SetModuleVisible`, `SetModuleOrder`, `SetModuleFitHeight`, `SetModuleStyle`, `SetModuleHighlighted`, `SetModuleMinimal`, `SetContentSpacing`, `RefreshLayout`, and `Destroy`. The host clamps itself to the viewport, follows the active theme, clips addon content, and can hide together with the main menu. Multiple `FitHeight` modules share the available height instead of each claiming the full viewport.

`AddCustom(id, object, height, controller, style)` accepts an optional fifth style argument. Use it to give custom content the same minimal and highlight contract as packaged addons. `AddAddon(id, addon, info)` reads the style from `info.Style`. Both paths store the effective style beside the module and keep its highlight inside the holder bounds.

Pass `ShowHeader = false` to `CreateAddonWindow` for a compact content-only window. Its content starts at the first pixel, dragging uses the root, and no empty title-bar space remains. `Style.ShowBackground`, `Style.ShowOutline`, and `Style.ShowShadow` can then be combined independently. A fully minimal standalone host is:

```luau
local Host = Library:CreateAddonWindow({
    Width = 360,
    Height = 260,
    ShowHeader = false,
    Style = {
        Minimal = true,
        ShowBackground = true,
        Padding = 4,
        Gap = 4,
        Radius = 4,
    },
})
```

`Host:Detach(id, parent)` transfers an existing module to a GUI container and returns its controller (or root for a custom module). It preserves the module state, removes the old holder, and stops the old host from owning its destruction. The new parent must be outside the old module holder. A missing module returns `nil`. To transfer it to another host:

```luau
local Gallery = SourceHost:Detach("Gallery", TargetHost.Content)
if Gallery then
    TargetHost:AddCustom("Gallery", Gallery.Root, Gallery.Height, Gallery)
end
```

After a direct detach, call the returned controller's `Destroy()` when finished. After transfer using `AddCustom` with the controller argument, the target host owns cleanup. `Remove(id)` destroys a module instead. If `AddAddon` fails while replacing an ID, the previous module remains usable.


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
- [x] Config regression coverage verifies round-trip values, legacy color transparency, custom adapters, deterministic compatibility skips, autoload cleanup, and rollback after a callback failure.
- [x] Theme persistence coverage verifies custom theme writes, reload, startup selection, protected built-in names, and deletion.
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

### 0.0.1-release-3

- Tightened the default density: 20px control rows in `Compact` (checkboxes 26px apart instead of 33px), `Grid.RowGap` wired to the groupbox gap, 32px groupbox headers, 44px top bar, 184px sidebar with 32px tab rows.
- Made the selected sidebar tab fill its row edge to edge with a full-height accent bar, and added `Window:AddTabSeparator` for captioned or plain sidebar sections.
- Reworked sub-tabs with 28px indented rows hanging off a straight 1px tree (stem under the parent icon, trunk, a branch per child), the path to the open child lit in the accent colour, and a lit parent while a child is open (`Library:AnimateTabTrail`).
- Started the sidebar tab list flush under the header, and fixed expanded sub-tab groups doubling their height at UI scales other than 100%.
- Added the `Dusk`, `Dawn` and `Honey` themes and raised the default theme's layer separation and accent saturation.
- Fixed light themes: contrast picking on the accent, light detection for palette previews, the disabled switch knob, the sidebar divider hover, the white collapse arrow, and over-dimmed resting labels (`Library:GetIdleTransparency`).
- Added `Library:SetWatermarkSegments` for icon and text segments, kept the watermark refreshing while the menu is closed, made `{fps}` count rendered frames, and added the `{executor}` token.
- Fixed half-pixel window centring on odd-width viewports.

- Fixed filesystem compatibility by keeping supported extensions on temporary and backup config/theme files; verified backups and recovery now cover partially failing writes.
- Fixed cross-tab groupbox identity, disabled control restore, numeric multi-select persistence, finite slider validation, and callback error propagation to rollback.
- Added explicit autoload reports, missing-control diagnostics, structured config messages, immediate selection after config creation, and a fresh request key for script loaders.
- Added README setup and troubleshooting, config UI workflow tests, simulated process reinitialization, and filesystem fault coverage.

- Unified the window edge geometry so the root owns every outer corner and top, sidebar, and footer surfaces remain one pixel inside its stroke.
- Made navigation selection fill the complete sidebar row and added `Shell.NavigationInset` for intentional inset variants.
- Removed the second visible groupbox header fill and shortened its divider so neither layer touches the rounded outline.
- Added live `SetStyle`, `SetMinimal`, and `SetHighlighted` controllers to visual addons.
- Added per-module `SetModuleStyle`, `GetModuleStyle`, `SetModuleMinimal`, and `SetModuleHighlighted` controls to addon windows, including custom highlight colors.
- Added `ShowHeader`, `ShowBackground`, `ShowOutline`, and `ShowShadow` style controls for content-only and minimal module layouts.
- Reworked notifications into smaller 260px toasts with 12px titles, 11px descriptions, tighter spacing, shorter motion, four-card limit, and optional close controls.
- Bound title and description faces directly to `Library.Scheme.Font`, disabled notification RichText, and refreshed open notifications after font changes.
- Added independent `TitleTextSize` and `DescriptionTextSize` settings while preserving `TextSize` compatibility.

### 0.0.1-release-15

- Rebuilt notification geometry with fixed-width cards, live appearance updates, viewport and DPI limits, optional progress, and quiet defaults. Removed scale animation and decorative layout interference.
- Fixed notification ownership of caller-provided instances, step validation, dynamic title creation, delayed cleanup, and unload cancellation.
- Refined the watermark with independent spacing, optional icon and accent, bounded text width, live colors, and correct DPI icon alignment. Released label registrations on destruction.
- Fixed scaled gallery and catalog widths, double-reserved scrollbar space, and immediate image updates that left old transitions active.
- Added module detachment and preserved an existing addon when its replacement fails to create.
- Fixed the dropdown's 21px value label inside a taller field, arrow overlap, UTF-8 truncation, dynamic label geometry, and font-height fitting.
- Expanded Preview and settings, updated types, and added regression cases for overlay lifecycle, gallery DPI, module ownership, and typography.

### 0.0.1-release-14

- Added every TTF from the external font catalog: Inter 28pt Medium, Inter 28pt SemiBold, Minecraftia, Proggy Tiny, Verdana, Tahoma 8px, Smallest Pixel 7, and Tahoma Bold.
- Extended downloadable font presets to accept their own source URL while preserving validation, lazy loading, failure caching, and the existing local asset source.
- Updated the public Library type and typography guide for the expanded catalog.

### 0.0.1-release-13

- Rebuilt config persistence around schema validation, deterministic serialization, verified temporary writes, final readback, and restoration of the previous file when verification fails.
- Added transactional config loading. Invalid data is rejected before mutation, callback failures restore the pre-load snapshot, and load reports expose applied and compatibility-skipped entries.
- Added `RegisterAdapter` and `UnregisterAdapter` so controllers, addon layouts, selections, presets, and other state outside core controls can participate in configs.
- Fixed autoload discovery, stale autoload cleanup after restart, safe empty autoload behavior, config list sorting, subfolder clearing, and the keybind menu toggle lookup.
- Enabled real custom theme persistence with validation, reload, deletion, verified writes, protected built-in names, and a saved startup theme.
- Reworked the color picker trigger into a larger layered swatch with a transparency checker, inset color surface, theme-aware outline, and reliable transparency restoration.
- Expanded addon windows with module lookup, visibility, order, height allocation, fit behavior, and content spacing controls. Multiple fit modules now share available height.
- Redesigned notifications with configurable width, margin, gap, padding, radius, stack limit, duration, accent, progress, dismissal, variants, and per-notification overrides.
- Redesigned the watermark with configurable typography, opacity, outline, radius, padding, accent, scale, side, drag state, position, icon, and visibility. Its scale now composes correctly with global DPI.
- Extended the Preview page and UI Settings examples, updated all public types, added Standards and complete usage guidance, and added regression coverage for config rollback and theme persistence.

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

## Config completion, hidden state and option versions

See [UPDATE_LOG.txt](UPDATE_LOG.txt) for the release-3 update notes and short examples.

Create all controls and register all adapters before loading. Subscribe with
`SaveManager:OnConfigLoaded(function(report) ... end)` before `LoadAutoloadConfig()`.
This callback runs after options, adapters and theme finalization, once per successful
load. It covers `Load`, `LoadJSON` and autoload. The returned function disconnects it.
Failed loads and rollback do not emit it. An absent autoload does not emit it either;
render defaults first. `report.Source` identifies `Load`, `JSON` or `Autoload`.
`report.Status` is `Loaded` or `Partial`. Check `Missing` and `MissingIds` for outdated
control IDs. Consumer callback failures are returned in `ListenerErrors` and do not
roll back a successful config. Avoid starting another load from this callback.

```lua
local SkinId = Library:AddHidden("SkinId", "default", { ConfigVersion = 1 })
local disconnect = SaveManager:OnConfigLoaded(function(report)
    refreshCatalog(SkinId:GetValue())
end)
refreshCatalog(SkinId:GetValue())
SaveManager:LoadAutoloadConfig()
```

`AddHidden(id, default, info?)` is available on Library and groupboxes. It creates
no GUI and participates in SaveManager like other options. `info` accepts `Callback`
and `ConfigVersion`. Methods: `GetValue`, `SetValue`, `OnChanged`, `SetConfigVersion`,
`SetVisible` (always stays hidden), `Destroy`. Table defaults, assigned values and
GetValue results are copied. Use JSON-compatible values and unique string or numeric
IDs. Nil, false and empty strings are deliberate values, not missing defaults.
OnChanged registers a callback without calling it immediately. Destroy unregisters
the option. Replace a formerly hidden Input with a new ID or explicitly migrate its
old text value; different saved control types are not implicitly converted.

Saved controls accept `ConfigVersion = positiveInteger` in their creation info.
`option:SetConfigVersion(version)` enables the same policy after creation. If the
saved version is lower, the loader restores that option's creation-time default.
Unversioned saved entries count as version zero. Saving writes the current version;
equal and newer saved versions keep their saved values. Without ConfigVersion,
existing behavior is unchanged. Defaults include picker transparency and key mode.
Use a version increment for changed semantics, not each script launch. ConfigVersion
does not reset absent entries or migrate custom adapters; adapters own their schema.

`Dropdown:GetSelected()` always returns an array, including single selection. An
empty selection returns `{}`. Multi Values arrays preserve their original order;
dictionaries use a deterministic key order. Existing `.Value` stays compatible.

Use `SetVisible(boolean)` directly on controls, groupboxes, dependency containers,
key/color pickers and tabboxes. Dependency containers combine manual visibility
with their dependency conditions. Hidden values never create visible controls.
Hiding picker and dropdown controls closes their active popups. Hiding a group
preserves its values; destroying it releases its owned controls.

### Standards for persistent state

Keep IDs stable and unique. Load only after constructing the UI and registering
adapters. Refresh dependent views through the completion callback instead of a
scheduled guess. Check the returned success and error from every save/load action.
Store model state in hidden options or custom adapters, not invisible text controls.
Update the library, types and addons together to the latest revision even while the
release label is unchanged. Keep a config backup before intentionally raising option
versions. Disconnect view callbacks when their consumer is destroyed.
## Catalog and item editor controls

The release label stays `0.0.1-release-3`. Update `Library.lua`, `Library.d.luau`,
`addons/ImageGallery.lua` and `Example.lua` together. The Preview tab includes an
item editor demo. The library manages UI and state; your script applies sticker
textures, attachment transforms and game-specific model changes.

### AddImageGrid(id, info)

Register the loaded gallery module once. No extra HTTP request is made by this API.
It returns the existing ImageGallery controller with search, categories, pagination,
responsive columns and reusable cards. `info.Addon = ImageGallery` can supply the
module for a single grid instead of registration.

```lua
Library:RegisterImageGrid(ImageGallery)
local Grid = Groupbox:AddImageGrid("StickerCatalog", {
    Items = {
        { Id = "blue", Name = "Blue", Image = "rbxassetid://123", Category = "Stickers" },
        { Id = "red", Name = "Red", Image = "rbxassetid://456", Category = "Stickers" },
    },
    Height = 280,
    PageSize = 12,
    MinCellWidth = 100,
    CellHeight = 90,
    DraggableItems = true,
    DragType = "Sticker",
    Callback = function(source, item)
        selectedSticker = item
    end,
})
```

Items use stable `Id` values and support `Name`, `Image`, `Thumbnail`, `Category`,
`Subtitle`, `Tags` and `Disabled`. Callback receives the original source followed
by the normalized item. Selection and drag payloads use the same normalized item.
`DraggableItems` defaults to false; `DragType` defaults to `Item` and must match
its target. A drag starts after eight screen pixels of movement; an ordinary tap
still selects a card. Scrolling pauses during a drag and resumes when it ends.

Layout options include `Height`, `Columns` (omit for automatic fitting),
`MinCellWidth`, `PageSize`, `CellHeight`, `Gap`, `ImagePadding`, `LabelHeight`,
`ScaleType`, `Visible`, and `Style`. `Preview` connects an ImagePreview controller;
`Model` connects a CollectionModel. The existing ImageGallery style and image
options remain available. PageSize is chosen at creation.

Use `SetItems`, `AddItem`, `RemoveItem`, `SetSearch`, `SetCategory`, `SetPage`,
`NextPage`, `PreviousPage`, `SetColumns`, `SetMinCellWidth`, `SetCellHeight`,
`SetHeight`, `Select(id, silent?)`, `GetSelected`, `SetVisible`, `SetStyle`,
`SetMinimal`, `SetHighlighted`, or `Destroy` on the returned controller. Destroying
its group also releases gallery handlers. Selection itself is not a saved option;
store a selected ID in AddHidden or use a config adapter if it must survive reloads.

### AddItemSlots(id, info)

Slots store a map from slot ID to item ID. They save through SaveManager as a hidden
option without serializing image data or Instances. The default slots are Sticker1
through Sticker5. Supply another array for charms or other attachment points.

```lua
local Slots = Groupbox:AddItemSlots("WeaponStickers", {
    Slots = { "Sticker1", "Sticker2", "Sticker3", "Sticker4", "Sticker5" },
    Items = stickerItems,
    Default = {},
    DragType = "Sticker",
    Accept = function(item, slotId)
        return not item.Disabled
    end,
    Callback = function(values)
        applyStickerIds(values)
    end,
    OnSelect = function(slotId, itemId)
        openStickerEditor(slotId, itemId)
    end,
})
local Charms = Groupbox:AddItemSlots("WeaponCharms", {
    Slots = { "Charm1", "Charm2", "Charm3", "Charm4" },
    DragType = "Charm",
})
```

`Slots` must be a nonempty array of unique strings. `Items` supplies display data
indexed by each item's Id. `Default` is a slot-to-ID map. Other settings are
`ConfigVersion`, `Visible`, `CornerRadius`, `DragType`, `Accept`, `Callback`,
`OnDrop` and `OnSelect`. Callback receives the complete value map after a change.
OnDrop receives `(slotId, item)` after Assign or a drop; clearing passes nil.
OnSelect receives `(slotId, itemId)` when a cell is activated. Accept runs before
assigning an item, including programmatic Assign, but not when restoring a config.
Keep config validation separate from transient catalog availability.

- `Assign(slotId, item)` assigns an item with Id, Name and Image; returns false if
  disabled or rejected by Accept. `Assign(slotId, nil)` clears the cell.
- `GetValue()` returns a copy. `SetValue(map)` restores/replaces the whole map.
  Unknown slots and non-string/non-number item IDs are rejected before assignment.
- `SetItems(items)` refreshes captions/images without changing selected IDs.
- `SetDisabled`, `SetVisible`, `SetConfigVersion`, `OnChanged` and `Destroy` follow
  other controls. Config loading can restore values while a control is disabled.

Unknown item IDs remain saved and appear as text until SetItems supplies metadata.
This lets a config load before an asynchronous catalog finishes downloading.
Slots wrap to additional rows on narrow screens. Hidden or clipped targets reject
drops. Opening a popup, losing focus or destroying the source cancels a pending drag.
Dragging assigns a copy of the item ID; it does not remove the source card.

For a tap-based alternative, retain the normalized item from the grid callback
and call `Slots:Assign(slotId, selectedItem)` from OnSelect. Preview demonstrates
both selection and dragging. Use a matching DragType for a separate charm grid.

### AddSliderGroup(id, info)

Creates a compact row of sliders. Narrow containers wrap the row without shrinking
controls below the configured minimum. Defaults are X and Y (-1 to 1), Rotation
(-180 to 180), Scale (0.1 to 3) and Wear (0 to 1). Values default to 0, 0, 0, 1, 0.

```lua
local Transform = Groupbox:AddSliderGroup("StickerTransform", {
    MinCellWidth = 96,
    Callback = function(value)
        updateSticker(value.X, value.Y, value.Rotation, value.Scale, value.Wear)
    end,
})
Transform:SetValue({ X = 0.25, Rotation = 45 })
```

Supply `Sliders = { { Id = "X", Text = "Offset X", Min = -2, Max = 2,
Default = 0, Rounding = 2 }, ... }` to define fields. Each entry supports normal
Slider options, including its own Callback and ConfigVersion. The group forces
compact display. Group settings are `Sliders`, `MinCellWidth`, `Visible`,
`ConfigVersion` and `Callback`; field versions override the group version.

`GetValue` returns all field values. `SetValue` updates only supplied fields and
emits the group callback once. Unknown fields and non-finite values are rejected
before updates. `SetDisabled` affects all fields. `SetVisible` hides the row;
`Destroy` releases its children. `Sliders.X` exposes an individual slider.
Config IDs use `groupId/fieldId`, for example `StickerTransform/Rotation`. Keep
both IDs stable and avoid using those IDs for unrelated controls. During config
load each child can notify; use OnConfigLoaded for one final model refresh.

One group can edit the active slot: keep per-slot transforms in an AddHidden map,
load that slot's values with SetValue when selecting it, and write the group callback
back to the map. Ignore the group's temporary field IDs with SetIgnoreIndexes if
only the per-slot map should be persisted. Load the active slot after OnConfigLoaded.

### AddViewport(id, info)

The existing control accepts `Object` or its new alias `Model`. Supply a BasePart
or Model. `Clone` defaults to true: edits affect the preview copy in `.Object`.
With Clone=false the control owns the supplied object, reparents it, and destroys
it on replacement or teardown. Do not pass a live game object with Clone=false.

```lua
local Preview = Groupbox:AddViewport("StickerModel", {
    Model = displayModel,
    Clone = true,
    Interactive = true,
    AutoFocus = true,
    Height = 240,
    MinZoom = 1,
    MaxZoom = 20,
})
```

Interactive defaults to false for compatibility. Enable it for mouse/touch rotation,
mouse-wheel zoom and pinch zoom. MinZoom and MaxZoom are camera distances used by
Focus; omitted values scale to the model bounds. Height and Visible control layout;
Camera can provide an external camera. External cameras are not destroyed.

Use `SetObject(object, clone?)`, `SetCamera`, `SetInteractive`, `SetHeight`,
`SetVisible`, `Focus`, `Zoom(amount)` or `Destroy`. Positive Zoom moves toward the
model; negative moves away. `.Frame`, `.Camera` and `.Object` expose the preview
objects so your renderer can update decals and attachments directly. Viewports now
work inside dialogs and restore the previous scrolling state after interaction.
Pinch end/cancel also restores scrolling when fingers leave the preview area.

### Nested popups

`Window:AddPopup(id, info)` uses the dialog system with stacking. `AddDialog`
remains supported. Open a child using `parent:AddPopup(id, info)`; closing it
reveals the parent with its state intact. Popups support normal groupbox controls,
including grids, slots, sliders and viewports.

```lua
local Catalog = Window:AddPopup("Catalog", { Title = "Stickers", Width = 560 })
Catalog:AddButton("Edit", function()
    local Editor = Catalog:AddPopup("StickerEditor", {
        Title = "Sticker position",
        Width = 560,
        FooterButtons = {
            { Text = "Done", Callback = function(dialog) dialog:Dismiss() end },
        },
    })
    Editor:AddSliderGroup("PopupTransform", {})
end)
```

Info supports Title, Description, Icon, Width, AutoDismiss, OutsideClickDismiss,
OnDismiss, FooterButtons and optional ParentDialog. With no explicit parent, the
currently active dialog becomes the parent. IDs are library-wide; reopening an ID
closes its previous instance. Escape dismisses only the top popup when input is not
already consumed. OutsideClickDismiss also affects only the top popup. Closing a
parent closes its descendants. `Dismiss` and `Destroy` are equivalent.

Height is limited to the window and long content scrolls inside the popup. Width
is clamped to available space and updates with window size. OnDismiss receives the
closing dialog. Build persistent models outside transient popups; destroy popup
controls without discarding the user's model data. Popup controls with temporary
IDs should be ignored by SaveManager, or recreated before loading saved values.
## September 9 wishlist update

The release remains `0.0.1-release-3`. Update Library.lua, Library.d.luau,
ImageGallery and SaveManager together. Mixed revisions can omit option versions,
hidden values or new report fields. The Preview tab demonstrates presets, release-only
sliders, keybind profiles, deferred pages and attachment markers.

### Sections, presets and change events

`Groupbox:AddSection(title)` creates one labeled separator control. It returns a
Label controller with SetText, SetVisible and Destroy, without adding a second
entry to the group's controls.

```lua
Groupbox:AddSection("Appearance")
local ok, message = Library:SetValues({ Thickness = 2, Enabled = true })
local disconnect = Library:OnConfigChanged(function(event)
    dirty = true
end)
```

SetValues validates option IDs before applying anything. It temporarily enables
disabled controls, restores their disabled state, and defers dependency updates to
one pass. Setters and individual control callbacks still run. Unknown IDs return
false and an error without applying the batch. Setter errors are collected; already
applied values are not rolled back. Do not use it as an atomic config transaction.
Use SaveManager.Load for config rollback behavior. The returned boolean reports
setter success, not completion of arbitrary asynchronous work started by callbacks.

Color picker values accept Color3 or `{ Value = color, Transparency = 0.5 }`.
Key pickers accept their usual `{ key, mode, modifiers }` tuple. Other controls use
their normal SetValue representation. Slider groups expose individual option IDs
as `groupId/fieldId`.

OnConfigChanged reports `{ Id, Values, Source }`: ordinary changes include Id;
batches include the changed values and Source="Batch". Source="Config" identifies
changes inside config application; ordinary control changes use "Control". The
signal includes Save=false options and rollback changes. It is not proof that a
config loaded successfully; use OnConfigLoaded for that. Values are snapshots;
read a key picker's Mode/Modifiers directly if needed. A nil value may be absent
from Values, while Id still identifies the changed control. Disconnect the returned
function when the observer is destroyed. Callback errors do not interrupt setters.

### Dropdown recovery and hidden option versions

Dropdown selections are checked against current Values. Unknown saved selections
fall back to the creation default if it is still valid, then to an available value
(or an empty selection when allowed). For multi selection, invalid saved entries
cause restoration of the valid default subset. The load report includes `Adjusted`
and `AdjustedIds` when a replacement occurs. Invalid multi values are also filtered
by the runtime setter. Required single dropdowns get an available initial value
when the requested default cannot be resolved.

Hidden options already support ConfigVersion; regression tests now exercise their
captured defaults alongside actual hidden controllers. A version is opt-in and must
increase to replace a saved value. Missing saved versions count as zero; equal
versions preserve the user value. `report.ResetIds` identifies version-driven resets.
Create the hidden option before loading. Do not confuse a config file's schema with
an individual option's ConfigVersion.

`SaveManager:GetConfigs()` returns the same sorted names used by the config selector.
Pending/backup files stay filtered out. Folder and filesystem rules match
RefreshConfigList, which remains available.

Set `Save = false` in an option's creation info, or call `option:SetSave(false)`.
SaveManager omits it when saving and skips old persisted entries when loading.
SetSave(true) enables persistence again. Hidden values and item slots support this
flag too. A slider group's Save setting is inherited by fields that do not override
it. Excluding a control does not disable its UI or callbacks.

### Search, group visibility and mobile tooltips

Global search includes Text, Tooltip, DisabledTooltip and dropdown keys/values.
Hidden options have no GUI and are skipped safely. Group and tab hiding closes
context menus belonging to descendant controls and dismisses their tooltip.

Holding a touch on a control for 0.55 seconds opens its tooltip. Moving more than
ten pixels cancels the hold so a scroll does not show it. Releasing the touch hides
it. Disabled tooltip text is supported. The source must still be visible and inside
the active popup. Tooltips remain conditional on TooltipsEnabled.

Changing the library font updates live notification faces and recalculates their
size and stack positions. Theme and font application use the existing property
registry; they do not require a whole-ScreenGui GetDescendants traversal. Subtree
scans are still used where needed for addon setup, cleanup and explicit model scans.

### Release-only slider callbacks and custom groups

```lua
Groupbox:AddSlider("Wear", {
    Text = "Wear", Default = 0, Min = 0, Max = 1, Rounding = 2,
    CallbackOnRelease = true,
    Callback = function(value) rebuildPreview(value) end,
})
```

The thumb and displayed value update during dragging. Callback and OnChanged run
once when dragging ends if a value changed. Programmatic SetValue remains immediate;
destroying the slider cancels a pending drag callback. The default remains live
callbacks. Individual fields of AddSliderGroup can set CallbackOnRelease too.

AddSliderGroup already accepts arbitrary `Sliders` entries. Supply unique Id values
and each field's normal Slider settings; the built-in X/Y/Rotation/Scale/Wear list
is only the default. See the item editor section above for layout and config IDs.

### Lazy tabs

```lua
local Tab = Window:AddLazyTab("Catalog", {
    Icon = "images",
    Build = function(tab)
        local group = tab:AddLeftGroupbox("Items")
        group:AddLabel("Created when first needed")
    end,
})
```

Build runs once on the first Show. The first visible tab builds immediately.
`Tab:Build()` can prepare a tab explicitly and returns success/error. A failed build
is reported and its created groupboxes/tabboxes are destroyed; it is not retried
silently. Build should only construct that tab, not start another config load.

SaveManager builds remaining lazy tabs before saving or loading so cold controls
are not omitted. `Library:BuildLazyTabs()` provides the same explicit preparation.
Lazy tabs reduce startup construction when those tabs are not needed immediately;
a startup autoload that restores all controls will still build them. Search does
not construct cold tabs just to inspect content that does not exist yet.

### Keybind profiles

```lua
local Profiles = Library:AddKeybindProfile("Combat", {
    Profiles = {
        Normal = { ActionKey = { "P", "Toggle", {} } },
        Alternate = { ActionKey = { "O", "Hold", { "LeftControl" } } },
    },
    Default = "Normal",
    CycleKey = "F6",
    Callback = function(name) currentProfileName = name end,
})
Profiles:Apply("Alternate")
```

Apply returns success/error and only accepts existing KeyPicker IDs. Next cycles
profile names in sorted order. Current contains the last successfully applied
name. CycleKey is optional; it is ignored while typing or when input is consumed.
Destroy disconnects the cycle key; library unload also destroys the profile.
Profiles and their active name are not automatically persisted. The underlying
key pickers save normally; use a hidden value if the profile name must be saved.
The info table can also be passed as the only argument.

### Attachment points in a viewport

```lua
local Preview = Groupbox:AddViewport("CharmPreview", {
    Model = model, Clone = true, Interactive = true,
    ShowAttachments = true,
    AttachmentNames = { "Charm1", "Charm2", "Charm3", "Charm4" },
    AttachmentRadius = 0.08,
})
```

ShowAttachments displays small spheres at Attachment.WorldCFrame. Omit
AttachmentNames to show all attachments. AttachmentRadius is in model units;
AttachmentColor overrides the theme accent. GetAttachments returns Attachment
instances from the preview model. SetAttachmentPointsEnabled toggles markers.
Call RefreshAttachmentPoints after changing the preview model's transforms or
attachments. Replacement refreshes automatically. Existing marker parts are reused
and removed when a point disappears. Scanning is explicit, not per rendered frame.

### Verified existing performance paths

Empty ImageGallery instances accept later SetItems calls and reuse their allocated
cards. Passing Gallery.Items back into SetItems is now safe. Search, category and
page state are refreshed on replacement. CollectionModel-backed galleries should
receive model changes through the model API so all bound views remain consistent.

GetTextBounds already uses a bounded cache keyed by text, font, text size and
available width. Width must remain part of the key because wrapping affects height.
Font changes invalidate the cache. Mobile fallback measurements have a retry
cooldown so a temporary font-service failure can recover.

Local regression tests cover batching, lazy builds, hidden option versions, stale
dropdowns, persistence exclusion, late catalog population, card reuse, search,
release-only callbacks and attachment marker reuse. Device rendering, gesture timing
and frame-time improvements still require checking in Roblox on target hardware.
## Compact addon windows and watermarks

Addon windows now default to a 28-pixel header without an icon badge or subtitle.
Titles are centered when there is no icon. `Compact = false` restores the larger
header. Set `ShowIcon = true` or `ShowSubtitle = true` to retain those elements in
compact windows. Explicit HeaderHeight is respected. Calling SetSubtitle explicitly
shows the text and uses a 44-pixel compact header. Compact hosts can be sized down
to 160 by 48 pixels; MinWidth and MinHeight can raise those limits.

Dashboard sections use a flat background without a second border by default.
Standalone dashboards hide the redundant section header when there is only one
section; headings return when more sections are added. Set HideSectionHeaders=true
to hide all headings, or false to show them. Compact=false retains the framed style.
Existing ShowTitle=false and ShowHeader=false section settings remain supported.

```lua
local List, Host = DashboardWindow.CreateStandalone(Library, {
    Title = "Spectators",
    WindowWidth = 240,
    Compact = true,
    AutoHeight = true,
    MaxContentHeight = 300,
    Resizable = false,
})
List:AddMetric({ Label = "player_one", Value = "spectating" })
```

AutoHeight follows actual content and caps it at MaxContentHeight (default 400).
It is enabled automatically only when neither Height nor WindowHeight is supplied.
Explicit dimensions keep their previous behavior unless AutoHeight=true is requested.
Rows beyond the cap remain scrollable. GetContentHeight returns the content height.
Supply actual spectator rows from your script; a Count metric alone cannot display
names that were never passed to the library.

The watermark now uses 12-pixel library text, three-pixel vertical padding, small
horizontal margins and a thin outline. It keeps the active library font and existing
text, positioning and DPI behavior. Choose a preset or override its style afterward:

```lua
Library:SetWatermarkPreset("Compact")
Library:SetWatermarkStyle({ TextSize = 12, HorizontalPadding = 8 })
```

Compact is the default. Minimal removes the outline and rounds no corners. Classic
restores the previous size and padding. Presets do not replace watermark text or move
it. Preview contains buttons to compare presets and open a small spectator-list demo.

# Runtime and advanced API

Everything below documents the runtime layer that ships in the same `Library.lua`
as the controls. None of it needs an addon. It has been in the build for a while
but had no guide coverage, so this section starts from zero and explains each
function, its arguments, what it returns, and how it behaves on bad input, on a
phone, and when the menu is closed.

A note on how this section was written: every function here was read out of
`Library.lua` before it was documented. Where the source does not contain a
function that people expect (some notification and sound helpers, for example),
it is listed under [Not yet in the build](#not-yet-in-the-build) instead of being
described as if it worked.

## Runtime contents

- [Reactivity and state](#reactivity-and-state)
- [Performance primitives](#performance-primitives)
- [The declarative builder](#the-declarative-builder)
- [Control registry, reset and history](#control-registry-reset-and-history)
- [Search and navigation](#search-and-navigation)
- [Sidebar sub-tabs](#sidebar-sub-tabs)
- [Mobile and touch](#mobile-and-touch)
- [Errors and diagnostics](#errors-and-diagnostics)
- [New controls](#new-controls)
- [Control extensions](#control-extensions)
- [Configs and profiles](#configs-and-profiles)
- [Themes: gallery, preview and contrast](#themes-gallery-preview-and-contrast)
- [Performance numbers](#performance-numbers)
- [Not yet in the build](#not-yet-in-the-build)

## Reactivity and state

The old way to read a control's value was to reach into `Library.Toggles` or
`Library.Options` by id and read `.Value`. That still works, but it means your
code has to know when to re-read. The reactivity layer inverts that: you hold a
state object, you subscribe to it, and the library tells you when it changes.

### Library:State(default)

`Library:State(Default)` returns a state object holding a deep copy of `Default`.
The object has three methods.

- `State:Get()` returns a deep copy of the current value. Reading inside an
  `Observe` callback also records the state as a dependency of that observer.
- `State:Set(Value)` stores a deep copy of `Value` and notifies subscribers. It
  returns `false` and does nothing when the new value is deep-equal to the
  current one, so setting a state to what it already holds is free and does not
  fire listeners. It also returns `false` if the state was destroyed.
- `State:Subscribe(Callback, Immediate)` registers `Callback(new, previous)` and
  returns a disconnect function. Pass `Immediate = true` to fire the callback
  once right away with the current value.
- `State:Destroy()` clears listeners and unregisters the state from the runtime.

Values are always copied on the way in and on the way out, so you cannot mutate
a table you handed to `Set` and have the state change under you, and a subscriber
cannot corrupt another subscriber's copy.

Set is re-entrant safe. If a subscriber calls `Set` again during dispatch, the
new value is queued and applied in the same dispatch loop rather than recursing.
The loop is capped at 100 iterations; if it is still changing after 100 passes it
stops and reports "Reactive update cycle exceeded 100 changes" through the error
channel, which is how a feedback loop between two states surfaces instead of
freezing the client.

```lua
local Coins = Library:State(0)

Coins:Subscribe(function(New, Old)
    print(string.format("coins went from %d to %d", Old or 0, New))
end)

Coins:Set(50)   -- fires the subscriber
Coins:Set(50)   -- returns false, no subscriber call
```

Edge behaviour: `Get` after `Destroy` still returns the last copied value, but
`Set` and `Subscribe` are no-ops (Subscribe asserts). A state you create is
tracked by the runtime and torn down on `Library:Unload`, so you do not have to
destroy it yourself unless you want the memory back sooner.

### Library:Observe(callback)

`Library:Observe(Callback)` runs `Callback` immediately, watches every state whose
`Get` was called during that run, and re-runs `Callback` whenever any of those
states change. It returns an observer with a `Destroy` method. Dependencies are
recomputed on every run, so an `if` branch that reads a different state next time
is tracked correctly.

```lua
local Enabled = Library:State(false)
local Mode = Library:State("Aim")

Library:Observe(function()
    if Enabled:Get() then
        print("active in", Mode:Get())     -- depends on both states
    else
        print("off")                       -- depends only on Enabled
    end
end)
```

When `Enabled` is false the observer does not depend on `Mode`, so changing
`Mode` does not re-run it. Turn `Enabled` on and the next run reads `Mode` and
starts tracking it. Errors thrown inside the callback are caught and reported
through the error channel rather than stopping the observer.

### Binding a control to a state

Instead of reading `Toggles`/`Options` by hand, most controls accept a `State`
field in their `Info` table. The binding is two-way: when the state changes the
control updates, and when the user changes the control the state is set from the
control's value. The library guards against the two sides fighting, so a user
edit does not bounce back and re-fire.

```lua
local Flying = Library:State(false)

Tab:AddLeftGroupbox("Movement"):AddToggle("Fly", {
    Text = "Fly",
    State = Flying,          -- toggle mirrors this state both ways
})

Flying:Set(true)            -- flips the toggle in the UI and runs its callback
```

Color pickers accept either a `Color3` or a `{ Value = Color3, Transparency = n }`
table from the state. Key pickers and other controls take their normal value
shape. If applying a state value throws (a bad shape, for instance) the error is
reported and the control keeps its previous value.

### VisibleWhen and EnabledWhen

`VisibleWhen` and `EnabledWhen` are control options that replace a hand-wired
dependency box for the common case. Each accepts one of three things:

- a literal `true`/`false`,
- a function returning a truthy value, or
- a state object (its `Get` is read).

`VisibleWhen` drives `Control:SetVisible`; `EnabledWhen` drives
`Control:SetDisabled` with the inverse (true means enabled). Both are wrapped in
an `Observe`, so when they read a state they re-evaluate automatically. When they
are plain functions that read other controls, they re-evaluate whenever those
controls change through the same observer machinery.

```lua
local Advanced = Group:AddToggle("Advanced", { Text = "Advanced mode" })

Group:AddSlider("Sensitivity", {
    Text = "Sensitivity",
    Default = 5, Min = 1, Max = 20,
    VisibleWhen = function() return Advanced.Value end,
})

-- or against a state
local Ready = Library:State(false)
Group:AddButton({ Text = "Launch", EnabledWhen = Ready, Func = Launch })
```

If the control does not implement the setter (`SetVisible`/`SetDisabled`) the
rule is skipped silently. The observer is destroyed with the control's binding
when the control's holder is destroyed, so these do not leak.

## Performance primitives

These exist because building or updating hundreds of instances in one frame drops
the client. They let you spread work across frames and reuse instances instead of
creating and destroying them.

### Library:CreatePool(template, factory)

A pool recycles UI rows. Pass either an `Instance` template to clone or a
`factory` function that returns a fresh row. It returns a pool with:

- `Acquire(...)` returns a free row or makes a new one (via `factory(template, ...)`
  or `template:Clone()`), marks it active, and makes its root visible. It asserts
  that the factory returns a unique row.
- `Release(Item)` hides the row, calls `Item.Reset` if the row table has one, and
  returns it to the free list. Returns `false` if the item was not active.
- `Trim(Keep)` destroys free rows until at most `Keep` remain. It calls
  `Item.Destroy` if present, otherwise destroys the root instance.
- `Destroy()` releases everything active, trims to zero, and unregisters the pool.

The pool finds a row's root through `Item` itself if it is an `Instance`, or
`Item.Root`, `Item.Holder`, or `Item.Button` on a table row, in that order. It
tracks how many rows it has created in `Pool.Created`, which is what the
performance tests assert against.

```lua
local Pool = Library:CreatePool(nil, function()
    local Row = Instance.new("TextLabel")
    Row.Size = UDim2.new(1, 0, 0, 24)
    return Row
end)

local A = Pool:Acquire()   -- new row, Created == 1
Pool:Release(A)            -- back to free list
local B = Pool:Acquire()   -- reuses A, Created still 1
Pool:Trim(0)               -- destroys the free row
```

### Library:CreateVirtualList(scroll, info)

A virtual list renders only the rows visible in a `ScrollingFrame` plus a small
overscan, so a list of thousands of items holds a handful of instances. `Info`:

- `CreateRow` (required): a factory passed to an internal pool, returns one row.
- `RenderRow(Row, Index)` (required): fills a row with the data for `Index`.
- `Count` (default 0): how many items the list has.
- `RowHeight` (default 28): fixed pixel height of every row. Rows must be a fixed
  height; the list computes offsets from `RowHeight` and does not measure rows.
- `Columns` (default 1): items per row for a grid.
- `Overscan` (default 2): extra rows rendered above and below the viewport.
- `Gap` (default 0): pixel gap subtracted from each cell.
- `Scale` (optional): a function returning a DPI scale, defaults to `Library.DPIScale`.

It returns a view with `Refresh()`, `SetCount(n)`, `ScrollTo(index)`, and
`Destroy()`. It sets the scroll frame's `AutomaticCanvasSize` to `None` and drives
`CanvasSize` itself. It refreshes automatically on `CanvasPosition` and
`AbsoluteSize` changes and destroys itself when the scroll frame is destroyed.

```lua
local View = Library:CreateVirtualList(Scroll, {
    Count = 5000,
    RowHeight = 28,
    CreateRow = function()
        local L = Instance.new("TextLabel"); L.Size = UDim2.new(1, 0, 0, 28); return L
    end,
    RenderRow = function(Row, Index) Row.Text = "Row " .. Index end,
})

View:SetCount(6000)   -- add rows, refreshes in place
View:ScrollTo(4000)   -- jump to an item
```

Measured characteristics (from `tests/Runtime.spec.luau`): a 5000-row list in a
300 by 280 viewport with `RowHeight = 28` and `Overscan = 2` creates at most 14
pooled rows on first render, and at most 28 after scrolling all the way to the
bottom. That is the whole point: the pool count tracks the visible window, not
the item count.

Limitation: `RowHeight` is fixed for the whole list. There is no per-row height
and no automatic measurement, so a list of variable-height content is not a fit
for this. Use a fixed row height or pad rows to a common height.

### Library:SetBuildBudget(ms) and Library:QueueBuild(callback, id)

`QueueBuild` defers a build job and runs queued jobs a few at a time, stopping
each frame once the elapsed time crosses the build budget, then resuming next
frame. This keeps a large build from blocking one frame. `SetBuildBudget(ms)`
sets how long a build pass may run per frame; it asserts `0 < ms <= 100` and the
default is 4ms.

`QueueBuild` returns a job with a `Status` field (`Pending`, `Running`,
`Completed`, `Failed`, or `Cancelled`), a `Seconds` timing once it runs, and a
`Cancel()` method that only works while still pending. Failed jobs report their
error through the error channel with the id you passed, and every run is recorded
in a rolling sample buffer that `Library:GetProfile()` reads.

```lua
Library:SetBuildBudget(6)   -- allow 6ms of build per frame

for Index = 1, 400 do
    Library:QueueBuild(function()
        Group:AddButton({ Text = "Item " .. Index, Func = function() end })
    end, "item-" .. Index)
end
```

### Library:QueueFrame(key, callback) and Library:RequestLayout(target)

`QueueFrame(Key, Callback)` coalesces work onto the next `Heartbeat`. Calling it
again with the same `Key` before the frame runs replaces the pending callback, so
many requests for the same target collapse into one run. This is why a burst of
changes to a groupbox resizes it once, not once per change.

`RequestLayout(Target)` is the common wrapper: it queues a frame that calls
`Target:Resize()` unless the target was destroyed. Reach for it after you add,
remove, or resize elements in a container and want the layout to settle. Layout
is deferred on purpose so a script that adds twenty controls in a loop pays for
one resize at the end of the frame instead of twenty mid-loop.

Force a synchronous resize only when you need the final size in the same frame,
for example when you are about to read `AbsoluteSize` to position something
relative to it. In that case call `Target:Resize()` directly instead of
`RequestLayout`.

### Lazy tabs

A lazy tab does not build its contents until it is first shown. `Window:AddLazyTab(Name, { Icon = ..., Build = function(Tab) ... end })`
returns a tab whose `Build` runs the callback the first time the tab is shown (or
immediately if it is the active tab at creation). If the build throws, the tab's
groupboxes and tabboxes are torn down and the error is re-raised, so a broken tab
does not leave half-built UI behind.

`Library:BuildLazyTabs()` forces every unbuilt lazy tab to build now and returns
`false, message` on the first failure. Use it before a config load that needs
every control to exist, since a control inside an unbuilt lazy tab is not
registered yet.

```lua
local Heavy = Window:AddLazyTab("Reports", {
    Icon = "chart-bar",
    Build = function(Tab)
        local G = Tab:AddLeftGroupbox("Live")
        -- expensive setup here, runs on first open
    end,
})

Library:BuildLazyTabs()   -- build everything now, before loading a config
```

## The declarative builder

`Library:Create(AppInfo)` builds an entire window, its tabs, groups, and controls
from one nested table, and returns an app handle. `Library:Mount(AppInfo)` is an
alias for it. The imperative API is unchanged; this is a second way to describe
the same tree.

`AppInfo` fields:

- `Window` (or the top-level table itself): the `CreateWindow` info. `Theme` sets
  the theme before the window is built.
- `Tabs` (alias `Pages`): a list or map of tab definitions.
- `Deferred = true`: build every element through `QueueBuild` instead of inline,
  so a large app spreads across frames. `OnReady` then fires after the build
  drains.
- `OnReady(App)`: called once the tree is built.

A tab definition can be a string (its name) or a table with `Name`/`Title`,
`Icon`, `Description`, `Order`, `Id`, `Lazy = true`, and `Groups` (alias
`Sections`). A group can be a string or a table with `Name`, `Side` (1/2 or
"left"/"right"), `Icon`, `Visible`, `Collapsed`, `DisableCollapsing`, `Id`, and
`Elements` (aliases `Controls`, `Items`). An element is a string (becomes a label)
or a table with a `Type` (alias `Kind`) and the same `Info` fields the imperative
`Add*` methods take, plus `Id` for a ref, `Value` as an alias for `Default`,
`OnClick`/`OnChanged` as aliases for `Func`/`Callback`, and `Addons` for nested
key and color pickers.

Element type map (the `Type` string, case-insensitive, with common aliases):

| Type | Builds | Aliases |
| --- | --- | --- |
| `label` | AddLabel | `text` |
| `button` | AddButton | `action` |
| `checkbox` | AddCheckbox | `check` |
| `toggle` | AddToggle | |
| `input` | AddInput | `textbox` |
| `slider` | AddSlider | |
| `dropdown` | AddDropdown | `select` |
| `divider` | AddDivider | `separator` |
| `image` | AddImage | |
| `video` | AddVideo | |
| `viewport` | AddViewport | |
| `table` | AddTable | |
| `chart` | AddChart | |
| `log` | AddLog | |
| `statrow` | AddStatRow | |
| `progressbar` | AddProgressBar | |
| `uipassthrough` | AddUIPassthrough | `ui` |
| `imagegrid` | AddImageGrid | |
| `itemslots` | AddItemSlots | |
| `slidergroup` | AddSliderGroup | |
| `segmented` | AddSegmented | `segment` |
| `badge` | AddBadge | `pill` |
| `emptystate` | AddEmptyState | `empty` |
| `detaillist` | AddDetailList | `detail` |
| `settingscard` | AddSettingsCard | `setting` |
| `splitbutton` | AddSplitButton | `split` |
| `skeleton` | AddSkeleton | `shimmer` |
| `steps` | AddSteps | `stepper`, `timeline` |

The app handle has `Refs` (id to element/tab/group), `App:Get(Id)`, `AllTabs`,
`AllGroups`, `All` (every element), `Tabs`/`Pages` (id to tab), `Groups`/`Sections`,
`App:Toggle`, `App:Notify`, and `App:Destroy` (which unloads the library). A
duplicate `Id` anywhere in the tree is an error, so refs are unique.

### The same tab, imperative and declarative

Imperative:

```lua
local Tab = Window:AddTab({ Name = "Combat", Icon = "swords" })
local G = Tab:AddLeftGroupbox("Aim")
G:AddToggle("AimEnabled", { Text = "Enabled", Default = false, Callback = OnAim })
G:AddSlider("AimSmooth", { Text = "Smoothing", Default = 5, Min = 1, Max = 20 })
```

Declarative:

```lua
local App = Library:Create({
    Window = { Title = "MonHub", Size = UDim2.fromOffset(780, 640) },
    Tabs = {
        {
            Name = "Combat", Icon = "swords",
            Groups = {
                {
                    Name = "Aim", Side = "left",
                    Elements = {
                        { Type = "toggle", Id = "AimEnabled", Text = "Enabled",
                          Default = false, OnChanged = OnAim },
                        { Type = "slider", Id = "AimSmooth", Text = "Smoothing",
                          Default = 5, Min = 1, Max = 20 },
                    },
                },
            },
        },
    },
    OnReady = function(App)
        print("built", App:Get("AimEnabled").Value)
    end,
})
```

Set a tab's `Lazy = true` to build its groups on first open, and set the
top-level `Deferred = true` to spread the whole build across frames. Nested key
and color pickers go in an element's `Addons` list, each with its own `Type`
(`keypicker`/`colorpicker`) and `Id`.

## Control registry, reset and history

Every control registers under its config id. These functions read that registry
and let you reset or roll back values without knowing where a control lives.

- `Library:GetControl(Id)` returns a control by id. Buttons and labels use the
  `button:Id` and `label:Id` prefixes; toggles and options resolve by plain id.
- `Library:GetAll()` returns a map of every live (non-destroyed) control, keyed
  the same way.
- `Library:ForEach(Callback)` calls `Callback(Control, Id)` for every live
  control, each wrapped in `SafeCallback` so one bad callback does not stop the
  walk.
- `Library:ResetDefaults(Ids)` restores the listed controls (or every control
  when `Ids` is nil) to their configured defaults. Returns `true`, or
  `false, message` if applying a value failed.
- `Library:ResetScope(Scope, Confirm)` resets a whole subtree. `Scope` can be a
  control, group, tabbox, or tab; passing `nil` means the whole window. Unless
  `Confirm == false` it opens a confirmation dialog first. `Window:Reset`,
  `Tab:Reset`, and `Control:Reset` are thin wrappers over this.

History is opt-in:

- `Library:EnableHistory(Limit)` turns on change recording, clamped to 1..1000
  entries (100 if you pass nothing).
- `Library:Undo()` and `Library:Redo()` step through recorded changes. Each
  returns `true`, or `false, message` such as "History is empty" or "Redo is empty".
- `Library:GetRecentChanges()` returns a copy of the history buffer, each entry
  carrying `Id`, `Before`, `After`, and a `Time`.

History does not record changes made during a config load or during undo/redo
replay, and it skips controls marked `Save = false`. Making a new change clears
the redo stack, the same as any editor.

```lua
Library:EnableHistory(200)

-- user toggles some things...
Library:Undo()   -- revert the last change
Library:Redo()   -- put it back

for _, Entry in Library:GetRecentChanges() do
    print(Entry.Id, "->", Entry.After)
end
```

## Search and navigation

- `Library:SearchControls(Query, FavoritesOnly)` returns a sorted list of
  `{ Id, Text, Control }` for controls whose text or id contains `Query`
  (case-insensitive substring). Pass `FavoritesOnly = true` to search only
  favorites.
- `Library:RevealControl(Id)` shows the control: it switches to its tab, expands
  its group or sub-tab, makes the control visible, scrolls it into view, and runs
  the reveal-text animation. Returns `false` if the control does not exist or was
  destroyed.
- `Library:SetFavorite(Id, Enabled)` marks a control as a favorite (asserts the
  control exists). `Library:GetFavorites()` returns the sorted favorite ids that
  still resolve to a live control.
- `Library:RegisterCommand(Id, Text, Callback)` adds a named action to the
  command palette and returns a function that removes it.
- `Library:OpenCommandPalette(FavoritesOnly)` opens a dialog with a search box
  over controls, tabs, and registered commands. Selecting a control reveals it;
  selecting a tab shows it; selecting a command runs its callback. It needs a
  window first and returns `nil, "Create a window first"` otherwise. Pass
  `FavoritesOnly = true` for a favorites-only palette.
- `Library:EnableCommandKeys()` binds keyboard chords: Ctrl+K opens the palette,
  Ctrl+Tab and Ctrl+Shift+Tab move between tabs, and Ctrl+Z / Ctrl+Y undo and
  redo while the menu is open. The binding ignores input while a text box is
  focused.

The palette and undo/redo are Ctrl chords. A touch device has no Ctrl key, so on
a phone `EnableCommandKeys` gives you nothing usable. Give touch users a button
that calls `Library:OpenCommandPalette()` directly, and wire undo/redo to
on-screen buttons if you want them there.

```lua
Library:EnableCommandKeys()   -- desktop chords

Library:RegisterCommand("panic", "Unload menu", function() Library:Unload() end)

-- touch entry point, since there is no Ctrl key on a phone
Group:AddButton({ Text = "Search", Func = function() Library:OpenCommandPalette() end })
```

## Sidebar sub-tabs

A tab can hold child tabs in the sidebar under a collapsible chevron.

- `Tab:AddSubTab(...)` takes the same arguments as `Window:AddTab` and returns the
  child tab. The first call adds a chevron expander to the parent and indents the
  child in the sidebar. `Tab.SubTabs` holds the children.
- `Tab:SetExpanded(State)` expands or collapses the group and returns the tab.
- `Tab:IsExpanded()` reports the current state.

Sub-tabs start collapsed. Selecting a child auto-expands its parent so the active
tab is always visible. When the sidebar is compacted (the narrow icon rail) the
group is force-expanded, because a collapsed chevron in a rail with no room for
the expander would make the children unreachable. On mobile the chevron and child
rows are sized to 44 pixels so they are tappable.

```lua
local Settings = Window:AddTab({ Name = "Settings", Icon = "settings" })
local Audio = Settings:AddSubTab({ Name = "Audio", Icon = "volume-2" })
local Video = Settings:AddSubTab({ Name = "Video", Icon = "monitor" })

Settings:SetExpanded(true)     -- open the group
print(Settings:IsExpanded())   -- true
```

### How nested tabs read

A sub-tab row is 4px shorter than a top-level row and indented 20px. The children
hang off a tree drawn from 1px lines:

- a short stem drops from 3px below the parent's icon to the bottom of the parent
  row, so the tree visibly starts at the parent;
- a trunk continues straight down through every child and stops at the last one;
- each child gets a straight horizontal branch at the middle of its row, ending
  4px before its icon (`├─` for middle rows, `└─` for the last).

The lines are plain 1px frames, not stroked curves, so they stay the same weight
at every size and land on whole pixels. The trunk is one continuous column with
no gap between the stem and the first child or between rows.

The open child is marked by lighting its path in the accent colour: the stem, the
trunk down to that child, and its branch. Rows below it keep the neutral line
colour. Switching between siblings shortens or extends the lit path. The parent
row also stays lit (full-strength label and icon over a faint band) while one of
its children is open, so `Farming` then `World Bosses` reads at a glance.

A parent with no groupboxes of its own opens its first child when clicked. In the
compact, icon-only sidebar the tree is hidden, because centred icons would sit on
top of the trunk.

The group's height comes from the logical row heights, so it stays correct at any
UI scale. Earlier builds measured it in screen pixels and doubled the gap under an
expanded group at 200% scale.

`Library:AnimateTabTrail(Button, Label, Icon, OnTrail)` applies or clears the lit
parent state. The library calls it for you on every tab switch and theme change;
call it yourself only if you drive tab visuals by hand.

### Sidebar separators

`Window:AddTabSeparator(Text?)` groups tabs in the sidebar.

```luau
Window:AddTab("Combat", "crosshair")
Window:AddTab("Visuals", "eye")
Window:AddTabSeparator("System")
Window:AddTab("Settings", "settings")
```

- With text, it adds a 26px section caption in the muted text colour, aligned
  with the tab icons and sitting close to the rows it introduces.
- Without text, it adds a 9px gap holding a full-width 1px line.
- It lands after the most recently added tab, so call it between the `AddTab`
  calls it should separate.
- In the compact sidebar a captioned separator swaps its caption for the line,
  since a truncated caption in a 48px column reads as noise.
- Returns the separator frame. It is destroyed with the window.

## Mobile and touch

The owner cares about phones, so this is a first-class section. `Library.IsMobile`
is the switch most of this keys off.

### Density

Density controls the size of rows, tracks, thumbs, indicators, swatches, and the
navigation height. `Library.DensityPresets` holds three presets:

| Metric | Compact | Comfortable | Touch |
| --- | --- | --- | --- |
| Row / Grid.Row | 24 | 30 | 44 |
| NavigationHeight | 38 | 44 | 44 |
| TrackRow | 14 | 18 | 20 |
| Thumb | 10 | 12 | 18 |
| Indicator | 16 | 18 | 24 |
| Swatch | 16 | 18 | 24 |
| RowGap | 9 | 10 | 12 |

- `Library:SetDensity(Mode)` sets the density ("Auto", "Compact", "Comfortable",
  or "Touch"), applies it, bumps the design revision, refreshes theme state, and
  resizes every tab. Returns the library.
- `Library:ResolveDensity(Mode)` returns the density that will actually be used.
  "Auto" resolves to "Touch" on mobile and "Compact" otherwise, and on a mobile
  device any non-Touch request is forced up to "Touch".
- `Library:ApplyDensity()` pushes the resolved preset into the live design tokens.

Because mobile forces Touch, the Touch preset raises Grid.Row to 44, TrackRow to
20, Thumb to 18, Indicator and Swatch to 24, and NavigationHeight to 44
automatically when `Library.IsMobile` is true. This is the 44-pixel rule: touch
targets land on 44 pixels so they are reliably tappable.

### Swipe between tabs, and what the old TabSwipe settings are not

`Library:SetTabSwipeEnabled(Enabled)` turns on a real touch swipe gesture that
moves between tabs. It works with:

- `Library:GetOrderedTabs()`, which returns the visible top-level tabs in order,
  and
- `Library:SwitchTabRelative(Delta, Wrap)`, which moves `Delta` tabs from the
  active one, optionally wrapping, and returns whether it moved.

Be clear on the naming, because it has misled people: `TabSwipeOffset`,
`TabSwipeFrom`, and `TabSwipeDirection` are only the tab-enter slide animation,
the little slide a tab's contents do when it appears. They are not the gesture.
The gesture is `SetTabSwipeEnabled` plus the two functions above. Setting the
`TabSwipe*` animation values does nothing for swiping between tabs.

```lua
Library:SetTabSwipeEnabled(true)          -- real finger swipe between tabs
Library:SwitchTabRelative(1, true)        -- next tab, wrap at the end
```

### Input capture

On a phone a tap in the menu can also fire the player's tool or gun underneath.
Input capture stops that.

- `Library:SetInputCapture(Enabled)` sets the library-wide default.
- `Library:ResolveInputCapture(Value)` returns the effective setting: the
  per-control `Value` when it is not nil, otherwise the library default.
- `Window:SetInputCapture` sets it at the window level.
- A per-control `Info.CaptureInput` overrides the default for that control.

Controls that host interactive surfaces (viewports, UI passthrough) read
`ResolveInputCapture(Info.CaptureInput)` to decide whether to swallow the touch.
Turn it on for a control the player will drag on so the input does not leak to the
game.

### Haptics

- `Library:Vibrate(Kind)` triggers a short vibration. `Kind` is "Light" (0.25),
  "Medium" (0.55), or "Heavy" (1); an unknown kind falls back to Light. It does
  nothing unless `Library.HapticsEnabled` is true and the device reports haptic
  support through `Library.Env.Haptics`.
- `Library:SetHapticsEnabled(Enabled)` toggles it.

Haptics are enabled by default only on mobile with a supporting device
(`Library.HapticsEnabled = Library.IsMobile and Library.Env.Haptics == true`).
On a desktop or a phone without a vibration motor, `Vibrate` returns quietly.

### Cursor

- `Library:SetCursorVariant(Name)` picks a cursor from `Library.CursorVariants`
  ("Default", "Pointer", "Hand", and so on). Returns `false` for an unknown name.
- `Library:SetCustomCursorEnabled(Enabled)` turns the custom cursor on or off and
  returns the effective state.

The custom cursor stays off on touch: both functions treat `Library.IsMobile` as
a hard off, since a drawn cursor on a touchscreen is wrong. `SetCustomCursorEnabled(true)`
returns false on a phone.

### Safe area, scrollbars, truncation

On notched phones the menu keeps clear of the safe-area insets. Scrollbars are
touch-reactive and auto-hide when a list is idle. Text truncation is UTF-8
character-safe, so Cyrillic and other multi-byte text is cut on character
boundaries and no longer corrupts mid-glyph.

## Errors and diagnostics

- `Library:SafeCallback(Func, ...)` runs a callback under `xpcall`, reports any
  error through the error channel with the owning control's id when it can find
  it, and optionally notifies. Every internal callback goes through this, which
  is why one throwing callback does not take down the menu. During a config load
  it routes callbacks through the load context instead so a throwing callback is
  isolated to its own entry.
- `Library:OnError(Callback)` subscribes to error reports and returns a disconnect
  function. Each report is `{ Message, Id, Source, Time }` where `Source` is
  "Callback", "State", "Observe", "Build", or "Config".
- `Library:Diagnose()` returns a live snapshot: counts of tracked resources by
  kind, connected connections, active tweens, live instances, pooled and active
  rows, pending builds, a copy of recent errors, and whether the library is
  unloaded.
- `Library.Env` is the capability probe, filled once at load: `Drawing`,
  `CustomAsset` (getcustomasset), `Clipboard` (setclipboard), `Request`
  (request/http_request), `FPSCap` (setfpscap), and `Haptics`.

Degrade gracefully by checking `Library.Env` before using a capability rather
than calling the global and catching the failure. For example, a copy button
should only appear when `Library.Env.Clipboard` is true; the input control's
`Copyable` option already gates itself on exactly that.

```lua
Library:OnError(function(Report)
    warn(string.format("[%s] %s", Report.Source, Report.Message))
end)

if Library.Env.Clipboard then
    Group:AddInput("Key", { Text = "Share code", Copyable = true })
end

print(Library:Diagnose().ActiveRows, "rows in use right now")
```

## New controls

Quick reference for the controls added this release. Each takes `(Id, Info)` on a
groupbox unless noted.

| Control | One line |
| --- | --- |
| `AddSegmented` | A 2 to 4 option pill selector with a sliding indicator |
| `AddBadge` | A small pill label, optionally with a leading text label |
| `AddEmptyState` | An icon, title, body, and optional action for an empty list |
| `AddDetailList` | A list of icon + title + subtitle rows, each optionally clickable |
| `AddSettingsCard` | A titled card wrapping one control with a description |
| `AddSplitButton` | A primary button with a chevron menu of extra actions |
| `AddSteps` | A step or timeline indicator you advance through |
| `AddSkeleton` | An animated loading placeholder |

### AddSegmented(id, info)

A segmented control. `Info`:

- `Text` (default "Segmented"): the label above the track, or nil for no label.
- `Values` (default `{}`): 2 to 4 values. More than 4 are dropped; fewer than 2
  asserts.
- `Default`: the initial value.
- `Callback(Value)` and `Changed(Value)`: run when the selection changes.
- `Disabled`, `Visible`: initial state.

It exposes `SetValue`, `GetValue`, a `Reset`, and the usual `SetVisible`. Returns
the segmented control.

```lua
Group:AddSegmented("Quality", {
    Text = "Render quality",
    Values = { "Low", "Medium", "High" },
    Default = "Medium",
    Callback = function(V) print("quality", V) end,
})
```

### AddBadge(id, info)

A pill. `Info`:

- `Text` (default "Badge"): the pill text.
- `Style` (default "Label"): the badge style.
- `Variant` (default "Accent"): the color variant.
- `Label`: optional text shown to the left, which right-aligns the pill.
- `Visible`.

Methods: `SetText(Value)`, `GetValue()`, `SetVisible(Visible)`. Returns the badge.

### AddEmptyState(id, info)

The placeholder for an empty list or a not-yet-loaded panel. `Info`:

- `Icon` (default "inbox"): the glyph.
- `Title` (default "Nothing here").
- `Text` (default ""): the body line.
- `ActionText`: when set, shows a button.
- `Callback`: run when the action button is pressed.
- `Visible`.

Returns the empty state, which supports `SetVisible`.

### AddDetailList(id, info)

A list of rows, each with an icon, a title, and a subtitle. `Info`:

- `Items` (default `{}`): a list of `{ Icon, Title, Text, Callback }` tables. A
  row with a `Callback` becomes clickable and highlights on hover, and tapping it
  fires a light haptic.
- `Visible`.

Methods: `SetItems(Items)` rebuilds the list and resizes, `GetValue()` returns the
current items, `SetVisible`. Returns the detail list. Rows are a minimum of 40
pixels tall.

```lua
local List = Group:AddDetailList("Servers", { Items = {} })
List:SetItems({
    { Icon = "server", Title = "US-East", Text = "42 ms", Callback = Join },
    { Icon = "server", Title = "EU-West", Text = "89 ms", Callback = Join },
})
```

### AddSettingsCard(id, info)

A titled card that wraps one control with a description, and stacks the control
below the text on a narrow width. `Info`:

- `Title` (default "Setting").
- `Text` (default ""): the description.
- `Control`: the control to host.
- `Visible`.

Returns the settings card.

### AddSteps(id, info)

A step or timeline indicator. `Info`:

- `Steps`: the list of steps.
- `Current` (default 1): the active step, clamped to the step count.
- `Visible`.

Methods: `SetCurrent(Index)`, `SetStatus(Index, Status)`, `GetCurrent()`,
`SetVisible`. Each returns the steps control where it makes sense for chaining.

### AddSkeleton(id, info)

An animated loading placeholder that you show while data loads and hide when it
arrives. `Info` is passed through to `CreateSkeletonBody` (row shapes and count),
plus `Visible`. Methods: `Start()`, `Stop()`, and `SetVisible` (which starts the
animation when shown and stops it when hidden). Returns the skeleton.

```lua
local Skel = Group:AddSkeleton("Loading", { Visible = true })
Skel:Start()
-- when data is ready:
Skel:SetVisible(false)
```

### AddSplitButton(id, info)

A primary button with a chevron that opens a menu of secondary actions. `Info`:

- `Text` (default "Button"): the primary label.
- `Callback` (alias `Func`): the primary action.
- `Options` (default `{}`): the menu entries.
- `Disabled`, `Visible`.

Returns the split button. On mobile the primary row and the chevron are sized to
44 pixels.

## Control extensions

Existing controls gained options this release.

### AddInput

New `Info` fields on `AddInput`:

- `Multiline` (default false): a multi-line box. `MaxLines` (default 4, minimum 2)
  caps its height.
- `Mask`: a single non-empty string used as the display mask (for a password-style
  field).
- `Prefix` / `Suffix`: non-empty strings shown before or after the value.
- `Clearable` (default false): shows a clear button.
- `Copyable` (default false): shows a copy button, but only when
  `Library.Env.Clipboard` is true. On an executor with no `setclipboard` the
  option is ignored.
- `Validate(Value)`: see below.

### Validate, SetError and ClearError

Any control that supports validation takes `Info.Validate`, a function called with
the control's value after a change. Returning a string marks the control invalid
and shows that string as a red caption under the control; returning nil clears the
error. You can also drive it by hand:

- `Control:SetError(Text)` marks the control invalid, shows `Text`, and tints the
  outline with the danger color.
- `Control:ClearError()` clears it.

`Control.Valid` reflects the current state. When a control has no `Validate`
function, `SetError` and `ClearError` are present but do nothing, so calling them
is always safe.

```lua
Group:AddInput("Port", {
    Text = "Port",
    Numeric = true,
    Validate = function(Value)
        local N = tonumber(Value)
        if not N or N < 1 or N > 65535 then return "Enter 1 to 65535" end
    end,
})
```

### AddDropdown

`Info.Chips` (with `Info.Multi = true`) renders selected values as removable chips
instead of a joined text summary. Chips only apply to a multi-select dropdown.

### AddButton

`Button:SetState(State, Text)` switches a button between "Idle", "Loading",
"Success", and "Error", optionally replacing the label. "Loading" locks the button
and spins a loader icon (unless reduced motion is on); "Idle" restores the
original label and icon. An invalid state asserts. Use it to show a long action's
progress on the button itself.

```lua
Group:AddButton({
    Text = "Save",
    Func = function(_, Button)
        Button:SetState("Loading", "Saving...")
        local Ok = DoSave()
        Button:SetState(Ok and "Success" or "Error", Ok and "Saved" or "Failed")
        task.delay(1.5, function() Button:SetState("Idle") end)
    end,
})
```

### AddProgressBar

- `Info.Indeterminate` (default false): an indeterminate bar that animates instead
  of showing a fixed fill. `Row:SetIndeterminate(State)` toggles it at runtime.
- `Info.Segments`: split the bar into 2 to 63 discrete cells. `Row.Segments` holds
  the count and `Row.Filled` how many are lit.

Indeterminate and segmented are mutually exclusive in behaviour: turning
indeterminate off on a non-segmented bar restores the normal fill.

## Configs and profiles

The config loader in `addons/SaveManager.lua` was rewritten to be resilient per
entry. This section explains the contract; the SaveManager reference elsewhere in
this guide covers the rest of its surface.

### What fails the whole file versus what is skipped

A load fails as a whole only when the file itself cannot be used: it is missing,
unreadable, or not decodable JSON. Once the file decodes, loading is per entry. A
malformed object inside it (a control entry that is not a table, or references an
unknown control) is skipped with a recorded reason, and the rest of the file still
loads. A callback that throws while applying one entry no longer rolls back the
whole load; that entry is marked failed and the others keep their applied values.
Partial loads are kept, not discarded.

### The load report

`SaveManager:LoadSummary(Report)` and `SaveManager:FormatLoadReport(Report)` read
the report a load produces. The report carries per-category counts: `Applied`,
`Unchanged`, `Skipped`, `Failed`, and `Missing`, plus a per-entry reason for
anything that was skipped, failed, or missing. Use it to tell the user "loaded 18,
skipped 2 (unknown controls)" instead of a bare success or failure.

### Batched apply

`SaveManager:SetApplyMode(Mode)`, `SaveManager:Apply()`, and
`SaveManager:RunApplyBatch(Batch, Report)` apply a config in batches rather than
all at once. Batching exists so a large config does not apply every control in one
frame and stall the client; it spreads the work the same way the build budget does
for construction.

### Autosave, recovery and backups

- `SaveManager:WriteRecoverySnapshot(Name)` writes a crash-recovery snapshot,
  debounced so rapid changes do not thrash the disk.
- `SaveManager:CheckRecovery()` reports whether a snapshot from an unclean exit
  exists, `SaveManager:RestoreRecovery()` restores it, and
  `SaveManager:ClearRecovery()` discards it.
- `SaveManager:SetBackupCount(Count)` sets how many rotated backups to keep,
  `SaveManager:ListBackups(Name)` lists them, `SaveManager:RotateBackup(Name)`
  rotates one in, and `SaveManager:RestoreBackup(Name, Index)` restores a specific
  backup. These return `true` or `false, reason`.
- `SaveManager:PreviewConfig(Name)` returns a diff preview of what loading that
  config would change, so you can show it before applying.

Profiles support duplicate and rename through the profile management UI, and the
diff preview is available before a load so the user is not committing blind.

## Themes: gallery, preview and contrast

The theme manager in `addons/ThemeManager.lua` gained a visual gallery and a
preview flow.

- `ThemeManager:BuildGallery(Groupbox)` builds the gallery of theme cards, each
  with real color-swatch previews. `ThemeManager:RebuildGallery(Names)` rebuilds
  it for a given set of names.
- `ThemeManager:PreviewTheme(Name)` applies a theme as a preview without
  committing it. `ThemeManager:ApplyPreview()` commits the previewed theme;
  `ThemeManager:CancelPreview()` reverts to what was active before the preview.
- `ThemeManager:UpdateContrast()` runs the contrast check. It compares font
  against background and warns when the ratio falls below the WCAG AA threshold of
  4.5:1, and offers a one-tap fix that nudges the colors until they pass.

Theme codes export and import through the theme-code field in the gallery. When
`Library.Env.Clipboard` is available the export button copies the code to the
clipboard and the import reads from it; when it is not, the user copies the code
out of the field or pastes it in by hand.

Three accessibility palettes ship alongside the standard themes: Deuteranopia,
Protanopia, and High Contrast. They are selectable like any other theme.

```lua
ThemeManager:PreviewTheme("High Contrast")   -- try it live
-- keep it:
ThemeManager:ApplyPreview()
-- or back out:
ThemeManager:CancelPreview()
```

## Performance numbers

Concrete figures, taken from the code and the specs rather than invented. Where a
number is not sourced, the behaviour is described qualitatively.

- Default build budget: 4ms per frame (`Runtime.BuildBudget = 4`). `QueueBuild`
  runs jobs until this is crossed, then continues next frame. Raise it with
  `SetBuildBudget` if you would rather build faster and can spare the frame time.
- Virtual list, 5000 rows: in a 300 by 280 viewport with `RowHeight = 28` and
  `Overscan = 2`, the pool creates at most 14 rows on first render and at most 28
  after scrolling to the end (`tests/Runtime.spec.luau`). The instance count
  tracks the visible window plus overscan, not the item count.
- Asset catalog over the same virtual list: a 5000-item catalog keeps its pool
  under 80 instances across a full scroll (`tests/Runtime.spec.luau`).
- Layout coalescing: `QueueFrame` collapses repeated requests for the same target
  into one run per frame, so adding N controls in a loop costs one resize, not N.
- Text metrics are cached. `Library:GetTextBounds` memoizes measured bounds, and
  `Library:ClearTextBoundsCache` drops the cache; repeated measurement of the same
  text and font is a cache hit rather than a re-measure.
- CanvasGroup cost: a `CanvasGroup` forces the engine to render its subtree to an
  off-screen buffer, which is more expensive than a plain frame. The rule is to
  use a CanvasGroup only when you actually need to fade or transform a whole
  subtree as one unit, and a plain `Frame` otherwise.

Read the live picture at any time with `Library:Diagnose()` for counts, or
`Library:GetProfile()` for the slowest recent build samples alongside the current
budget.

## Not yet in the build

These were expected this session but are not present in `Library.lua` as read, so
they are not documented above. Grep confirmed each is absent:

- Notification actions (`Info.Actions`), grouping with a counter, priorities and
  categories (`Info.Priority` / `Info.Category`), `Library:GetNotificationHistory`,
  `Library:ShowNotificationHistory`, `Library:SetNotificationFilter`, and
  `Library:SetNotificationAnchor`. The current notification surface is `Library:Notify`
  (with `SoundId` and `Volume`), `Library:SetNotifySide`,
  `Library:SetNotificationOptions`, and `Library:ClearNotifications`, documented in
  the Notifications section above.
- The bottom Line notification mode and its mobile default.
- Watermark format strings and custom tokens: `Library:SetWatermarkFormat` and
  `Library:RegisterWatermarkToken`. The current watermark surface is
  `Library:SetWatermark`, `Library:SetWatermarkVisibility`,
  `Library:SetWatermarkPreset`, and `Library:SetWatermarkStyle`.
- Sound tokens: `Library:PlaySound`, `Library:SetSoundEnabled`,
  `Library:SetSoundVolume`.
- Streamer mode: `Library:SetStreamerMode`.

When these land, document each the same way as the rest of this section: what it
is for, the full signature, every `Info` field with types and defaults, the return
value, and the failure and touch behaviour.
