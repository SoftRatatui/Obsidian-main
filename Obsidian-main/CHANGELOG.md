## 22.08.2026

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
+ Changed the default AddToggle presentation to a compact 16x16 square checkmark with a restrained 3px radius
+ Kept the legacy sliding switch available through Library.ForceCheckbox = false
+ Rebuilt keybind rows around a fixed horizontal layout with a 14x14 checkmark and deterministic alignment
+ Replaced fractional checkmark scaling with fixed-size antialiased glyphs and opacity-only motion for cleaner small-pixel rendering

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

## 19.08.2026

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

## 18.08.2026

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
+ Centralized click sound with Library:SetClickSound
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

## 17.08.2026

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

## 12.08.2026

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

## 11.07.2026

```diff
[changes]
+ Loading configs now triggers element callbacks even if their value hasn't changed
```

## 09.07.2026

```diff
[changes]
+ Background Image now supports external URLs using getcustomasset
```

## 07.07.2026

```diff
[features]
+ Dropdown.DragSelect, Dropdown:SetDragSelect(Value: boolean) (only works on non-touch devices and Multi dropdowns)
+ Animations.Groupbox, Animations.KeyPicker

[changes]
+ Notification appear and disappear animations are now smooth

[fixes]
+ Fixed Library.ToggleKeybind
```

## 05.07.2026

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

## 02.07.2026

```diff
[changes]
+ Save Manager and Theme Manager refactored
+ Save Manager now saves the keybind menu visibility and position
+ Save Manager and Theme Manager now show what theme is the default and what config is autoloaded inside the dropdowns

[fixes]
+ Fixed dialogs buttons breaking with Destructive buttons if ThemeManager:SetDefaultTheme was used
```

## 01.07.2026

```diff
[features]
+ Confirmation dialogs to destructive actions in Save Manager and Theme Manager
+ Groupbox collapsed state now saves in configuration files
```


## 28.06.2026

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

## 26.06.2026

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

## 21.04.2026

```diff
[features]
+ SaveManager:SetLoadingOrder(enabled: boolean, order: { })
```

## 05.04.2026

```diff
[features]
+ Library.Scheme.DestructiveColor
+ Library:CreateLoading(LoadingInfo)
~ Read documentation at http://docs.mspaint.cc/obsidian/core/library/loading
```

## 03.04.2026

```diff
[features]
+ Tab:SetVisible()
```

## 28.03.2026

```diff
[features]
+ Dropdown.FormatListValue(Value)
  - Randomized formatting will not be preserved as the function is called every time the context menu is rebuilt
```

## 24.03.2026

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

## 17.03.2026

```diff
[features]
+ Window:SetCornerRadius(Radius: number)

[fixes]
+ Fixed Window:SetFooter not changing the label text
+ Fixed footer background not properly resizing
+ Fixed Tab buttons not respecting corner radius
```

## 16.01.2026

```diff
[features]
+ Library:ResetCursorIcon()
+ Library:ChangeCursorIcon(ImageId: string)
+ Library:ChangeCursorIconSize(Size: UDim2)
```

## 30.12.2025

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

## 18.12.2025

```diff
+ Patched static key bypass inside Key Box
    * The AddKeyBox function now only takes the callback function
    * The callback function only returns the provided key, you need to implement your own handler inside the callback
```

## 09.11.2025

```diff
+ Added Library.ImageManager (https://docs.mspaint.cc/obsidian/core/library/utility#custom-asset-icons)
```

## 02.11.2025

```diff
+ Warning Box now follows the UI style of Obsidian (rounded corners with outlines)
+ Watermark now correctly resizes itself with new line characters
```

## 01.11.2025

```diff
+ The ignored indexes (SaveManager.SetIgnoreIndexes) are no longer applied when you load a configuration that contains them
```

## 5.10.2025

```diff
+ Added support for modifier keys in KeyPicker (for example: LCtrl + E)
+ Fixed DoClick not calling the correct callbacks
```

## 17.09.2025

```diff
+ Added support for custom icons (rbxasset, rbxassetid, rbxthumb, getcustomasset) for Tabs and Groupboxes
```

## 14.09.2025

```diff
+ Added `Press` mode to `KeyPicker`
```

## 19.08.2025

```diff
+ Fixed `KeyPicker` in Toggle mode not working properly when Key is nil
```

### 12.08.2025

```diff
+ Fixed `Tab:UpdateWarningBox()` not resizing properly
```

### 10.08.2025

```diff
+ Added a LockSize option `Tab:UpdateWarningBox()` to set the maximum size of the warning box to 3.25 size of the Tab Container (optional)
+ Added support for mouse button 3 (middle click)
```

### 17.07.2025

```diff
+ Added Description parameter to `Window:AddTab()` method to set a description for the tab
+ Updated `Window:AddTab()` method to accept a table with Name, Icon, and Description or a table with Name, Icon (optional), and Description (optional)
+ Updated `Library:CreateWindow()`'s WindowInfo parameter to include a `DisableSearch` option to disable the search box in the window
```

### 15.07.2025

```diff
+ Added watermark support to the library
+ Added `Library:SetWatermarkVisibility()` method to toggle the visibility of the watermark
+ Added `Library:SetWatermark()` method to set the watermark text
```

### 14.07.2025

```diff
+ Added `AddImage` component
```

### 13.07.2025

```diff
+ Updated lucide icons to the latest version
+ Changed lucide icons to be using `getcustomasset` to bypass ContentProvider detections
+ Added `AddViewport` component
```

### 12.07.2025

```diff
+ Added `ThemeManager:SetDefaultTheme()` method to set the default theme for the library
+ Improved `Library:SafeCallback()` to handle errors correctly and return everything correctly (previously it would only return the first return value)
+ Added `BackgroundImage` parameter to `Window` constructor to set a background image for the window
```

### 02.07.2025

```diff
+ Added dropdown support for `AddDependencyBox` and `AddDependencyGroupBox`
```

### 15.06.2025

```diff
+ Fixed Obsidian's `Library:Validate()` function to ignore arrays (setting modes option on AddKeyPicker would fail previously)
```

### 04.06.2025

```diff
+ Added Notify.Persist and Notify:Destroy() methods to make persistent notifications easier to manage
+ Added Icon parameter to Groupbox constructor that matches the accent color.
```

### 17.05.2025

```diff
+ Added a new `AddDependencyBox` and `AddDependencyGroupBox` methods to the `Groupbox` class
```

### 18.01.2024

```diff
+ Added a Hover Animation to Buttons
+ Added Risky to Buttons
+ Changed Toggle's Checkbox to Switch (Checkbox is still possible with AddCheckbox)
+ Dropdown disabled values moved to the bottom
+ Fixed DPI Scale issues (Title Wrapping, Slider Fill Bar and Dropdown Menu Size)
```
