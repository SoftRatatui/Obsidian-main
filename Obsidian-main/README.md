# MonHub UI

A Roblox UI library with six semantic themes, responsive layouts, short interface transitions, mobile input support, configuration persistence, and compatibility with the original Obsidian/Linoria-style API.

Read the canonical [complete guide](GUIDE.md) for installation, API usage, themes, configs, launcher behavior, and troubleshooting. Migrating from the original Obsidian: read the [migration guide](MIGRATION_GUIDE.md).

## What changed

- Six focused visual presets: neutral-gray `Default`, violet `Metal`, near-black `Midnight`, cool `Steel`, green-gray `Sage`, and warm-neutral `Ash`; all use semantic background, card, raised, control, hover, muted-text, and accent layers, with a feature-gated soft shadow on elevated surfaces.
- Packaged Inter Bold typography through `LoadCustomFont` and `SetThemeFont`, with Gotham fallback and persistence across theme switches.
- Motion controller prevents duplicate transitions for window, tab, groupbox, dropdown, key picker, slider, and toggle interactions.
- New declarative API: create a complete interface from one readable table.
- Backwards compatible: `CreateWindow`, `AddTab`, `AddToggle`, and the existing addons still work.
- Faster startup: Roblox-hosted icon sprites are preferred, the Lucide module is cached, and optional image files are no longer downloaded before the first window.
- Less work while typing and changing controls: search is debounced, text measurements are cached, dependency updates are batched, and unchanged values are ignored.
- Responsive geometry: windows remain inside the viewport, resize work is coalesced, and narrow content switches from two cramped columns to one readable vertical layout.
- Consistent layout: footer, resize handle, group headers, and content columns use separate aligned regions.
- Centralized click sound, draggable clamped Watermark, FPS/ping settings, R6 ESP preview, a real native character Trail addon, and refined sliders.
- Theme changes are atomic: registered instances and stateful controls are refreshed together, while raw legacy palette fields are ignored so old colors cannot remain in the top bar, overlays, controls, or footer.

## Quick start

### Executor

```luau
local function Fetch(URL)
    local Environment = getfenv()
    local function ReadGlobal(Name)
        if type(Environment) ~= "table" then
            return nil
        end
        local Success, Value = pcall(function()
            return Environment[Name]
        end)
        return Success and Value or nil
    end
    local SynEnvironment = ReadGlobal("syn")
    local Request = ReadGlobal("request") or ReadGlobal("http_request") or (type(SynEnvironment) == "table" and rawget(SynEnvironment, "request") or nil)
    if type(Request) == "function" then
        local Response = Request({ Url = URL, Method = "GET" })
        local Body = type(Response) == "table" and (Response.Body or Response.body) or Response
        if type(Body) == "string" and #Body > 0 then
            return Body
        end
    end

    return game:HttpGet(URL)
end

local Source = Fetch("https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua?monhub=0.0.1-release-6")
local Library = assert(loadstring(Source))()
if Library.ReleaseVersion ~= "0.0.1-release-6" then
    warn(string.format("MonHub version notice: expected %s, received %s", "0.0.1-release-6", tostring(Library.ReleaseVersion)))
end

local App = Library:Create({
    Title = "MonHub",
    Footer = "MonHub v0.0.1",

    Tabs = {
        {
            Name = "Main",
            Icon = "house",

            Sections = {
                {
                    Name = "Player",
                    Side = "Left",

                    Controls = {
                        {
                            Type = "Toggle",
                            Id = "enabled",
                            Text = "Enabled",
                            Default = true,
                            OnChanged = function(Value)
                                print("Enabled:", Value)
                            end,
                        },
                        {
                            Type = "Slider",
                            Id = "speed",
                            Text = "Speed",
                            Min = 0,
                            Max = 100,
                            Default = 35,
                        },
                        {
                            Type = "Button",
                            Text = "Run action",
                            Variant = "Primary",
                            OnClick = function()
                                print("Clicked")
                            end,
                        },
                    },
                },
            },
        },
    },
})

App:Get("speed"):SetValue(50)
```

## Current interface

`Default` starts automatically with layered neutral-gray surfaces and a muted slate accent. `Metal` is the dark violet reference preset, while `Midnight` provides a near-black neutral profile with a muted steel accent. All three use Gotham Regular as the zero-download fallback, compact 16×16 checkmarks inside a 22px row, restrained 6px outer geometry, subtle single-pixel outlines, and a fixed footer. The complete showcase installs the packaged Inter Bold font before creating its window. Cards, popups, inputs, hover states, and secondary text have separate semantic colors, which creates depth without blur or blanket rounding. Sidebar tabs use an inset full-width row with a soft background transition. Hover tooltips are disabled by default. The window stays within the viewport; use the move icon in the top-right corner to reposition it. The adjacent minimize icon collapses the window into a centered draggable launcher with the script title; closing by keybind keeps the screen clear and is reopened by the same keybind. Watermark starts in the top-left corner, can be dragged, can be snapped left or right, stays clamped inside the viewport, and does not display time.

For a mobile-first size, use `Library.IsMobile` when creating the window. The library automatically changes narrow two-column content into a readable single column and coalesces resize updates to avoid animation stutter.

Buttons support `Default`, `Primary`, and `Ghost` variants. `Secondary` remains an alias for `Default`. Warning and danger button styling and automatic semantic icons were removed from the current API; maintained projects must migrate those variants to the current set and use clear text, an explicit icon, or a confirmation dialog instead.

Toggles support `Default`, `Warning`, and `Danger` through `Variant`. Their active track and outline use the semantic color while inactive controls remain neutral, so dense settings pages stay calm. Activating a `Danger` toggle opens a short `Cancel` / `Continue` confirmation; turning it off stays immediate for a quick exit. Set `ConfirmDanger = false` to opt out, or provide `ConfirmTitle` and `ConfirmDescription` for the dialog copy. `Caution` and `Destructive` are accepted aliases; legacy `Risky = true` maps to `Danger`.

Use `ShowCompactLauncher`, `CompactLauncherIcon`, `CompactLauncherSize`, `CompactLauncherWidth`, `CompactLauncherTitle`, `CompactLauncherPosition`, and `CompactLauncherDraggable` in `CreateWindow` to configure the launcher. It stays outside the main window, remains inside the viewport, and uses a movement threshold so dragging never triggers an accidental reopen.

## Full executor profile

MonHub is tuned for full-featured executors with `request`, `loadstring`, filesystem APIs, `getcustomasset`, `gethui`, and `protectgui`. This profile keeps every visual enhancement, local config workflow, custom image support, cursor, and refined transitions enabled.

The library retains ordinary defensive guards where they are free, but reduced-feature executor compatibility is not the target of this build.

### Wally / Roblox Studio

The current public Wally package metadata points to upstream Obsidian. To guarantee this exact MonHub build, vendor `Library.lua`, `Library.d.luau`, and `addons`, or publish a package pinned to this repository. See [Wally or Studio installation](MIGRATION_GUIDE.md#wally-or-studio-installation).

## Declarative structure

```text
App
└── Tabs / Pages
    └── Sections / Groups
        └── Controls / Elements
```

Supported control types: `Label`, `Button`, `Toggle`, `Checkbox`, `Input`, `Slider`, `Dropdown`, `Divider`, `Viewport`, `Image`, `Video`, and `UIPassthrough`. `KeyPicker` and `ColorPicker` can be added through an element's `Addons` array.

Use `Id` only when code needs to access an element later. `App:Get(Id)` returns the created element. `App:Toggle()`, `App:Notify(...)`, and `App:Destroy()` cover the common lifecycle operations.

## Visual preview module

`addons/VisualPreview.lua` renders a clone of a real Roblox character in a side panel, arbitrary GUI parent, or groupbox. `addons/DrawingESPPreview.lua` supplies one Drawing renderer for both live entities and the preview, so the preview can show the project's real box, text, and health implementation instead of maintaining a second fake overlay.

```luau
local VisualPreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/VisualPreview.lua?monhub=0.0.1-release-6"
))()
local DrawingESPPreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/DrawingESPPreview.lua?monhub=0.0.1-release-6"
))()
local Players = game:GetService("Players")

local PreviewGroup = Tabs.Visuals:AddRightGroupbox("Live preview", "scan-eye")
local ESPRenderer = DrawingESPPreview.Create()
local Preview = VisualPreview.CreateEmbedded(Library, PreviewGroup, {
    Name = "ESP preview",
    Target = Players.LocalPlayer,
    Height = 320,
    Enabled = false,
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

Use `VisualPreview.Create` for the external side panel, `VisualPreview.CreateEmbedded` for a groupbox, or pass `Parent = SomeGuiObject` for a direct mount. `Renderer` is optional; without one, the preview uses its built-in theme-aware fallback. A custom renderer can implement `AttachPreview`, `UpdatePreview`, `SetPreviewVisible`, and `DetachPreview`.

Drag the character with the left mouse button or touch to rotate it. Use the mouse wheel to zoom. `Preview:Rotate(x, y)`, `Preview:SetZoom(value)`, and `Preview:ResetView()` are available for custom controls.

Optional `ImageGallery.lua` and `ImagePreview.lua` addons provide pooled skin grids and animated full-size 2D previews. `CharacterTrail.lua` adds a native Roblox `Trail` with gradient colors, independent start/end transparency, width curves, texture presets, lighting, character respawn support, and no frame loop. These addons are never loaded by the core library; `Example.lua` imports them explicitly as a complete interactive showcase. `TracerPreview.lua` remains only as a legacy decorative image sample and is not imported by the current example. For the complete opt-in addon examples, see [GUIDE.md](GUIDE.md#media-and-esp-preview) and [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md#esp-preview-addon).

The redesign is isolated in `ExperimentalLibrary.lua`, a complete copy of the production API with a fixed icon-only navigation rail, larger centered icons, wider content, and refined module headers. `Experimental.lua` loads that copy and exposes `CharacterTrail`, `TextureGallery`, `VisualPreview`, `DrawingESPPreview`, `FixedR6Preview`, and the packaged Inter Bold font through `Library.Experimental`. `TextureGallery` is a lightweight trail-texture selector with a wide selected preview and compact cards. `FixedR6Preview` creates an actual R6 from the selected player's current `HumanoidDescription`, keeps the panel fixed to its assigned tab, and accepts the same renderer adapter used by the live ESP. Run `ExperimentalExample.lua` to test the complete experimental layout. Production `Library.lua` is unchanged by this redesign.

## Theme presets

The release contains six built-ins: `Default`, the neutral-gray startup theme; `Metal`, the desaturated violet reference theme; `Midnight`, the near-black neutral theme; `Steel`, a cool blue-gray theme; `Sage`, a quiet green-gray theme; and `Ash`, a warm neutral theme. Switch directly with `Library:SetTheme("ThemeName")`. Raw legacy palette tables and saved color fields are ignored.

`ThemeManager.lua` adds a minimal six-preset dropdown. Its `ThemeManager_ThemeList` option is saved by SaveManager even when `IgnoreThemeSettings()` filters obsolete raw color fields. Gotham Regular is the readable zero-download fallback; `assets/Inter-Bold.ttf` is the packaged showcase font.

## Legacy API

The original API remains supported:

```luau
local Window = Library:CreateWindow({ Title = "Legacy UI" })
local Tab = Window:AddTab("Main", "house")
local Group = Tab:AddLeftGroupbox("General")

Group:AddToggle("enabled", {
    Text = "Enabled",
    Default = true,
    Callback = function(Value)
        print(Value)
    end,
})

Group:SetOrder(10)
Window:FitToViewport()
```

MonHub migration and feature guide: [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)

Original legacy API documentation: [docs.mspaint.cc/obsidian](https://docs.mspaint.cc/obsidian)

## Optional asset preload

The first window now opens without waiting for optional local PNG downloads. If an executor specifically needs local custom assets, preload them in the background:

```luau
Library.ImageManager.PreloadAssets()
```

## License

MIT — see [LICENSE](LICENSE).

Icons are provided by [Lucide](https://lucide.dev/) through [lucide-roblox-direct](https://github.com/mstudio45/lucide-roblox-direct).
