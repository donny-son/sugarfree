# Sugarfree

Strip formatting "sugar" from clipboard content — a macOS menu-bar utility.

> Ported from NoBold(https://github.com/donny-son/nobold-mac). This repo is the macOS app (at the repo root). A Chrome
> extension counterpart solves the same problem at copy-time but lives in a separate
> repo and is not included here; the parity note in the design contract applies if/when
> that counterpart changes.

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
  rule set (`Sugar`) gated per sugar, in `PasteboardMonitor`
- Rewrites only changed clipboard representations and preserves unrelated pasteboard
  types/items
- Tracks `selfWriteCount` to prevent infinite loops
- Bundle ID `com.sugarfree.app`; source lives in `Sugarfree/`

## Build

```bash
./build.sh            # generate the xcodeproj (XcodeGen) + xcodebuild
./build.sh --run      # build then launch
open Sugarfree.xcodeproj   # open in Xcode
```

For release signing, copy `Configs/LocalSigning.xcconfig.example` to
`Configs/LocalSigning.xcconfig` and fill in your team identity.

> Build settings live in `Configs/Base.xcconfig` (PRODUCT_NAME, bundle ID, INFOPLIST_FILE)
> — these override `project.yml`'s base settings, so change names in both.

## Design workflow (contract)

Any visual / branding change MUST follow this loop. These are rules, not suggestions.

1. Mock before you build. Prototype design directions as a self-contained HTML/CSS file in `Design/` (e.g. `Design/theme-cotton.html`). Render the real UI surfaces (the menu-bar popover, settings) so type, color, and weight are judged in context — not abstract swatches.
2. Name every option. Each direction gets a stable name (e.g. Cotton, Sorbet, Mint, Ink). The user approves exactly one by name before any native code changes. Do not start the SwiftUI work until a named option is chosen.
3. Single source of truth for tokens. `Sugarfree/Theme.swift` is the canonical home for the palette and shared styles:
   - `Ink` enum — paper/ink surfaces + text (the calm base).
   - `Cotton` enum — the cotton-candy gradient brand accent (`gradient`, `buttonGradient`, `accent`, `tint`, `ink`).
   - Reusable views: `Wordmark` (DynaPuff + Cotton gradient), `BrandMark`, `inkSheet()`, `StatusPill`, `CottonPrimaryButtonStyle`, `SectionLabel`, `InkRule`.
   - Component views MUST reference `Theme.swift` tokens — never hardcode a hex value in a view. New color/spacing → add it to `Ink`/`Cotton` first, then use it.
   - HTML mocks must mirror the same token values. If a mock and `Theme.swift` disagree, that's drift — fix it in the same change.
4. Verify before claiming done. After implementing, `./build.sh` must succeed, then relaunch (`pkill -x Sugarfree; open build/DerivedData/Build/Products/Debug/Sugarfree.app`) and visually confirm the popover. Report build status honestly.
5. Keep platforms in parity. If/when the Chrome counterpart changes, a behavior change to formatting-stripping in one should be mirrored (or consciously noted) in the other. Keep "Sugar types handled" below accurate.

### Brand: Cotton theme

- Approved direction: Cotton — Ink paper/ink surfaces (legible) + a cotton-candy gradient applied ONLY as an accent (wordmark, ON toggles, primary button, status pill). Never wash a body surface with the gradient. Source of truth: `Design/BRAND.md`.
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

Caveats (best-effort regex; documented, not bugs):
- Plain-text italic via `_` only matches at non-alphanumeric boundaries, so `snake_case`
  identifiers survive. Underline has no markdown form, so it's RTF/HTML only.
- HTML stripping is regex-based (no DOM parse); combined `text-decoration` shorthands
  (e.g. `underline line-through`) may not split cleanly.
