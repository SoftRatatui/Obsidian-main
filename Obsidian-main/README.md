# MonHub UI

A polished Roblox UI library with a premium Azure default theme, responsive layouts, smooth animations, mobile support, configuration saving, and full access to the original Obsidian/Linoria-style API.

Migrating from the original Obsidian: read the complete [migration guide](MIGRATION_GUIDE.md).

## What changed

- Azure visual system with layered blue-slate surfaces, a muted cool accent, 4px geometry, and Gotham typography.
- Motion controller prevents duplicate transitions for window, tab, groupbox, dropdown, key picker, slider, and toggle interactions.
- New declarative API: create a complete interface from one readable table.
- Backwards compatible: `CreateWindow`, `AddTab`, `AddToggle`, and the existing addons still work.
- Faster startup: Roblox-hosted icon sprites are preferred, the Lucide module is cached, and optional image files are no longer downloaded before the first window.
- Less work while typing and changing controls: search is debounced, text measurements are cached, dependency updates are batched, and unchanged values are ignored.
- Responsive geometry: windows remain inside the viewport, resize work is coalesced, and narrow content switches from two cramped columns to one readable vertical layout.
- Consistent layout: footer, resize handle, group headers, and content columns use separate aligned regions.
- Centralized click sound, draggable Watermark, FPS/ping settings, interactive R6 viewport controls, and refined sliders.
- Editable top-bar theme color with backwards-compatible fallback for existing themes.

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

## Full executor profile

MonHub is tuned for full-featured executors with `request`, `loadstring`, filesystem APIs, `getcustomasset`, `gethui`, and `protectgui`. This profile keeps every visual enhancement, local theme/config workflow, custom image support, cursor, and refined transitions enabled.

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

`addons/VisualPreview.lua` creates an isolated white R6 `ViewportFrame` preview for a single tab. Its overlay can independently show a box, name, distance, health bar, tracer, highlight, and accent color. The preview never reads or changes players in the experience.

```luau
local VisualPreview = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/VisualPreview.lua"
))()

local Preview = VisualPreview.Create(Tabs.Visuals, {
    Name = "ESP preview",
    Enabled = false,
})

Preview:SetEnabled(true)
Preview:SetTracerVisible(true)
Preview:SetColor(Color3.fromRGB(119, 166, 209))
```

## Themes

`Azure` is the default. `Graphite`, `BlackPurple`, and `Classic` remain available:

```luau
Library:SetTheme("BlackPurple")
```

You can pass `Theme = "Azure"` to `Library:Create`, select another built-in theme, or supply a custom theme table.

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
