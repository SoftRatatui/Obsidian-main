# MonHub UI

A polished Roblox UI library with one premium Metal design system, responsive layouts, smooth animations, mobile support, configuration saving, and full access to the original Obsidian/Linoria-style API.

Read the canonical [complete guide](GUIDE.md) for installation, API usage, Metal behavior, configs, launcher behavior, and troubleshooting. Migrating from the original Obsidian: read the [migration guide](MIGRATION_GUIDE.md).

## What changed

- One Metal visual system with layered neutral-gray surfaces, a muted steel accent, restrained 6px outer geometry, subtle single-pixel outlines, and Gotham Medium typography.
- Motion controller prevents duplicate transitions for window, tab, groupbox, dropdown, key picker, slider, and toggle interactions.
- New declarative API: create a complete interface from one readable table.
- Backwards compatible: `CreateWindow`, `AddTab`, `AddToggle`, and the existing addons still work.
- Faster startup: Roblox-hosted icon sprites are preferred, the Lucide module is cached, and optional image files are no longer downloaded before the first window.
- Less work while typing and changing controls: search is debounced, text measurements are cached, dependency updates are batched, and unchanged values are ignored.
- Responsive geometry: windows remain inside the viewport, resize work is coalesced, and narrow content switches from two cramped columns to one readable vertical layout.
- Consistent layout: footer, resize handle, group headers, and content columns use separate aligned regions.
- Centralized click sound, draggable clamped Watermark, FPS/ping settings, R6 ESP preview, and refined sliders.
- Legacy presets, custom theme files, and stale theme config fields now resolve to Metal instead of leaving mixed colors behind.

## Quick start

### Executor

```luau
local function Fetch(URL)
    local Request = request or http_request or (syn and syn.request)
    if type(Request) == "function" then
        local Response = Request({ Url = URL, Method = "GET" })
        local Body = type(Response) == "table" and (Response.Body or Response.body) or Response
        if type(Body) == "string" and #Body > 0 then
            return Body
        end
    end

    return game:HttpGet(URL)
end

local Source = Fetch("https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/Library.lua")
local Library = assert(loadstring(Source))()

local App = Library:Create({
    Title = "MonHub",
    Footer = "Ready",

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

## Current Metal interface

`Metal` is the only shipped profile. It uses neutral-gray surfaces, a muted steel accent, Gotham Medium typography, compact 24×14 soft switches, restrained 6px outer geometry, subtle single-pixel outlines, and a fixed footer. It feels soft through typography, contrast, spacing, and restrained motion rather than excessive corner rounding. Sidebar tabs use an inset full-width row, while selected states stay soft without pushing against the window edge. Legacy themes and saved appearance data cannot override Metal on launch. Hover tooltips are disabled by default. The window stays within the viewport; use the move icon in the top-right corner to reposition it. The adjacent minimize icon collapses the window into a centered draggable launcher with the script title; closing by keybind keeps the screen clear and is reopened by the same keybind. Watermark starts in the top-left corner, can be dragged, can be snapped left or right, stays clamped inside the viewport, and does not display time.

For a mobile-first size, use `Library.IsMobile` when creating the window. The library automatically changes narrow two-column content into a readable single column and coalesces resize updates to avoid animation stutter.

Buttons support `Default`, `Primary`, `Warning`, `Danger`, and `Ghost` variants. `Warning` and `Danger` receive restrained semantic icons by default; pass `Icon = "..."` to replace one or `Icon = false` to remove it. `Library:SetButtonVariantIcon("Danger", "trash-2")` changes the default for new and existing semantic danger buttons. `Risky = true` remains supported and maps to `Danger` when no explicit variant is provided. `Secondary`, `Caution`, and `Destructive` remain accepted as legacy aliases for `Default`, `Warning`, and `Danger`.

Toggles support `Default`, `Warning`, and `Danger` through `Variant`. Their active track and outline use the semantic color while inactive controls remain neutral, so dense settings pages stay calm. Activating a `Danger` toggle opens a short `Cancel` / `Continue` confirmation; turning it off stays immediate for a quick exit. Set `ConfirmDanger = false` to opt out, or provide `ConfirmTitle` and `ConfirmDescription` for the dialog copy. `Caution` and `Destructive` are accepted aliases; legacy `Risky = true` maps to `Danger`.

Use `ShowCompactLauncher`, `CompactLauncherIcon`, `CompactLauncherSize`, `CompactLauncherWidth`, `CompactLauncherTitle`, `CompactLauncherPosition`, and `CompactLauncherDraggable` in `CreateWindow` to configure the launcher. It stays outside the main window, remains inside the viewport, and uses a movement threshold so dragging never triggers an accidental reopen.

## Full executor profile

MonHub is tuned for full-featured executors with `request`, `loadstring`, filesystem APIs, `getcustomasset`, `gethui`, and `protectgui`. This profile keeps every visual enhancement, local config workflow, custom image support, cursor, and refined transitions enabled.

The library retains ordinary defensive guards where they are free, but reduced-feature executor compatibility is not the target of this build.

### Wally / Roblox Studio

The current public Wally package metadata points to upstream Obsidian. To guarantee this exact MonHub build, vendor `Library.lua`, `Library.d.luau`, and `addons`, or publish a package pinned to this repository. See [Wally or Studio installation](MIGRATION_GUIDE.md#установка-через-wally-или-studio).

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

`addons/VisualPreview.lua` renders a clone of a real Roblox character inside a separate preview for one regular tab. Supply a `Player`, `Model`, or resolver function through `Target`; when omitted, it uses the current `LocalPlayer` character. It opens beside the main window without changing the tab layout, stays inside the viewport, and hides whenever the main menu hides. Its box, text placement, gradient, health bar, tracer, and R6-only chams mirror the supplied ESP settings. The preview never changes the original character.

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

`Window` is required when the library is used through the legacy API: pass the return value of `Library:CreateWindow`. `Renderer` is optional; provide it only when your own project exposes a function that builds the same objects as its live ESP. The generic module clones and previews a real target character without it. Box Scale and Dynamic Boxes use the same FOV/depth calculation as the live renderer. Call `Preview:SetTarget(PlayerOrModel)` to follow another real character.

Drag the character with the left mouse button or touch to rotate it. Use the mouse wheel to zoom. `Preview:Rotate(x, y)`, `Preview:SetZoom(value)`, and `Preview:ResetView()` are available for custom controls.

For a ready-to-use binding from real ESP controls, see the ESP preview section in [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md#esp-preview-addon).

## Metal baseline

Metal starts automatically and is the only palette in this release. `Library:SetTheme("Metal")` remains available as an explicit reset. Other legacy preset names and theme tables are accepted only for compatibility and reset to Metal; they do not recolor the UI. Theme selection, custom theme files, and persisted palette defaults are unavailable until the theme system returns.

Gotham Medium is deliberately kept as the readable UI default: it has stable small-size rendering and the full characters needed for labels, values, keybinds, and sliders. The supplied `Milkyway DEMO.ttf` is not bundled or loaded because it is licensed for personal use only and a local `.ttf` is not a portable Roblox UI font. A future custom font must be licensed, Roblox-compatible, and tested for full glyph coverage before it can become an optional visual accent.

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
