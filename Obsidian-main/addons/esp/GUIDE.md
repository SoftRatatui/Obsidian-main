# MonHub Universal ESP Addon

This document covers only the optional ESP addon. The addon is not part of the core library and is never loaded by `Library.lua` unless a project explicitly downloads and starts it.

## Files

| File | Purpose |
|---|---|
| `ESP.lua` | Standalone renderer and entity lifecycle |
| `MonHubUI.lua` | Optional MonHub settings tab |
| `ESP.d.luau` | Complete public type declarations |

Raw sources:

- [ESP.lua](https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/esp/ESP.lua)
- [MonHubUI.lua](https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/esp/MonHubUI.lua)
- [ESP.d.luau](https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/esp/ESP.d.luau)

## Requirements

- `loadstring`
- HTTP access through `game:HttpGet` or an executor request function
- `Drawing.new`
- Roblox services available to a LocalScript environment

The renderer does not require debug APIs, metatable hooks, hidden properties, global installation, or executor-specific `syn` globals. Native Highlight is optional and remains disabled by default.

## Quick start

```luau
local UniversalESP = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/esp/ESP.lua?monhub=esp-2"
))()

local ESP = UniversalESP.new({
    AutoStart = true,
    WrapPlayers = true,
    Settings = {
        Enabled = true,
        MaxDistance = 2500,
        TextDistance = 600,
        MaxRendered = 64,
    },
})

Library:OnUnload(function()
    ESP:Destroy()
end)
```

`UniversalESP.Available` reports whether Drawing is usable. `ESP.Available` contains the same state for the controller.

## MonHub settings page

```luau
local UniversalESPUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SoftRatatui/Obsidian-main/main/Obsidian-main/addons/esp/MonHubUI.lua?monhub=esp-2"
))()

local ESPTab = Window:AddTab("ESP", "scan-eye")
local ESPPanel = UniversalESPUI.Mount(Library, ESPTab, ESP, {
    Prefix = "MainESP_",
    Keybind = "None",
    AutoNPCs = false,
    NPCContainer = workspace,
})
```

The adapter creates separate groups for entities, filters, boxes, geometry, text, health, tracers, model visuals, colors, distance fade, crosshair, runtime, and NPC tracking. Stable prefixed option IDs allow SaveManager to store the full panel.

Set `OwnController = true` only when the UI handle owns the renderer lifecycle. Otherwise destroy the controller from the project unload handler.

## Controller API

| Method | Result |
|---|---|
| `UniversalESP.new(info)` | Creates an isolated controller. |
| `ESP:Start()` | Starts one throttled `RenderStepped` scheduler. |
| `ESP:Stop()` | Pauses rendering and hides owned visuals. |
| `ESP:Set(path, value)` | Writes one dotted settings path. |
| `ESP:Get(path)` | Reads one dotted settings path. |
| `ESP:ApplySettings(settings)` | Deep-merges a settings table. |
| `ESP:ApplyPreset(name)` | Applies `Performance`, `Balanced`, or `Quality`. |
| `ESP:SetEnabled(state)` | Changes the master renderer state. |
| `ESP:WrapPlayers(info)` | Wraps all players and watches joins and leaves. |
| `ESP:UnwrapPlayers()` | Removes all player entries and player watchers. |
| `ESP:WrapObject(object, info)` | Wraps a Player, Model, NPC, or BasePart. |
| `ESP:UnwrapObject(objectOrId)` | Removes one entry and every visual it owns. |
| `ESP:GetEntry(objectOrId)` | Returns an entry record. |
| `ESP:ScanNPCs(container, info)` | Adds existing humanoid NPC models. |
| `ESP:WatchNPCs(container, info)` | Returns a destroyable live NPC watcher. |
| `ESP:SetAutomaticNPCs(state, container, info)` | Controls one managed NPC watcher. |
| `ESP:SetCategoryStyle(category, style)` | Assigns shared category colors, distance, and visual masks. |
| `ESP:GetCategoryStyle(category)` | Returns a category style. |
| `ESP:SetFilterList(values)` | Replaces the normalized whitelist or blacklist. |
| `ESP:SetIgnored(object, state)` | Temporarily ignores an object without unwrapping it. |
| `ESP:CreatePreviewAdapter(info)` | Creates a VisualPreview renderer adapter. |
| `ESP:GetStats()` | Returns counts, state, availability, and the last renderer error. |
| `ESP:Restart(rebuild)` | Restarts and optionally recreates entity visuals. |
| `ESP:HideAll()` | Hides entities, preview drawings, Highlights, and crosshair. |
| `ESP:Destroy()` | Disconnects watchers and removes every owned object. |

`Wrap`, `Unwrap`, `TrackNPCs`, and `Exit` are aliases for `WrapObject`, `UnwrapObject`, `WatchNPCs`, and `Destroy`.

## Global settings

| Path | Values | Purpose |
|---|---|---|
| `Enabled` | boolean | Master state |
| `Players` | boolean | Player entries |
| `NPCs` | boolean | NPC entries |
| `Parts` | boolean | Manual non-humanoid entries |
| `IncludeLocalPlayer` | boolean | Local character rendering |
| `AliveCheck` | boolean | Hides dead humanoids |
| `TeamCheck` | boolean | Hides local teammates |
| `TeamColors` | boolean | Uses Roblox team colors |
| `VisibilityCheck` | boolean | Interval-cached line-of-sight raycasts |
| `VisibilityInterval` | `0.02` to `2` | Seconds between raycasts per entity |
| `OcclusionMode` | `Fade`, `Color`, `Hide`, `Ignore` | Result of a failed visibility check |
| `MaxDistance` | number | Global render distance in studs |
| `TextDistance` | number | Maximum label distance |
| `MaxRendered` | `0` to `1000` | Entity budget; `0` is unlimited |
| `SortMode` | `Distance`, `Priority`, `Name` | Selection order when a budget is active |
| `FilterMode` | `All`, `Whitelist`, `Blacklist` | Global list behavior |
| `FilterMatch` | `Exact`, `Contains`, `Prefix` | Token matching behavior |
| `DistanceUnit` | `Studs`, `Meters`, `Feet` | Label unit |
| `DistanceScale` | number | Project-specific distance multiplier |
| `UpdateRate` | `5` to `240` | Maximum render updates per second |
| `TextUpdateRate` | `1` to `60` | Label cache refresh rate |

## Boxes and geometry

| Path | Purpose |
|---|---|
| `Box.Enabled` | Master box state |
| `Box.Style` | `Corner`, `Full`, or projected `3D` |
| `Box.Dynamic` | Exact model bounding box or lightweight two-point bounds |
| `Box.Scale` | Uniform world-space scale |
| `Box.ScaleX`, `Box.ScaleY` | Independent horizontal and vertical scale |
| `Box.PaddingX`, `Box.PaddingY` | Additional world-space padding |
| `Box.Thickness` | Main line thickness |
| `Box.Transparency` | Main line opacity |
| `Box.Outline` | Dark contrast outline |
| `Box.OutlineThickness` | Outline thickness |
| `Box.Fill` | Interior fill for 2D styles |
| `Box.FillTransparency` | Fill opacity |
| `Box.Gradient` | Vertical two-color interpolation |
| `Box.Rainbow` | Animated primary color |
| `Box.RainbowSpeed` | Rainbow cycle speed |
| `Box.CornerWidth`, `Box.CornerHeight` | Corner segment proportions |
| `Box.MinimumSize`, `Box.MaximumSize` | Screen-space size clamps |

## Text

`Text.Name`, `Text.Team`, `Text.Distance`, `Text.Tool`, `Text.Health`, `Text.Category`, and `Text.Flags` control individual labels. Every label can also be disabled per entry or per category through `AllowedVisuals`.

| Path | Purpose |
|---|---|
| `Text.DisplayName` | Uses DisplayName instead of username for players |
| `Text.Size` | Base Drawing text size |
| `Text.MinimumSize`, `Text.MaximumSize` | Distance-scaling clamps |
| `Text.RelativeSize` | Scales labels from projected box height |
| `Text.Outline` | Text outline |
| `Text.Font` | `Plex`, `UI`, `System`, or `Monospace` |
| `Text.NameCase` | `Normal`, `Upper`, or `Lower` |
| `Text.MaxNameLength` | Truncation limit |
| `Text.DistanceDecimals` | Zero to three decimals |
| `Text.TopOffset`, `Text.BottomOffset` | Box-to-label offsets |
| `Text.Spacing` | Distance between stacked labels |
| `Text.TeamBrackets`, `Text.ToolBrackets` | Optional label brackets |

## Health bar

| Path | Purpose |
|---|---|
| `HealthBar.Enabled` | Master state |
| `HealthBar.Position` | `Left`, `Right`, `Top`, or `Bottom` |
| `HealthBar.Width` | Fill width |
| `HealthBar.Offset` | Distance from the box |
| `HealthBar.Outline` | Background outline |
| `HealthBar.Text` | Numeric value at the current health point |
| `HealthBar.Transparency` | Fill opacity |
| `HealthBar.BackgroundTransparency` | Background opacity |
| `HealthBar.ColorMode` | Shared color mode |

## Tracers

| Path | Purpose |
|---|---|
| `Tracer.Enabled` | Master state |
| `Tracer.Origin` | `Bottom`, `Center`, `Mouse`, `Top`, or `Custom` |
| `Tracer.Target` | `Bottom`, `Center`, or `Top` of bounds |
| `Tracer.OriginX`, `Tracer.OriginY` | Normalized custom viewport point |
| `Tracer.TargetOffsetX`, `Tracer.TargetOffsetY` | Final target pixel offset |
| `Tracer.StartPadding`, `Tracer.EndPadding` | Shortens the line at either end |
| `Tracer.Thickness` | Main line thickness |
| `Tracer.Transparency` | Line opacity |
| `Tracer.Outline` | Contrast outline |
| `Tracer.ColorMode` | Shared color mode |

## Skeleton, head dot, arrows, and Highlight

`Skeleton.ColorMode`, `HeadDot.ColorMode`, `OffscreenArrow.ColorMode`, and `Highlight.ColorMode` accept `Custom`, `Primary`, `Gradient`, `Health`, `Visibility`, or `Rainbow`.

Skeleton settings include `Enabled`, `Thickness`, `Transparency`, `Outline`, and `MaxJoints`. Motor6D pairs are cached and work with R6, R15, and custom Motor6D rigs.

Head dot settings include `Enabled`, `Filled`, `Radius`, `Sides`, `Thickness`, `Transparency`, `Outline`, `ScaleWithDistance`, `MinimumRadius`, and `MaximumRadius`.

Off-screen arrow settings include `Enabled`, `Radius`, `Size`, `Filled`, `Transparency`, `Outline`, `Pulse`, `PulseSpeed`, `ShowName`, `ShowDistance`, and `TextSize`.

Highlight settings include `Enabled`, `FillTransparency`, `OutlineTransparency`, `DepthMode`, `HealthColor`, and `ColorMode`. Highlight creates native Roblox instances only while it is enabled.

## Crosshair

The optional crosshair is independent from entity rendering and shares the renderer scheduler.

| Path | Purpose |
|---|---|
| `Crosshair.Enabled` | Master state |
| `Crosshair.Position` | Viewport `Center` or `Mouse` |
| `Crosshair.Size` | Arm length |
| `Crosshair.Gap` | Static center gap |
| `Crosshair.Thickness` | Arm thickness |
| `Crosshair.Transparency` | Opacity |
| `Crosshair.Outline` | Contrast outline |
| `Crosshair.TStyle` | Hides the upper arm |
| `Crosshair.Rotate` | Enables continuous rotation |
| `Crosshair.RotationSpeed` | Degrees per second |
| `Crosshair.Pulse` | Animates the center gap |
| `Crosshair.PulseSpeed` | Pulse frequency |
| `Crosshair.PulseMinimum`, `Crosshair.PulseMaximum` | Pulse gap range |
| `Crosshair.CenterDot` | Center dot state |
| `Crosshair.CenterDotRadius` | Dot radius |
| `Crosshair.CenterDotFilled` | Filled or outlined dot |

## Colors and distance fade

`Colors.Mode` accepts `Entity`, `Static`, `Team`, `Health`, `Visibility`, or `Rainbow`. Entity mode selects `Colors.Enemy`, `Colors.Team`, `Colors.NPC`, or `Colors.Part` from the current entry.

Dedicated colors are available for the box gradient, tracer, skeleton, head dot, arrow, visible and occluded states, outline, text, low and high health, Highlight fill and outline, and crosshair.

Distance fade is disabled by default. `Fade.Start` is the normalized fraction of the current maximum distance where fading begins. `Fade.Minimum` is the opacity at maximum range. `Fade.OccludedMultiplier` can soften occluded visuals without changing their colors.

```luau
ESP:ApplySettings({
    Fade = {
        Enabled = true,
        Start = 0.55,
        Minimum = 0.2,
        OccludedMultiplier = 0.45,
    },
})
```

## Players and per-entry metadata

```luau
ESP:WrapPlayers({
    Category = "Players",
    Priority = 20,
    Flags = function(Player, Character)
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        return Humanoid and Humanoid.Sit and { "SITTING" } or {}
    end,
})
```

Entry metadata:

| Field | Purpose |
|---|---|
| `Id` | Stable custom entry ID |
| `Kind` | `Player`, `NPC`, or `Part` |
| `Name`, `Team`, `Tool`, `Flags` | Static values or protected resolver functions |
| `Category` | Filter and category-profile key |
| `Predicate` | Game-specific visibility rule |
| `Color`, `GradientColor` | Per-entry color overrides |
| `MaxDistance`, `TextDistance` | Per-entry distance overrides |
| `Priority` | Selection weight for a limited renderer |
| `AllowedVisuals` | Per-entry visual mask |

Supported visual-mask keys are `Box`, `Name`, `Team`, `Distance`, `Tool`, `HealthText`, `Category`, `Flags`, `HealthBar`, `Tracer`, `Skeleton`, `HeadDot`, `OffscreenArrow`, and `Highlight`.

## NPCs

```luau
local NPCWatcher = ESP:WatchNPCs(workspace.NPCs, {
    Category = "Hostile",
    Priority = 50,
    Name = function(Model)
        return Model:GetAttribute("DisplayName") or Model.Name
    end,
    Flags = function(Model)
        local Level = Model:GetAttribute("Level")
        return Level and { "LVL " .. tostring(Level) } or {}
    end,
    Predicate = function(Model)
        return Model:GetAttribute("Hidden") ~= true
    end,
    AllowedVisuals = {
        Tracer = false,
    },
})

Library:OnUnload(function()
    NPCWatcher:Destroy()
end)
```

NPC scanning is opt-in. Use a dedicated NPC folder when possible instead of watching all descendants of Workspace.

## Parts, loot, and world objects

```luau
local Id = ESP:WrapObject(workspace.SupplyCrate, {
    Kind = "Part",
    Name = "Supply crate",
    Category = "Loot",
    Priority = 10,
    MaxDistance = 1200,
    Flags = { "RARE", "$2500" },
    AllowedVisuals = {
        Skeleton = false,
        HeadDot = false,
        Highlight = false,
    },
})

ESP:UnwrapObject(Id)
```

## Category profiles

Category styles avoid repeating colors, distance limits, and masks on every wrapped object.

```luau
ESP:SetCategoryStyle("Loot", {
    Color = Color3.fromRGB(185, 151, 229),
    GradientColor = Color3.fromRGB(225, 211, 244),
    MaxDistance = 1400,
    AllowedVisuals = {
        Tracer = false,
        Skeleton = false,
        HeadDot = false,
    },
})
```

Per-entry values override category colors and distances. A visual is enabled only when both the category mask and entry mask permit it. Pass `nil` as the style to remove a category profile.

## Whitelist, blacklist, and ignored objects

```luau
ESP:SetFilterList("PlayerName, 12345678, Hostile")
ESP:Set("FilterMode", "Whitelist")

ESP:SetIgnored(workspace.TemporaryObject, true)
ESP:SetIgnored(workspace.TemporaryObject, false)
```

The filter compares normalized entry IDs, object names, usernames, display names, user IDs, and category names. Matching can be exact, substring-based, or prefix-based. `SetIgnored` changes visibility without destroying or recreating the entry.

## Live R6 preview

The preview adapter uses the same box, text, health, colors, and settings as the live renderer.

```luau
local LiveRenderer = ESP:CreatePreviewAdapter()
local Preview = VisualPreview.CreateEmbedded(Library, PreviewGroup, {
    Id = "ProductionESPPreview",
    Name = "ESP preview",
    Target = game:GetService("Players").LocalPlayer,
    Height = 320,
    Renderer = LiveRenderer,
})
```

The default adapter follows controller settings. `{ UseContext = true }` allows a component showcase to override box, name, team, distance, weapon, and health visibility from its preview context.

## Presets and performance

| Preset | Intended use |
|---|---|
| `Performance` | Large NPC populations and weak frame budgets |
| `Balanced` | Default player and moderate NPC workloads |
| `Quality` | Higher refresh and visibility checks |

Recommended production setup:

- Set `MaxRendered` to the maximum number of meaningful nearby targets.
- Use `SortMode = "Priority"` and per-entry priorities when objectives must win over ordinary entities.
- Keep `TextDistance` shorter than `MaxDistance`.
- Disable `VisibilityCheck` unless occlusion state is needed.
- Use `Box.Dynamic = false` when approximate character bounds are acceptable.
- Disable skeletons and Highlights for large NPC collections.
- Keep NPC watchers scoped to a dedicated container.
- Use one controller instead of separate frame loops for each feature.
- Always call `Destroy` during unload.

Visibility results, labels, and Motor6D joints use independent caches. With `MaxRendered = 0`, the renderer avoids candidate sorting and renders entries directly.

## Troubleshooting

### Nothing is visible

Check `UniversalESP.Available`, `ESP.Settings.Enabled`, the class toggle, `MaxDistance`, `FilterMode`, and the entity budget. A whitelist with an empty list intentionally shows nothing.

### NPCs are missing

`NPCs = true` only permits wrapped NPC entries. Call `ScanNPCs`, `WatchNPCs`, or `SetAutomaticNPCs` to create them.

### Colors do not match entry types

Set `Colors.Mode = "Entity"`. `Static`, `Health`, `Visibility`, `Team`, and `Rainbow` intentionally replace entity colors.

### Old drawings remain after reload

Keep the controller in one variable and call `ESP:Destroy()` before starting another copy. Do not create multiple controllers for the same entity list.

### Highlight is unwanted

Keep `Highlight.Enabled = false`. No Highlight instance is created while it is disabled.

## Changelog

### 1.1.0

- Added entity budgets with distance, priority, and name selection.
- Added normalized whitelists, blacklists, category matching, and ignored-object state.
- Added category profiles with shared colors, distance limits, and visual masks.
- Added independent box scale, padding, corner proportions, and size clamps.
- Added complete text formatting, unit conversion, line spacing, and label masks.
- Added shared component color modes and distance-aware opacity.
- Added custom tracer origins, offsets, padding, and color modes.
- Added scalable head dots and labeled, pulsing off-screen arrows.
- Added an animated center or mouse crosshair with T style, rotation, pulse, and dot controls.
- Added the expanded MonHub settings panel and updated public types.

### 1.0.0

- Added one standalone renderer for Players, NPCs, Models, and BaseParts.
- Added full, corner, and projected 3D boxes, text, health bars, tracers, skeletons, head dots, off-screen arrows, and Highlight.
- Added player lifecycle tracking, manual wrapping, NPC scanning, live NPC watchers, presets, statistics, preview integration, and deterministic cleanup.
