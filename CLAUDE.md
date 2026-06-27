# Sugarfree

Strip formatting "sugar" from clipboard content — a macOS menu-bar utility.

> This repo is the macOS app (at the repo root) **plus** a cross-platform `sugarfree` CLI
> that shares the same stripping logic. A Chrome extension counterpart solves the same
> problem at copy-time but lives in a separate repo and is not included here; the parity
> note in the design contract applies if/when that counterpart changes.

## Why

AI chat tools (Claude, ChatGPT, Gemini) copy text with formatting sugar (HTML
`<strong>`/`<b>`, RTF bold traits, markdown `**`/`__`). It's annoying when pasting into
plain-text contexts. Sugarfree cleans it off the clipboard automatically.

The user picks which sugars to strip (bold / italic / underline / strikethrough) from a
checklist; bold + italic are on by default. Each enabled sugar is removed across every
clipboard representation that carries it.

## Architecture (macOS app)

- macOS 13+ menu-bar utility, `LSUIElement` (no Dock icon). The `App` scene is an empty
  `Settings` window; the menu bar is an AppKit `NSStatusItem` driven by
  `MenuBarStatusItemController` (see below), not SwiftUI `MenuBarExtra`
- Why `NSStatusItem` and not `MenuBarExtra`: a `MenuBarExtra` label is snapshotted into a
  *template* image (`isTemplate = true`), so macOS strips all color — the state dot and the
  crush shards would render flat monochrome. The controller renders the SwiftUI icon
  (`MenuBarIcon`) to an `NSImage` with `isTemplate = false` (color survives), advances the
  crush keyframe via a timer (`CrushAnimator`) re-rendering each tick, and toggles an
  `NSPopover` hosting the dashboard. The glyph stays monochrome by rendering in the menu
  bar's current appearance (`Color.primary`); only the dot/shards carry color
- Single custom menu-bar dashboard (`MenuBarDashboard`, shown in the `NSPopover`) holding all
  status, controls, format preferences, and the polling-interval picker (no separate Settings
  window)
- Built as a real Xcode macOS app target generated from `project.yml` via XcodeGen
- Polls `NSPasteboard.general.changeCount` on a configurable interval (`PasteboardMonitor`)
- Strips the enabled sugars from RTF (font traits + underline/strikethrough attributes),
  HTML (tag unwrap + inline-style removal), and plain text (markdown markers) — one typed
  rule set (`Sugar`) gated per sugar, in `PasteboardMonitor`
- Rewrites only changed clipboard representations and preserves unrelated pasteboard
  types/items
- Applies optional structural transforms after stripping — currently Tables → list
  (`Transform`, `TransformOutputFormat`), converting Markdown/HTML tables into YAML or
  TOML list items via `TableConverter` (pure Foundation). Transforms reshape content
  (lossy), so they default to off and live in their own dashboard section
- Tracks `selfWriteCount` to prevent infinite loops
- Three system-wide hotkeys are **user-configurable** via the
  [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) package (app-only
  dependency; not in `SugarCore`/CLI). Actions + defaults live in `ShortcutNames.swift`:
  `toggleCleanup` (⌃⌥P), `cleanNow` (⌃⌥K), and `togglePopover` (⌃⌥S, opens the dashboard).
  Defaults use control+option (not ⌘⇧) to avoid colliding with common editor shortcuts.
  Handlers are wired where the action lives — `PasteboardMonitor` for the first two,
  `MenuBarStatusItemController` for the popover. Global hotkeys (not SwiftUI
  `.keyboardShortcut`) are required because an `LSUIElement` accessory is never frontmost.
  The dashboard's "Shortcuts" section hosts a `KeyboardShortcuts.Recorder` per action
  (record / ✕ clear / ↺ reset); KeyboardShortcuts persists changes in `UserDefaults` itself.
  Recorder layout source of truth: `Design/shortcut-recorder.html` (direction "A · Inline field")
- Bundle ID `com.sugarfree.app`; app source lives in `Sugarfree/`

## Shared core + CLI (cross-platform)

- The stripping/transform logic is the **single source of truth** in the SwiftPM
  package at the repo root (`Package.swift`): the `SugarCore` library holds `Sugar`,
  `Transform`, `TransformOutputFormat`, `stripHTML`/`stripPlainText`/`stripRTF`
  (`Sources/SugarCore/`), and `TableConverter`. The macOS app links `SugarCore`
  (via `packages:`/`dependencies:` in `project.yml`) instead of defining these itself —
  so the app and CLI can never drift. **Change stripping behavior in `SugarCore` only.**
- `stripRTF` needs AppKit, so it is gated `#if canImport(AppKit)` — macOS only. The
  pure HTML/plain-text/table logic compiles on Linux and Windows too.
- `sugarfree` (`Sources/sugarfree/`) is a `swift-argument-parser` CLI: a stdin→stdout
  filter mirroring the app's defaults (bold+italic on). Docs in `cli/README.md`; AI-harness
  and build-workflow recipes in `hooks/README.md`.
- Logic tests live in SwiftPM (`Tests/SugarCoreTests/`, run with `swift test`) — they
  replace the old Xcode `SugarfreeTests` target.
- Distribution differs by platform: the macOS `.dmg` **bundles** the universal CLI
  inside the app (`Contents/Resources/sugarfree`, embedded + signed in `release.sh`),
  and the app symlinks it to `/usr/local/bin/sugarfree` on first launch (`CLIInstaller`,
  admin-prompt only if needed). Linux/Windows ship the CLI **only** (no app), as binaries
  from the CLI release build.
- The app and the CLI are **separate release tracks** — they never share a tag or a
  GitHub release. macOS app: `app-v*` tags, DMG built/published by `release.sh`. CLI:
  `cli-v*` tags, archives built by `release.yml` CI. They may version independently.
  See `RELEASING.md`.

## Build

macOS app (unchanged):

```bash
./build.sh            # generate the xcodeproj (XcodeGen) + xcodebuild
./build.sh --run      # build then launch
open Sugarfree.xcodeproj   # open in Xcode
```

CLI + shared core (any platform with Swift 5.9+):

```bash
swift build                              # build SugarCore + sugarfree
swift test                               # run SugarCore logic tests
swift build -c release --product sugarfree
```

CI builds/tests on macOS + Linux (`.github/workflows/ci.yml`). Releases are two
independent tracks (app + CLI) — see **Releasing** below.

For release signing, copy `Configs/LocalSigning.xcconfig.example` to
`Configs/LocalSigning.xcconfig` and fill in your team identity.

> Build settings live in `Configs/Base.xcconfig` (PRODUCT_NAME, bundle ID, INFOPLIST_FILE)
> — these override `project.yml`'s base settings, so change names in both.

## Releasing

The macOS app and the cross-platform CLI ship on **two independent tracks** that never
share a tag or a GitHub release. They are still separate tracks (separate tags, releases,
and build pipelines), but **as of 1.5.1 they share a single version number** — always bump
both together and release them at the same version. Full runbook in `RELEASING.md`; the
summary:

| Track | Tag | Built by | Published assets |
|---|---|---|---|
| macOS app | `app-v<ver>` | `./release.sh` (local) | `Sugarfree-<ver>.dmg` — Developer ID-signed + notarized; **bundles the CLI** |
| CLI | `cli-v<ver>` | `.github/workflows/release.yml` (CI) | `sugarfree-<ver>-<platform>` tarballs/zip + `.sha256` |

Both start by bumping the version, then pushing a track-prefixed tag:

- **App** — bump `MARKETING_VERSION` (+ `CURRENT_PROJECT_VERSION`) in **both**
  `Configs/Base.xcconfig` and `project.yml`. Run `./release.sh` (archives Release,
  embeds + signs the universal CLI in the bundle, then builds + notarizes + staples the
  DMG into `dist/`). Then `git tag app-v<ver> && git push origin app-v<ver>` and
  `gh release create app-v<ver> dist/Sugarfree-<ver>.dmg`. Needs Apple Developer ID +
  notary creds locally — CI cannot do this leg.
- **CLI** — bump `version:` in `Sources/sugarfree/Sugarfree.swift`, then
  `git tag cli-v<ver> && git push origin cli-v<ver>`. CI builds and publishes the rest.

`release.yml` is shaped around two failure modes already fixed (don't regress them):

- **Build matrix uploads artifacts only; a single `release` job (`needs: build`)
  downloads them all and attaches in one `action-gh-release` call.** Attaching from each
  matrix leg in parallel raced — duplicate draft releases + intermittent "Server Error"
  uploads.
- **Linux legs build inside the official `swift:6.0-jammy` container** (multi-arch, so the
  same tag covers arm64); the `setup-swift` action was unreliable on the bare arm64
  runner. The job strips the `cli-` tag prefix so assets read `sugarfree-<ver>-…`.
- **Windows is best-effort (`continue-on-error`)** — `setup-swift` can't currently resolve
  a Swift version on its runner, so no Windows binary is produced. It never blocks the
  release; this is a known open item.

Current published releases: `app-v1.5.1` (DMG) and `cli-v1.5.1` (macOS-universal + Linux
x86_64/arm64; no Windows). The app and CLI version numbers are kept in lockstep.

## Design workflow (contract)

Any visual / branding change MUST follow this loop. These are rules, not suggestions.

1. Mock before you build. Prototype design directions as a self-contained HTML/CSS file in `Design/` (e.g. `Design/theme-cotton.html`). Render the real UI surfaces (the menu-bar popover, settings) so type, color, and weight are judged in context — not abstract swatches.
2. Name every option. Each direction gets a stable name (e.g. Cotton, Sorbet, Mint). The user approves exactly one by name before any native code changes. Do not start the SwiftUI work until a named option is chosen.
3. Single source of truth for tokens. `Sugarfree/Theme.swift` is the canonical home for the palette and shared styles:
   - `Surface` enum — the glass base: system label colors (`text`/`secondary`/`tertiary`), `hairline`/`glassEdge`, `groupFill`, plus `idle` (amber) and the `markTile`/`markGlyph` lockup tones. Surfaces themselves are `Material`, not hex.
   - `Cotton` enum — the cotton-candy gradient brand accent (`gradient`, `buttonGradient`, `accent`, `tint`, `ink`, `candy`).
   - Reusable views: `Wordmark` (DynaPuff + Cotton gradient), `BrandMark`, `AuroraBackground` (the header bloom), `surfaceSheet()` (glass panel), `surfaceBlock()` (inset grouped-list card), `StatusPill`, `CottonPrimaryButtonStyle`, `SectionLabel`, `SurfaceRule`, `Keycap`.
   - Component views MUST reference `Theme.swift` tokens — never hardcode a hex value in a view. New color/spacing → add it to `Surface`/`Cotton` first, then use it.
   - HTML mocks must mirror the same token values. If a mock and `Theme.swift` disagree, that's drift — fix it in the same change.
4. Verify before claiming done. After implementing, `./build.sh` must succeed, then relaunch (`pkill -x Sugarfree; open build/DerivedData/Build/Products/Debug/Sugarfree.app`) and visually confirm the popover. Report build status honestly.
5. Keep platforms in parity. If/when the Chrome counterpart changes, a behavior change to formatting-stripping in one should be mirrored (or consciously noted) in the other. Keep "Sugar types handled" below accurate.

### Brand: Aurora (Liquid Glass) theme

- Approved direction: **Aurora** (Liquid Glass) — Apple-native translucent `Material` surfaces (the popover's own vibrant glass; desktop bleeds through) + a faint cotton aura behind the header, with the cotton-candy gradient applied ONLY as an accent (wordmark, ON toggles, primary button, status pill, header aura). Never wash a body surface with the gradient. Approved 2026-06-20, superseding the original **Cotton** paper theme (warm paper + hard ink borders + hard offset shadow). Mock + named directions (Frost vs. Aurora): `Design/theme-glass.html`. Source of truth: `Design/BRAND.md`. macOS-13 target → glass is built with `Material`/specular-edge/soft-shadow, not the macOS-26 `glassEffect` API.
- Wordmark: lowercase `sugarfree` in DynaPuff (bundled at `Sugarfree/Fonts/DynaPuff.ttf`, registered via `ATSApplicationFontsPath`, OFL license alongside it), painted with `Cotton.gradient`. In-app product label may be title-case "Sugarfree" (e.g. the standard About panel).
- Mark: `Design/logo-lollipop-off.svg` (tabler `lollipop-off`). Ships as the `LollipopOff` template imageset in `Assets.xcassets`, tinted via `.renderingMode(.template)`. The menu-bar glyph is always monochrome (template image / system tint — no gradient there).
- App icon master: `Design/AppIcon-master.svg` (paper squircle + cotton-gradient lollipop = icon "B"). Regenerate the `AppIcon.appiconset` PNGs with:
  ```bash
  for s in 16 32 64 128 256 512 1024; do \
    rsvg-convert -w $s -h $s Design/AppIcon-master.svg \
      -o Sugarfree/Assets.xcassets/AppIcon.appiconset/icon-$s.png; done
  ```
- AccentColor carries explicit light/dark cotton-pink values so controls stay visible in both appearances; keep it aligned with the `Cotton` palette.

## Sugar types handled

Each sugar is independently toggleable. Coverage per representation:

| Sugar | RTF | HTML | Plain text (markdown) |
|---|---|---|---|
| Bold | `.bold` symbolic trait | `<strong>`/`<b>`, `font-weight` | `…`, `…` |
| Italic | `.italic` symbolic trait | `<em>`/`<i>`, `font-style:italic` | `…`, `…` |
| Underline | `.underlineStyle` attribute | `<u>`, `text-decoration:underline` | — (no markdown form) |
| Strikethrough | `.strikethroughStyle` attribute | `<s>`/`<del>`/`<strike>`, `text-decoration:line-through` | `~~…~~` |
| Headers | — (no marker form) | `<h1>`–`<h6>` unwrap to text | `# …` … `###### …` at line start (keeps text) |
| Horizontal rules | — (no marker form) | `<hr>` (void element) removed | `---`/`***`/`___` line (thematic break) removed whole |

Caveats (best-effort regex; documented, not bugs):
- Plain-text italic via `_` only matches at non-alphanumeric boundaries, so `snake_case`
  identifiers survive. Underline has no markdown form, so it's RTF/HTML only.
- HTML stripping is regex-based (no DOM parse); combined `text-decoration` shorthands
  (e.g. `underline line-through`) may not split cleanly.
- Headers only strip a `#` run that is at the start of a line and **followed by
  whitespace** (ATX), so a `#` used as a regular character survives — mid-line (`C#`,
  `issue #42`), with no following space (`#tag`), or a run longer than six (`####### …`).
  An optional trailing closing `#` run is dropped. Headers have no RTF marker form (RTF
  headings are just larger/bold fonts), so they're plain-text + HTML only.
- Horizontal rules match a CommonMark thematic break: a whole line of 3+ matching `-`, `*`,
  or `_` (optionally space-separated), removed including its newline. Emphasis markers
  survive because they always carry inner content (`**bold**`), so the all-marker line
  anchor never matches them. No RTF marker form (RTF rules are paragraph borders), so it's
  plain-text + HTML only.

## Transforms (structural)

Beyond stripping emphasis, the app can reshape content. Transforms are independently
toggleable, off by default (they're lossy), and configured in their own "Transforms"
dashboard section. Source of truth: `Transform` / `TransformOutputFormat` in
`PasteboardMonitor.swift`; conversion in `TableConverter.swift`.

| Transform | What it does | Output |
|---|---|---|
| Tables → list | Converts Markdown pipe tables and HTML `<table>` into list items | YAML-style or TOML-style (user picks) |

- Mapping is header-keyed list items: row 1 = headers; each following row becomes one
  list entry mapping `header: cell`. Lossless for any column count — no key-column guessing.
- Output is style, not spec-strict: keys and values are emitted raw — no quoting,
  for readability. YAML-style is `- header: value` list items; TOML-style is one
  `header = value` block per row, blank-line separated (no `[[rows]]` table headers).
- Representations: the plain-text (Markdown) and HTML reps are both converted; the HTML
  table is replaced with a `<pre>` block of the converted text. When a table is converted in
  an item, that item's RTF representation is dropped (we don't parse RTF tables), so rich
  paste targets fall back to the converted HTML/plain text instead of pasting the old table.
- Caveats (best-effort, documented): RTF-only tables (no Markdown/HTML rep) are not
  converted; HTML parsing is regex-based (no DOM), so nested tables aren't handled; because
  values are unquoted, a numeric-looking cell will read as a number to a strict parser (the
  text is preserved verbatim, which is the priority for paste).
