# MonHub update log

This is the markdown changelog. Older release-3 notes and short examples stay in
[UPDATE_LOG.txt](UPDATE_LOG.txt); this file continues from there and covers the
current session grouped by area.

## !! VERSION NUMBER IS UNRESOLVED - OWNER DECISION NEEDED !!

Do not treat any single number below as correct. Three sources disagree right now and
none of them has been changed to match the others. Read this before you cite a version
anywhere.

| Source | File / location | Claims |
| --- | --- | --- |
| Runtime constant | `Library.lua`, `ReleaseVersion = "0.0.1-release-3"` (around line 249) | `0.0.1-release-3` |
| Addon constants | `addons/MetricsPanel.lua`, `addons/Onboarding.lua` (`ReleaseVersion` fields) | `0.0.1-release-3` |
| This file and README | `UPDATE_LOG.txt`, `README.md` | `0.0.1-release-3` |
| Guide header | `GUIDE.md` line 3 and its `RELEASE` constant | `0.0.1-release-3` |
| Guide changelog | `GUIDE.md` changelog section | lists `release-15`, `release-14`, `release-13`, `release-12`, `release-11`, `release-10`, `release-9`, with the `release-3` entry placed **above** all of them and out of order |
| Owner, verbally | not written in any file | `0.0.1-release-12`, and told the team not to change it |

So the code says `release-3`, the guide's own changelog implies work up to `release-15`
exists, and the owner has said the number is `release-12`. These cannot all be right.

Nothing here changes a version string, and no new number was invented. When the owner
picks the authoritative value, aligning the rest is one edit per location:

1. `Library.lua` `ReleaseVersion` (this is the value the cache-busting URL parameter is
   built from - see the versioning section below, item on stale caches).
2. `addons/MetricsPanel.lua` and `addons/Onboarding.lua` `ReleaseVersion`.
3. `GUIDE.md` line 3, its `RELEASE` constant, and the ordering of its changelog headers.
4. `README.md` and the two `CACHE` strings in `Example.lua` / `QuickStart.luau`.
5. The heading of the session block directly below, which is left as `UNRESOLVED` on
   purpose so it cannot be mistaken for a settled number.

Until then, quote the file you read the number from rather than a bare "the version".

## Update 2026-09-25 (version: UNRESOLVED, see the note above)

Group headers in the sidebar, a simpler sub-tab guide, new notifications, and the
UI scale fix. Numbers are measured in game unless a line says otherwise.

### Sidebar

- A tab with sub-tabs is now a group header, not a page. Clicking it expands or
  collapses the group and never opens it. Its label and icon rest one step greyer
  than ordinary tabs (`Library:GetRestingTransparency`) and its hover is fainter.
  `Tab:Show()` on a header opens its first visible child.
- The parent row no longer lights up while one of its children is open.
  `Library:AnimateTabTrail` is kept for custom sidebars, but the library no longer
  calls it.
- The sub-tab tree is now a single 1px guide from under the header icon through the
  children, ending 6px short of the last row. The open child's own segment of the
  guide turns the accent colour, with the same width and position as the line, so
  the marker cannot land half a pixel off it. The horizontal branches, the lit path
  and the separate 2px rounded marker are gone.
- Swipe and keyboard tab switching skip headers and reach children of collapsed
  groups.

### Notifications

- Each card has a tinted icon tile in the variant colour: `info` by default,
  `circle-check` for success, `triangle-alert` for warning, `circle-x` for error and
  danger. `Icon` replaces it, `Icon = false` removes it.
- Title 13px in the body colour, description 12px muted. A card with a single line
  of text shows it in the body colour at title size, centred against the tile.
- A 2px countdown line runs along the whole bottom edge in the variant colour, just
  inside the outline. It is cut from a shape with the card's corner radius, so its
  ends follow the rounded corners (`ShowProgress` now defaults to on). The countdown
  pauses while the cursor is over the card.
- Cards slide in 14px from the screen edge while fading in, and slide back out. They
  used to drop 3px.
- New defaults: width 280, margin 10, gap 6, padding 10, corner radius 6, duration
  4 s. The outline is a little stronger and the close icon brightens on hover.

### UI scale

- Changing the UI scale no longer breaks the menu. Several places read on-screen
  sizes (`AbsoluteSize`, which already includes the scale) and wrote them back as
  offsets, applying the scale twice: the two-column split, key tab boxes, resize
  handles, dividers, addon hosts, slider tracks, and button and tabbox content
  centring. Another 14 places used the library scale where the element sat under a
  different one. New helpers: `Library:GetEffectiveScale(Instance)` and
  `Library:LogicalSize(GuiObject)`.

### Verification

- Every visible element recorded at 100% and compared at 150%: 0 of 85 off. At
  125%: 2 of 195 off by 2px, both text widths, since Roblox rounds font sizes and
  text cannot scale exactly linearly. Before the fix, 102 of 192 were off at 150%.
- At 100%, 1 visible object sits on a fractional size, the progress bar fill, which
  is proportional by design. The guide segments sit in one column (x = 579) with no
  gaps between rows.
- Notifications checked on screen at 100%, 200% and 300% in all four variants. A
  first draft drew the countdown line one layer below the card, so the card covered
  it and only its ends showed past the rounded corners. A second draft inset the
  line by the padding, which read as a stub. The line now draws on the card's own
  layer, spans the full width and follows the corner radius.

## Update 2026-09-24 (version: UNRESOLVED, see the note above)

Denser layout, a reworked sidebar, three new themes, light theme fixes and a
segmented watermark. Numbers are measured in game unless a line says otherwise.

### Density

- Control rows are 20px instead of 24px in the `Compact` preset, which desktop uses
  by default. Checkboxes now sit 26px apart instead of 33px, so rows without a
  slider no longer look looser than rows with one. `Touch` (44px) and
  `Comfortable` (30px) are unchanged. Checked by geometry only; see Verification.
- `Grid.RowGap` now sets the gap between controls in a groupbox: 6px in `Compact`,
  8px in `Comfortable`, 10px in `Touch`. The token existed before, but nothing read
  it, so switching density never changed the spacing.
- Groupbox header 38px to 32px, groupbox padding 9px/13px to 6px/9px (top/bottom),
  top bar 52px to 44px, content padding and column gap 12px to 10px.
- Sidebar 214px to 184px wide, tab rows 38px to 32px.
- A groupbox with five toggles went from 216px to 171px tall (computed from the
  tokens, not measured).

### Sidebar

- The selected tab fills its row from edge to edge, with a full-height 2px accent
  bar on the left. Tab rows are square (`Shell.NavigationRadius`, default 0) and
  stack without gaps. The old pill touched both sidebar edges but sat 7px below
  the divider, which read as crooked.
- `Window:AddTabSeparator(Text?)` groups tabs: a caption with text, a thin line
  without. In the compact, icon-only sidebar the caption turns into a line.
- Sub-tabs hang off a tree of straight 1px lines: a stem from under the parent's
  icon, a trunk that stops at the last child, and a branch into each child
  (`├─`, `└─`). Child rows are 28px and indented 20px. The path to the open child
  (stem, trunk, its branch) is lit in the accent colour, and the parent row stays
  lit too (`Library:AnimateTabTrail`), so the path reads without a second tab
  strip above the content. An earlier draft used thin rounded strokes, which
  rendered unevenly and left a gap under the parent icon; the tree hides in the
  compact sidebar.
- The tab list starts flush under the header. It had a 6px empty strip on top.
- Fixed: at a UI scale other than 100%, an expanded sub-tab group was sized in
  screen pixels and grew by the scale factor, leaving an empty gap under it (twice
  the needed height at 200%). The height now comes from the logical row sizes.

### Themes

- `Default` separates its layers more (contrast step background to surface 1.057
  to 1.079, surface to element 1.103 to 1.145) and uses a more saturated accent,
  `#9A8CF5`, 84% saturation instead of 63%. Body text 15.7:1, muted text 6.4:1.
- New themes:

  | Theme | Kind | Accent | Body text | Muted text |
  | --- | --- | --- | --- | --- |
  | `Dusk` | dark, Rosé Pine based | soft rose `#EBBCBA` | 12.5:1 | 5.1:1 |
  | `Dawn` | light, warm paper | dusty rose `#BA6679` | 8.3:1 | 4.8:1 |
  | `Honey` | light, cream | deep amber `#B0701A` | 9.3:1 | 5.1:1 |

  Aliases: `dusk`, `rosepine`, `dawn`, `rose`, `pink`, `light`, `honey`, `amber`.
  All three are registered in the ThemeManager gallery as built-ins.
- ThemeManager's own `Default` palette table now matches the library. It still held
  a grey `#858DA0` accent that the gallery and older code paths read.

### Light theme fixes

- The contrast picker used for checkmarks on the accent could pick light on light,
  because its dark candidate was the (light) background.
- `Library.IsLightTheme` is now derived from background brightness, so a light
  palette previewed through `SetPalette` is treated as light too. Before, only
  `SetTheme` set it.
- A disabled switch knob got brighter instead of dimmer on light themes.
- The sidebar divider hover faded into a light background instead of highlighting.
- The groupbox collapse arrow was white and disappeared on light themes.
- Inactive tab labels and unchecked toggle labels fell to about 2.4:1 on light
  themes. `Library:GetIdleTransparency(Base?)` dims less on light themes, and
  switching theme reapplies the resting state to rows already built.

### Watermark

- `Library:SetWatermarkSegments(Segments)` draws the watermark as segments, each an
  optional Lucide icon plus text with `{token}` substitutions, split by thin
  vertical dividers. `Accent = true` colours a segment, meant for the hub name.
- The watermark keeps refreshing while the menu is closed. It used to stop together
  with the menu, which froze FPS and ping during play. Checked with the menu closed:
  ping 98 ms to 70 ms and FPS 113 to 67 within three seconds.
- `{fps}` counts rendered frames. It used `workspace:GetRealPhysicsFPS()`, the
  physics rate, which sits near 60 whatever the real frame rate is. The counter
  runs only while the watermark is visible and uses `{fps}`.
- New `{executor}` token, from `identifyexecutor()` when available.

### Fixes

- A centred window on an odd-width viewport landed on a half pixel (x = 275.5 on a
  1451px viewport), shifting every element inside it by half a pixel. It now
  centres on whole pixels.

### Not shipped

- The elevation, glass and grey-theme refresh started on 2026-09-21 was reverted
  before release. It is kept on the git tag `refresh-v2-backup` and in the stash
  `refresh-v2-uncommitted`.

### Verification

- In game with `Honey` active: 0 of 118 visible objects on fractional positions or
  sizes. Theme switching takes 4 ms.
- Sub-tabs in game at 200% scale: the stem and trunk sit in one column with 0 gaps
  from the parent row through the last child; switching the open child moves the
  lit path correctly; no empty gap under expanded groups.
- The 20px row change was first checked by geometry only (checkbox 16px with 2px
  margins, switch track 14px, key picker 18px, swatch 16px, all on whole pixels).
  It was seen on screen on 2026-09-25 at 100% and 200%: checkbox, key picker and
  plain rows sit at an even pitch.
- `tests/check.ps1` was not run; the luau toolchain is not installed here.

## Session changes (version: UNRESOLVED, see the note above)

Everything below was read back out of the actual code before it was written down. A
feature that could not be found in `Library.lua` or an addon is not listed here; the
ones that were expected but are absent are in the "Not landed" section at the end.

### Sidebar sub-tabs

- `Tab:AddSubTab(...)` creates a child tab under a sidebar tab. `Tab.SubTabs` holds the
  children, `Tab:SetExpanded(state)` and `Tab:IsExpanded()` control and read the group.
- A chevron expander sits on any tab that has children. Groups start collapsed. Selecting
  a child auto-expands its parent, and compacting the sidebar force-expands every group so
  a child never becomes unreachable.

### Mobile and touch

- Density presets: `Library.DensityPresets` holds `Comfortable`, `Compact` and `Touch`.
  `Library:SetDensity`, `Library:ResolveDensity` and `Library:ApplyDensity` select and
  apply them. `Touch` raises `Grid.Row` to 44, `TrackRow` to 20, `Thumb` to 18,
  `Indicator` and `Swatch` to 24, and `NavigationHeight` to 44. `ResolveDensity` with
  `Auto` returns `Touch` on mobile and `Compact` otherwise, and any non-`Touch` choice is
  overridden to `Touch` while `Library.IsMobile` is true.
- Real swipe between tabs: `Library:SetTabSwipeEnabled(enabled)`,
  `Library:GetOrderedTabs()` and `Library:SwitchTabRelative(delta)` are the actual touch
  gesture. The older `TabSwipeOffset`, `TabSwipeFrom` and `TabSwipeDirection` settings are
  only the tab-enter slide animation and are not the gesture. The names have misled people
  before, so keep them separate.
- Input capture: `Library:SetInputCapture`, `Library:ResolveInputCapture`,
  `Window:SetInputCapture` and per-control `Info.CaptureInput`. This is what stops a tap
  inside the menu from also firing the player's gun.
- Haptics: `Library:Vibrate(Kind)` with `Library.HapticsEnabled` as the switch.
  `Library.Env.Haptics` reports whether the device actually supports vibration (it probes
  `HapticService:IsVibrationSupported` behind a `pcall`).
- Cursor: `Library:SetCursorVariant` and `Library:SetCustomCursorEnabled`. The custom
  cursor stays off on touch.
- Safe area: top inset is read through `GuiService:GetGuiInset` behind a `pcall` so a
  notch does not sit under the header.
- Scrollbars auto-hide and react to touch through `ConfigureAutoScrollbar` with idle and
  hover transparency.
- Truncation is UTF-8 aware (`utf8.len` / `utf8.offset`), so cutting a Cyrillic label no
  longer splits a character and corrupts the string.

### New controls

- Added `Funcs:AddSegmented`, `AddBadge`, `AddEmptyState`, `AddDetailList`,
  `AddSettingsCard`, `AddSplitButton`, `AddSteps` and `AddSkeleton`.
- Dropdown `Info.Chips`.
- Input `Info.Multiline`, `Mask`, `Prefix`, `Suffix`, `Clearable` and `Copyable`.
- Validation: `Info.Validate` with `Control:SetError` and `Control:ClearError`.
- `Button:SetState` takes `Idle`, `Loading`, `Success` or `Error` (invalid states assert).
- Progress `Info.Indeterminate` and `Info.Segments`.
- `Tab:SetBadge(Text, Style)`.
- Control gating: `VisibleWhen` and `EnabledWhen` options.

### Runtime, reactivity and the declarative builder

These have existed for a while with no guide coverage, so they are recorded here.

- State: `Library:State(default)` returns a value with `Get`, `Set` and `Subscribe`.
  `Library:Observe` watches it.
- Pooling and virtualization: `Library:CreatePool(template, factory)` with `Acquire`,
  `Release` and `Trim`; `Library:CreateVirtualList(scroll, info)`.
- Scheduling: `Library:SetBuildBudget(ms)`, `Library:QueueBuild`, `Library:RequestLayout`,
  `Library:QueueFrame`.
- Errors: `Library:SafeCallback`, `Library:OnError`, `Library:ReportError`, and the
  `Library.Env` capability table (`Drawing`, `CustomAsset`, `Clipboard`, `Request`,
  `FPSCap`, `Haptics`).
- Control access: `Library:GetControl`, `Library:GetAll`, `Library:ForEach`,
  `Library:SearchControls`, `Library:RevealControl`, `Library:ResetScope`,
  `Library:ResetDefaults`, `Window:Reset`.
- History: `Library:EnableHistory`, `Library:RecordChange`, `Library:Undo`,
  `Library:Redo`, `Library:GetRecentChanges`.
- Commands and favorites: `Library:RegisterCommand`, `Library:OpenCommandPalette`,
  `Library:EnableCommandKeys`, `Library:SetFavorite`, `Library:GetFavorites`.
- Diagnostics: `Library:Diagnose`.
- Lazy tabs: `Window:AddLazyTab` and `Library:BuildLazyTabs`.
- Declarative builder: `Library:Create(AppInfo)` and `Library:Mount(AppInfo)` build a
  window from a table. Element types map through `DeclarativeElementMethods`: `table`,
  `chart`, `log`, `statrow`, `progressbar`, `button`, `checkbox`, `divider`, `dropdown`,
  `image`, `input`, `label`, `slider`, `toggle`, `uipassthrough`, `video`, `viewport`,
  `imagegrid`, `itemslots`, `slidergroup`, `segmented`, `badge`, `emptystate`,
  `detaillist`, `settingscard`, `splitbutton`, `skeleton` and `steps`.

### Config reliability and profiles (addons/SaveManager.lua)

- Loading is resilient per entry instead of all-or-nothing. A malformed object is skipped
  with a reason rather than rejecting the whole file, a throwing callback no longer rolls
  back the load, and a partial load is kept.
- The report carries `Applied`, `Unchanged`, `Skipped`, `Failed` and `Missing` with a
  reason per entry.
- New API: `SaveManager:LoadSummary`, `FormatLoadReport`, `SetApplyMode`, `Apply`,
  `RunApplyBatch`, `SetBackupCount`, `ListBackups`, `RotateBackup`, `RestoreBackup`,
  `WriteRecoverySnapshot`, `CheckRecovery`, `RestoreRecovery`, `ClearRecovery` and
  `PreviewConfig`.

### Themes (addons/ThemeManager.lua)

- `BuildGallery` / `RebuildGallery` render colour-swatch preview cards.
- `PreviewTheme`, `ApplyPreview` and `CancelPreview` try a theme without committing.
- `UpdateContrast` warns when a pair drops below WCAG 4.5:1 and offers a one-tap fix.
- Clipboard export and import of a theme code.
- Three accessibility palettes: `Deuteranopia`, `Protanopia` and `HighContrast`.

### Gallery virtualization

- `ImageGallery` and `TextureGallery` now scroll one continuous virtualized collection
  through `Library:CreateVirtualList`, with lazy images.
- `SetPage`, `NextPage` and `PreviousPage` are no-op scroll shims kept for compatibility,
  and the page cap is gone.

### New addons

- `addons/MetricsPanel.lua`: a metrics panel with sampled series (`AddChart`, rolling
  samples capped at 120 points, min/max/avg). Embedded and standalone placement through
  `MetricsPanel.CreateEmbedded` and `MetricsPanel.CreateStandalone`.
- `addons/Onboarding.lua`: an onboarding flow, embedded or standalone through
  `Onboarding.CreateEmbedded` and `Onboarding.CreateStandalone`.

### Regression tests (tests/)

- Added `Api.spec.luau`, `Layout.spec.luau`, `Runtime.spec.luau` and `Addons.spec.luau`
  alongside the existing `SaveManager`, `Overlays`, `EditorControls`, `CollectionModel`,
  `ThemeManagerPersistence`, `Typography`, `TextBounds` and `Loader` specs. Run them with
  `tests/check.ps1`.

### Not landed (do not document as shipped)

These were expected this session but are absent from the code today. Grep before adding
them; right now they should stay out of the guide and README.

- Notifications: `Info.Actions`, grouping with a counter,
  `Library:GetNotificationHistory` / `ShowNotificationHistory`, `Info.Priority` /
  `Info.Category`, `Library:SetNotificationFilter`, `Library:SetNotificationAnchor`, and a
  bottom `Line` mode. Only `Library:SetNotificationOptions` (alias `SetNotifyOptions`)
  exists.
- Watermark tokens: `Library:SetWatermarkFormat` and `RegisterWatermarkToken`.
- Sound: `Library:PlaySound`, `SetSoundEnabled`, `SetSoundVolume`.
- `Library:SetStreamerMode`.

## Versioning going forward

### The scheme

Use semantic versioning for the public number: `MAJOR.MINOR.PATCH`.

- `MAJOR`: an API break, when existing calls stop working or change meaning.
- `MINOR`: new controls or options that do not break existing code, like this session's
  new controls and the declarative builder.
- `PATCH`: fixes with no API change.

The `-release-N` label is a separate publishing counter and does not track API surface,
which is a large part of why the numbers above disagree. Keep the release label if you
want, but drive user-facing decisions off the semver number, and bump the semver number by
the rule above rather than by how many times files were pushed.

### Stale caches on a reused label (roadmap item 114)

`Library.lua` builds a cache-busting query parameter from `ReleaseVersion`. In
`LoadBundledFont` the download URL gets:

```lua
URL ..= (string.find(URL, "?", 1, true) and "&monhub=" or "?monhub=") .. tostring(Library.ReleaseVersion)
```

The failure: when a new revision is published under an existing release label, the label
does not change, so this parameter does not change, so the executor or CDN cache key is
identical and the old file is served. Users stay on a stale copy even though a new revision
shipped. The main-file loader in `Example.lua` hides this for `Library.lua` itself because
its `CACHE` string appends `os.time()`, which busts on every run, but the bundled-font URLs
above have no such salt and rely on the label alone.

The recommendation: add a distinct revision field separate from the release label, for
example `Library.Revision`, incremented on every publish even when the label is unchanged,
and build the cache parameter from `Revision` (or from `ReleaseVersion .. "-" .. Revision`)
instead of the label alone. Then a republish always produces a new cache key and no viewer
is left on a stale copy. This also removes the reliance on `os.time()` in the loader, which
busts too aggressively and defeats caching entirely.
