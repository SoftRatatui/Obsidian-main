# Obsidian UI

A fast Roblox UI library with a calm black-purple default theme, responsive layouts, smooth animations, mobile support, configuration saving, and full access to the original Linoria-style API.

## What changed

- New black-purple visual system with softer surfaces, focus states, rounded corners, and Gotham typography.
- Smooth window, tab, groupbox, dropdown, key picker, and toggle transitions enabled by default.
- New declarative API: create a complete interface from one readable table.
- Backwards compatible: `CreateWindow`, `AddTab`, `AddToggle`, and the existing addons still work.
- Faster startup: bundled Roblox icon sprites are preferred, the Lucide module is cached, and optional image files are no longer downloaded before the first window.
- Less work while typing: search is debounced and text measurements are cached.

## Quick start

### Executor

```luau
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"
))()

local App = Library:Create({
    Title = "My Interface",
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

### Wally / Roblox Studio

```luau
local Obsidian = require(Packages.Obsidian)
local App = Obsidian.create({
    Title = "My Interface",
    Tabs = { -- same declarative structure as above
    },
})
```

## Declarative structure

```text
App
└── Tabs / Pages
    └── Sections / Groups
        └── Controls / Elements
```

Supported control types: `Label`, `Button`, `Toggle`, `Checkbox`, `Input`, `Slider`, `Dropdown`, `Divider`, `Viewport`, `Image`, `Video`, and `UIPassthrough`. `KeyPicker` and `ColorPicker` can be added through an element's `Addons` array.

Use `Id` only when code needs to access an element later. `App:Get(Id)` returns the created element. `App:Toggle()`, `App:Notify(...)`, and `App:Destroy()` cover the common lifecycle operations.

## Themes

`BlackPurple` is the default. The previous visual style remains available:

```luau
Library:SetTheme("Classic")
```

You can also pass `Theme = "Classic"` to `Library:Create`, or supply a custom theme table.

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
```

Full documentation: [docs.mspaint.cc/obsidian](https://docs.mspaint.cc/obsidian)

## Optional asset preload

The first window now opens without waiting for optional local PNG downloads. If an executor specifically needs local custom assets, preload them in the background:

```luau
Library.ImageManager.PreloadAssets()
```

## License

MIT — see [LICENSE](LICENSE).
