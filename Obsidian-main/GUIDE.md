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
8. [Watermark, keybinds, and launcher](#watermark-keybinds-and-launcher)
9. [Media and ESP preview](#media-and-esp-preview)
10. [Declarative API](#declarative-api)
11. [Advanced utilities](#advanced-utilities)
12. [Motion, performance, and lifecycle](#motion-performance-and-lifecycle)
13. [Troubleshooting](#troubleshooting)
14. [Migration from Obsidian](#migration-from-obsidian)
15. [Release checklist](#release-checklist)
16. [Changelog](#changelog)

## Which version is running

The most common testing mistake is changing a local `Library.lua` while the script still downloads an older copy from GitHub. Restarting the script does not load local edits when it uses a remote URL.

Use the local loader while testing files from this repository:

```luau
local Library = loadstring(readfile("Library.lua"))()
```

Use the raw GitHub URL only after the changes are published:

```luau
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua?monhub=0.0.1-release-6-image-ui-3"
))()
if Library.ReleaseVersion ~= "0.0.1-release-6" then
    warn(string.format("MonHub version notice: expected %s, received %s", "0.0.1-release-6", tostring(Library.ReleaseVersion)))
end
```

Do not use a GitHub `blob/...` URL with `loadstring`: it returns HTML and produces `Expected ident` on line 1. Keep `Library.lua` and every addon from the same commit or folder. `Example.lua` is a complete showcase, but it intentionally uses a fixed non-responsive desktop layout; it is not the only recommended window configuration.

## Installation and first window

The full visual profile targets executors that provide `loadstring`, HTTP requests, filesystem APIs, `getcustomasset`, `gethui`, and `protectgui`. The library itself can still run without optional addons, but saved configs and local image assets need the relevant executor APIs.

Create a small legacy-style interface first:

```luau
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua?monhub=0.0.1-release-6-image-ui-3"
))()
if Library.ReleaseVersion ~= "0.0.1-release-6" then
    warn(string.format("MonHub version notice: expected %s, received %s", "0.0.1-release-6", tostring(Library.ReleaseVersion)))
end

local Window = Library:CreateWindow({
    Title = "MonHub Private",
    Footer = "MonHub v0.0.1",
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
    Footer = "MonHub v0.0.1",
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
    TabTransitionTime = 0.075,
    TabSwipeOffset = 2,
    TabSwipeFrom = "bottom",
})
```

`Default`, Gotham Regular, a restrained 6px outer radius, compact square checkmarks, and a footer are the normal MonHub profile. Its neutral-gray palette separates the window background, cards, raised overlays, controls, hover states, muted text, and soft accent surfaces instead of deriving every component from one color. `Metal` is the violet reference preset and `Midnight` is the near-black neutral preset. The window is clamped to the viewport. The top-right move icon repositions the main window.

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

`AddToggle` defaults to a compact, fully filled 16×16 square with a fixed-size antialiased checkmark inside a 22px layout-managed row. It has no corner mask, so the four edge pixels remain solid at every DPI scale. The mark uses opacity-only motion so fractional resize frames cannot create pixel shimmer. `AddCheckbox` uses the same square language. Existing projects that prefer the legacy 24×14 sliding switch can set `Library.ForceCheckbox = false` before creating controls; explicit checkbox creation still uses `AddCheckbox`.

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
    Text = "Open help",
    Variant = "Ghost",
    Func = function()
        print("Help")
    end,
})
```

Supported button variants are `Default`, `Primary`, and `Ghost`; `Secondary` remains an alias for `Default`. Warning and danger button styling was removed because colored outlines competed with the content and made dense pages inconsistent. Use an explicit `Icon`, a confirmation dialog, or clear button text when an action needs additional context.

Migration to the current button set is required for new and maintained scripts. Replace `Warning`, `Danger`, `Caution`, `Destructive`, and `Risky` button variants with `Default`, `Primary`, or `Ghost`. The old names still resolve to `Default` only to keep cached scripts from failing; they are not part of the release design contract. Warning and danger toggle variants remain supported because they communicate persistent state rather than a one-shot action.

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
    Transparency = 0,
    BackgroundTransparency = 0.12,
    OutlineTransparency = 0.48,
    OutlineThickness = 1,
    CornerRadius = 5,
    Padding = 10,
    ImageSize = UDim2.fromScale(1, 1),
    ImagePosition = UDim2.fromScale(0.5, 0.5),
    ImageAnchorPoint = Vector2.new(0.5, 0.5),
    ImageScale = 1,
    Rotation = 0,
    AspectRatio = 0,
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

`AddImage` keeps the asset, its container, and its outline independent. `Transparency` affects only the asset; `BackgroundTransparency` affects the panel behind it; `OutlineTransparency` affects only the stroke. Layout controls are `Padding`, `ImageSize`, `ImagePosition`, `ImageAnchorPoint`, `ImageScale`, `Rotation`, `AspectRatio`, and `TileSize`. Runtime methods are `SetImage`, `SetColor`, `SetTransparency`, `SetBackgroundTransparency`, `SetOutlineTransparency`, `SetBackgroundColor`, `SetOutlineColor`, `SetPadding`, `SetCornerRadius`, `SetScaleType`, `SetImageSize`, `SetImageScale`, `SetImagePosition`, `SetTileSize`, `SetRotation`, `SetAspectRatio`, `SetHeight`, `SetVisible`, and `Destroy`. `ImageScale` is the easiest way to enlarge an asset that contains excessive transparent margins without changing its panel size. Pass `nil` to `SetBackgroundColor` or `SetOutlineColor` to resume theme colors.

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

Use a dialog for a deliberate destructive action. `Ghost`, `Primary`, and `Default` footer variants follow the same component system as ordinary buttons.

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
            Variant = "Primary",
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

The release ships six restrained palettes. `Default` starts automatically with layered neutral-gray surfaces and a muted slate accent. `Metal` uses dark neutral surfaces with a desaturated violet accent. `Midnight` uses near-black surfaces and a low-saturation steel accent. `Steel` is a cool blue-gray preset, `Sage` is a quiet green-gray preset, and `Ash` is a warm neutral preset. Every palette uses Gotham Regular, restrained 6px outer geometry, subtle single-pixel outlines, and semantic warning/danger colors. The interface feels soft through text contrast, spacing, surface hierarchy, and short motion—not blanket rounding.

Every preset supplies `BackgroundColor`, `SurfaceColor`, `RaisedColor`, `ElementColor`, `HoverColor`, `TopBarColor`, `AccentColor`, `AccentSoftColor`, `OutlineColor`, `FontColor`, `MutedFontColor`, and `ShadowColor`. `SetTheme` copies the complete preset, updates the instance registry, then refreshes stateful controls such as active toggles, disabled sliders, buttons, and the compact launcher. This order is deliberate: a theme switch cannot leave an old hover color, top bar, footer, popup, or active control behind. Supported clients receive one subtle `UIShadow` on elevated windows, dialogs, notifications, and the launcher; unsupported clients fall back silently to the normal outline, and ordinary controls never receive individual blurred shadows.

`Library.Themes` contains `Default`, `Metal`, `Midnight`, `Steel`, `Sage`, and `Ash`. Legacy preset names resolve safely to one of these built-ins, while raw legacy theme tables and individual saved color fields are ignored so they cannot leave a mixed palette.

```luau
Library:SetTheme("Default")
Library:SetTheme("Metal")
Library:SetTheme("Midnight")
Library:SetTheme("Steel")
Library:SetTheme("Sage")
Library:SetTheme("Ash")
```

### Font policy

Inter Bold is loaded automatically by `Library.lua` before the first window is created. The same `Library.Scheme.Font` is used by windows, controls, overlays, notifications, keybind rows, previews, galleries, and dashboard addons. The downloaded TTF and its generated metadata are cached in `MonHub/assets`, so the network is used only when the cached font is missing or invalid.

```luau
local ActiveFont = Library.DefaultFont
local FontError = Library.DefaultFontError
```

`LoadCustomFont` validates the downloaded font header and never executes font data. Clients without `isfile`, `writefile`, `makefolder`, and `getcustomasset` automatically use Gotham. The default override remains active through every theme switch. Call `Library:SetThemeFont(AnotherFont)` only when a project intentionally replaces the global typography.

Theme updates are transactional. Every registered property is isolated during repaint, stateful controls refresh after the base pass, and a final pass applies descriptors created by those state changes. A faulty dynamic property can no longer prevent the remaining colors on the same element from updating.

### ThemeManager preset selector

`ThemeManager.lua` exposes a minimal six-item preset dropdown without a palette editor or custom theme files:

```luau
local ThemeManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/ThemeManager.lua?monhub=0.0.1-release-6"
))()

ThemeManager:SetLibrary(Library)
ThemeManager:ApplyToTab(Tabs["UI Settings"])
```

The selector uses the ID `ThemeManager_ThemeList`, so SaveManager can persist any built-in preset with the rest of a configuration. Old marker files and raw color fields remain ignored rather than deleted. This keeps user files recoverable while preventing stale colors from repainting only part of the interface.

### SaveManager

Build every control before loading configurations:

```luau
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/SaveManager.lua?monhub=0.0.1-release-6"
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

## Watermark, keybinds, and launcher

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

## Media and ESP preview

`addons/VisualPreview.lua` clones a real Roblox character into a `ViewportFrame`. It can open as a fixed side panel, mount into any `GuiObject`, or live directly inside a MonHub groupbox. The clone keeps the target's rig, body colors, clothing, accessories, and current appearance without changing the source character. Drag or touch rotates it, the mouse wheel zooms it, and it hides with the main interface.

`addons/DrawingESPPreview.lua` is the ready-made shared Drawing backend. Its `UpdateEntity` method draws the same box, name, distance, weapon, and health state for a live player or the preview clone. The preview therefore does not need a second decorative ESP implementation.

```luau
local VisualPreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/VisualPreview.lua?monhub=0.0.1-release-6"
))()
local DrawingESPPreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/DrawingESPPreview.lua?monhub=0.0.1-release-6"
))()
local Players = game:GetService("Players")

local PreviewGroup = Tabs.Visuals:AddRightGroupbox("Live preview", "scan-eye")
local ESPRenderer = DrawingESPPreview.Create({
    Color = Color3.fromRGB(119, 166, 209),
    GradientColor = Color3.fromRGB(202, 220, 239),
})

local Preview = VisualPreview.CreateEmbedded(Library, PreviewGroup, {
    Id = "PlayerPreview",
    Name = "ESP preview",
    Target = Players.LocalPlayer,
    Height = 320,
    Enabled = false,
    Gradient = true,
    DynamicBoxes = true,
    Renderer = ESPRenderer,
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

Use `VisualPreview.Create(Library, Tab, Info)` without `Groupbox` for the fixed side-panel form. Set `Parent = SomeGuiObject` for a direct mount. Use `Preview:Mount(Parent, Height)` or `Preview:Embed(Groupbox, Id, Height)` to move an existing preview. `Preview:SetTarget(PlayerOrModel)`, `Preview:Rotate(x, y)`, `Preview:SetZoom(value)`, and `Preview:ResetView()` remain available in every form.

The shared renderer exposes `CreateEntity`, `UpdateEntity`, `SetEntityVisible`, and `RemoveEntity`. Feed the absolute screen bounds already calculated by the live ESP into the same method:

```luau
local Entity = ESPRenderer:CreateEntity()

ESPRenderer:UpdateEntity(Entity, {
    Visible = true,
    Bounds = {
        AbsoluteX = BoxX,
        AbsoluteY = BoxY,
        Width = BoxWidth,
        Height = BoxHeight,
    },
    ContentPosition = Vector2.zero,
    ContentSize = workspace.CurrentCamera.ViewportSize,
    Color = Config.BoxColor,
    GradientColor = Config.BoxGradientColor,
    BoxVisible = Config.Boxes,
    NameVisible = Config.Names,
    DistanceVisible = Config.Distance,
    WeaponVisible = Config.Weapons,
    HealthVisible = Config.HealthBar,
    Name = Player.DisplayName,
    Distance = Distance,
    Weapon = WeaponName,
    Health = HealthRatio,
})
```

Call `UpdateEntity` from the live ESP's existing frame scheduler and call `RemoveEntity` when its player entry is removed. There is no extra heartbeat in the renderer itself. Call `ESPRenderer:Destroy()` during script unload. When the executor has no Drawing API, `DrawingESPPreview.Create(...).Available` is false and `VisualPreview` uses its theme-aware GUI fallback.

For a custom live ESP backend, pass an adapter table with `AttachPreview(Preview, Context)`, `UpdatePreview(Preview, Context)`, `SetPreviewVisible(Preview, Visible)`, and `DetachPreview(Preview)`. `Context.Bounds` contains absolute and local box coordinates, while `Context.Model` is the real cloned model. This makes the preview use the project's actual renderer rather than approximating its visual style.

### Fixed real-R6 visual preview

`addons/FixedR6Preview.lua` requests the current player's applied `HumanoidDescription`, creates an actual R6 model, mounts that model in the fixed `VisualPreview` side panel, and uses `DrawingESPPreview` or a supplied renderer adapter. The panel is tied to one tab, hides with the main window, stays fixed to the selected side, supports drag rotation and wheel zoom, and refreshes the R6 appearance after character appearance changes.

```luau
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua?monhub=0.0.1-release-6-image-ui-3"
))()
local VisualPreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/VisualPreview.lua?monhub=0.0.1-release-6"
))()
local DrawingESPPreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/DrawingESPPreview.lua?monhub=0.0.1-release-6"
))()
local FixedR6Preview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/FixedR6Preview.lua?monhub=0.0.1-release-6"
))()

local Window = Library:CreateWindow({ Title = "Visual test" })
local Visuals = Window:AddTab("Visuals", "scan-eye")
local Preview = FixedR6Preview.Create(Library, VisualPreview, DrawingESPPreview, Visuals, {
    Target = game:GetService("Players").LocalPlayer,
    Enabled = true,
    Side = "Right",
    Alignment = "Center",
    Box = true,
    Health = true,
    Gradient = true,
    DynamicBoxes = true,
})
```

Use `Preview.Preview` for the complete `VisualPreview` API. `Preview:SetEnabled`, `SetColors`, `SetGradientEnabled`, `SetPosition`, `Rotate`, `SetZoom`, `RefreshCharacter`, and `Destroy` cover the common path. To display the exact production ESP instead of the bundled Drawing renderer, pass the same live renderer adapter through `Renderer`. The wrapper owns and cleans only the renderer it creates itself.

### Optional image gallery and animated preview

`addons/ImageGallery.lua` and `addons/ImagePreview.lua` are opt-in addons for skin changers, weapon catalogues, skybox selectors, map cards, and other image-heavy tools. `Library.lua` never loads them automatically. The complete `Example.lua` imports them explicitly because it is the visual addon showcase; projects that do not request them create no related instances, connections, tweens, or network requests. The example includes nine skybox assets split into Space, Atmosphere, and Worlds categories.

The gallery uses a fixed cell pool for one page. With `PageSize = 15`, only fifteen cards exist even if `Items` contains thousands of skins. Search is debounced by 80ms, hidden pages do not assign image URLs, and there is no heartbeat or render loop. The full preview uses two recycled image layers for a short crossfade and zoom transition.

```luau
local ImageGallery = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/ImageGallery.lua?monhub=0.0.1-release-6-image-ui-3"
))()
local ImagePreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/ImagePreview.lua?monhub=0.0.1-release-6-image-ui-3"
))()

local SkinGrid = Tabs.Visuals:AddLeftGroupbox("Skins", "layout-grid")
local SkinLook = Tabs.Visuals:AddRightGroupbox("Selected skin", "image")

local Preview = ImagePreview.CreateEmbedded(Library, SkinLook, "SkinPreview", {
    Height = 280,
    ScaleType = "Fit",
    ImageTransparency = 0,
    ImagePadding = 12,
    ImageScale = 1,
    BackgroundTransparency = 0.04,
    CanvasTransparency = 0.18,
    CaptionTransparency = 0.08,
    OutlineTransparency = 0.48,
    ShadeTransparency = 0.62,
    Title = "Select a skin",
    Motion = true,
})

local Gallery = ImageGallery.CreateEmbedded(Library, SkinGrid, "SkinGallery", {
    Height = 344,
    Columns = 5,
    PageSize = 15,
    CellHeight = 78,
    CellTransparency = 0.06,
    OutlineTransparency = 0.48,
    ImageTransparency = 0,
    ImageBackgroundTransparency = 0.22,
    ImagePadding = 5,
    ImageScale = 1,
    ForwardItemStyle = true,
    Preview = Preview,
    Items = {
        {
            Id = "aurora",
            Name = "Aurora",
            Category = "Rifles",
            Subtitle = "Assault rifle",
            Thumbnail = 1234567890,
            PreviewImage = 1234567891,
            ImageTransparency = 0.05,
            ImageBackgroundTransparency = 0.35,
            ScaleType = "Fit",
            ImageSize = UDim2.fromScale(0.9, 0.9),
            ImageScale = 1.2,
            ImagePosition = UDim2.fromScale(0.5, 0.5),
        },
        {
            Id = "ember",
            Name = "Ember",
            Category = "Melee",
            Subtitle = "Knife",
            Image = "rbxassetid://9876543210",
        },
    },
    OnSelected = function(Item)
        if Item then
            SelectSkin(Item.Id)
        end
    end,
})
```

`Image`, `AssetId`, and primitive numeric IDs are normalized to `rbxassetid://`. Use `Thumbnail` or `ThumbnailId` for the light grid image and `PreviewImage` or `FullImage` for the larger selected view. When those fields are omitted, both views use `Image`. Complete `rbxassetid://`, `rbxasset://`, and executor-provided custom asset strings pass through unchanged. Each item can override `Color`, `ImageTransparency`, `ImageBackgroundTransparency`, `ScaleType`, `ImageSize`, `ImagePosition`, `ImageAnchorPoint`, `ImageScale` or `Zoom`, `TileSize`, `Rotation`, `RectOffset`, and `RectSize`. Set `ForwardItemStyle = true` only when those compatible overrides should also replace the bound `ImagePreview` style; otherwise the preview keeps its independent runtime settings.

Gallery methods are `SetItems`, `AddItem`, `RemoveItem`, `SetSearch`, `SetCategory`, `SetPage`, `NextPage`, `PreviousPage`, `SetColumns`, `SetCellHeight`, `SetScaleType`, `SetImageTransparency`, `SetImageBackgroundTransparency`, `SetBackgroundTransparency`, `SetCellTransparency`, `SetOutlineTransparency`, `SetContainerOutlineTransparency`, `SetImagePadding`, `SetLabelHeight`, `SetImageSize`, `SetImageScale`, `SetImagePosition`, `SetTileSize`, `SetRotation`, `SetCornerRadius`, `Select`, `GetSelected`, `BindPreview`, `SetVisible`, `SetHeight`, `Mount`, and `Destroy`. Clicking the category button cycles only categories present in the current item list.

Preview methods are `SetImage`, `SetTitle`, `SetSubtitle`, `SetImageColor`, `SetImageTransparency`, `SetScaleType`, `SetImageSize`, `SetImageScale`, `SetImagePosition`, `SetImagePadding`, `SetTileSize`, `SetRotation`, `SetBackgroundTransparency`, `SetCanvasTransparency`, `SetCaptionTransparency`, `SetOutlineTransparency`, `SetOutlineThickness`, `SetCornerRadius`, `SetShade`, `SetCaptionVisible`, `SetMotion`, `SetVisible`, `SetHeight`, `Mount`, and `Destroy`. Use `CreateEmbedded` for a groupbox or `Create(Library, { Parent = Frame, ... })` for a direct 2D panel.

Recommended layouts:

- Skin or weapon changer: `Columns = 5`, `PageSize = 15`, `CellHeight = 78`, `ScaleType = "Fit"`, with `ImagePreview` in the opposite column.
- Skybox, arena, or background selector: `Columns = 1`, `PageSize = 5`, `CellHeight = 58`, `ScaleType = "Crop"` for wide image rows.
- Compact icon picker: `Columns = 7`, `PageSize = 21`, `CellHeight = 58`, with the external preview omitted.

Keep the item list as plain data and load thumbnails rather than full-resolution promotional images in the grid. Reserve the larger image for `ImagePreview`. Roblox asset IDs must be accessible to the running client; executor custom assets should be converted with the executor's asset function before being passed to the addon.

### Real character Trail addon

`addons/CharacterTrail.lua` creates a native Roblox `Trail` on a real character. It is fully optional and is never loaded by `Library.lua`. A disabled controller creates no `Trail` or `Attachment` instances; enabling it creates one `Trail` and two attachments, follows character respawns, and uses no frame loop. The current `Example.lua` imports this addon explicitly and exposes every production setting.

```luau
local CharacterTrail = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/CharacterTrail.lua?monhub=0.0.1-release-6"
))()

local TrailController = CharacterTrail.Create({
    Enabled = false,
    Target = game:GetService("Players").LocalPlayer,
    ColorA = Color3.fromRGB(120, 166, 209),
    ColorB = Color3.fromRGB(203, 221, 239),
    TransparencyMin = 0.04,
    TransparencyMax = 0.18,
    WidthStart = 1,
    WidthEnd = 0,
    AttachmentWidth = 1.3,
    Lifetime = 0.34,
    Texture = "Beam",
    FaceCamera = true,
})

TrailController:SetEnabled(true)
TrailController:SetTransparency(0.04, 0.18)
TrailController:SetWidthScale(1, 0)
TrailController:SetTexture("Plasma")
```

Controller methods are `SetEnabled`, `SetTarget`, `SetColors`, `SetTransparency`, `SetWidthScale`, `SetAttachmentWidth`, `SetVerticalOffset`, `SetAttachmentPart`, `SetLifetime`, `SetMinLength`, `SetMaxLength`, `SetTexture`, `SetTextureMode`, `SetTextureLength`, `SetFaceCamera`, `SetLight`, `SetBrightness`, `ApplyPreset`, `Refresh`, `GetTrail`, `GetState`, and `Destroy`. Built-in style presets are `Soft`, `Energy`, `Plasma`, and `Minimal`; built-in texture presets are `None`, `Beam`, `Lightning`, `Heartrate`, `Chain`, `Glitch`, `Swirl`, `Neon`, `Plasma`, and `Laser`. A numeric asset ID or full `rbxassetid://` URL may be passed directly to `SetTexture`.

`addons/TracerPreview.lua` remains in the repository only as a legacy decorative image addon. It is not imported by the current showcase and should not be used when the intended result is an in-world trail.

### Trail texture gallery

`addons/TextureGallery.lua` is the optional texture-specific selector. It replaces square skybox cards with a wide selected preview and compact two-column trail cards. It has no search, category, pagination, or frame loop; the default ten-item list is created only when the addon is explicitly loaded. Every card shows its texture over a two-color track, so transparent trail assets and the texture-free `Clean` option remain visible.

```luau
local TextureGallery = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/TextureGallery.lua?monhub=0.0.1-release-6-image-ui-3"
))()
local TextureGroup = Tabs.Effects:AddLeftGroupbox("Trail textures", "gallery-horizontal")
local Gallery = TextureGallery.CreateEmbedded(Library, TextureGroup, "TrailTextures", {
    Height = 302,
    Columns = 2,
    ImageTransparency = 0.04,
    PreviewImageTransparency = 0.05,
    ImageScale = 1,
    CardTransparency = 0.04,
    PreviewTransparency = 0.04,
    OutlineTransparency = 0.42,
    ScaleType = "Stretch",
    Items = TextureGallery.DefaultItems,
    Selected = "beam",
    OnSelected = function(Item)
        TrailController:SetTexture(Item.Texture)
        TrailController:SetColors(Item.ColorA, Item.ColorB)
    end,
})
```

The intentionally small API is `SetItems`, `Select`, `GetSelected`, `SetColumns`, `SetImageTransparency`, `SetPreviewImageTransparency`, `SetCardTransparency`, `SetPreviewTransparency`, `SetOutlineTransparency`, `SetScaleType`, `SetImageScale`, `SetVisible`, `Mount`, and `Destroy`. Item fields are `Id`, `Name`, `Texture`, `ColorA`, `ColorB`, `ImageTransparency`, `PreviewImageTransparency`, `ImageScale`, `PreviewImageScale`, and `ScaleType`. Numeric IDs and complete Roblox asset strings are accepted.

### Separate dashboard window

`addons/DashboardWindow.lua` creates an independent theme-aware window for compact runtime information and script actions. Its top bar, section headers, outlines, typography, accent lines, spacing, and fast visibility transition follow the main MonHub interface. It is optional and creates nothing until `Create` is called. Static text starts no scheduler. All function-backed text and metrics share one update task, which starts with the first provider, pauses while the dashboard is hidden, and ends when the final dynamic widget is removed.

```luau
local DashboardWindow = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/DashboardWindow.lua?monhub=0.0.1-release-6-dashboard-ui-2"
))()

local Dashboard = DashboardWindow.Create(Library, {
    Title = "Script dashboard",
    Icon = "layout-dashboard",
    Width = 304,
    Height = 320,
    Position = "Right",
    Draggable = true,
})

local Runtime = Dashboard:AddSection({ Title = "Runtime", Icon = "activity" })
Runtime:Add("Connected and ready.")
Runtime:Add(function()
    local Character = game:GetService("Players").LocalPlayer.Character
    return Character and "Character: " .. Character.Name or "Character: waiting"
end)
Runtime:Add({
    Type = "Metric",
    Label = "Place ID",
    Value = function()
        return game.PlaceId
    end,
    Interval = 1,
})
Runtime:Add({
    Type = "Button",
    Text = "Refresh data",
    Callback = function()
        Dashboard:Refresh()
    end,
})

local CustomFrame = Instance.new("Frame")
CustomFrame.BorderSizePixel = 0
Runtime:Add({
    Type = "Custom",
    Instance = CustomFrame,
    Height = 40,
})
```

The generic `Section:Add` method accepts a string, a provider function, or a table with `Type = "Text"`, `"Metric"`, `"Button"`, or `"Custom"`. `AddSection` accepts either a title string or `{ Title, Icon, Order, ShowTitle }`. Explicit methods are `AddText`, `AddMetric`, `AddButton`, and `AddCustom`. Dashboard-level calls use a lazily created `Overview` section. Dashboard methods are `AddSection`, `Add`, `AddText`, `AddMetric`, `AddButton`, `AddCustom`, `SetTitle`, `SetVisible`, `Toggle`, `SetDraggable`, `SetPosition`, `SetSize`, `Refresh`, and `Destroy`. Every section and widget also supports `SetVisible` and `Destroy`; dynamic text and metric widgets expose `SetProvider`.

Closing the dashboard only hides it, so it can be reopened through `Dashboard:Toggle()` without rebuilding its contents. The complete production showcase in `Example.lua` loads this addon directly.

## Declarative API

For an interface described by data rather than sequential calls, use `Library:Create`:

```luau
local App = Library:Create({
    Title = "MonHub",
    Footer = "MonHub v0.0.1",
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

The library coalesces viewport fitting, search, dependency updates, and motion. It uses keyed short tweens for hover, keybind menus, notifications, dialogs, tab content, and the compact launcher; it adds no perpetual glow or render-loop effect. Window opening and closing use 90ms and 60ms opacity-only transitions, with no scale or font resizing. Tabs use a 75ms entry and a 45ms exit fade with a 2px maximum offset. Keybind overlays use a 70ms fade, keybind rows use 75ms, and standard controls use 110ms state transitions. Gotham Regular remains the zero-download fallback; the complete showcase installs the packaged Inter Bold font. The real character Trail uses native Roblox rendering and character events rather than `RenderStepped`. Avoid `RenderStepped` or `while task.wait()` loops for UI-only changes when an `OnChanged` callback, a dependency box, or a setter is enough.

```luau
Window:SetAnimations({
    ToggleWindow = true,
    TabSwitch = true,
    Groupbox = true,
    Dropdown = true,
    KeyPicker = true,
}, 0.075, 2, "bottom")

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

First confirm that GitHub Desktop pushed the repository and branch used by the raw URL. Then check the loader URL itself. Some executors and intermediary caches retain a previous response for an unchanged raw URL even when `main` points at a newer commit. Every current loader therefore appends `?monhub=0.0.1-release-6` to `Library.lua` and every addon. Increase this release value whenever publishing a new build, and use the same value for Library, ThemeManager, SaveManager, VisualPreview, and the project script. For a local test, use `loadstring(readfile("Library.lua"))()` so no HTTP cache is involved.

Do not mix an updated ThemeManager with an older Library. If a selector shows a new preset but most surfaces keep an earlier palette, the two modules came from different cached revisions. A versioned URL prevents that mixed state.

The current build reports `Library.ReleaseVersion == "0.0.1-release-6"`. Project loaders compare this value before creating the window and emit a non-blocking warning when an executor returns an older cached build. A patch-level mismatch never prevents the interface from starting.

The current Library also unloads an older MonHub instance before creating its ScreenGui. This prevents a previous window from remaining underneath or above the new release during repeated executor runs. A full rejoin is no longer required for normal UI updates, although game-specific script state may still require its own cleanup.

### `Expected ident` on line 1

The loader received HTML or another non-Luau response. Use a raw GitHub URL, not a browser `blob` URL, and verify the URL in a browser before executing it.

### The UI starts with an old or mixed theme

Use `Library.lua`, `ThemeManager.lua`, and `SaveManager.lua` from the same commit, then call `SaveManager:IgnoreThemeSettings()` while migrating old configs. Raw legacy palette fields, including old or partial semantic surface fields, are ignored, while a valid `ThemeManager_ThemeList` value restores any of the six built-in palettes. The current theme engine repaints registered instances and stateful controls together. It also rebinds the window, top bar, title zone, sidebar, content area, and footer directly on every theme transaction, so a missing or externally changed registry entry cannot leave the header on the previous palette. Old custom-theme files remain on disk but are not executed or applied.

### A config does not load

Create all tabs and controls before `LoadAutoloadConfig()`. Call `SaveManager:IgnoreThemeSettings()` when reusing configs created by older builds. Inspect the returned error from `SaveManager:Load(name)` or `LoadJSON(content)` instead of assuming a failed parser succeeded.

### The watermark is on the right

New sessions start on the left. A saved config may deliberately restore a previous `WatermarkSide = "Right"` choice. Select Left in UI Settings or call `Library:SetWatermarkSide("Left")`.

### The window touches or crosses a viewport edge

The current window fitter clamps both size and position after Roblox publishes the first real `AbsoluteSize`, then repeats the clamp after every viewport resize. Keep `Responsive = true`, avoid externally forcing the root frame position, and let the library complete one heartbeat before measuring custom content. Embedded custom frames should use scale or the available column width rather than a fixed width larger than their groupbox.

### The preview rotates but no character is visible

Pass a real `Player` or `Model` as `Target`, create it after the target character exists, and keep the preview addon from the same revision as Library. The generic preview needs no `Renderer`; only use one when your project provides it.

## Migration from Obsidian

This section focuses on moving an existing Obsidian project to MonHub without rewriting its application logic.

MonHub keeps the legacy API: `CreateWindow`, `AddTab`, groupboxes, controls, `SaveManager`, `Library.Options`, and `Library.Toggles` continue to work. `ThemeManager` now provides a minimal built-in preset selector.

The release baseline is a neutral-gray `Default` theme with violet `Metal` and near-black `Midnight` presets, Gotham Regular fallback typography, packaged Inter Bold support, responsive sidebar behavior, compact checkmark toggles, short motion, a draggable clamped watermark, R6 ESP preview support, a native character Trail addon, optimized search, and a declarative API.

### Useful links

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
- [ImageGallery.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/addons/ImageGallery.lua)
- [ImagePreview.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/addons/ImagePreview.lua)
- [CharacterTrail.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/addons/CharacterTrail.lua)
- [TextureGallery.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/addons/TextureGallery.lua)
- [FixedR6Preview.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/addons/FixedR6Preview.lua)
- [DashboardWindow.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/addons/DashboardWindow.lua)
- [Inter-Bold.ttf](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/assets/Inter-Bold.ttf)
- [Legacy TracerPreview.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/addons/TracerPreview.lua)
- [Current type declarations](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/Library.d.luau)
- [Changelog](#changelog)
- [Original Obsidian](https://github.com/deividcomsono/Obsidian)
- [Legacy API reference](https://docs.mspaint.cc/obsidian)
- [Lucide icon catalogue](https://lucide.dev/icons/)
- [MIT license](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/LICENSE)

### Short migration route

For most projects, complete these steps in order:

1. Back up the working script and configuration folder.
2. Replace the upstream `Library.lua` URL with the MonHub raw URL.
3. Keep existing control IDs unchanged.
4. Update `SaveManager.lua`; add `ThemeManager.lua` when the settings page should expose the six built-in presets.
5. Run a smoke test for callbacks, configs, keybinds, mobile layout, and unload.

### Step 1: replace the loader

An upstream loader usually looks like this:

```luau
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"
))()
```

Replace it with MonHub:

```luau
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua?monhub=0.0.1-release-6-image-ui-3"
))()
if Library.ReleaseVersion ~= "0.0.1-release-6" then
    warn(string.format("MonHub version notice: expected %s, received %s", "0.0.1-release-6", tostring(Library.ReleaseVersion)))
end
```

Use `raw.githubusercontent.com`, not a `github.com/.../blob/...` URL. A blob page returns HTML, which causes Luau to report `Expected ident` on line 1.

### Step 2: keep the legacy API

Do not move to the declarative API during the first migration. Existing code can stay almost unchanged:

```luau
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua?monhub=0.0.1-release-6-image-ui-3"
))()
if Library.ReleaseVersion ~= "0.0.1-release-6" then
    warn(string.format("MonHub version notice: expected %s, received %s", "0.0.1-release-6", tostring(Library.ReleaseVersion)))
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

### API compatibility

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

### Window settings

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

### Tabs and groupboxes

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

### Moving controls

#### Toggle and Checkbox

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

#### Input

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

#### Slider

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

#### Dropdown

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

#### Button, Label, and Divider

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

This button migration is required for maintained code. Replace every legacy semantic button variant explicitly rather than relying on the compatibility fallback. Warning and danger toggle variants remain supported because their visual state stays visible after the click.

Toggles also accept `Variant = "Warning"` or `Variant = "Danger"`. In the enabled state only the track and outline become semantic, so key-picker rows do not shift. Enabling a danger toggle opens a short `Cancel` / `Continue` dialog. Turning it off is immediate. Set `ConfirmDanger = false` to disable confirmation, or set `ConfirmTitle` and `ConfirmDescription` for custom dialog copy.

The title-bar minimize button collapses the UI to a centered draggable launcher with the script title. When the menu is hidden by keybind, the launcher does not appear; use the same bind to restore the menu. Configure this through `ShowCompactLauncher`, `CompactLauncherIcon`, `CompactLauncherSize`, `CompactLauncherWidth`, `CompactLauncherTitle`, `CompactLauncherPosition`, and `CompactLauncherDraggable` in `CreateWindow`.

### ColorPicker and KeyPicker addons

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

### Reading values

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

### Theme presets and font policy

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

Inter Bold is now loaded automatically before the first window is created and becomes the shared font for the core UI and every theme-aware addon:

```luau
local ActiveFont = Library.DefaultFont
local FontError = Library.DefaultFontError
```

The TTF is validated and cached in `MonHub/assets`. The font override remains active through theme changes. Executors without the required filesystem or custom-asset APIs receive Gotham automatically, so no project-side font loader is required.

### Watermark, FPS, and ping

Basic API:

```luau
Library:SetWatermark("My Hub  |  Ready")
Library:SetWatermarkVisibility(true)
Library:SetWatermarkSide("Left")
Library:SetWatermarkDraggable(true)
```

The watermark starts in the top-left. It can be dragged with mouse or touch, or snapped through `SetWatermarkSide("Left")` and `SetWatermarkSide("Right")`. It remains within the viewport after dragging, text changes, and screen-size changes.

[Example.lua](https://github.com/SoftRatatui/Obsidian-main/blob/main/Obsidian-main/Example.lua) includes ready-to-use Watermark, Show FPS, and Show Ping settings. It updates text every 0.5 seconds, counts FPS with a lightweight `RenderStepped` counter, and reads `Data Ping` safely through `Stats`.

### Interactive R6 viewport

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

### ESP preview addon

`addons/VisualPreview.lua` clones a real character from `Target` without changing the source. It supports a fixed panel beside the window, a direct `GuiObject` parent, and a MonHub groupbox. `addons/DrawingESPPreview.lua` provides a shared Drawing backend so live players and the preview use the same entity update path.

Load the addon from the same commit as `Library.lua`:

```luau
local VisualPreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/VisualPreview.lua?monhub=0.0.1-release-6"
))()
local DrawingESPPreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/DrawingESPPreview.lua?monhub=0.0.1-release-6"
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

### Real character Trail addon

Replace decorative `TracerPreview` usage with `addons/CharacterTrail.lua` when the effect must exist on the real player. The addon creates a native Roblox `Trail`, follows respawns, and creates no Trail or Attachment instances while disabled.

```luau
local CharacterTrail = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/CharacterTrail.lua?monhub=0.0.1-release-6"
))()

local TrailController = CharacterTrail.Create({
    Enabled = false,
    Target = game:GetService("Players").LocalPlayer,
    ColorA = Color3.fromRGB(120, 166, 209),
    ColorB = Color3.fromRGB(203, 221, 239),
    TransparencyMin = 0.04,
    TransparencyMax = 0.18,
    WidthStart = 1,
    WidthEnd = 0,
    AttachmentWidth = 1.3,
    Lifetime = 0.34,
    Texture = "Beam",
    FaceCamera = true,
})

TrailController:SetEnabled(true)

Library:OnUnload(function()
    TrailController:Destroy()
end)
```

Use `SetColors`, `SetTransparency`, `SetWidthScale`, `SetAttachmentWidth`, `SetVerticalOffset`, `SetAttachmentPart`, `SetLifetime`, `SetMinLength`, `SetMaxLength`, `SetTexture`, `SetTextureMode`, `SetTextureLength`, `SetFaceCamera`, `SetLight`, and `SetBrightness` for direct settings. `ApplyPreset("Soft" | "Energy" | "Plasma" | "Minimal")` changes a complete visual profile. Texture names include `None`, `Beam`, `Lightning`, `Heartrate`, `Chain`, `Glitch`, `Swirl`, `Neon`, `Plasma`, and `Laser`; numeric asset IDs and `rbxassetid://` strings are also accepted.

The old `TracerPreview.lua` remains available only for compatibility with scripts that intentionally need a decorative menu image. It is not used by the current `Example.lua` and must not be treated as an in-world effect.

### Focused visual and dashboard addons

These modules remain standalone and are loaded only by projects that need them:

```luau
local TextureGallery = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/TextureGallery.lua?monhub=0.0.1-release-6-image-ui-3"
))()
local DashboardWindow = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/DashboardWindow.lua?monhub=0.0.1-release-6-dashboard-ui-2"
))()
local VisualPreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/VisualPreview.lua?monhub=0.0.1-release-6"
))()
local DrawingESPPreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/DrawingESPPreview.lua?monhub=0.0.1-release-6"
))()
local FixedR6Preview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/FixedR6Preview.lua?monhub=0.0.1-release-6"
))()
```

Use `DashboardWindow` for information or actions that must remain independent from the main tab layout. Its compact top bar, section cards, metric spacing, outline colors, font, and visibility transition are synchronized with the main interface. A string creates static text, a function creates automatically refreshed text, `Type = "Metric"` creates a named dynamic value, `Type = "Button"` runs a callback, and `Type = "Custom"` mounts a supplied `GuiObject`. The addon uses one scheduler for all providers and stops it while hidden.

```luau
local Dashboard = DashboardWindow.Create(Library, {
    Title = "Runtime",
    Position = "Right",
    Draggable = true,
})

local Status = Dashboard:AddSection("Status")
Status:Add("Loaded")
Status:Add({
    Type = "Metric",
    Label = "Player",
    Value = function()
        return game:GetService("Players").LocalPlayer.DisplayName
    end,
})
Status:Add({
    Type = "Button",
    Text = "Refresh",
    Callback = function()
        Dashboard:Refresh()
    end,
})
```

The texture selector is intentionally smaller than the general image gallery. It creates no search box, category control, pagination state, or frame loop:

```luau
local TextureGroup = Tabs.Effects:AddLeftGroupbox("Trail textures", "gallery-horizontal")

local Gallery = TextureGallery.CreateEmbedded(Library, TextureGroup, "TrailTextures", {
    Height = 302,
    Columns = 2,
    Items = TextureGallery.DefaultItems,
    Selected = "beam",
    OnSelected = function(Item)
        TrailController:SetTexture(Item.Texture)
        TrailController:SetColors(Item.ColorA, Item.ColorB)
    end,
})
```

The fixed preview creates an actual R6 from the current player's applied appearance. Its built-in renderer is suitable for UI testing; pass the renderer adapter used by the real ESP through `Renderer` when the preview must follow the exact production drawing path.

```luau
local Preview = FixedR6Preview.Create(Library, VisualPreview, DrawingESPPreview, Tabs.Visuals, {
    Target = game:GetService("Players").LocalPlayer,
    Renderer = LiveESPRenderer,
    Side = "Right",
    Alignment = "Center",
    Box = true,
    Health = true,
    Gradient = true,
    DynamicBoxes = true,
})
```

Image-heavy selectors are separate opt-in addons and are never loaded by the core library. The complete `Example.lua` imports them explicitly as a showcase:

```luau
local ImageGallery = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/ImageGallery.lua?monhub=0.0.1-release-6-image-ui-3"
))()
local ImagePreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/ImagePreview.lua?monhub=0.0.1-release-6-image-ui-3"
))()

local Look = ImagePreview.CreateEmbedded(Library, PreviewGroup, "SkinLook", {
    Height = 280,
    ImagePadding = 12,
    ImageScale = 1,
    CanvasTransparency = 0.18,
    CaptionTransparency = 0.08,
    OutlineTransparency = 0.48,
    Motion = true,
})

local Gallery = ImageGallery.CreateEmbedded(Library, SkinGroup, "SkinGrid", {
    Height = 344,
    Columns = 5,
    PageSize = 15,
    CellTransparency = 0.06,
    OutlineTransparency = 0.48,
    ImageBackgroundTransparency = 0.22,
    ImagePadding = 5,
    ImageScale = 1,
    Preview = Look,
    Items = SkinDefinitions,
    OnSelected = function(Item)
        ApplySkin(Item.Id)
    end,
})
```

The gallery creates only `PageSize` reusable cards, assigns images only for the active filtered page, and debounces search. The preview recycles two image layers for crossfade and zoom. Neither addon has a frame loop. Card, image-area, asset, caption, container, and outline transparency are independent. Global image layout can be overridden per item with size, position, anchor, zoom, scale type, tile size, rotation, and sprite rectangle fields. See the current image-addon section in `GUIDE.md` for the complete method list and item schema.

### Image, Video, and UIPassthrough

```luau
local MediaGroup = Tabs.Visuals:AddRightGroupbox("Media", "image")

MediaGroup:AddImage("PreviewImage", {
    Image = "sparkles",
    Color = Color3.fromRGB(184, 189, 201),
    Transparency = 0,
    BackgroundTransparency = 0.12,
    OutlineTransparency = 0.48,
    Padding = 10,
    CornerRadius = 5,
    ImageSize = UDim2.fromScale(1, 1),
    ImagePosition = UDim2.fromScale(0.5, 0.5),
    ImageScale = 1,
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

`AddImage` exposes independent setters for the asset, panel, outline, padding, corner radius, size, position, tile size, rotation, aspect ratio, height, and visibility. `AddUIPassthrough` accepts an existing `GuiBase2d` and places it inside a groupbox.

### ThemeManager presets

Load `ThemeManager.lua` when the UI Settings page should expose the six built-in presets:

```luau
local ThemeManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/ThemeManager.lua?monhub=0.0.1-release-6"
))()

ThemeManager:SetLibrary(Library)
ThemeManager:ApplyToTab(Tabs["UI Settings"])
```

The addon creates a minimal `Default` / `Metal` / `Midnight` / `Steel` / `Sage` / `Ash` dropdown with the ID `ThemeManager_ThemeList`. SaveManager persists that selection. It does not expose raw palette editing or load custom theme files.

### SaveManager

```luau
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/SaveManager.lua?monhub=0.0.1-release-6"
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

### UI Settings layout

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

### Mobile and desktop

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

### Motion and performance

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

### Notifications

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
})
```

### Dependency controls

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

### Unload and cleanup

```luau
Library:OnUnload(function()
    print("Interface unloaded")
end)

Library:Unload()
```

MonHub disconnects registered signals, destroys UI and draggable elements, cancels active animations, and clears options and cached measurements. Register external connections through `Library:GiveSignal`, or disconnect them in `OnUnload`.

### Declarative API

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

### Wally or Studio installation

The repository `wally.toml` still contains upstream package metadata. Installing `deividcomsono/obsidian` from the public Wally registry can return original Obsidian rather than this MonHub build.

Use one of these options for exact MonHub behavior:

1. A raw loader in an executor environment.
2. A vendor copy of current `Library.lua`, `Library.d.luau`, and `addons` in your project.
3. A private Wally package or Git submodule pinned to a MonHub repository commit.

Do not mix MonHub `Library.lua` with addons from a different version.

### Troubleshooting

#### `Expected ident` on line 1

Cause: the loader received HTML, an error page, or a private-repository page.

Check that:

- The URL is a raw URL.
- The repository and branch are accessible.
- The path includes `Obsidian-main/Library.lua`.
- The GitHub response is not empty.
- The executor supports `game:HttpGet` and `loadstring`.

#### The UI looks like old Obsidian

Cause: the project is loading an upstream URL, upstream Wally package, or an old cached file.

Fix: verify the URL and restart the session.

#### Font Face becomes Code

Use the current `Library.lua` and remove any old ThemeManager UI that creates a font selector. The release themes use Gotham Regular until a project explicitly installs the packaged Inter Bold font. Legacy raw appearance fields must be included in `SaveManager:IgnoreThemeSettings()` during config migration.

#### A configuration does not load

Check that:

- All controls exist before `LoadAutoloadConfig`.
- IDs were preserved.
- `SetFolder` and `SetSubFolder` match the old project.
- The executor supports file APIs.

#### Watermark shows `0 ms`

`Stats.Network.ServerStatsItem["Data Ping"]` can be unavailable immediately after joining. Wait for the next update interval.

#### The UI leaves the screen

Use a responsive size and call:

```luau
Window:FitToViewport()
```

The current fitter reclamps after Roblox publishes the updated `AbsoluteSize` and after every viewport resize. If a custom embedded element still overflows, remove its fixed width and size it from the groupbox's available width.

#### The viewport rotates but the model is invisible

Check `Object`, `Clone`, `PrimaryPart`, bounding box, and `AutoFocus`. For a `Model`, set a `PrimaryPart` when possible.

### Final checklist

- [ ] The raw URL points to MonHub.
- [ ] Library and addons come from one version.
- [ ] `Library.ReleaseVersion` reports `0.0.1-release-6`; a mismatch is informational and never blocks startup.
- [ ] Existing control IDs are preserved.
- [ ] Default applies as the neutral-gray startup theme.
- [ ] Metal applies as the violet alternate theme.
- [ ] Gotham Regular is not replaced by Code, or packaged Inter Bold loads successfully before window creation.
- [ ] The window fits the desktop viewport.
- [ ] Sidebar compact works on mobile.
- [ ] Toggle and checkbox callbacks work.
- [ ] Slider works with mouse and touch.
- [ ] Dropdown single and multi values persist.
- [ ] KeyPicker and ColorPicker work.
- [ ] Maintained buttons use only `Default`, `Primary`, or `Ghost` variants.
- [ ] Old appearance fields are ignored when configurations load.
- [ ] `ThemeManager_ThemeList` saves and restores the selected built-in theme.
- [ ] Old configurations load, or are deliberately moved to a new folder.
- [ ] Watermark, FPS, and ping controls work.
- [ ] Search has no visible delay.
- [ ] Unload cleans up UI and external connections.
- [ ] `CharacterTrail:Destroy()` runs on unload when the addon is enabled.
- [ ] A separate dashboard closes, reopens, clamps to the viewport, and is destroyed on unload.
- [ ] The texture gallery and fixed R6 preview are loaded only on pages that use them.
- [ ] The script is tested on desktop and mobile.

### Recommended real migration order

1. Replace the loader and open a window without addons.
2. Test tabs and controls.
3. Test `Library.Options` and `Library.Toggles`.
4. Add SaveManager without autoload and call `IgnoreThemeSettings()` for old configurations.
5. Create and load a test configuration.
6. Enable autoload.
7. Add Watermark.
8. Test desktop, mobile, DPI, and resizing.
9. Add optional `CharacterTrail`, texture, image, or preview addons one at a time and verify cleanup.
10. Move to the declarative API only after all previous steps pass.

This order localizes errors and makes each stage easy to roll back.

## Release checklist

- [ ] `Library.lua`, `ThemeManager.lua`, `SaveManager.lua`, and optional addons come from one commit.
- [ ] `Library.ReleaseVersion` reports `0.0.1-release-6`; a cache mismatch warns but never blocks startup.
- [ ] Local changes are tested with a local loader before publishing.
- [ ] All user-facing labels and notifications are English.
- [ ] The window is readable at desktop and narrow/mobile widths.
- [ ] Maintained scripts use only `Default`, `Primary`, or `Ghost` button variants.
- [ ] Every danger control has a clear confirmation or an intentional opt-out.
- [ ] Old appearance keys are ignored while legacy configs are migrated.
- [ ] All six built-ins repaint the top bar, footer, overlays, controls, and active states without stale colors.
- [ ] `ThemeManager_ThemeList` saves and restores with configurations.
- [ ] Watermark, keybind menu, compact launcher, and unload are tested.
- [ ] `CharacterTrail:Destroy()` is called during project unload when the addon is used.
- [ ] `Dashboard:Destroy()` is called automatically by library unload or explicitly by project cleanup.
- [ ] A fixed R6 preview receives the live renderer adapter when it must match production ESP exactly.
- [ ] `assets/Inter-Bold.ttf` is published with the same release when the custom font is enabled.
- [ ] This `GUIDE.md` is updated for every public API or behavior change.

For the complete showcase, see [Example.lua](Example.lua). For exact production type signatures, see [Library.d.luau](Library.d.luau). The project is distributed under the terms in [LICENSE](LICENSE).

## Changelog

### 26.08.2026

[removed]
- Removed automatic button audio, its shared runtime object, public methods, dashboard hooks, examples, and type declarations.
- Removed redundant documentation files after consolidating their maintained content into `GUIDE.md`.

[documentation]
- Made `GUIDE.md` the single English documentation source for installation, the complete API, addons, migration, troubleshooting, release checks, and project history.

### 25.08.2026

```diff
[image system]
+ Expanded core AddImage with independent asset, background, and outline transparency plus color, padding, corner, transform, zoom, tiling, rotation, and aspect-ratio controls
+ Rebuilt ImageGallery cards with a separate clipped image viewport and global or per-item size, position, anchor, zoom, scale, tile, rotation, sprite, tint, and transparency settings
+ Expanded ImagePreview with canvas, caption, container, outline, shade, padding, position, size, tile, rotation, and caption-visibility controls
+ Added matching transparency and scale controls to TextureGallery

[showcase]
+ Added interactive image styling controls to Example.lua and documented the complete current API and item schema

[performance]
+ Preserved the fixed gallery cell pool, recycled two-layer preview transition, lazy asset assignment, and zero frame-loop design
```

### 24.08.2026

```diff
[character trail]
+ Added the optional native CharacterTrail addon with two-color gradients, start/end transparency, width curves, texture presets, attachment placement, lighting, and character respawn support
+ Kept the disabled controller allocation-free and used native Roblox rendering without a frame loop
+ Replaced the decorative tracer section in Example.lua with complete controls for the real character Trail

[stability]
+ Repainted keybind state rows synchronously after every theme transaction so a finishing hover tween cannot restore stale palette colors
+ Reclamped window size and position after the first absolute-layout update and every viewport resize to prevent first-frame edge overflow

[typography]
+ Installed assets/Inter-Bold.ttf automatically from Library.lua as the global core and addon font with a cached Gotham fallback
+ Resolved custom font weights from 100 through 900 instead of always requesting Regular from the generated family

[visual addons]
+ Added the optional TextureGallery addon with a wide selected preview, compact trail cards, ten built-in textures, and direct CharacterTrail binding
+ Added the optional FixedR6Preview addon that creates an actual R6 from the current player appearance and accepts the live ESP renderer adapter
+ Added the optional DashboardWindow addon with sections, static and function-backed text, metrics, callbacks, custom GuiObject mounting, dragging, clamping, and complete theme registration
+ Refined DashboardWindow into a compact main-UI style with a themed top bar, groupbox headers, thinner spacing, native close icon, soft shadow, and fast visibility transition

[performance]
+ Kept TextureGallery and FixedR6Preview opt-in; TextureGallery has no frame loop, search worker, or pagination state, while FixedR6Preview reuses the existing preview scheduler and adds only an appearance-change connection
+ Used one lazy scheduler for every dashboard provider and stopped it automatically while the separate window is hidden or has no dynamic widgets

[maintenance]
+ Removed the temporary alternate loader, duplicate library build, and alternate showcase so Library.lua is the only maintained core
+ Standardized repository documentation in English and repaired the Wally/Studio section link
+ Verified that executable source and documented code examples contain no comments or authoring metadata
+ Updated GUIDE.md, MIGRATION_GUIDE.md, README.md, Example.lua, and release URLs for 0.0.1-release-6
```

### 23.08.2026

```diff
[visual modules]
+ Added embedded, direct-parent, and fixed-panel mounting modes to the real-character VisualPreview addon
+ Added a renderer adapter contract so the same live ESP backend can render the preview clone without a separate fake overlay
+ Added DrawingESPPreview with one reusable entity path for boxes, two-tone edges, names, distance, weapons, and health bars
+ Added opt-in ImageGallery with pooled pagination, category cycling, debounced search, selection binding, and asset-ID normalization
+ Added opt-in ImagePreview with full-size images, recycled crossfade layers, short zoom motion, direct mounting, and groupbox embedding
+ Restored TracerPreview as an independent opt-in addon that is never loaded by the core library
+ Expanded Example.lua into a complete interactive showcase for every addon and its primary runtime setters
+ Removed tracer rendering from the main ESP preview while retaining a harmless compatibility setter for older integrations
+ Replaced synthetic gallery entries with real skybox image assets and added nine tracer texture presets to the addon showcase
+ Removed the separate sidebar selection strip in favor of the existing soft selected-tab surface, label, and icon state

[performance]
+ Kept the Drawing backend allocation-stable by creating objects once per entity and mutating them in place
+ Limited image gallery allocation to one reusable page and kept both image addons free of frame loops
+ Preserved the built-in GUI fallback when Drawing is unavailable
+ Added explicit tween cancellation, connection cleanup, and registry removal for manually destroyed visual addons
+ Removed two decorative instances from every sidebar tab

[documentation]
+ Updated GUIDE.md, MIGRATION_GUIDE.md, and README.md with the shared live renderer contract, optional gallery, and animated 2D preview
```

### 22.08.2026

```diff
[theme engine]
+ Replaced three overloaded palette colors with semantic Background, Surface, Raised, Element, Hover, AccentSoft, MutedFont, and Shadow layers
+ Theme changes now repaint the registry and refresh every stateful control in one transaction, including active toggles, buttons, sliders, and the compact launcher
+ Updated ThemeManager, SaveManager migration filters, VisualPreview, and type declarations for complete palette coverage
+ Isolated every registered property during repaint and added a final state pass so one invalid dynamic property cannot block the rest of an element
+ Increased surface separation in Metal, Midnight, and Ash while keeping their accents muted
+ Added validated cached Inter Medium loading with a persistent theme-font override and GothamMedium fallback
+ Added a shared release query to every remote loader so executor and raw-CDN caches cannot mix Library and addon revisions after a push
+ Automatically unloads the previous MonHub ScreenGui before a repeated run so an old interface cannot cover the new release
+ Added a dedicated core-surface binding pass for the window, header, title zone, sidebar, content, and footer so the top bar cannot retain a previous theme color

[soft visual pass]
+ Rebalanced Default into a calmer layered gray palette and refined Metal and Midnight without increasing global corner radius
+ Unified the top bar, title zone, search area, and header controls on one registered top-bar surface so every theme repaints the full header
+ Added raised overlays, distinct card surfaces, softer selected-tab hover states, and two-tone slider fills
+ Increased standard control breathing room while preserving the compact 16x16 checkmark and fast interaction timings
+ Reduced tab crossfade to 75ms in, 45ms out, and 2px of travel for a faster, calmer transition

[release]
+ Finalized six restrained built-in themes: neutral-gray Default, desaturated-violet Metal, near-black Midnight, cool Steel, green-gray Sage, and warm-neutral Ash
+ Removed warning and danger button styling and automatic semantic button icons; legacy values now resolve to the neutral default style
+ Added a minimal ThemeManager preset dropdown whose ThemeManager_ThemeList value persists with SaveManager configurations
+ Kept raw legacy palette fields and custom theme files isolated so they cannot leave the interface in a mixed visual state
+ Standardized the release typography on readable Gotham Regular
+ Updated GUIDE.md, MIGRATION_GUIDE.md, README.md, Example.lua, and type declarations for the six-theme release contract

[design]
+ Reduced visual noise with one subtle outline per surface instead of paired outline and shadow strokes
+ Added inset full-width sidebar tabs so indicators no longer sit against the frame edge
+ Refined tabbox selection into a soft accent surface with short color/transparency transitions
+ Normalized content insets and group spacing for a calmer, less crowded layout
+ Changed the default AddToggle presentation to a compact, fully filled 16x16 square checkmark without a corner mask
+ Kept the legacy sliding switch available through Library.ForceCheckbox = false
+ Rebuilt keybind rows around a fixed horizontal layout with a 14x14 checkmark and deterministic alignment
+ Replaced fractional checkmark scaling with fixed-size antialiased glyphs and opacity-only motion for cleaner small-pixel rendering
+ Removed two UICorner instances per checkbox/keybind pair so the four corner pixels stay filled and the render tree is smaller
+ Changed release checks from fatal errors to non-blocking notices so a cached patch revision cannot prevent startup

[motion]
+ Window opening now uses a 90ms opacity-only transition and closing uses 60ms, without scaling or font resizing
+ Tab entry now uses a 75ms fade/2px offset and exit uses a 45ms fade
+ Standard control state transitions now use a responsive 110ms timing
+ Keybind overlays use a 70ms fade and 75ms row transitions without fractional UIScale animation

[performance]
+ Removed one UIStroke from every standard outlined surface
+ Removed unused raw theme editor controls, palette file work, and repeated palette restoration paths
+ Replaced direct optional executor-global reads with cached environment lookups to avoid strict Luau unknown-global errors
```

### 19.08.2026

```diff
[design]
+ Azure is now the default visual system: deep blue-slate layers, a restrained cool-blue accent, and high-contrast soft-white typography
+ Added a solid theme-aware top-bar surface and refined accent dividers for a more composed premium layout
+ Graphite remains available as an optional neutral preset

[motion]
+ Tuned window opening, closing, tab, dropdown, key picker, keybind, notification, and groupbox timings for smoother 60 FPS transitions
+ Window closing now combines a short fade with a restrained scale settle instead of an abrupt transparency-only exit
+ Tab motion uses a smaller 8px offset for a cleaner, less distracting page transition

[features]
+ Added addons/VisualPreview.lua with a local white R6 3D preview and configurable box, name, distance, health, tracer, highlight, and color overlays
+ Viewport controls now expose their Box and Frame for safe module-level overlays

[performance]
+ Full executor profile keeps advanced UI features enabled while reusing the existing tween deduplication and coalesced resize pipeline

[changes]
- Removed the public capability and LowSpec profile API from this full-featured build
```

### 18.08.2026

```diff
[design]
+ Graphite V2 default theme with lighter neutral layers, a restrained steel-gray accent, and compact 4px geometry
+ Restrained cool-gray surfaces for tabs, groupboxes, window chrome, controls, and focused search
+ BlackPurple remains available as an optional preset
+ Smooth animations are enabled by default and toggle transitions now animate color and position
+ Refined the default radius from 9px to 4px for a cleaner, less rounded visual system
+ Checkboxes now use a compact square shape with a clear accent-filled selected state
+ Narrower sidebar proportions and denser navigation improve usable content space

[features]
+ Library:Create / Library:Mount declarative UI API
+ App:Get, App:Toggle, App:Notify, and App:Destroy lifecycle helpers
+ Graphite, BlackPurple, and Classic built-in theme presets with Library:SetTheme
+ Library.ImageManager.PreloadAssets for optional background asset downloads
+ Draggable Watermark with FPS and ping settings in Example.lua
+ Interactive R6 viewport showcase with mouse, wheel, touch, and pinch controls
+ Editable TopBarColor theme field with automatic fallback for older themes
+ Responsive content columns that switch to a readable vertical layout on narrow windows and touch devices
+ Keybind panel filters out unassigned and invalid binds, hides when empty, and animates rows and visibility
+ Central motion controller deduplicates tab, groupbox, slider, dropdown, search, and button transitions
+ Runtime capability reporting with Library:GetCapabilities and Library:Supports
+ Auto, Safe, and LowSpec compatibility modes for restricted executor environments

[compatibility]
+ Module, icon, and optional image downloads now prefer request and fall back to game:HttpGet
+ Core UI falls back safely when gethui, cloneref, clonefunction, hidden-property APIs, or getgenv are unavailable
+ ThemeManager and SaveManager no longer require clonefunction and report filesystem availability
+ Config export keeps JSON in the visible input when clipboard access is unavailable

[optimizations]
+ Removed four blocking optional image downloads from module initialization
+ Lucide source is cached and uses Roblox-hosted sprites instead of synchronously downloading two PNG files
+ Text bounds are cached and temporary GetTextBoundsParams instances are destroyed
+ Search input is debounced and stale requests are discarded
+ Keybind visibility updates avoid repeated tween work unless a bind or state actually changes
+ Theme registry now uses weak instance keys
+ Slider decimal rounding no longer formats strings on every drag frame
+ Resize callbacks are coalesced instead of rebuilding every tab multiple times in the same task cycle
+ Window visibility now uses one CanvasGroup tween instead of creating tweens for every descendant
+ Window closing is six times faster, uses one short CanvasGroup fade, and supports immediate reversal
+ Watermark statistics update at a fixed interval with one lightweight frame counter
+ Viewport and DPI changes are coalesced before recalculating responsive geometry
+ Dependency checks are batched for internal control updates and unchanged values skip callbacks, dependency work, and animations
+ Dropdown virtualization avoids redundant row property writes while scrolling

[fixes]
+ Timed event waits no longer fire a destroyed BindableEvent
+ Unload callbacks no longer remove from the front of an array repeatedly
+ Unload only clears the global Library reference when it still owns it
+ Window dragging and resizing stay inside the active viewport
+ Window geometry is repaired automatically after viewport or DPI changes
+ Scrollable columns now expose subtle overflow indicators and safe bottom spacing
+ Footer, resize handle, and content use separate non-overlapping layout regions
+ Groupbox titles truncate correctly and no longer extend beyond icon headers
+ Added Groupbox:SetOrder for predictable addon alignment
+ ThemeManager no longer resets Gotham to Code when opening UI Settings
+ Slider labels, values, track, thumb, mouse input, and touch input now use separate aligned regions
+ Rapid menu toggles no longer get ignored or leave stale visibility state
+ Groupboxes keep a consistent bottom breathing space after their final control
+ Groupbox height follows deferred coalesced layout measurements instead of stale element sizes
+ Groupbox height includes the measured bottom edge of every visible final control
```

### 17.08.2026

```diff
[features]
+ ColorPicker.Resizable
+ Window.AlwaysOnTop, Window:SetAlwaysOnTop, Loading.AlwaysOnTop

[changes]
+ TextBox focus now tweens the border between OutlineColor and AccentColor
+ Added Hover highlights on Dropdown items, KeyPicker mode-select buttons, and ColorPicker context menu items

[fixes]
+ Implemented MinContainerWidth properly
```

### 12.08.2026

```diff
[features]
+ Large dropdown lists are now virtualized for faster opens and lower instance count
+ Dropdowns no longer crash the game with over 10,000 values
+ Dictionary Values support: key = selection identity, value = display label
+ Dropdown:SetValues now prunes stale selections that are no longer in Values

[changes]
+ Dropdown.DisabledValues and Dropdown.ValueImages now accept dictionary keys or labels
+ Dropdown:AddValues on dictionary Values merges maps (or key=label for arrays)
+ Sparse numeric tables are treated as arrays (value identity), not dictionaries

[fixes]
+ Multi-dropdown dictionary keys no longer stripped to display labels (Issue #109)
```

### 11.07.2026

```diff
[changes]
+ Loading configs now triggers element callbacks even if their value hasn't changed
```

### 09.07.2026

```diff
[changes]
+ Background Image now supports external URLs using getcustomasset
```

### 07.07.2026

```diff
[features]
+ Dropdown.DragSelect, Dropdown:SetDragSelect(Value: boolean) (only works on non-touch devices and Multi dropdowns)
+ Animations.Groupbox, Animations.KeyPicker

[changes]
+ Notification appear and disappear animations are now smooth

[fixes]
+ Fixed Library.ToggleKeybind
```

### 05.07.2026

```diff
[features]
+ Added Animations.ToggleWindow
+ Added Animations.TabSwitch, TabTransitionTime, TabSwipeOffset, TabSwipeFrom (left/right/top/bottom)
+ Added Animations.Dropdown
+ Window:SetAnimations(Animations, TabTransitionTime, TabSwipeOffset, TabSwipeFrom)
+ Added DisableCollapsing to AddLeftGroupbox, AddRightGroupbox

[changes]
+ KeyPickers now allow setting the bind to any modifier key if it was only pressed and not held down

[fixes]
+ Fixed Library.ToggleKeybind not working properly with modifier keys
+ Fixed KeyPickers firing while picking a bind for any KeyPicker
```

### 02.07.2026

```diff
[changes]
+ Save Manager and Theme Manager refactored
+ Save Manager now saves the keybind menu visibility and position
+ Save Manager and Theme Manager now show what theme is the default and what config is autoloaded inside the dropdowns

[fixes]
+ Fixed dialogs buttons breaking with Destructive buttons if ThemeManager:SetDefaultTheme was used
```

### 01.07.2026

```diff
[features]
+ Confirmation dialogs to destructive actions in Save Manager and Theme Manager
+ Groupbox collapsed state now saves in configuration files
```


### 28.06.2026

```diff
[features]
+ Groupbox:SetVisible(Visible: boolean), Groupbox:Show(), Groupbox:Hide()
+ Groupbox:AddTabbox()
+ Collapse Groupbox arrow (disable with DisableCollapsing option)
+ TitleColor, DescriptionColor options for Library:Notify({ ... })
+ Library.Scheme.BackgroundImage and "Background Image" option in Theme Manager
+ Library.Window

[changes]
+ Tabbox:AddTab() now returns Tab and TabStoringIndex
+ Window BackgroundImage can now be set even when it was previously not set during creation

[fixes]
+ Fixed searching restoring hidden elements each time
+ Fixed attempt to index nil with 'Destroy' errors in Dropdown:BuildDropdownList()
+ Fixed rounded corners with Tab buttons inside Tabbox
+ Fixed Tab button spacing when it doesn't have name
```

### 26.06.2026

```diff
[features]
+ :Destroy() function for every element
+ Volume option for Library:Notify()
+ KeyPicker for buttons (Only works with 'Press' mode, Callback to the button will have an passed value FromKeyPicker which will be true if it was activated by the key picker)
+ Icon and IconPosition parameters to Library:AddDraggableLabel() and Library:AddDraggableButton()
+ Slider.AllowRightClickInput (right click/double tap to open text input for specific value)
+ Library:AddDraggableImageButton()

[changes]
+ Implemented individual rounded corners for certain elements (dropdowns, right-click context menus)
+ Right-click context menus will now connect to the buttons visually
+ Dropdown:GetActiveValues() => Dropdown:GetActiveValues(ReturnCountForMulti: boolean) [true => returns value count]
+ The dropdown menu will now close if the button is not visible on the screen.
+ Other KeyPickers will no longer trigger when you are selecting the keybind
+ Mouse button KeyPickers will no longer trigger when you have the UI opened
+ Draggable labels, buttons, menus and image buttons will now find an position where they won't overlap other dragging elements

[fixes]
+ Fixed AllowNull not properly working with Multi dropdowns
+ Fixed dropdown context menu not matching button size on the X axis

[optimizations]
+ Obsidian Library table will now get properly garbage collected after calling Library:Unload()
```

### 21.04.2026

```diff
[features]
+ SaveManager:SetLoadingOrder(enabled: boolean, order: { })
```

### 05.04.2026

```diff
[features]
+ Library.Scheme.DestructiveColor
+ Library:CreateLoading(LoadingInfo)
~ Read documentation at http://docs.mspaint.cc/obsidian/core/library/loading
```

### 03.04.2026

```diff
[features]
+ Tab:SetVisible()
```

### 28.03.2026

```diff
[features]
+ Dropdown.FormatListValue(Value)
  - Randomized formatting will not be preserved as the function is called every time the context menu is rebuilt
```

### 24.03.2026

```diff
[features]
+ Input.VerifyValue(NewValue: string): boolean
+ Input.ClearTextOnBlur
+ KeyPicker.Blacklisted, KeyPicker.BlacklistedModifiers
+ KeyPicker.Whitelisted, KeyPicker.WhitelistedModifiers

[changes]
+ CornerRadius now applies to more elements
+ Height of the slider increased by 1px
```

### 17.03.2026

```diff
[features]
+ Window:SetCornerRadius(Radius: number)

[fixes]
+ Fixed Window:SetFooter not changing the label text
+ Fixed footer background not properly resizing
+ Fixed Tab buttons not respecting corner radius
```

### 16.01.2026

```diff
[features]
+ Library:ResetCursorIcon()
+ Library:ChangeCursorIcon(ImageId: string)
+ Library:ChangeCursorIconSize(Size: UDim2)
```

### 30.12.2025

```diff
[breaking changes]
! Library.Scheme:
  .Red -> .RedColor
  .Dark -> .DarkColor
  .White -> .WhiteColor
! WindowInfo.Compact -> WindowInfo.SidebarCompacted
! WindowInfo.SidebarMinWidth -> WindowInfo.MinSidebarWidth
! WindowInfo.MinContentWidth -> WindowInfo.MinContainerWidth
- WindowInfo.SidebarCollapseThreshold
- WindowInfo.SidebarHighlightCallback function
- WindowInfo.InitialSidebarWidth
- WindowInfo.InitialSidebarScale

[fixes]
+ Fixed DPI Scaling

[features]
+ WindowInfo.DisableCompactingSnap
  -> WindowInfo.CompactWidthActivation

[changes]
+ WindowInfo.SidebarCompactWidth default value (54) to new value (48)
+ Library:SetWatermark is deprecated due to Library:AddDraggableLabel having the same functionality
```

### 18.12.2025

```diff
+ Patched static key bypass inside Key Box
    * The AddKeyBox function now only takes the callback function
    * The callback function only returns the provided key, you need to implement your own handler inside the callback
```

### 09.11.2025

```diff
+ Added Library.ImageManager (https://docs.mspaint.cc/obsidian/core/library/utility#custom-asset-icons)
```

### 02.11.2025

```diff
+ Warning Box now follows the UI style of Obsidian (rounded corners with outlines)
+ Watermark now correctly resizes itself with new line characters
```

### 01.11.2025

```diff
+ The ignored indexes (SaveManager.SetIgnoreIndexes) are no longer applied when you load a configuration that contains them
```

### 5.10.2025

```diff
+ Added support for modifier keys in KeyPicker (for example: LCtrl + E)
+ Fixed DoClick not calling the correct callbacks
```

### 17.09.2025

```diff
+ Added support for custom icons (rbxasset, rbxassetid, rbxthumb, getcustomasset) for Tabs and Groupboxes
```

### 14.09.2025

```diff
+ Added `Press` mode to `KeyPicker`
```

### 19.08.2025

```diff
+ Fixed `KeyPicker` in Toggle mode not working properly when Key is nil
```

#### 12.08.2025

```diff
+ Fixed `Tab:UpdateWarningBox()` not resizing properly
```

#### 10.08.2025

```diff
+ Added a LockSize option `Tab:UpdateWarningBox()` to set the maximum size of the warning box to 3.25 size of the Tab Container (optional)
+ Added support for mouse button 3 (middle click)
```

#### 17.07.2025

```diff
+ Added Description parameter to `Window:AddTab()` method to set a description for the tab
+ Updated `Window:AddTab()` method to accept a table with Name, Icon, and Description or a table with Name, Icon (optional), and Description (optional)
+ Updated `Library:CreateWindow()`'s WindowInfo parameter to include a `DisableSearch` option to disable the search box in the window
```

#### 15.07.2025

```diff
+ Added watermark support to the library
+ Added `Library:SetWatermarkVisibility()` method to toggle the visibility of the watermark
+ Added `Library:SetWatermark()` method to set the watermark text
```

#### 14.07.2025

```diff
+ Added `AddImage` component
```

#### 13.07.2025

```diff
+ Updated lucide icons to the latest version
+ Changed lucide icons to be using `getcustomasset` to bypass ContentProvider detections
+ Added `AddViewport` component
```

#### 12.07.2025

```diff
+ Added `ThemeManager:SetDefaultTheme()` method to set the default theme for the library
+ Improved `Library:SafeCallback()` to handle errors correctly and return everything correctly (previously it would only return the first return value)
+ Added `BackgroundImage` parameter to `Window` constructor to set a background image for the window
```

#### 02.07.2025

```diff
+ Added dropdown support for `AddDependencyBox` and `AddDependencyGroupBox`
```

#### 15.06.2025

```diff
+ Fixed Obsidian's `Library:Validate()` function to ignore arrays (setting modes option on AddKeyPicker would fail previously)
```

#### 04.06.2025

```diff
+ Added Notify.Persist and Notify:Destroy() methods to make persistent notifications easier to manage
+ Added Icon parameter to Groupbox constructor that matches the accent color.
```

#### 17.05.2025

```diff
+ Added a new `AddDependencyBox` and `AddDependencyGroupBox` methods to the `Groupbox` class
```

#### 18.01.2024

```diff
+ Added a Hover Animation to Buttons
+ Added Risky to Buttons
+ Changed Toggle's Checkbox to Switch (Checkbox is still possible with AddCheckbox)
+ Dropdown disabled values moved to the bottom
+ Fixed DPI Scale issues (Title Wrapping, Slider Fill Bar and Dropdown Menu Size)
```
