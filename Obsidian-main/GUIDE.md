# MonHub UI — Complete Guide

`GUIDE.md` is the canonical guide for this build. When the public API, default visual behavior, addons, or configuration format changes, update this file in the same change.

## Contents

1. [Which version is running](#which-version-is-running)
2. [Installation and first window](#installation-and-first-window)
3. [Window, tabs, and layout](#window-tabs-and-layout)
4. [Controls](#controls)
5. [Values, callbacks, and dependencies](#values-callbacks-and-dependencies)
6. [Dialogs, notifications, and loading](#dialogs-notifications-and-loading)
7. [Themes and configuration](#themes-and-configuration)
8. [Watermark, keybinds, launcher, and sound](#watermark-keybinds-launcher-and-sound)
9. [Media and ESP preview](#media-and-esp-preview)
10. [Declarative API](#declarative-api)
11. [Advanced utilities](#advanced-utilities)
12. [Motion, performance, and lifecycle](#motion-performance-and-lifecycle)
13. [Troubleshooting](#troubleshooting)
14. [Release checklist](#release-checklist)

## Which version is running

The most common testing mistake is changing a local `Library.lua` while the script still downloads an older copy from GitHub. Restarting the script does not load local edits when it uses a remote URL.

Use the local loader while testing files from this repository:

```luau
local Library = loadstring(readfile("Library.lua"))()
```

Use the raw GitHub URL only after the changes are published:

```luau
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua"
))()
```

Do not use a GitHub `blob/...` URL with `loadstring`: it returns HTML and produces `Expected ident` on line 1. Keep `Library.lua` and every addon from the same commit or folder. `Example.lua` is a complete showcase, but it intentionally uses a fixed non-responsive desktop layout; it is not the only recommended window configuration.

## Installation and first window

The full visual profile targets executors that provide `loadstring`, HTTP requests, filesystem APIs, `getcustomasset`, `gethui`, and `protectgui`. The library itself can still run without optional addons, but saved configs and local image assets need the relevant executor APIs.

Create a small legacy-style interface first:

```luau
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua"
))()

Library:SetClickSound(92679954573730, 0.3)

local Window = Library:CreateWindow({
    Title = "MonHub Private",
    Footer = "Beta v0.0.1",
    Size = UDim2.fromOffset(760, 660),
    Center = true,
    AutoShow = true,
    GlobalSearch = true,
    Font = Enum.Font.Gotham,
    CornerRadius = 6,
})

local MainTab = Window:AddTab("Main", "house")
local MainGroup = MainTab:AddLeftGroupbox("General", "settings-2")

MainGroup:AddToggle("Enabled", {
    Text = "Enabled",
    Default = false,
    Callback = function(Value)
        print("Enabled:", Value)
    end,
})
```

For a local test, replace the first two lines with the `readfile` loader from the previous section. `QuickStart.luau` contains a short declarative equivalent, and `Example.lua` contains a wider real-world showcase.

## Window, tabs, and layout

### Important window settings

```luau
local Window = Library:CreateWindow({
    Title = "MonHub Private",
    Footer = "Beta v0.0.1",
    Size = UDim2.fromOffset(760, 660),
    Position = UDim2.fromScale(0.5, 0.5),
    Center = true,
    AutoShow = true,
    Resizable = false,
    GlobalSearch = true,
    NotifySide = "Right",
    Font = Enum.Font.Gotham,
    CornerRadius = 6,
    ShowCustomCursor = true,
    AlwaysOnTop = false,
    ToggleKeybind = Enum.KeyCode.RightShift,

    ResponsiveLayout = true,
    SingleColumnWidth = 540,
    HideSearchAtWidth = 210,
    EnableSidebarResize = false,

    ShowCompactLauncher = true,
    CompactLauncherIcon = "maximize-2",
    CompactLauncherSize = 36,
    CompactLauncherWidth = 172,
    CompactLauncherTitle = "MonHub Private",
    CompactLauncherPosition = UDim2.fromScale(0.5, 0.5),
    CompactLauncherAnchorPoint = Vector2.new(0.5, 0.5),
    CompactLauncherDraggable = true,

    Animations = {
        ToggleWindow = true,
        TabSwitch = true,
        Groupbox = true,
        Dropdown = true,
        KeyPicker = true,
    },
    TabTransitionTime = 0.11,
    TabSwipeOffset = 4,
    TabSwipeFrom = "bottom",
})
```

`Default`, Gotham Regular, a restrained 6px outer radius, compact square checkmarks, and a footer are the normal MonHub profile. Its neutral-gray palette uses soft separators, full-width sidebar tabs, and fixed icon/text alignment. `Metal` is the violet reference preset and `Midnight` is the near-black neutral preset. The window is clamped to the viewport. The top-right move icon repositions the main window.

Runtime window setters are available when a value needs to change after construction:

```luau
Window:ChangeTitle("MonHub Private")
Window:SetFooter("Beta v0.0.1")
Window:SetCornerRadius(6)
Window:SetAlwaysOnTop(true)
Window:SetResponsiveLayoutEnabled(true)
Window:FitToViewport()
```

### Tabs and groupboxes

```luau
local Controls = Window:AddTab("Controls", "sliders-horizontal")
local Visuals = Window:AddTab({
    Name = "Visuals",
    Icon = "eye",
    Description = "ESP and display settings",
    Order = 2,
})

local Left = Controls:AddLeftGroupbox("Movement", "move")
local Right = Controls:AddRightGroupbox("Actions", "zap")

Left:SetOrder(1)
Right:SetOrder(2)
```

Use left and right groupboxes for desktop pages. With `ResponsiveLayout = true`, a narrow window changes the page into one readable column. A `Tabbox` creates a smaller tab container inside a groupbox:

```luau
local Tabbox = Right:AddTabbox("Modes")
local Normal = Tabbox:AddTab("Normal")
local Advanced = Tabbox:AddTab("Advanced")

Normal:AddLabel("Normal settings")
Advanced:AddLabel("Advanced settings")
```

## Controls

Every named control is available through `Library.Options` or `Library.Toggles`. Prefer unique IDs. All callback text and labels shown to users should be English if the rest of the client is English.

### Toggle and checkbox

```luau
local Enabled = Left:AddToggle("Enabled", {
    Text = "Enable feature",
    Default = false,
    Variant = "Default",
    Callback = function(Value)
        print(Value)
    end,
})

local SafeMode = Left:AddCheckbox("SafeMode", {
    Text = "Safe mode",
    Default = true,
})
```

`AddToggle` defaults to a compact 16×16 square with a 3px radius and an animated checkmark. `AddCheckbox` uses the same clear square language. Existing projects that prefer the legacy 24×14 sliding switch can set `Library.ForceCheckbox = false` before creating controls; explicit checkbox creation still uses `AddCheckbox`.

Toggle variants are `Default`, `Warning`, and `Danger`. `Caution` is a legacy alias for `Warning`; `Destructive` is an alias for `Danger`. `Risky = true` also maps to `Danger` when no explicit variant is supplied.

```luau
local Reset = Left:AddToggle("ResetEverything", {
    Text = "Reset everything",
    Variant = "Danger",
    ConfirmDanger = true,
    ConfirmTitle = "Enable reset?",
    ConfirmDescription = "This action may affect your session.",
    Callback = function(Value)
        if Value then
            print("Confirmed")
        end
    end,
})
```

Enabling a danger toggle through the UI opens a short `Cancel` / `Continue` dialog. Turning it off remains immediate. `SetValue(true)` is intentionally immediate for programmatic code and configuration loading. Use `ConfirmDanger = false` only when your control already has its own confirmation flow.

### Button variants

```luau
Left:AddButton({
    Text = "Apply",
    Variant = "Primary",
    Icon = "check",
    Func = function()
        print("Applied")
    end,
})

Left:AddButton({
    Text = "Reset",
    Variant = "Danger",
    Func = function()
        print("Reset")
    end,
})

Left:AddButton({
    Text = "Open help",
    Variant = "Ghost",
    Func = function()
        print("Help")
    end,
})
```

Supported variants are `Default`, `Primary`, `Warning`, `Danger`, and `Ghost`. `Secondary`, `Caution`, and `Destructive` are accepted legacy aliases. Buttons use a flat theme-aware surface by default; primary, warning, and danger variants stay visually restrained through their outline and optional icon rather than a large colored fill. Warning and danger buttons receive restrained semantic icons by default. Replace one with `Icon = "..."`, remove it with `Icon = false`, or change the global default:

```luau
Library:SetButtonVariantIcon("Danger", "trash-2")
```

### Input, slider, and dropdown

```luau
Left:AddInput("ProfileName", {
    Text = "Profile name",
    Default = "Default profile",
    Finished = true,
    ClearTextOnFocus = false,
    Callback = function(Value)
        print(Value)
    end,
})

Left:AddSlider("Power", {
    Text = "Power",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
})

Left:AddDropdown("Mode", {
    Text = "Mode",
    Values = { "Balanced", "Fast", "Quality" },
    Default = "Balanced",
    AllowNull = false,
    Searchable = true,
})
```

Useful slider settings: `Prefix`, `Suffix`, `Compact`, `HideMax`, `FormatDisplayValue`, and `AllowRightClickInput`. Dropdowns support `Multi`, `DisabledValues`, `ValueImages`, `DragSelect`, `MaxVisibleDropdownItems`, `SpecialType = "Player" | "Team"`, `ExcludeLocalPlayer`, and custom display formatters.

### Labels, dividers, and nested buttons

```luau
Left:AddLabel("A short explanation")
Left:AddLabel({ Text = "<b>Rich text</b> is supported", DoesWrap = true })
Left:AddDivider()

local Parent = Left:AddButton("More actions", function()
    print("Parent action")
end)

Parent:AddButton("Secondary action", function()
    print("Secondary action")
end)
```

### KeyPicker and ColorPicker addons

Add keybinds and colors to a label or a toggle:

```luau
local Feature = Left:AddToggle("Feature", {
    Text = "Feature",
    Default = false,
})

Feature:AddKeyPicker("FeatureKey", {
    Default = "H",
    Mode = "Toggle",
    SyncToggleState = true,
    Text = "Feature key",
})

Feature:AddColorPicker("FeatureColor", {
    Default = Color3.fromRGB(119, 182, 255),
    Transparency = 0,
    Title = "Feature color",
})
```

Feature keybinds expose `Toggle` and `Hold`. `Toggle` persists until pressed again; `Hold` remains active only while the key is down. `Press` is reserved for label and button actions and is intentionally hidden from the state keybind menu. Use `NoUI = true` for a menu keybind that should not appear there. Only configured feature binds appear in that menu.

### Media controls

```luau
local Media = Visuals:AddLeftGroupbox("Media", "image")

Media:AddImage("Logo", {
    Image = "sparkles",
    Color = Color3.fromRGB(184, 189, 201),
    Height = 82,
})

Media:AddVideo("Trailer", {
    Video = "rbxassetid://5608324215",
    Looped = true,
    Playing = false,
    Volume = 0,
    Height = 175,
})

Media:AddUIPassthrough("Custom", {
    Instance = someGuiObject,
    Height = 110,
})
```

`AddViewport` accepts a `BasePart` or `Model`. Set `Clone = true` for an isolated copy, `AutoFocus = true` to fit it, and `Interactive = true` for mouse/touch rotation.

## Values, callbacks, and dependencies

Controls expose `SetValue`, `SetVisible`, `SetDisabled`, `SetText`, `OnChanged`, and `Destroy` where appropriate.

```luau
Library.Toggles.Enabled:SetValue(true)
Library.Options.Power:SetValue(75)
Library.Options.Mode:SetValue("Quality")

Library.Toggles.Enabled:OnChanged(function(Value)
    print("Enabled is now", Value)
end)
```

Use a dependency box to hide settings until a requirement is met:

```luau
local Extra = Left:AddDependencyBox()
Extra:AddSlider("AdvancedPower", {
    Text = "Advanced power",
    Min = 0,
    Max = 50,
    Default = 25,
})

Extra:SetupDependencies({
    { Library.Toggles.Enabled, true },
})
```

Dependency refreshes are batched and unchanged values are ignored. Do not create a polling loop just to update control visibility.

## Dialogs, notifications, and loading

Use a dialog for a deliberate destructive action. `Ghost`, `Primary`, `Warning`, and `Danger` footer variants follow the same component system as ordinary buttons.

```luau
Window:AddDialog("ClearConfig", {
    Title = "Clear configuration?",
    Description = "This cannot be undone.",
    Icon = "triangle-alert",
    AutoDismiss = true,
    OutsideClickDismiss = false,
    FooterButtons = {
        Cancel = {
            Title = "Cancel",
            Variant = "Ghost",
            Order = 1,
            Callback = function() end,
        },
        Continue = {
            Title = "Continue",
            Variant = "Danger",
            Order = 2,
            Callback = function()
                print("Cleared")
            end,
        },
    },
})
```

Use notifications for non-blocking feedback:

```luau
Library:Notify({
    Title = "Saved",
    Description = "Configuration updated.",
    Time = 3,
    Icon = "check",
})
```

For startup or asynchronous work, use a loading screen:

```luau
local Loading = Library:CreateLoading({
    Title = "MonHub Private",
    CurrentStep = 1,
    TotalSteps = 3,
    ShowSidebar = false,
})

Loading:SetDescription("Loading modules")
Loading:SetCurrentStep(2)
Loading:Continue()
```

`Loading:ShowErrorPage(true)`, `SetErrorMessage`, and `SetErrorButtons` provide a clean recovery screen. Always call `Destroy()` if a loading instance will not continue.

## Themes and configuration

### Built-in themes

The release ships exactly three palettes. `Default` starts automatically with layered neutral-gray surfaces and a muted slate accent. `Metal` uses dark neutral surfaces with a restrained violet accent inspired by the release reference. `Midnight` uses near-black neutral surfaces and a muted steel accent. All three use Gotham Regular, restrained 6px outer geometry, subtle single-pixel outlines, and semantic warning/danger colors. The interface feels soft through text contrast, spacing, surface hierarchy, and short motion—not blanket rounding.

`Library.Themes` contains only `Default`, `Metal`, and `Midnight`. Legacy preset names resolve safely to one of these built-ins, while raw legacy theme tables and individual saved color fields are ignored so they cannot leave a mixed palette.

```luau
Library:SetTheme("Default")
Library:SetTheme("Metal")
Library:SetTheme("Midnight")
```

### Font policy

Gotham Regular is the default UI font. It stays readable at small Roblox control sizes, preserves complete labels, numbers, punctuation, and keybind text, and avoids the dense appearance of a heavier weight.

### ThemeManager preset selector

`ThemeManager.lua` exposes a minimal three-item preset dropdown without a palette editor or custom theme files:

```luau
local ThemeManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/ThemeManager.lua"
))()

ThemeManager:SetLibrary(Library)
ThemeManager:ApplyToTab(Tabs["UI Settings"])
```

The selector uses the ID `ThemeManager_ThemeList`, so SaveManager can persist `Default`, `Metal`, or `Midnight` with the rest of a configuration. Old marker files and raw color fields remain ignored rather than deleted. This keeps user files recoverable while preventing stale colors from repainting only part of the interface.

### SaveManager

Build every control before loading configurations:

```luau
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/SaveManager.lua"
))()

SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("MonHub")
SaveManager:SetSubFolder(tostring(game.PlaceId))

local ConfigGroup = SaveManager:BuildConfigSection(Tabs.Settings)
ConfigGroup:SetOrder(-100)
SaveManager:LoadAutoloadConfig()
```

`IgnoreThemeSettings()` is recommended while migrating old configurations. It skips stale raw appearance entries but intentionally keeps `ThemeManager_ThemeList`, allowing the selected built-in preset to save and restore normally. Configuration parser errors return a readable error instead of silently reporting success. Config names must be plain file names: do not use slashes, `..`, reserved marker names, or leading/trailing spaces.

## Watermark, keybinds, launcher, and sound

### Watermark

```luau
Library:SetWatermark("MonHub  |  120 FPS  |  42 ms")
Library:SetWatermarkVisibility(true)
Library:SetWatermarkSide("Left")
Library:SetWatermarkDraggable(true)
```

The default watermark starts at the top-left, has no clock, can be dragged with mouse or touch, and stays inside the viewport after text or screen-size changes. `SetWatermarkSide("Right")` snaps it to the top-right. The library does not automatically save a dragged pixel position; save a side preference through your own config control when needed.

### Menu keybind and keybind menu

```luau
MenuGroup:AddLabel("Menu keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Show or hide the menu",
})

Library.ToggleKeybind = Library.Options.MenuKeybind
Library:SetKeybindMenuVisible(true)
```

Set `Library.ToggleKeybind` to the menu keybind or point it at an `AddKeyPicker` option. A menu `KeyPicker` is saved with normal configurations by default and restored safely during config loading; `SetValue` never opens or closes the window. The keybind menu intentionally displays only entries with actual configured binds. Toggle rows use a fixed 14×14 checkmark, an 18px row, and layout-managed spacing so DPI scaling cannot move the label or indicator. The overlay uses a 70ms opacity-only transition and rows settle in 75ms. Use `NoUI = true` for the menu keybind itself.

Only add the menu key picker to `SaveManager:SetIgnoreIndexes()` when the bind must remain global and independent from every configuration. The keybind overlay visibility and position are also stored with each configuration.

### Centered compact launcher

The minimize icon hides the main window and leaves a small centered, draggable launcher with the script title. It restores with a short fade and a subtle scale settle. Clicking it restores the window. Hiding the UI with the keybind deliberately does not create a launcher, keeping gameplay and the camera clear; press the same keybind to reopen.

```luau
Window:SetCompactLauncherTitle("MonHub Private")
Window:SetCompactLauncherIcon("maximize-2")
Window:SetCompactLauncherWidth(172)
Window:SetCompactLauncherPosition(UDim2.fromScale(0.5, 0.5))
Window:SetCompactLauncherDraggable(true)
```

### Click sound

```luau
Library:SetClickSound(92679954573730, 0.3)
```

The first argument is the asset ID and the second is volume from `0` to `1`.

## Media and ESP preview

`addons/VisualPreview.lua` creates a separate preview beside one regular tab. It clones a real Roblox character from a `Player`, `Model`, or resolver function; it never changes the original character. It hides with the menu, stays within the viewport, supports drag rotation and scroll-wheel zoom, and follows the active theme surface and lighting profile.

```luau
local VisualPreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/VisualPreview.lua"
))()
local Players = game:GetService("Players")

local Preview = VisualPreview.Create(Library, Tabs.Visuals, {
    Name = "ESP preview",
    Window = Window,
    Target = Players.LocalPlayer,
    Width = 300,
    Height = 420,
    Enabled = false,
    Side = "Auto",
    Alignment = "Center",
    Gap = 12,
})

Preview:SetEnabled(true)
Preview:SetBoxVisible(true)
Preview:SetNameVisible(true)
Preview:SetDistanceVisible(true)
Preview:SetColor(Color3.fromRGB(119, 182, 255))
Preview:SetGradientColor(Color3.fromRGB(186, 138, 255))
Preview:SetGradientEnabled(true)
Preview:SetChams(true, Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), 0.25, 0)
```

Use `Preview:SetTarget(PlayerOrModel)`, `Preview:Rotate(x, y)`, `Preview:SetZoom(value)`, and `Preview:ResetView()` for custom controls. `Renderer` is optional. It must return a table with a live GuiObject in `Container`; `BoxFrame`, `BoxStroke`, `BoxGradient`, `InfoTop`, `InfoBottom`, `HealthBack`, and `HealthFill` are optional and are safely skipped when absent. Do not paste an undefined `State.CreateESPPreview` placeholder into a project.

## Declarative API

For an interface described by data rather than sequential calls, use `Library:Create`:

```luau
local App = Library:Create({
    Title = "MonHub",
    Footer = "Ready",
    Window = {
        Size = UDim2.fromOffset(760, 660),
        Center = true,
    },
    Tabs = {
        {
            Name = "Dashboard",
            Icon = "house",
            Sections = {
                {
                    Name = "General",
                    Side = "Left",
                    Controls = {
                        {
                            Type = "Toggle",
                            Id = "active",
                            Text = "Active",
                            Default = true,
                            OnChanged = function(Value)
                                print(Value)
                            end,
                        },
                        {
                            Type = "Slider",
                            Id = "intensity",
                            Text = "Intensity",
                            Min = 0,
                            Max = 100,
                            Default = 40,
                        },
                    },
                },
            },
        },
    },
})

App:Get("intensity"):SetValue(60)
App:Notify({ Title = "MonHub", Description = "Ready", Time = 3 })
```

Supported element types are `Label`, `Button`, `Toggle`, `Checkbox`, `Input`, `Slider`, `Dropdown`, `Divider`, `Viewport`, `Image`, `Video`, and `UIPassthrough`. Add `KeyPicker` and `ColorPicker` objects through an element’s `Addons` array. `App:Toggle()` controls visibility and `App:Destroy()` cleans up the app.

## Advanced utilities

Use these lower-level helpers only when the standard window and controls do not cover the integration:

```luau
Library:SetDPIScale(100)
Library:SetNotifySide("Left")
Library:SetIconModule(CustomIconModule)

Library:AddToRegistry(CustomFrame, {
    BackgroundColor3 = "MainColor",
    BorderColor3 = "OutlineColor",
})
```

`AddToRegistry` makes a custom `Instance` follow the active palette. Values may be Scheme field names or resolver functions. Call `RemoveFromRegistry(CustomFrame)` before replacing an externally owned GUI object. Use `GiveSignal(connection)` for connections that should be cleaned automatically by `Library:Unload()`.

`AddDraggableLabel`, `AddDraggableButton`, `AddDraggableImageButton`, and `AddDraggableMenu` create clamped reusable overlays. `AddContextMenu` and `AddTooltip` are available for custom controls. Keep custom overlays small and viewport-clamped so they do not block gameplay input.

## Motion, performance, and lifecycle

The library coalesces viewport fitting, search, dependency updates, and motion. It uses keyed short tweens for hover, keybind menus, notifications, dialogs, tab content, and the compact launcher; it adds no perpetual glow or render-loop effect. Window opening and closing use 90ms and 60ms opacity-only transitions, with no scale or font resizing. Tabs use a 110ms entry and a 70ms exit fade with a 4px maximum offset. Keybind overlays use a 70ms fade, keybind rows use 75ms, and standard controls use 110ms state transitions. Gotham Regular remains the default readable UI font. Avoid `RenderStepped` or `while task.wait()` loops for UI-only changes when an `OnChanged` callback, a dependency box, or a setter is enough.

```luau
Window:SetAnimations({
    ToggleWindow = true,
    TabSwitch = true,
    Groupbox = true,
    Dropdown = true,
    KeyPicker = true,
}, 0.11, 4, "bottom")

Library:Notify({
    Title = "Saved",
    Description = "Configuration updated.",
    Time = 3,
    Icon = "check",
})

Library:OnUnload(function()
    print("UI cleaned up")
end)

Library:Unload()
```

Window hide and restore animations are intentionally short and opacity-led so text does not scale or change appearance during close. `Unload()` cancels managed tweens, disconnects signals, destroys UI, and clears library references. It is safe to call more than once, but it is terminal: create a fresh library instance before building another window. A library instance supports one window only, which prevents duplicate global input handlers.

## Troubleshooting

### Changes do not appear after restarting

You are probably loading `Library.lua` from GitHub while editing a local copy. Test with `loadstring(readfile("Library.lua"))()` or publish the changed files, then use the raw URL. Update the library and addons together.

### `Expected ident` on line 1

The loader received HTML or another non-Luau response. Use a raw GitHub URL, not a browser `blob` URL, and verify the URL in a browser before executing it.

### The UI starts with an old or mixed theme

Use the current `Library.lua` and call `SaveManager:IgnoreThemeSettings()` while migrating old configs. Raw legacy palette fields are ignored, while a valid `ThemeManager_ThemeList` value restores `Default`, `Metal`, or `Midnight`. Old custom-theme files remain on disk but are not executed or applied.

### A config does not load

Create all tabs and controls before `LoadAutoloadConfig()`. Call `SaveManager:IgnoreThemeSettings()` when reusing configs created by older builds. Inspect the returned error from `SaveManager:Load(name)` or `LoadJSON(content)` instead of assuming a failed parser succeeded.

### The watermark is on the right

New sessions start on the left. A saved config may deliberately restore a previous `WatermarkSide = "Right"` choice. Select Left in UI Settings or call `Library:SetWatermarkSide("Left")`.

### The preview rotates but no character is visible

Pass a real `Player` or `Model` as `Target`, create it after the target character exists, and keep the preview addon from the same revision as Library. The generic preview needs no `Renderer`; only use one when your project provides it.

## Release checklist

- [ ] `Library.lua`, `ThemeManager.lua`, `SaveManager.lua`, and optional addons come from one commit.
- [ ] Local changes are tested with a local loader before publishing.
- [ ] All user-facing labels and notifications are English.
- [ ] The window is readable at desktop and narrow/mobile widths.
- [ ] Every danger control has a clear confirmation or an intentional opt-out.
- [ ] Old appearance keys are ignored while legacy configs are migrated.
- [ ] `Default` starts in gray, `Metal` applies violet, and `Midnight` applies near-black without stale colors.
- [ ] `ThemeManager_ThemeList` saves and restores with configurations.
- [ ] Watermark, keybind menu, compact launcher, and unload are tested.
- [ ] This `GUIDE.md` is updated for every public API or behavior change.

For historical Obsidian migration notes, see [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md). For a working feature showcase, see [Example.lua](Example.lua). For exact type signatures, see [Library.d.luau](Library.d.luau).
