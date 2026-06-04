# Brand: sugarfree

> The app strips markdown "syntactic sugar" (bold, italic, underline, strikethrough, …)
> from clipboard content, with per-type control.

## Identity (locked 2026-06-03)

| Aspect | Value | Notes |
|---|---|---|
| Canonical wordmark | `sugarfree` | lowercase everywhere as the wordmark/asset name |
| UI label | `Sugarfree` | title case when shown as a product name in-app |
| Bundle ID | `com.sugarfree.app` | |
| Module / folder | `Sugarfree` / `Sugarfree/` | |
| Wordmark font | **DynaPuff** (Google), weight 600 | rounded/candy display face; variable 400–700 |
| Visual theme | **Cotton** — calm paper surfaces + cotton-candy gradient accent | restrained: candy in accents, calm paper surfaces |
| Mark | **lollipop-off** (tabler) | replaces stars-off; `Design/logo-lollipop-off.svg` |
| App icon | **B** — cotton-gradient lollipop on paper tile | gradient mark only viable on icon, not menubar |
| Metaphor | diet/clean lead, CS "syntactic sugar" as dev-only wink | |

## Visual — Cotton theme

**Surfaces & text stay calm paper** for legibility. The **cotton-candy gradient is the
brand accent**, applied ONLY to: the wordmark, ON toggles, the primary button, the status
("cleaning") pill, and the app-icon mark. Body surfaces are never gradient-washed.

Surface/text tokens:
- desk `#ECE9E1` / dark `#121214`
- surface `#FAF8F3` / dark `#1D1D1F`
- text `#161616` / dark `#F4F1EA`
- markTile `#161616` / markGlyph `#FAF8F3` (inverted in dark)

New Cotton accent tokens (in the sibling `Cotton` enum):

| token | light | dark | use |
|---|---|---|---|
| cotton (brand gradient) | `#FF6FB5 → #FF9A6B → #FFC857` @100° | `#FF8AC4 → #FFB07A → #FFD879` | wordmark, ON toggle, icon |
| cotton-btn (deeper, white text reads) | `#F0469B → #FF7A4D` | `#FF5FAE → #FF8A5B` | primary button |
| cotton-tint | `rgba(255,111,181,.14)` | `rgba(255,138,196,.16)` | pill background |
| cotton-ink (deep-pink text) | `#C8327E` | `#FF9ECB` | pill text |

The old green `active`/amber `idle` status colors are **replaced by the cotton accent** for
the ON/cleaning state; OFF/idle uses neutral gray (`hairline`/`tertiary`).

> **Menubar constraint:** the menu-bar glyph is a template image and follows the system tint
> — it is ALWAYS monochrome at rest. No gradient there. Gradient lollipop is app-icon only.
>
> **Menubar cleanup cue + on/off state (added 2026-06-04):**
> - *On/off hint:* the menu-bar glyph's opacity tracks state — auto-cleanup ON (active) is
>   full strength (1.0), idle (on, nothing selected) is dimmed (0.6), OFF (paused) is muted
>   (0.35). So the menu bar shows at a glance whether cleanup is running.
> - *Resting glyph:* the plain **lollipop** (`Design/logo-lollipop.svg`), not lollipop-off.
> - *Clean cue:* on each clean the glyph does a brief one-shot flip to the **lollipop-off**
>   mark tinted cotton-pink (`Cotton.accent`), then resets after ~0.5s. A MenuBarExtra label
>   is snapshotted by the status bar, so frame-driven tweens (TimelineView / implicit
>   animation) don't run there — the cue is a deliberate discrete swap, not an interpolated
>   slash. This momentary pink flip is the documented exception to "always monochrome."
> The brand **mark** (About lockup, app icon) is still lollipop-off — only the menu-bar
> resting glyph is the plain lollipop, so the "off" is earned live at clean-time.
> Source of truth: `MenuBarStatusIcon` in `MenuBarDashboard.swift`.

> Branding change → bound by the CLAUDE.md design contract: mock in `Design/`, name the
> option, get approval, then build, then verify (`./build.sh` + relaunch).
