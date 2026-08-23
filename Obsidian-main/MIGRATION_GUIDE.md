# Migrating from Obsidian to MonHub UI

The canonical API guide is [GUIDE.md](GUIDE.md). This document focuses on moving an existing Obsidian project to MonHub without rewriting its application logic.

MonHub keeps the legacy API: `CreateWindow`, `AddTab`, groupboxes, controls, `SaveManager`, `Library.Options`, and `Library.Toggles` continue to work. `ThemeManager` now provides a minimal built-in preset selector.

The release baseline is a neutral-gray `Default` theme with violet `Metal` and near-black `Midnight` presets, Gotham Regular typography, responsive sidebar behavior, compact checkmark toggles, short motion, click sound support, a draggable clamped watermark, R6 ESP preview support, optimized search, and a declarative API.

## Useful links

- [MonHub UI repository](https://github.com/SoftRatatui/Obsidian-main)
- [Library.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/Library.lua)
- [Raw Library.lua](https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua)
- [Complete Example.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/Example.lua)
- [Raw Example.lua](https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Example.lua)
- [QuickStart.luau](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/QuickStart.luau)
- [ThemeManager.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/addons/ThemeManager.lua)
- [SaveManager.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/addons/SaveManager.lua)
- [VisualPreview.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/addons/VisualPreview.lua)
- [Raw VisualPreview.lua](https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/VisualPreview.lua)
- [DrawingESPPreview.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/addons/DrawingESPPreview.lua)
- [TracerPreview.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/addons/TracerPreview.lua)
- [Current type declarations](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/Library.d.luau)
- [Changelog](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/CHANGELOG.md)
- [Original Obsidian](https://github.com/deividcomsono/Obsidian)
- [Legacy API reference](https://docs.mspaint.cc/obsidian)
- [Lucide icon catalogue](https://lucide.dev/icons/)
- [MIT license](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/LICENSE)

## Short migration route

For most projects, complete these steps in order:

1. Back up the working script and configuration folder.
2. Replace the upstream `Library.lua` URL with the MonHub raw URL.
3. Keep existing control IDs unchanged.
4. Update `SaveManager.lua`; add `ThemeManager.lua` when the settings page should expose the two theme presets.
5. Run a smoke test for callbacks, configs, keybinds, mobile layout, and unload.

## Step 1: replace the loader

An upstream loader usually looks like this:

```luau
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"
))()
```

Replace it with MonHub:

```luau
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua?monhub=0.0.1-final-theme-5"
))()
if Library.ReleaseVersion ~= "0.0.1-final-theme-5" then
    warn(string.format("MonHub version notice: expected %s, received %s", "0.0.1-final-theme-5", tostring(Library.ReleaseVersion)))
end
```

Use `raw.githubusercontent.com`, not a `github.com/.../blob/...` URL. A blob page returns HTML, which causes Luau to report `Expected ident` on line 1.

## Step 2: keep the legacy API

Do not move to the declarative API during the first migration. Existing code can stay almost unchanged:

```luau
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua?monhub=0.0.1-final-theme-5"
))()
if Library.ReleaseVersion ~= "0.0.1-final-theme-5" then
    warn(string.format("MonHub version notice: expected %s, received %s", "0.0.1-final-theme-5", tostring(Library.ReleaseVersion)))
end

local Window = Library:CreateWindow({
    Title = "My Hub",
    Footer = "MonHub v0.0.1",
    Center = true,
    AutoShow = true,
    Resizable = true,
    GlobalSearch = true,
    EnableSidebarResize = true,
    Font = Enum.Font.Gotham,
    CornerRadius = 6,
    TabTransitionTime = 0.075,
    TabSwipeOffset = 2,
    Size = Library.IsMobile and UDim2.fromOffset(520, 480) or UDim2.fromOffset(720, 680),
})

local MainTab = Window:AddTab("Main", "house")
local GeneralGroup = MainTab:AddLeftGroupbox("General", "settings-2")

GeneralGroup:AddToggle("Enabled", {
    Text = "Enabled",
    Default = true,
    Callback = function(Value)
        print("Enabled:", Value)
    end,
})
```

## API compatibility

| Upstream Obsidian | MonHub UI | Migration action |
|---|---|---|
| `Library:CreateWindow` | Supported | Keep it |
| `Window:AddTab` | Supported | Keep it |
| `Window:AddKeyTab` | Supported | Keep it |
| `Tab:AddLeftGroupbox` | Supported | Keep it |
| `Tab:AddRightGroupbox` | Supported | Keep it |
| `AddToggle` | Supported | Keep it |
| `AddCheckbox` | Supported | Keep it |
| `AddInput` | Supported | Keep it |
| `AddSlider` | Supported | Keep it |
| `AddDropdown` | Supported | Keep it |
| `AddButton` | Supported | Keep it |
| `AddLabel` and `AddDivider` | Supported | Keep them |
| `AddColorPicker` | Supported | Keep it |
| `AddKeyPicker` | Supported | Keep it |
| `Library.Options` | Supported | Do not rename IDs |
| `Library.Toggles` | Supported | Do not rename IDs |
| `ThemeManager` | Minimal preset selector | Add it to expose all six built-ins |
| `SaveManager` | Supported | Update the addon file |
| `Library:SetWatermark` | Supported | Use when needed |
| `Library:SetWatermarkVisibility` | Supported | Use when needed |
| `Library:SetWatermarkSide` | Supported | Use `"Left"` or `"Right"` |
| `Library:SetWatermarkDraggable` | Supported | Enables or disables dragging |

The visual design of controls has changed, but their primary methods remain. `SetValue` does not call a callback again when the value is unchanged, which avoids redundant dependencies, tweens, and calculations.

## Window settings

Recommended settings:

```luau
local Window = Library:CreateWindow({
    Title = "MonHub",
    Footer = "MonHub v0.0.1",
    NotifySide = "Right",
    Center = true,
    AutoShow = true,
    Resizable = true,
    GlobalSearch = true,
    EnableSidebarResize = true,
    EnableCompacting = true,
    ShowCustomCursor = true,
    Font = Enum.Font.Gotham,
    CornerRadius = 6,
    TabTransitionTime = 0.075,
    TabSwipeOffset = 2,
    TabSwipeFrom = "bottom",
    Size = Library.IsMobile and UDim2.fromOffset(520, 480) or UDim2.fromOffset(720, 680),
    Animations = {
        ToggleWindow = true,
        TabSwitch = true,
        Groupbox = true,
        Dropdown = true,
        KeyPicker = true,
    },
})
```

| Setting | Purpose |
|---|---|
| `Title` | Window title |
| `Footer` | Bottom-bar text |
| `Size` | Desktop or mobile size |
| `Center` | Centers the window on creation |
| `Resizable` | Allows resizing |
| `GlobalSearch` | Searches controls |
| `EnableSidebarResize` | Allows sidebar-width dragging |
| `EnableCompacting` | Enables a compact sidebar |
| `CornerRadius` | Outer radius from 0 to 20 |
| `Font` | `Enum.Font` or `Font` |
| `TabTransitionTime` | Tab transition duration |
| `TabSwipeOffset` | Tab content entry distance |
| `TabSwipeFrom` | `left`, `right`, `top`, or `bottom` |

Call this after a viewport change or manual size change:

```luau
Window:FitToViewport()
```

## Tabs and groupboxes

```luau
local Tabs = {
    Main = Window:AddTab("Main", "house"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Settings = Window:AddTab("UI Settings", "settings-2"),
}

local MainLeft = Tabs.Main:AddLeftGroupbox("Player", "user")
local MainRight = Tabs.Main:AddRightGroupbox("World", "globe")

MainLeft:SetOrder(0)
MainRight:SetOrder(0)
```

Use `SetOrder` when SaveManager sections or dynamic groupboxes need a predictable placement.

## Moving controls

### Toggle and Checkbox

```luau
local FeatureToggle = MainLeft:AddToggle("FeatureEnabled", {
    Text = "Feature enabled",
    Default = false,
    Tooltip = "Enables the feature",
    Callback = function(Value)
        print(Value)
    end,
})

MainLeft:AddCheckbox("SafeMode", {
    Text = "Safe mode",
    Default = true,
    Callback = function(Value)
        print(Value)
    end,
})
```

`AddToggle` now defaults to a compact 16×16 square with a 3px radius and an animated checkmark while retaining the same boolean API. `AddCheckbox` uses the same square language. Set `Library.ForceCheckbox = false` before creating controls only when an older project deliberately wants the legacy sliding switch.

### Input

```luau
MainLeft:AddInput("ProfileName", {
    Text = "Profile name",
    Default = "Default",
    Placeholder = "Enter a profile name",
    Finished = true,
    ClearTextOnFocus = false,
    Callback = function(Value)
        print(Value)
    end,
})
```

### Slider

```luau
MainLeft:AddSlider("PowerLevel", {
    Text = "Power level",
    Default = 65,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    AllowRightClickInput = true,
    Callback = function(Value)
        print(Value)
    end,
})
```

The slider API is unchanged. The control has separate label/value areas, a thin track, a thumb, mouse drag, touch drag, and numeric right-click input.

### Dropdown

```luau
MainRight:AddDropdown("Quality", {
    Text = "Quality",
    Values = { "Low", "Balanced", "High" },
    Default = "Balanced",
    AllowNull = false,
    Callback = function(Value)
        print(Value)
    end,
})

MainRight:AddDropdown("Modules", {
    Text = "Enabled modules",
    Values = { "Visuals", "Utility", "Movement" },
    Default = { "Visuals", "Utility" },
    Multi = true,
})

MainRight:AddDropdown("Command", {
    Text = "Search command",
    Values = { "Alpha", "Bravo", "Charlie", "Delta" },
    Default = "Alpha",
    Searchable = true,
})
```

Large dropdown lists are virtualized. Arrays, dictionaries, multi-select values, player dropdowns, and team dropdowns remain supported.

### Button, Label, and Divider

```luau
MainLeft:AddLabel("Status: ready", true)
MainLeft:AddDivider()

MainLeft:AddButton({
    Text = "Run action",
    DoubleClick = false,
    Variant = "Primary",
    Func = function()
        print("Action executed")
    end,
})
```

The short button form also remains available:

```luau
MainLeft:AddButton("Run action", function()
    print("Action executed")
end)
```

Available button variants are `Default`, `Primary`, and `Ghost`. `Secondary` remains an alias for `Default`. Older `Warning`, `Danger`, `Caution`, `Destructive`, and `Risky` button styling now resolves to `Default`, so legacy scripts remain functional without carrying colored outlines into the current design. Use an explicit icon or confirmation dialog when the action needs extra context.

Toggles also accept `Variant = "Warning"` or `Variant = "Danger"`. In the enabled state only the track and outline become semantic, so key-picker rows do not shift. Enabling a danger toggle opens a short `Cancel` / `Continue` dialog. Turning it off is immediate. Set `ConfirmDanger = false` to disable confirmation, or set `ConfirmTitle` and `ConfirmDescription` for custom dialog copy.

The title-bar minimize button collapses the UI to a centered draggable launcher with the script title. When the menu is hidden by keybind, the launcher does not appear; use the same bind to restore the menu. Configure this through `ShowCompactLauncher`, `CompactLauncherIcon`, `CompactLauncherSize`, `CompactLauncherWidth`, `CompactLauncherTitle`, `CompactLauncherPosition`, and `CompactLauncherDraggable` in `CreateWindow`.

## ColorPicker and KeyPicker addons

```luau
FeatureToggle:AddColorPicker("FeatureColor", {
    Title = "Feature color",
    Default = Color3.fromRGB(121, 126, 139),
    Transparency = 0,
    Resizable = true,
    Callback = function(Color)
        print(Color)
    end,
})

FeatureToggle:AddKeyPicker("FeatureKeybind", {
    Text = "Feature keybind",
    Default = "H",
    Mode = "Toggle",
    SyncToggleState = true,
    Callback = function(State)
        print(State)
    end,
})
```

Feature keybinds support `Toggle` and `Hold`. `Press` remains an action-bind mode for labels and buttons and does not appear in the keybind state panel.

The keybind panel hides unassigned (`None`) or invalid entries and does not display when it is empty. Enable its animated display with:

```luau
Library:SetKeybindMenuVisible(true)
```

When the first valid key is assigned later, the panel appears automatically while this setting is enabled.

## Reading values

Do not change IDs when migrating configurations.

```luau
local Options = Library.Options
local Toggles = Library.Toggles

print(Toggles.FeatureEnabled.Value)
print(Options.PowerLevel.Value)
print(Options.Quality.Value)

Toggles.FeatureEnabled:SetValue(true)
Options.PowerLevel:SetValue(80)
Options.Quality:SetValue("High")
```

`Toggles` contains toggle and checkbox controls. `Options` contains inputs, sliders, dropdowns, key pickers, color pickers, and other option controls.

## Theme presets and font policy

`Default` applies automatically with neutral-gray surfaces and a muted slate accent. `Metal` is the desaturated violet preset based on the release reference. `Midnight` is a near-black neutral preset with a muted steel accent. `Steel`, `Sage`, and `Ash` add cool blue-gray, quiet green-gray, and warm-neutral alternatives. Every preset uses Gotham Regular, restrained outer geometry, and subtle single-pixel outlines. Background, card, raised overlay, control, hover, muted text, and soft accent surfaces are separate semantic tokens. Softness comes from readable type, balanced contrast, regular spacing, and short movement—not blanket corner rounding.

```luau
Library:SetTheme("Default")
Library:SetTheme("Metal")
Library:SetTheme("Midnight")
Library:SetTheme("Steel")
Library:SetTheme("Sage")
Library:SetTheme("Ash")
```

The release contains exactly these six built-ins. Legacy preset names resolve safely, but raw theme tables and old saved palette fields cannot restore a prior font, `TopBarColor`, background image, radius, or partial color palette. Theme application now updates the full instance registry and then refreshes stateful components, preventing an active toggle, popup, launcher, slider, or hover state from retaining the previous palette.

Old theme files and marker files are not automatically deleted, but they are not applied. This leaves future recovery possible without allowing stale data to damage the release interface.

Gotham Regular is the production font because it remains clear at small UI sizes without making dense settings pages look overly heavy.

## Click sound

MonHub uses one shared audio object for all `GuiButton` controls:

```luau
Library:SetClickSound(92679954573730, 0.3)
```

Disable it with:

```luau
Library:SetClickSound(false)
```

If sound does not play, check the asset availability for the current experience and Roblox audio permissions.

## Watermark, FPS, and ping

Basic API:

```luau
Library:SetWatermark("My Hub  |  Ready")
Library:SetWatermarkVisibility(true)
Library:SetWatermarkSide("Left")
Library:SetWatermarkDraggable(true)
```

The watermark starts in the top-left. It can be dragged with mouse or touch, or snapped through `SetWatermarkSide("Left")` and `SetWatermarkSide("Right")`. It remains within the viewport after dragging, text changes, and screen-size changes.

[Example.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/Example.lua) includes ready-to-use Watermark, Show FPS, and Show Ping settings. It updates text every 0.5 seconds, counts FPS with a lightweight `RenderStepped` counter, and reads `Data Ping` safely through `Stats`.

## Interactive R6 viewport

```luau
local PreviewGroup = Tabs.Visuals:AddLeftGroupbox("Character preview", "user-round")

PreviewGroup:AddViewport("CharacterViewport", {
    Object = CharacterModel,
    Clone = true,
    AutoFocus = true,
    Interactive = true,
    Height = 260,
})
```

Controls:

- Left or right mouse drag rotates the model.
- Mouse wheel zooms.
- Touch drag rotates.
- Pinch zooms.

Zoom is clamped relative to model size. `Object` must be a `BasePart` or `Model`.

## ESP preview addon

`addons/VisualPreview.lua` clones a real character from `Target` without changing the source. It supports a fixed panel beside the window, a direct `GuiObject` parent, and a MonHub groupbox. `addons/DrawingESPPreview.lua` provides a shared Drawing backend so live players and the preview use the same entity update path. `addons/TracerPreview.lua` creates reusable asset-ID tracer samples.

Load the addon from the same commit as `Library.lua`:

```luau
local VisualPreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/VisualPreview.lua?monhub=0.0.1-final-theme-5"
))()
local DrawingESPPreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/DrawingESPPreview.lua?monhub=0.0.1-final-theme-5"
))()
local Players = game:GetService("Players")

local PreviewGroup = VisualsTab:AddRightGroupbox("Live preview", "scan-eye")
local ESPRenderer = DrawingESPPreview.Create({
    Color = Color3.fromRGB(119, 166, 209),
    GradientColor = Color3.fromRGB(202, 220, 239),
})

local Preview = VisualPreview.CreateEmbedded(Library, PreviewGroup, {
    Name = "ESP preview",
    Target = Players.LocalPlayer,
    Height = 320,
    Enabled = false,
    Gradient = true,
    DynamicBoxes = true,
    Renderer = ESPRenderer,
})
```

Use `VisualPreview.Create(Library, VisualsTab, Info)` for the external panel. Pass `Parent = SomeGuiObject` or call `Preview:Mount(Parent, Height)` for direct mounting. `VisualPreview.CreateEmbedded` and `Preview:Embed` place the preview directly in a groupbox.

Bind the preview to the same callbacks that change the live ESP:

```luau
local function SyncPreview()
    Preview:SetEnabled(Config.ESPEnabled == true)
    Preview:SetBoxVisible(Config.ESPBoxes == true)
    Preview:SetNameVisible(Config.ESPNames == true)
    Preview:SetTeamVisible(Config.ESPTeamText == true)
    Preview:SetWeaponVisible(Config.ESPWeapons == true)
    Preview:SetDistanceVisible(Config.ESPDistance == true)
    Preview:SetHealthVisible(Config.ESPHealth == true)
    Preview:SetTracerVisible(Config.TracersEnabled == true)
    Preview:SetColor(Config.ESPGradient and Config.ESPGradientStart or Config.BoxColor)
    Preview:SetGradientEnabled(Config.ESPGradient == true)
    Preview:SetGradientColor(Config.ESPGradientEnd)
    Preview:SetChams(
        Config.ChamsEnabled == true,
        Config.ChamsFillColor,
        Config.ChamsOutlineColor,
        Config.ChamsFillTrans,
        Config.ChamsOutlineTrans
    )
end
```

To migrate the live ESP to the shared backend, keep the project's existing player iteration, visibility checks, projection, and throttling. Replace only the final object writes with `ESPRenderer:UpdateEntity(Entity, State)`. `State.Bounds` uses absolute screen coordinates and `State.Health` is a normalized value from `0` to `1`. Call `ESPRenderer:CreateEntity()` once per tracked player and `ESPRenderer:RemoveEntity(Entity)` when that player is removed. The preview passes the same state fields automatically.

Projects that already have a polished renderer do not need to replace it. Pass an adapter with `AttachPreview`, `UpdatePreview`, `SetPreviewVisible`, and `DetachPreview`; each update receives the cloned `Context.Model`, projected `Context.Bounds`, colors, visibility flags, text values, and health. With no adapter or Drawing support, the preview retains its theme-aware GUI fallback.

Use `SetPosition("Auto" | "Right" | "Left", "Center" | "Top" | "Bottom")` and `SetPanelGap(number)` only for panel placement. Drag the character with left mouse or touch to rotate it; use the mouse wheel for zoom. `Preview:Rotate(deltaX, deltaY)`, `Preview:SetZoom(value)`, and `Preview:ResetView()` are available for custom controls.

Create an embedded asset tracer with:

```luau
local TracerPreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/TracerPreview.lua?monhub=0.0.1-final-theme-5"
))()

local Tracer = TracerPreview.CreateEmbedded(Library, PreviewGroup, "TracerSample", {
    AssetId = 1234567890,
    ColorA = Color3.fromRGB(255, 213, 58),
    ColorB = Color3.fromRGB(255, 246, 166),
    Glow = 0.82,
    Speed = 1.25,
    Height = 92,
})
```

Use `TracerPreview.Create(Library, { Parent = SomeGuiObject, ... })` outside a groupbox. Numeric IDs are normalized to `rbxassetid://`; complete asset URLs and custom asset paths are accepted unchanged.

## Image, Video, and UIPassthrough

```luau
local MediaGroup = Tabs.Visuals:AddRightGroupbox("Media", "image")

MediaGroup:AddImage("PreviewImage", {
    Image = "sparkles",
    Color = Color3.fromRGB(184, 189, 201),
    ScaleType = Enum.ScaleType.Fit,
    Height = 82,
})

MediaGroup:AddVideo("PreviewVideo", {
    Video = "rbxassetid://5608324215",
    Looped = true,
    Playing = false,
    Volume = 0,
    Height = 175,
})
```

`AddUIPassthrough` accepts an existing `GuiBase2d` and places it inside a groupbox.

## ThemeManager presets

Load `ThemeManager.lua` when the UI Settings page should expose the six built-in presets:

```luau
local ThemeManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/ThemeManager.lua?monhub=0.0.1-final-theme-5"
))()

ThemeManager:SetLibrary(Library)
ThemeManager:ApplyToTab(Tabs["UI Settings"])
```

The addon creates a minimal `Default` / `Metal` / `Midnight` / `Steel` / `Sage` / `Ash` dropdown with the ID `ThemeManager_ThemeList`. SaveManager persists that selection. It does not expose raw palette editing or load custom theme files.

## SaveManager

```luau
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/SaveManager.lua?monhub=0.0.1-final-theme-5"
))()

SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("MonHub")
SaveManager:SetSubFolder(tostring(game.PlaceId))
local ConfigGroup = SaveManager:BuildConfigSection(Tabs.Settings)
ConfigGroup:SetOrder(-100)
SaveManager:LoadAutoloadConfig()
```

Configuration migration rules:

1. Preserve existing control IDs.
2. Keep the old `SetFolder` value to reuse an existing config folder.
3. Use a new `MonHub` folder to begin with clean configurations.
4. Do not call `LoadAutoloadConfig` before all controls are created.
5. Call `SaveManager:IgnoreThemeSettings()` before loading legacy autoload configs; it filters old palette fields but keeps `ThemeManager_ThemeList`.
6. The menu KeyPicker is saved normally. Add it to `SetIgnoreIndexes()` only when it must remain global across every configuration.

## UI Settings layout

Recommended placement:

```text
Left column
1. Interface

Right column
1. Configuration
```

Use `Groupbox:SetOrder`:

```luau
local InterfaceGroup = Tabs.Settings:AddLeftGroupbox("Interface", "panel-left")
InterfaceGroup:SetOrder(-100)

local ConfigGroup = SaveManager:BuildConfigSection(Tabs.Settings)
ConfigGroup:SetOrder(-100)
```

## Mobile and desktop

MonHub compacts the sidebar on touch devices. On a narrow working area, content columns stack vertically: left first, right second. This preserves readable control width instead of compressing sliders, dropdowns, or inputs.

```luau
local WindowSize = Library.IsMobile
    and UDim2.fromOffset(520, 460)
    or UDim2.fromOffset(760, 660)
```

Responsive layout is enabled by default. Customize its thresholds for your UI:

```luau
local Window = Library:CreateWindow({
    ResponsiveLayout = true,
    SingleColumnWidth = 540,
    HideSearchAtWidth = 210,
})
```

`SingleColumnWidth` is the content width at which two columns stack vertically. `HideSearchAtWidth` is the extreme threshold where search hides instead of overlapping the title. Only call `Window:SetResponsiveLayoutEnabled(false)` when a window is guaranteed to remain desktop-sized.

Recommendations:

- Do not make a desktop window smaller than `480x360` without testing controls.
- Keep tab names short.
- Use label wrapping for long text.
- Test both columns at 75%, 100%, 125%, and 150% DPI.
- Test the viewport in landscape mobile orientation.
- Call `Window:FitToViewport()` after manual resizing.
- The relevant setting is in `UI Settings → Responsive layout` in `Example.lua`.

## Motion and performance

All primary transitions are enabled by default and complete after their tween; none creates a perpetual effect.

```luau
Window:SetAnimations({
    ToggleWindow = true,
    TabSwitch = true,
    Groupbox = true,
    Dropdown = true,
    KeyPicker = true,
}, 0.075, 2, "bottom")
```

Window opening uses a 90ms opacity-only transition and closing uses 60ms, without scale or font resizing. Tabs crossfade in 75ms and leave in 45ms with only 2px of travel. The keybind overlay fades in 70ms, its rows settle in 75ms, and standard controls use 110ms state transitions. For an immediate UI, disable one animation category instead of all transitions. Repeated hover or a repeated state assignment does not create a new tween because the library reuses the current target.

For custom controls that change multiple values in one callback, call `Library:QueueDependencyUpdate()`. The library then performs one dependency pass at the end of the current task cycle.

## Notifications

Legacy form:

```luau
Library:Notify({
    Title = "Saved",
    Description = "Configuration saved successfully.",
    Time = 4,
    Icon = "check",
})
```

Notification sound:

```luau
Library:Notify({
    Title = "Ready",
    Description = "The interface is ready.",
    Time = 3,
    SoundId = 92679954573730,
    Volume = 0.3,
})
```

## Dependency controls

```luau
local AdvancedToggle = MainRight:AddToggle("AdvancedMode", {
    Text = "Advanced mode",
    Default = false,
})

local DependencyBox = MainRight:AddDependencyBox()
DependencyBox:AddSlider("AdvancedValue", {
    Text = "Advanced value",
    Default = 25,
    Min = 0,
    Max = 50,
})
DependencyBox:SetupDependencies({ { AdvancedToggle, true } })
```

## Unload and cleanup

```luau
Library:OnUnload(function()
    print("Interface unloaded")
end)

Library:Unload()
```

MonHub disconnects registered signals, destroys UI and draggable elements, cancels active animations, and clears options and cached measurements. Register external connections through `Library:GiveSignal`, or disconnect them in `OnUnload`.

## Declarative API

Moving to the declarative API is optional. Do it after the legacy migration is stable.

```luau
local App = Library:Create({
    Title = "My Interface",
    Footer = "MonHub v0.0.1",
    Tabs = {
        {
            Name = "Main",
            Icon = "house",
            Sections = {
                {
                    Name = "General",
                    Side = "Left",
                    Controls = {
                        {
                            Type = "Toggle",
                            Id = "enabled",
                            Text = "Enabled",
                            Default = true,
                            OnChanged = function(Value)
                                print(Value)
                            end,
                        },
                        {
                            Type = "Slider",
                            Id = "power",
                            Text = "Power",
                            Min = 0,
                            Max = 100,
                            Default = 50,
                        },
                    },
                },
            },
        },
    },
})

App:Get("power"):SetValue(75)
App:Toggle(true)
```

Hierarchy:

```text
App
└── Tabs / Pages
    └── Sections / Groups
        └── Controls / Elements
```

`Id` is needed only for elements accessed by code. `App:Get(Id)` returns the created control.

## Wally or Studio installation

The repository `wally.toml` still contains upstream package metadata. Installing `deividcomsono/obsidian` from the public Wally registry can return original Obsidian rather than this MonHub build.

Use one of these options for exact MonHub behavior:

1. A raw loader in an executor environment.
2. A vendor copy of current `Library.lua`, `Library.d.luau`, and `addons` in your project.
3. A private Wally package or Git submodule pinned to a MonHub repository commit.

Do not mix MonHub `Library.lua` with addons from a different version.

## Troubleshooting

### `Expected ident` on line 1

Cause: the loader received HTML, an error page, or a private-repository page.

Check that:

- The URL is a raw URL.
- The repository and branch are accessible.
- The path includes `Obsidian-main/Library.lua`.
- The GitHub response is not empty.
- The executor supports `game:HttpGet` and `loadstring`.

### The UI looks like old Obsidian

Cause: the project is loading an upstream URL, upstream Wally package, or an old cached file.

Fix: verify the URL and restart the session.

### Font Face becomes Code

Use the current `Library.lua` and remove any old ThemeManager UI that creates a font selector. The release themes use Gotham Regular. Legacy raw appearance fields must be included in `SaveManager:IgnoreThemeSettings()` during config migration.

### A configuration does not load

Check that:

- All controls exist before `LoadAutoloadConfig`.
- IDs were preserved.
- `SetFolder` and `SetSubFolder` match the old project.
- The executor supports file APIs.

### Click sound does not work

Check Roblox audio permissions and asset `92679954573730` availability for the current experience.

### Watermark shows `0 ms`

`Stats.Network.ServerStatsItem["Data Ping"]` can be unavailable immediately after joining. Wait for the next update interval.

### The UI leaves the screen

Use a responsive size and call:

```luau
Window:FitToViewport()
```

### The viewport rotates but the model is invisible

Check `Object`, `Clone`, `PrimaryPart`, bounding box, and `AutoFocus`. For a `Model`, set a `PrimaryPart` when possible.

## Final checklist

- [ ] The raw URL points to MonHub.
- [ ] Library and addons come from one version.
- [ ] Existing control IDs are preserved.
- [ ] Default applies as the neutral-gray startup theme.
- [ ] Metal applies as the violet alternate theme.
- [ ] Gotham Regular is not replaced by Code.
- [ ] The window fits the desktop viewport.
- [ ] Sidebar compact works on mobile.
- [ ] Toggle and checkbox callbacks work.
- [ ] Slider works with mouse and touch.
- [ ] Dropdown single and multi values persist.
- [ ] KeyPicker and ColorPicker work.
- [ ] Old appearance fields are ignored when configurations load.
- [ ] `ThemeManager_ThemeList` saves and restores the selected built-in theme.
- [ ] Old configurations load, or are deliberately moved to a new folder.
- [ ] Click sound is available.
- [ ] Watermark, FPS, and ping controls work.
- [ ] Search has no visible delay.
- [ ] Unload cleans up UI and external connections.
- [ ] The script is tested on desktop and mobile.

## Recommended real migration order

1. Replace the loader and open a window without addons.
2. Test tabs and controls.
3. Test `Library.Options` and `Library.Toggles`.
4. Add SaveManager without autoload and call `IgnoreThemeSettings()` for old configurations.
5. Create and load a test configuration.
6. Enable autoload.
7. Add Watermark and click sound.
8. Test desktop, mobile, DPI, and resizing.
9. Move to the declarative API only after all previous steps pass.

This order localizes errors and makes each stage easy to roll back.
