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
