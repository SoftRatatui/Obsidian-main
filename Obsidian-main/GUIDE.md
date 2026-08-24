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
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua?monhub=0.0.1-release-6"
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
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua?monhub=0.0.1-release-6"
))()
if Library.ReleaseVersion ~= "0.0.1-release-6" then
    warn(string.format("MonHub version notice: expected %s, received %s", "0.0.1-release-6", tostring(Library.ReleaseVersion)))
end

Library:SetClickSound(92679954573730, 0.3)

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
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua?monhub=0.0.1-release-6"
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
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/ImageGallery.lua?monhub=0.0.1-release-6"
))()
local ImagePreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/ImagePreview.lua?monhub=0.0.1-release-6"
))()

local SkinGrid = Tabs.Visuals:AddLeftGroupbox("Skins", "layout-grid")
local SkinLook = Tabs.Visuals:AddRightGroupbox("Selected skin", "image")

local Preview = ImagePreview.CreateEmbedded(Library, SkinLook, "SkinPreview", {
    Height = 280,
    ScaleType = "Fit",
    Title = "Select a skin",
    Motion = true,
})

local Gallery = ImageGallery.CreateEmbedded(Library, SkinGrid, "SkinGallery", {
    Height = 344,
    Columns = 5,
    PageSize = 15,
    CellHeight = 78,
    Preview = Preview,
    Items = {
        {
            Id = "aurora",
            Name = "Aurora",
            Category = "Rifles",
            Subtitle = "Assault rifle",
            Thumbnail = 1234567890,
            PreviewImage = 1234567891,
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

`Image`, `AssetId`, and primitive numeric IDs are normalized to `rbxassetid://`. Use `Thumbnail` or `ThumbnailId` for the light grid image and `PreviewImage` or `FullImage` for the larger selected view. When those fields are omitted, both views use `Image`. Complete `rbxassetid://`, `rbxasset://`, and executor-provided custom asset strings pass through unchanged.

Gallery methods are `SetItems`, `AddItem`, `RemoveItem`, `SetSearch`, `SetCategory`, `SetPage`, `NextPage`, `PreviousPage`, `SetColumns`, `Select`, `GetSelected`, `BindPreview`, `SetVisible`, `SetHeight`, `Mount`, and `Destroy`. Clicking the category button cycles only categories present in the current item list.

Preview methods are `SetImage`, `SetTitle`, `SetSubtitle`, `SetImageColor`, `SetImageTransparency`, `SetScaleType`, `SetMotion`, `SetVisible`, `SetHeight`, `Mount`, and `Destroy`. Use `CreateEmbedded` for a groupbox or `Create(Library, { Parent = Frame, ... })` for a direct 2D panel.

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
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/TextureGallery.lua?monhub=0.0.1-release-6"
))()
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

The intentionally small API is `SetItems`, `Select`, `GetSelected`, `SetColumns`, `SetVisible`, `Mount`, and `Destroy`. Item fields are `Id`, `Name`, `Texture`, `ColorA`, and `ColorB`. Numeric IDs and complete Roblox asset strings are accepted.

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

For historical Obsidian migration notes, see [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md). For the complete showcase, see [Example.lua](Example.lua). For exact production type signatures, see [Library.d.luau](Library.d.luau).
