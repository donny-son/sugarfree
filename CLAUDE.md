# Sugarfree

Strip formatting "sugar" from clipboard content — a macOS menu-bar utility.

> This repo is the macOS app (at the repo root). A Chrome extension counterpart solves the
> same problem at copy-time but lives in a separate repo and is not included here; the parity
> note in the design contract applies if/when that counterpart changes.

## Why

AI chat tools (Claude, ChatGPT, Gemini) copy text with formatting sugar (HTML
`<strong>`/`<b>`, RTF bold traits, markdown `**`/`__`). It's annoying when pasting into
plain-text contexts. Sugarfree cleans it off the clipboard automatically.

The user picks which sugars to strip (bold / italic / underline / strikethrough) from a
checklist; bold + italic are on by default. Each enabled sugar is removed across every
clipboard representation that carries it.

## Architecture (macOS app)

- SwiftUI `MenuBarExtra` utility (macOS 13+), `LSUIElement` (no Dock icon)
- Single custom menu-bar dashboard (`MenuBarDashboard`) holding all status, controls,
  format preferences, and the polling-interval picker (no separate Settings window)
- Built as a real Xcode macOS app target generated from `project.yml` via XcodeGen
- Polls `NSPasteboard.general.changeCount` on a configurable interval (`PasteboardMonitor`)
- Strips the enabled sugars from RTF (font traits + underline/strikethrough attributes),
  HTML (tag unwrap + inline-style removal), and plain text (markdown markers) — one typed
  rule set (`Sugar`) gated per sugar. The HTML + plain-text strippers are Foundation-only
  and live in `SugarStripper` (`Sugarfree/SugarStripper.swift`); `PasteboardMonitor` layers
  the AppKit-only RTF stripping on top and delegates the text reps to `SugarStripper`
- Ships a companion `sugarfree` CLI (`cli/main.swift`, built via `Package.swift`) — a
  stdin→stdout filter for LLM pipelines / shell workflows / Claude Code hooks. It reuses
  the same `SugarStripper` + `TableConverter` core (no AppKit), so the pipe and the
  clipboard strip text identically; the shared core keeps the app and CLI in parity by
  construction (see "CLI" below)
- Rewrites only changed clipboard representations and preserves unrelated pasteboard
  types/items
- Applies optional structural transforms after stripping — currently Tables → list
  (`Transform`, `TransformOutputFormat`), converting Markdown/HTML tables into YAML or
  TOML list items via `TableConverter` (pure Foundation). Transforms reshape content
  (lossy), so they default to off and live in their own dashboard section
- Tracks `selfWriteCount` to prevent infinite loops
- Bundle ID `com.sugarfree.app`; source lives in `Sugarfree/`

## Build

```bash
./build.sh            # generate the xcodeproj (XcodeGen) + xcodebuild
./build.sh --run      # build then launch
open Sugarfree.xcodeproj   # open in Xcode
```

The CLI builds separately via SwiftPM (no Xcode/XcodeGen needed):

```bash
swift build -c release          # produces .build/release/sugarfree
swift run sugarfree --help      # run without installing
```

For release signing, copy `Configs/LocalSigning.xcconfig.example` to
`Configs/LocalSigning.xcconfig` and fill in your team identity.

## CLI (`sugarfree`)

A stdin→stdout filter mirroring the app's stripping, for pipelines/hooks where
the clipboard isn't involved. Source: `cli/main.swift`; manifest: `Package.swift`.

- Reuses `SugarStripper` (HTML + plain-text/markdown) and `TableConverter` — the
  same Foundation-only core the app uses. No AppKit, so RTF is out of scope (you
  pipe text, not clipboard items) and it builds on macOS and Linux.
- Defaults to stripping bold + italic (parity with the app, via `Sugar.defaults`).
  `--all`, `--bold`/`--italic`/`--underline`/`--strikethrough`/`--headers`,
  `--strip a,b`, and `--no-<sugar>` select the set. `--html` switches the input
  format; `--tables <yaml|toml>` enables the table→list transform.
- Reads stdin (or file args / `-`) and writes the processed text verbatim to
  stdout. `--help` / `--version` print and exit; bad args exit non-zero.
- Parity: any change to the stripping rules lives in `SugarStripper` /
  `TableConverter`, so the app and CLI never drift. Keep "Sugar types handled"
  accurate for both.

> Build settings live in `Configs/Base.xcconfig` (PRODUCT_NAME, bundle ID, INFOPLIST_FILE)
> — these override `project.yml`'s base settings, so change names in both.

## Design workflow (contract)

Any visual / branding change MUST follow this loop. These are rules, not suggestions.

1. Mock before you build. Prototype design directions as a self-contained HTML/CSS file in `Design/` (e.g. `Design/theme-cotton.html`). Render the real UI surfaces (the menu-bar popover, settings) so type, color, and weight are judged in context — not abstract swatches.
2. Name every option. Each direction gets a stable name (e.g. Cotton, Sorbet, Mint). The user approves exactly one by name before any native code changes. Do not start the SwiftUI work until a named option is chosen.
3. Single source of truth for tokens. `Sugarfree/Theme.swift` is the canonical home for the palette and shared styles:
   - `Surface` enum — calm paper surfaces + text (the legible base).
   - `Cotton` enum — the cotton-candy gradient brand accent (`gradient`, `buttonGradient`, `accent`, `tint`, `ink`).
   - Reusable views: `Wordmark` (DynaPuff + Cotton gradient), `BrandMark`, `surfaceSheet()`, `StatusPill`, `CottonPrimaryButtonStyle`, `SectionLabel`, `SurfaceRule`.
   - Component views MUST reference `Theme.swift` tokens — never hardcode a hex value in a view. New color/spacing → add it to `Surface`/`Cotton` first, then use it.
   - HTML mocks must mirror the same token values. If a mock and `Theme.swift` disagree, that's drift — fix it in the same change.
4. Verify before claiming done. After implementing, `./build.sh` must succeed, then relaunch (`pkill -x Sugarfree; open build/DerivedData/Build/Products/Debug/Sugarfree.app`) and visually confirm the popover. Report build status honestly.
5. Keep platforms in parity. If/when the Chrome counterpart changes, a behavior change to formatting-stripping in one should be mirrored (or consciously noted) in the other. Keep "Sugar types handled" below accurate.

### Brand: Cotton theme

- Approved direction: Cotton — calm paper surfaces (legible) + a cotton-candy gradient applied ONLY as an accent (wordmark, ON toggles, primary button, status pill). Never wash a body surface with the gradient. Source of truth: `Design/BRAND.md`.
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
