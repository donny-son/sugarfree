# Brand: sugarfree

> Renamed from **NoBold**. The app strips markdown "syntactic sugar" (bold, italic,
> underline, strikethrough, …) from clipboard content, with per-type control.

## Identity (locked 2026-06-03)

| Aspect | Value | Notes |
|---|---|---|
| Canonical wordmark | `sugarfree` | lowercase everywhere as the wordmark/asset name |
| UI label | `Sugarfree` | title case when shown as a product name in-app |
| Bundle ID | `com.sugarfree.app` | clean break from `com.nobold.app` |
| Module / folder | `Sugarfree` / `Sugarfree/` | renamed from `NoBold` (full break) |
| Wordmark font | **DynaPuff** (Google), weight 600 | rounded/candy display face; variable 400–700 |
| Visual theme | **Cotton** — Ink surfaces + cotton-candy gradient accent | restrained: candy in accents, calm paper surfaces |
| Mark | **lollipop-off** (tabler) | replaces stars-off; `Design/logo-lollipop-off.svg` |
| App icon | **B** — cotton-gradient lollipop on paper tile | gradient mark only viable on icon, not menubar |
| Metaphor | diet/clean lead, CS "syntactic sugar" as dev-only wink | |

## Visual — Cotton theme

**Surfaces & text stay Ink** (paper/ink) for legibility. The **cotton-candy gradient is the
brand accent**, applied ONLY to: the wordmark, ON toggles, the primary button, the status
("cleaning") pill, and the app-icon mark. Body surfaces are never gradient-washed.

Retained Ink surface/text tokens (unchanged):
- desk `#ECE9E1` / dark `#121214`
- surface `#FAF8F3` / dark `#1D1D1F`
- text `#161616` / dark `#F4F1EA`
- markTile `#161616` / markGlyph `#FAF8F3` (inverted in dark)

New Cotton accent tokens (add to the `Ink` enum, or a sibling `Cotton` enum):

| token | light | dark | use |
|---|---|---|---|
| cotton (brand gradient) | `#FF6FB5 → #FF9A6B → #FFC857` @100° | `#FF8AC4 → #FFB07A → #FFD879` | wordmark, ON toggle, icon |
| cotton-btn (deeper, white text reads) | `#F0469B → #FF7A4D` | `#FF5FAE → #FF8A5B` | primary button |
| cotton-tint | `rgba(255,111,181,.14)` | `rgba(255,138,196,.16)` | pill background |
| cotton-ink (deep-pink text) | `#C8327E` | `#FF9ECB` | pill text |

The old green `active`/amber `idle` status colors are **replaced by the cotton accent** for
the ON/cleaning state; OFF/idle uses neutral gray (`hairline`/`tertiary`).

> **Menubar constraint:** the menu-bar glyph is a template image and follows the system tint
> — it is ALWAYS monochrome. No gradient there. Gradient lollipop is app-icon only.

## Rename sweep (when executing the rebrand)

- `project.yml`: `name`, `PRODUCT_NAME`, `PRODUCT_BUNDLE_IDENTIFIER`, `INFOPLIST_FILE`,
  target name, `PRODUCT_MODULE_NAME`, scheme.
- `NoBold/` source folder → `Sugarfree/` (and the `Info.plist` path).
- Chrome extension `manifest.json` name/description.
- `README.md` copy + imagery, `CLAUDE.md` references.
- Regenerate `NoBold.xcodeproj` via XcodeGen after `project.yml` edits.
- App icon regenerated from `Design/AppIcon-master.svg` (cotton lollipop on a paper tile,
  icon B); the `LollipopOff` template imageset replaces `StarsOff`.

> Branding change → bound by the CLAUDE.md design contract: mock in `Design/`, name the
> option, get approval, then build, then verify (`./build.sh` + relaunch).
