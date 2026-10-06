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

## Update 2026-10-06 (version: UNRESOLVED, see the note above)

Loading for players who cannot reach GitHub reliably. Checked in game with a
simulated network; not checked from inside Russia.

### Loader

- `dist/version.txt` holds `<hash>-<bytes>` of the build. The loader reads it first
  (a few bytes) and runs the stored copy when the version matches, so a normal start
  downloads nothing else. Before, every start downloaded 927 KB.
- 5 second budget for the network part. A downloaded file is accepted only if it
  compiles and its size equals the size in `version.txt`; the previous check was
  compilation alone.
- Fallback order: fresh download, stored copy in `MonHub/cache/`, copy embedded in
  the hub, then a clear error. After a fallback the loader keeps downloading in the
  background for up to two minutes and stores the result.
- The mirror that answered is stored and tried first next time. With GitHub raw
  hanging, the first start takes about 1.4 s and the second 0.2 s in the simulation.
  Mirrors start one second apart instead of two.
- `MonHubLoad()` takes no arguments now (it was `MonHubLoad("Library.lua")`).
  `MonHubConfig` replaces the loose settings: `Repo`, `Branch`, `Folder`, `Cache`,
  `Timeout`, `Stagger`, `Extra`, `Embedded`, `Get`.
- `tools/embed_hub.py` writes a copy of a hub with the library embedded and its
  downloads replaced by `MonHubLoad()` and `Library.Addons.Name`. Both current hubs
  were converted and compile (BloxStrike 1.3 MB, Jump For Animals 1.0 MB); they were
  not run.
- `.gitattributes` forces LF in `dist/`. The repository normalises line endings, and
  a CRLF copy would differ from the byte count in `version.txt` and be rejected.

### Stale CDN copies

- Measured with the real mirrors after the first push of `dist/`: GitHub raw,
  raw.githack and four jsDelivr routes all answered with 200 in 0.4 to 1.7 s, but
  `Library.lua` was not the same everywhere: raw 949416 bytes (an older push),
  jsDelivr 949175 bytes (an even older one), against 949475 in the repository, while
  `version.txt` was current on all of them. A loader that trusts a mirror would have
  run an old build; the size check refused it, which in a region where jsDelivr is the
  only route means no hub at all.
- The build now also writes `dist/Library.<hash>.lua`, and `version.txt` names it.
  A new file name has never been cached, so it cannot be stale, and an old
  `version.txt` still points at a file that exists because the last five builds are
  kept. The loader asks for the pinned file first and falls back to `Library.lua`.
  Git stores both names as one blob.
- statically.io is removed from the list: it served `version.txt` but timed out on
  the 950 KB file after 30 s in the test. raw.githack is removed too: fetching a file
  from it ends in a redirect to `raw.githubusercontent.com`, so it is not a second
  route when GitHub raw is blocked. The list is now GitHub raw and four jsDelivr
  routes (Gcore, Fastly, main, Cloudflare); an independent route needs a host of
  your own (`MonHubConfig.Extra`).
- With the pinned file pushed, every route returned `Library.<hash>.lua` byte for byte
  identical (SHA-256) in 0.65 to 1.1 s, and the real Diagnose run on the desktop
  client downloaded it from raw and ran all steps.
- Cloudflare: its status page reported a partial outage (Asia and some data centres)
  at the time, with CDN, Pages and Workers operational and the Moscow and Saint
  Petersburg data centres operational. Only two of the six mirrors use Cloudflare, so
  an outage there does not stop the loader. Delta's own key service may sit behind
  Cloudflare; that is outside this library.
- Simulated: stale `Library.lua` next to a fresh pinned file (fresh build used),
  pinned file not published yet (alias used), only stale copies anywhere (refused,
  embedded copy used).

### Cleanup pass that stalled a frame

- Reported as the hub "lagging". A simulated hub (40 groupboxes, 4025 registry
  entries, 7644 interface objects, loaded the old way from GitHub) showed no problem
  at load (about 2.5 s with the downloads, 0.9 s to build) or at idle, and a full
  Unload took 80 ms. The one stall was `Library:PruneRuntime()`: 60 to 86 ms in a
  single frame, every 30 s, because it walked every registry entry up to the root
  and removed dead entries from the lists one by one.
- It now checks with `Instance:IsDescendantOf(game)`, works from a snapshot, yields
  every 250 checks and compacts the lists in one pass. Same hub: the sweep takes
  about 0.7 s of wall time and the worst frame during it equals a normal frame.
  Counters still return to their starting values after create and destroy cycles
  (corners 112 to 12, tweens 163 to 3 in the check).
- `tools/embed_hub.py --light` writes a hub with the loader only (9 KB added, against
  950 KB). The embedded copies are optional; a 1.3 MB script can be too much for an
  executor's editor on a phone.
- Not reproduced: a hub that "does not load at all". Loading the old way from the
  pushed repository and building the full hub worked here. The client was also
  rejoined by the game several times during this work (new server each time), which
  looks like the game's own behaviour and not the library.

### Diagnostic script

- `dist/Diagnose.lua` runs the whole start on the device and prints the result in an
  on-screen panel and to `MonHub_diagnose.txt`: executor and platform, which
  functions exist, each mirror's answer and speed, download size and compile time,
  then the library step by step with tracebacks. Run on the desktop client it
  reports every step ok in about 3 seconds. It exists because a phone user's error
  text (`attempt to index nil with 'Appearance'`, from a 7 line script) could not be
  traced: nothing in the library, the loader or the two hubs indexes a field called
  `Appearance` on anything, so the error comes from another script or from the
  executor.

### Phones (Delta and similar executors)

- The 5 second limit only makes sense when something can run instead. With no stored
  copy and nothing embedded (the first launch of a hub that is not embedded) the
  loader would have given up at 5 s on any slow mobile connection and shown nothing.
  It now waits up to 60 s (`PatientTimeout`), starts mirrors 3 s apart instead of 1 s
  so a slow link is not split between copies of one 950 KB file, and shows a Roblox
  notification at the start and on failure, since a phone has no console.
- Size check tolerance of 16 bytes plus CRLF conversion; `dist/Library.lua` is
  written without trailing whitespace. Some HTTP layers trim a final newline, and an
  exact byte match would reject every download there.
- Requests use `request` and fall back to `game:HttpGet` when `request` gives no
  usable answer (some mobile executors restrict one of them).
- The library was run with every optional executor function removed (`gethui`,
  `protectgui`, `cloneref`, `getcustomasset`, all file functions, `request`,
  `loadstring`, `identifyexecutor`, `syn`, `setclipboard`) and built a full window:
  tabs, sub-tabs, every control, key and colour pickers, notifications, watermark,
  both bundled addons, Touch and Compact densities, 125% scale, two themes and
  Unload. Everything worked, parented to CoreGui, with the Gotham font.
- Not tested on a real phone: no mobile executor was available.

### Startup network use

- Measured with the library running in an environment that records every request:
  nothing is requested while the library loads, apart from the Inter font, which is
  requested from a background task. Icons are inside the build.
- A failed font download is now retried after 15, 45 and 120 seconds instead of
  giving up for the session.
- Loading the library offline took 0.02 s; through the loader with the embedded copy
  0.15 s.

### Simulated network results

| Case | Result |
| --- | --- |
| Nothing reachable, nothing stored | Embedded copy runs, 0.00 s |
| GitHub raw hangs, a CDN answers | 1.4 s, then 0.2 s on the next start |
| Stored copy current | Library.lua is not requested at all |
| New version published | Downloaded once |
| First mirror truncates, second returns HTML, third is good | Third is used |
| Every mirror takes 8 s | Stored copy runs at the 5.0 s mark |
| Stored copy cut short, version matches | Rejected, downloaded again |
| Nothing at all | Error naming the failures |

All seven mirror hosts answered from the test client (a 404, since `dist/` is not
pushed yet), so the address formats are right.

## Update 2026-10-05 (version: UNRESOLVED, see the note above)

A second pass on the look, modelled on a reference menu the owner liked, plus the
phone layout. Checked in game at 100%, 150% and 200%, in the compact sidebar and
with the Touch density.

### Sidebar

- A tab with sub-tabs is now one rounded card: the tab is the header (icon, name,
  chevron up while open) and the sub-tabs are text rows under it, aligned with the
  header's label. Groups start expanded so the sub-tabs are visible at once.
- The selected sub-tab gets a soft rounded fill and full text. Headers rest at full
  strength; the previous grey header is gone, and so are the guide line, the
  horizontal branches and the accent segment.
- All rows are inset pills (8px inset, radius 5), 6px between cards, 2px inside a
  card. The list and the pills now share one inset, so there is no uneven strip at
  the top.
- A collapsed group used to leave an extra 4px gap because its empty holder still
  took part in the list. It is hidden when empty.
- In the compact sidebar the cards drop their inset and sub-tab icons come back.

### Window

- Seamless: the top bar, sidebar, content area and footer use the background colour
  and the rules between them are gone. Only the groupboxes and the sidebar cards are
  raised. `Shell.Seamless = false` brings back the separate colours and rules.
- The footer is a borderless 22px strip in the window colour: text in the bottom
  left corner, aligned with the title, resize grip at the right. A faint rule
  remains under the header only. A draft that put the version in the header was
  dropped; it crowded the search field.
- Every gutter is 10px: window edge to sidebar cards, sidebar to content, between
  the two columns, the right edge, and top and bottom. Before, the gap between the
  columns was 29px and the top gap 17px: padding on both columns, on the page
  container and on two empty spacer frames per column all stacked. The spacers are
  removed. Measured in game: card left 10, sidebar to content 10, column gap 10,
  right margin 10, top gap 10.
- The open tab is a quiet neutral pill (8% of the text colour) with accent text.
  The accent bar and the accent-tinted fill are gone; an earlier draft with no
  fill at all made the selection hard to see.
- Sub-tab text rests brighter (30% dim instead of 50%) so the rows are readable at
  a glance, and sidebar cards use the groupbox surface.

### Fewer layers

- No accent bar, no accent-tinted fill and no hover fill behind tabs. The open tab
  is a neutral pill with accent text. The indicator frame is gone, one instance
  less per tab. `Library:AnimateTabTrail` and `Effects.NavigationIndicator` are
  removed.
- Sidebar group cards are transparent with a hairline outline. Tabbox headers lose
  their tinted fill and show the open tab through label colour.
- Groupboxes and tabboxes are 35% translucent (`Opacity.Card`), strokes are
  lighter (`Stroke.SoftTransparency` 0.46 to 0.6), and an unused transparent header
  frame in every groupbox is gone.

### Key pickers

- The bind box next to a toggle was sized once, from the text width in whatever font
  was active at that moment. A hub that sets its own font after building the menu
  (or a font that finishes downloading later) left the box too narrow, so "None" was
  clipped against the edge and touched the switch. The box now re-measures when the
  font changes, rounds to whole pixels with the same parity as its height, and has a
  fixed height of the indicator size plus 2 instead of the fractional text height
  plus 4. Checked with four fonts: the box is always at least 10px wider than the
  text.

### Memory

- Measured in game by creating and destroying 30 groupboxes of eight controls each:
  instances, registry entries, options and toggles returned to their starting
  count. Three lists did not: `Library.Corners` and `SpecificCorners` grew by about
  24 entries per groupbox, `Library.Signals` by one per control, and
  `Library.ActiveTweens` by one per destroyed instance.
- New `Library:PruneRuntime()` runs every 30 seconds and clears those lists of
  disconnected connections and of entries whose instances are gone, after they
  stay detached for three sweeps. After the fix all counters return to their
  starting values, and a live control keeps its registry entry through the sweeps.
- Tooltips used to keep two global input listeners per control for the life of the
  control. They now listen only while a finger is down, and the tooltip label is
  stored once instead of once per tooltip.
- `Unload` was checked too: after it the registry and signal lists are empty and
  the interface is gone from the container.

### Controls

- Toggles draw as 28x16 switches by default, with the key picker and colour picker
  between label and switch. `AddCheckbox` follows, so existing hubs change without
  edits. `Library.ToggleStyle = "Checkbox"` or the old `Library.ForceCheckbox` bring
  the tick boxes back.
- The on state of the switch is the full accent colour; before it was blended 56%
  into the surface and looked washed out.
- Sliders and progress bars were visibly jagged. The 4px track had a one pixel
  outline, a corner radius of 3 and a gradient fill, so the outline ring and the
  fill edge disagreed on the curve and the ends looked stepped; the progress bar
  also clipped its fill with a mask, which is not smoothed. Now the track is an 8px
  pill (10px on Touch) with a full radius, no outline, no gradient and no clipping,
  and the fill is a pill of the same shape. The knob is a plain 12px circle (14px on
  hover) without its own ring. Validation errors still show a red ring.

### Notifications

- Plain cards, 300px wide: 14px title, 13px muted description, a close cross
  centred on the right, 14px padding, radius 8, slightly translucent surface.
- No automatic icons or bars. Success, warning and error tint only the title. The
  repeat counter is a neutral badge.

### Phones

- When the content is 540px wide or less, the page columns stack into one column in
  one scroll. Before, they became two half-height panels with a scroll each, which
  left two or three rows visible on a landscape phone.
- Key pickers and colour swatches attached to a row stay vertically centred on tall
  Touch rows. They sat at the top edge.

## Update 2026-10-03 (version: UNRESOLVED, see the note above)

Loading reliability, mainly for players in Russia without a VPN, where
raw.githubusercontent.com is slow or cut off.

### What was wrong

- Startup downloaded the Lucide icon module from raw.githubusercontent.com,
  synchronously and with no fallback. When GitHub hung, the whole library hung.
- The first launch also waited for the Inter font (427 KB) from the same host.
- Hubs downloaded 968 KB of library source plus each addon separately, from
  GitHub only. A throttled connection often cut the file short, and running a
  truncated file fails with "attempt to call a nil value".

### Build

- `python tools/build.py` runs darklua and writes `dist/Library.lua`: the library,
  all 17 addons and the icon module in one file, 927 KB in total against 968 KB
  for the library source alone. Minified copies of each addon go to
  `dist/addons/`. Lines stay under 240 characters.
- Bundled addons are reached through `Library.Addons.Name` (or
  `Library:GetAddon`). Each one runs the first time it is read, so unused addons
  cost nothing. `Library:GetAddonNames()` lists them, `Library.Bundled` tells the
  build from the source.
- The sources are unchanged in layout and stay the files to edit. Loading
  `Library.lua` and `addons/*.lua` from the repository root works as before.

### Downloads

- `Loader.lua` is a block to paste into hubs. It tries GitHub raw, then after
  2 seconds without an answer starts the next mirror in parallel: jsDelivr via
  Gcore, Fastly, its main CDN and Cloudflare, then raw.githack and statically.
  Only a response that compiles is accepted. Each good download is cached in
  `MonHub/cache/`, and that copy is loaded when every mirror fails.
- Inside the library, every raw.githubusercontent.com download (font, image
  assets, the icon module when not bundled) uses the same mirrors, jsDelivr first,
  with a time limit. A cached icon module that no longer compiles is downloaded
  again instead of breaking the icons.
- When the Inter font is not cached, the window opens in Gotham at once and
  switches to Inter in the background. It does not switch if the font was changed
  in the meantime.

### Verification

- In game: the build loads, all 17 addons start from it without errors, icons and
  the Inter font work, ThemeManager and SaveManager build their sections, and the
  menu looks the same as from the sources.
- All seven mirrors answered from the test client. A font download through them
  took 0.58 s; a missing file went through all seven and gave up in 3.8 s.
- The loader pointed at the pushed repository loaded in 0.54 s; pointed at a
  repository that does not exist, it gave up on all mirrors in 3.4 s and loaded
  the cached copy.
- Not tested from inside Russia. Which mirrors are reachable there changes over
  time; the loader does not depend on any single one.

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

- Cards are plain panels: title 13px in the body colour, description 12px muted,
  thin outline. A card with a single line of text shows it at title size in the
  body colour.
- Status variants get a 16px icon in their colour (`circle-check`, `triangle-alert`,
  `circle-x`), centred on the first line of text. Default cards have no icon unless
  one is passed. An earlier draft of this update put every icon in a tinted tile and
  gave every card a coloured bar, which read as generic; both are gone.
- Text is measured at the scale it is drawn at. Before, a line that fit on screen at
  200% could still be sized as two lines, leaving an empty strip under it. The space
  under the last line now equals the padding on every card at 100%, 125% and 200%.
- The timer pauses while the cursor is over a card.
- Cards slide in 10px from the screen edge while fading in, and slide back out. They
  used to drop 3px.
- The progress line (`ShowProgress`, off by default, or `Steps`) runs along the
  whole bottom edge just inside the outline and follows the corner radius.
- The repeat counter is a small neutral badge instead of an accent pill.
- New defaults: width 280, margin 10, gap 6, padding 10, corner radius 6 (the card
  radius used by the rest of the library), duration 4 s.

### Progress bar

- Redrawn as a slider track without the thumb: label on an 18px row, a 4px rounded
  track with the soft outline on a 14px row, the same 6px side inset and accent
  gradient as the slider. In a groupbox with a slider, both tracks start and end on
  the same pixel. Before, it was a square 4px strip in the groupbox's own colour, so
  the empty part was nearly invisible and it did not line up with anything.
- The value reads `531/5100` in the muted colour, like the slider's `40/100`. It used
  to read `531 / 5100` in the body colour.
- The fill width is rounded to whole pixels, and any value above zero shows at least
  a round 4px dot. `Row.Fraction` holds the filled share; the regression test now
  checks it instead of `Fill.Size.X.Scale`, which is 0 once the fill is sized in
  pixels.
- Segmented bars use one small outlined track per cell.
- `Color` also accepts a scheme key such as `"SuccessColor"`.
- Default height 30 to 32, the slider's height.

### UI scale

- Changing the UI scale no longer breaks the menu. Several places read on-screen
  sizes (`AbsoluteSize`, which already includes the scale) and wrote them back as
  offsets, applying the scale twice: the two-column split, key tab boxes, resize
  handles, dividers, addon hosts, slider tracks, and button and tabbox content
  centring. The item slot grid and the field group grid divided by the library
  scale instead of reading the logical size. Another 14 places used the library
  scale where the element sat under a different one. New helpers:
  `Library:GetEffectiveScale(Instance)` and `Library:LogicalSize(GuiObject)`.

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
