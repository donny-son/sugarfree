---
version: alpha
name: Sugarfree-design-analysis
description: A clean Apple-native Liquid Glass menu-bar utility. One fixed-width popover floating on the system's vibrant translucent material, with a faint cotton-candy aura blooming behind the header (the "Aurora" direction). Surfaces are real-time-blurred glass — never paper — with thin specular edge highlights, soft float shadows, and zero hard borders. The DynaPuff cotton-gradient wordmark and the cotton palette are the only color events; they ride on glass that otherwise recedes into the desktop behind it.

colors:
  cotton-g1: "#FF6FB5"
  cotton-g2: "#FF9A6B"
  cotton-g3: "#FFC857"
  cotton-btn-1: "#F0469B"
  cotton-btn-2: "#FF7A4D"
  cotton-accent: "#F0469B"
  cotton-ink: "#C8327E"
  cotton-tint: "rgba(255,111,181,0.16)"
  cotton-ring: "rgba(240,70,155,0.40)"
  aura-pink: "rgba(255,111,181,0.26)"
  aura-amber: "rgba(255,200,87,0.18)"
  idle-amber: "#B0721A"
  glass-panel: "system vibrant Material (NSPopover) / regularMaterial"
  glass-inset: "ultraThinMaterial"
  group-fill: "rgba(255,255,255,0.04)"
  glass-edge: "rgba(255,255,255,0.22)"
  window-background: "#F5F5F7"
  text: "system .primary label"
  secondary: "system .secondary label"
  tertiary: "system .tertiaryLabel"
  hairline: "system .separatorColor"
  mark-tile: "#161616"
  mark-glyph: "#FAF8F3"
  on-accent: "#FFFFFF"
  dark-window-background: "#1C1C1E"
  dark-cotton-g1: "#FF8AC4"
  dark-cotton-g2: "#FFB07A"
  dark-cotton-g3: "#FFD879"
  dark-cotton-btn-1: "#FF5FAE"
  dark-cotton-btn-2: "#FF8A5B"
  dark-cotton-tint: "rgba(255,138,196,0.16)"
  dark-cotton-ink: "#FF9ECB"
  dark-mark-tile: "#F2EFE8"
  dark-idle-amber: "#E3B341"

typography:
  wordmark:
    fontFamily: "DynaPuff, system-ui, sans-serif"
    fontSize: 22px
    fontWeight: 600
    lineHeight: 1.0
    letterSpacing: -0.2px
  status-headline:
    fontFamily: "SF Pro Text, -apple-system, system-ui, sans-serif"
    fontSize: 13px
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: 0
  toggle-label:
    fontFamily: "SF Pro Text, -apple-system, system-ui, sans-serif"
    fontSize: 13px
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: 0
  body:
    fontFamily: "SF Pro Text, -apple-system, system-ui, sans-serif"
    fontSize: 12.5px
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: 0
  body-small:
    fontFamily: "SF Pro Text, -apple-system, system-ui, sans-serif"
    fontSize: 11.5px
    fontWeight: 400
    lineHeight: 1.35
    letterSpacing: 0
  count-figure:
    fontFamily: "SF Mono, ui-monospace, SFMono-Regular, Menlo, monospace"
    fontSize: 15px
    fontWeight: 600
    lineHeight: 1.0
    letterSpacing: 0
  button-primary:
    fontFamily: "SF Pro Text, -apple-system, system-ui, sans-serif"
    fontSize: 14px
    fontWeight: 600
    lineHeight: 1.0
    letterSpacing: 0
  section-label:
    fontFamily: "SF Pro Text, -apple-system, system-ui, sans-serif"
    fontSize: 11px
    fontWeight: 600
    lineHeight: 1.0
    letterSpacing: 0.5px
  status-pill:
    fontFamily: "SF Pro Text, -apple-system, system-ui, sans-serif"
    fontSize: 10px
    fontWeight: 600
    lineHeight: 1.0
    letterSpacing: 0.6px
  keycap:
    fontFamily: "SF Mono, ui-monospace, SFMono-Regular, Menlo, monospace"
    fontSize: 11px
    fontWeight: 600
    lineHeight: 1.0
    letterSpacing: 0
  meta-mono:
    fontFamily: "SF Mono, ui-monospace, SFMono-Regular, Menlo, monospace"
    fontSize: 10.5px
    fontWeight: 400
    lineHeight: 1.3
    letterSpacing: 0
  example-mono:
    fontFamily: "SF Mono, ui-monospace, SFMono-Regular, Menlo, monospace"
    fontSize: 10.5px
    fontWeight: 400
    lineHeight: 1.3
    letterSpacing: 0
  footer-action:
    fontFamily: "SF Pro Text, -apple-system, system-ui, sans-serif"
    fontSize: 11.5px
    fontWeight: 500
    lineHeight: 1.0
    letterSpacing: 0

rounded:
  none: 0px
  keycap: 6px
  group: 12px
  button: 12px
  sheet: 18px
  pill: 9999px
  full: 9999px

spacing:
  xxs: 2px
  xs: 4px
  sm: 7px
  md: 10px
  base: 12px
  lg: 14px
  panel: 18px

components:
  popover-window:
    backgroundColor: "{colors.glass-panel}"
    overlay: "{colors.aura-pink} + {colors.aura-amber} radial bloom (Aurora)"
    textColor: "{colors.text}"
    width: 320px
    padding: 18px
  glass-sheet:
    backgroundColor: "regularMaterial"
    borderColor: "{colors.glass-edge}"
    rounded: "{rounded.sheet}"
    padding: 14px
    shadow: "0 12px 22px rgba(0,0,0,0.20)"
  glass-group:
    backgroundColor: "{colors.group-fill}"
    borderColor: "{colors.hairline}"
    rounded: "{rounded.group}"
    padding: 12px
  brand-mark:
    backgroundColor: "{colors.mark-tile}"
    iconColor: "{colors.mark-glyph}"
    rounded: "30% of size"
    shadow: "soft"
  wordmark:
    backgroundColor: transparent
    textColor: "{colors.cotton-g1}"
    typography: "{typography.wordmark}"
  status-pill-active:
    backgroundColor: "{colors.cotton-tint}"
    textColor: "{colors.cotton-ink}"
    borderColor: "{colors.cotton-ring}"
    typography: "{typography.status-pill}"
    rounded: "{rounded.pill}"
    padding: 4px 10px
  status-pill-paused:
    backgroundColor: "{colors.hairline} @60%"
    textColor: "{colors.secondary}"
    typography: "{typography.status-pill}"
    rounded: "{rounded.pill}"
    padding: 4px 10px
  status-pill-idle:
    backgroundColor: "rgba(176,114,26,0.16)"
    textColor: "{colors.idle-amber}"
    typography: "{typography.status-pill}"
    rounded: "{rounded.pill}"
    padding: 4px 10px
  section-label:
    backgroundColor: transparent
    textColor: "{colors.secondary}"
    typography: "{typography.section-label}"
  toggle-on:
    backgroundColor: "{colors.cotton-accent} (native switch tint)"
    rounded: "{rounded.pill}"
  segmented-picker:
    backgroundColor: "native glass segmented"
    selectedTint: "{colors.cotton-accent}"
    typography: "{typography.body}"
  button-primary:
    backgroundColor: "{colors.cotton-btn-1} → {colors.cotton-btn-2} gradient"
    sheen: "white 30% → clear, top→center"
    textColor: "{colors.on-accent}"
    borderColor: "white 20%"
    glow: "{colors.cotton-ring}, radius 10, y 3"
    typography: "{typography.button-primary}"
    rounded: "{rounded.button}"
    padding: 9px vertical, full width
  keycap:
    backgroundColor: "{colors.glass-inset}"
    textColor: "{colors.text}"
    borderColor: "{colors.hairline}"
    typography: "{typography.keycap}"
    rounded: "{rounded.keycap}"
    height: 20px
    shadow: "0 1px 2px rgba(0,0,0,0.12)"
  shortcut-recorder:
    backgroundColor: "native (KeyboardShortcuts.Recorder)"
    selectedTint: "{colors.cotton-accent}"
    typography: "{typography.keycap}"
  checkbox-on:
    backgroundColor: "{colors.cotton-accent} (native switch)"
  example-code-block:
    backgroundColor: "{colors.glass-inset}"
    borderColor: "{colors.hairline}"
    textColor: "{colors.secondary}"
    typography: "{typography.example-mono}"
    rounded: "{rounded.keycap}"
  sugar-row:
    backgroundColor: transparent
    textColor: "{colors.text}"
    exampleColor: "{colors.tertiary}"
    typography: "{typography.toggle-label}"
    dividerColor: "{colors.hairline}"
    padding: 7px vertical
  count-figure:
    backgroundColor: transparent
    textColor: "{colors.text}"
    typography: "{typography.count-figure}"
  hairline-rule:
    backgroundColor: "{colors.hairline}"
    height: 1px
  footer-action:
    backgroundColor: transparent
    textColor: "{colors.secondary}"
    typography: "{typography.footer-action}"
  menubar-glyph:
    backgroundColor: transparent
    iconColor: "system-tint (monochrome)"
    flashColor: "{colors.cotton-accent}"
    size: 18px
---

## Overview

Sugarfree is a macOS menu-bar utility whose entire interface is a single fixed-width
popover — no Dock icon, no Settings window, no second surface. The visual language is
Apple's **Liquid Glass**: the panel is the system's own vibrant, real-time-blurred
translucent material, so the desktop and windows behind it bleed softly through. Content
floats on that glass; the glass itself recedes. This replaced an earlier "Cotton" paper
theme (warm paper surfaces, hard ink borders, a hard offset shadow) — the brand survived
intact, but the *surface execution* moved from printed-paper to glass.

The system holds one disciplined tension. The base layer is **neutral glass**: translucent
`Material`, system label text (so type stays vibrant and legible over whatever shows
through), thin white specular edge highlights, soft float shadows, continuous corners, and
zero hard borders. Against that calm, exactly one thing is allowed color: the
**cotton-candy gradient** (`{colors.cotton-g1}` → `{colors.cotton-g2}` →
`{colors.cotton-g3}`). It is a brand event, never a background. It appears on only five
surfaces — the DynaPuff wordmark, ON toggles, the "Clean Now" button, the active status
pill, and (the approved **Aurora** signature) a faint cotton aura blooming behind the header
— and it is forbidden everywhere else. The body glass is never gradient-washed.

Density is high but quiet. Each setting gets one row in a 320px column: a status block, an
"Automatic cleanup" toggle, a segmented interval picker, the primary button, a shortcuts
list, a per-sugar checklist grouped into an inset glass card, a transforms card, and a
footer. The rhythm comes from SF-native grouped-list section headers
(`Check interval`, `Shortcuts`, `Sugars to strip`, `Transforms`), 1px separator rules, and
inset glass group cards — the same vocabulary as System Settings and Control Center. One
design language, expressed in one breath: a glass desk accessory.

Key Characteristics:
- Single fixed-width (320px) popover; no Dock icon, no separate Settings window.
- Glass base: the system's vibrant translucent `Material`, with desktop bleeding through.
- Aurora signature: a faint cotton-candy radial bloom behind the header, over the glass.
- Soft float shadows + thin specular edge highlights for depth — no hard borders, no offset block.
- One color event: the cotton gradient, restricted to wordmark, ON toggle, button, active pill, aura.
- DynaPuff rounded "candy" face for the wordmark ONLY; everything else is SF system text.
- SF-native grouped-list section headers + inset glass cards (System-Settings vocabulary).
- Fully appearance-adaptive: system label colors + adaptive cotton stops keep both modes coherent.
- The menu-bar glyph is ALWAYS monochrome at rest (template image / system tint); glass and gradient never enter the menu bar.

## Colors

> Source surfaces analyzed: the menu-bar popover (`MenuBarDashboard.swift`), the glass theme
> mock (`Design/theme-glass.html`, Aurora direction), and the brand spec (`Design/BRAND.md`).
> Token source of truth is `Sugarfree/Theme.swift` (`Surface` + `Cotton` enums). The glass
> surfaces are `Material` (not a hex); text and hairlines are system semantic colors, so they
> adapt to appearance and vibrancy automatically. Only the cotton accents carry explicit
> light/dark hexes.

### Brand & Accent
- Cotton Gradient (`{colors.cotton-g1}` #FF6FB5 → `{colors.cotton-g2}` #FF9A6B → `{colors.cotton-g3}` #FFC857, ~100°): The single brand event. Wordmark fill (clipped to the DynaPuff glyphs), ON toggle, app-icon mark, and the source colors of the Aurora bloom. The only gradient in the system; never a panel background.
- Cotton Button (`{colors.cotton-btn-1}` #F0469B → `{colors.cotton-btn-2}` #FF7A4D): The "Clean Now" fill, deep enough to carry white text, finished with a white specular sheen over the top half (the "liquid" highlight).
- Cotton Accent (`{colors.cotton-accent}` #F0469B): Solid pink for native control tints that can't take a gradient — the switch on-color, segmented selection, checked toggle.
- Cotton Ink (`{colors.cotton-ink}` #C8327E): Deep-pink text on a cotton tint — the "ACTIVE" pill label.
- Cotton Tint (`{colors.cotton-tint}` rgba(255,111,181,0.16)): Low-alpha pink behind the active status pill — the one steady-state place pink touches a fill.
- Aura (`{colors.aura-pink}` + `{colors.aura-amber}`): The Aurora bloom — `Cotton.candy` stops at 18–26% alpha as two radial gradients (pink top-leading, amber top-trailing) over the header glass. Translucent so the glass still reads.

### Surface (glass)
- Panel Glass (`{colors.glass-panel}`): The popover's own vibrant `Material` (the system draws it; it is translucent + blurred + appearance-adaptive). For real windows (onboarding) it is `regularMaterial` painted over `{colors.window-background}`.
- Inset Glass (`{colors.glass-inset}` = `ultraThinMaterial`): A lighter blurred fill for small inset elements — keycaps and the example-code blocks.
- Group Fill (`{colors.group-fill}` rgba(255,255,255,0.04)): A barely-there white film on the inset grouped-list cards, so they read as a slightly raised pane on the panel glass.
- Window Background (`{colors.window-background}` #F5F5F7 / dark #1C1C1E): The clean Apple settings gray under the onboarding window's material — NOT warm paper.

### Text
- Text (`{colors.text}` = system `.primary`): Headlines, row labels, the count figure. System label color so it stays vibrant and legible over translucent glass in both modes.
- Secondary (`{colors.secondary}` = system `.secondary`): Sub-status, section labels, footer actions, paused-pill text.
- Tertiary (`{colors.tertiary}` = system `.tertiaryLabel`): Timestamps, example markup, row glyphs — the quietest tier.

### Hairlines & Edges
- Hairline (`{colors.hairline}` = system `.separatorColor`): The 1px rule between sections, around grouped cards, and the dividers inside grouped lists. Adaptive; the structural divider of the layout.
- Glass Edge (`{colors.glass-edge}` rgba(255,255,255,0.22)): The thin white specular highlight stroked on glass panel edges — catches "light" the way a real glass bevel would. This replaced the old hard ink border entirely.

### Status (non-brand)
- Idle Amber (`{colors.idle-amber}` #B0721A, dark #E3B341): The "attention" state — auto-cleanup on, nothing selected to strip. Full-strength text, ~16% pill fill. The only non-pink accent; it signals "check me," never "action."

### Brand Mark (lockup only)
- Mark Tile (`{colors.mark-tile}` #161616, dark #F2EFE8) / Mark Glyph (`{colors.mark-glyph}` #FAF8F3, dark #161616): The lollipop-off on a solid tile — the About / onboarding lockup, with a soft drop shadow. The one place a solid (non-glass) surface remains, because a brand lockup wants weight.

### Dark Mode
Glass and all semantic colors re-resolve automatically (the `Material` darkens; `.primary`
/ `.secondary` / `.separatorColor` flip). The cotton stops carry explicit brightened dark
values (#FF6FB5… → #FF8AC4…) so the candy still reads against the darker glass. Dark mode is
the same five-zone glass structure, re-resolved — not a separate palette.

### Brand Gradient Policy
One gradient family (Cotton), brand-restricted to five surfaces (wordmark, ON toggle,
primary button, active pill, Aurora bloom). The glass panel, rows, and grouped cards are
neutral `Material` — depth comes from translucency, specular edges, and soft shadow, never a
decorative gradient on a container. The discrete `Cotton.candy` stops may also appear as
individual chips in a celebratory burst (menu-bar clean flash, popover confetti) — a
momentary exception, never a steady-state fill.

## Typography

### Font Family
- Wordmark: `DynaPuff, system-ui, sans-serif` weight 600 — the bundled rounded candy display face (`Sugarfree/Fonts/DynaPuff.ttf`, OFL). Used ONLY in the wordmark and app-icon lockup.
- UI / Body: `SF Pro Text, -apple-system, system-ui, sans-serif` — every label, status line, section header, and button. Section headers are now SF (native grouped-list style), not mono.
- Mono: `SF Mono, ui-monospace, Menlo, monospace` — reserved for the "machine" register: the cleaned-count figure, keycaps, timestamps, and the literal markup examples (`**bold**`, `~~strike~~`). The wink at the "syntactic sugar" metaphor.

### Hierarchy

| Token | Size | Weight | Line Height | Letter Spacing | Use |
|---|---|---|---|---|---|
| `{typography.wordmark}` | 22px | 600 | 1.0 | -0.2px | "sugarfree" wordmark, DynaPuff, gradient-filled |
| `{typography.count-figure}` | 15px | 600 | 1.0 | 0 | The cleaned-count number, SF Mono |
| `{typography.button-primary}` | 14px | 600 | 1.0 | 0 | "Clean Now" button label |
| `{typography.status-headline}` | 13px | 500 | 1.3 | 0 | The live status line ("Auto-cleaned Bold") |
| `{typography.toggle-label}` | 13px | 500 | 1.3 | 0 | Control labels ("Automatic cleanup", sugar names) |
| `{typography.body}` | 12.5px | 400 | 1.4 | 0 | Secondary copy, row labels |
| `{typography.body-small}` | 11.5px | 400 | 1.35 | 0 | Sub-status detail line |
| `{typography.footer-action}` | 11.5px | 500 | 1.0 | 0 | "About" / "Quit" footer links |
| `{typography.section-label}` | 11px | 600 | 1.0 | 0.5px | UPPERCASE SF grouped-list section headers |
| `{typography.status-pill}` | 10px | 600 | 1.0 | 0.6px | "ACTIVE" / "PAUSED" pill text, uppercase |
| `{typography.keycap}` | 11px | 600 | 1.0 | 0 | Single glyph inside a keycap (⌘, ⇧, P) |
| `{typography.meta-mono}` | 10.5px | 400 | 1.3 | 0 | Timestamps, "cleaned" suffix |
| `{typography.example-mono}` | 10.5px | 400 | 1.3 | 0 | The `**bold**` / `~~strike~~` example markup |

### Principles

- One display face, used once. DynaPuff is the candy voice, rationed to the wordmark. The discipline is what makes the wordmark feel special.
- Mono is a semantic register, not decoration — and now narrower than before. The glass theme moved section headers OUT of mono into native SF (Apple grouped-list style); mono is kept only for true "machine truth" (count, keycaps, timestamps, literal markup).
- Section labels are native, not mono. Uppercase SF Pro Text, 11px / 600, +0.5px tracking, secondary color — the System Settings / Control Center grouped-header look. They structure the panel without boxes.
- System label colors over fixed hexes. Body text uses `.primary` / `.secondary` / `.tertiaryLabel` so it stays legible against translucent, desktop-tinted glass and adapts to vibrancy. The paper theme's fixed near-black ink would muddy over glass.
- Weight ladder is 400 / 500 / 600. Body 400; interactive labels and status lines 500; emphatic/brand text (button, count, section label, pill, footer) 600. No 700 in the UI.
- Sizes run small and exact. Working range 10–15px tuned to the 320px column, with half-pixel sizes (11.5, 12.5, 10.5). The count at 15px is the largest non-wordmark element.

### Note on Font Substitutes
- The wordmark requires the bundled DynaPuff; without it the candy character is lost, so it is not optional on brand surfaces.
- All UI text resolves to real SF Pro Text / SF Mono on macOS via `-apple-system` / `ui-monospace` — no web fallback (native app).
- For off-platform mocks (`Design/*.html`), use `-apple-system, BlinkMacSystemFont, "SF Pro Text"` and `ui-monospace, SFMono-Regular, Menlo`.

## Layout

### Spacing System
- Working unit: small and tuned, not a strict 8px grid. Structural values cluster at 7 / 10 / 12 / 14 / 18px.
- Tokens: `{spacing.xxs}` 2px · `{spacing.xs}` 4px · `{spacing.sm}` 7px · `{spacing.md}` 10px · `{spacing.base}` 12px · `{spacing.lg}` 14px · `{spacing.panel}` 18px.
- Popover width: fixed 320px; the column is the column.
- Panel padding: `{spacing.panel}` (18px) of inset between the popover edge and content — slightly airier than the paper theme's 16px, to let the glass breathe.
- Group card padding: `{spacing.base}` (12px) horizontal inside an inset grouped-list card.
- Row padding: `{spacing.sm}` (7px) vertical per row in the grouped sugar/transform lists; rows are separated by a 1px `Divider`, not by a gap.
- Section-label rhythm: ~14px between major sections (with a separator rule), ~6–10px from a label to its first row.
- Button: 9px vertical padding, full-width.

### Grid & Container
- Single column. Everything is one vertical stack; the "grid" is the row list.
- Row structure: `[leading glyph 16px] [label + inline mono example] [spacer] [native control]`.
- Shortcut rows: `[label, fixed 104px] [native recorder, flex] [reset ↺]`.
- Grouped cards: the Sugars and Transforms lists are wrapped in a `glass-group` (12px radius, group-fill, hairline border) with internal `Divider`s — the native inset grouped-list pattern. Shortcuts and the status block stay ungrouped on the panel glass.

### Whitespace Philosophy
Glass wants a little more air than paper did. The 18px panel inset and the inset grouped
cards give each zone room so the translucency reads as depth, not clutter. It is still a
glanceable index card — every setting visible without scrolling — but it now floats rather
than sits. The only solid, weighty element is the brand-mark lockup (onboarding/About),
which earns its solidity as an identity moment.

## Elevation & Depth

| Level | Treatment | Use |
|---|---|---|
| Glass panel | System vibrant `Material` + Aurora bloom + soft float shadow (the OS popover shadow) | The popover itself |
| Specular edge | 0.75px `{colors.glass-edge}` (white 22%) stroke | Glass panel / sheet / keycap edges — the "bevel" highlight |
| Inset group | `{colors.group-fill}` film + 1px `{colors.hairline}` border, 12px radius | Grouped sugar/transform list cards |
| Inset glass | `ultraThinMaterial` + hairline | Keycaps, example-code blocks |
| Soft float | `0 12px 22px rgba(0,0,0,0.20)` (sheet) · `0 1px 2px rgba(0,0,0,0.12)` (keycap) | The glass-sheet helper and keycaps |
| Button glow | `{colors.cotton-ring}` radius 10, y 3 | The one brand-colored bloom, under "Clean Now" only |

Shadow philosophy. Depth is now **translucency + a thin specular edge + a soft float
shadow** — the Apple Liquid Glass recipe. There is no hard offset block and no hard border
anywhere; the old "printed sticker" language is gone. The single brand-colored shadow is the
cotton-pink glow under the primary button, which makes the one gradient surface feel lit.
Everything else relies on the system material's own elevation (the OS draws the popover's
drop shadow) plus the white specular edge that reads as a glass bevel.

### Decorative Depth
- The Aurora bloom adds brand warmth *as light through glass*, not as a fill — two low-alpha radial gradients over the header.
- Specular edge + soft shadow create the floating-pane feel without any border.
- Dark mode keeps the same recipe (material darkens, specular edge and shadow re-resolve), so the glass identity survives the appearance switch.

## Shapes

### Border Radius Scale

| Token | Value | Use |
|---|---|---|
| `{rounded.none}` | 0px | Hairline rules, the wordmark text |
| `{rounded.keycap}` | 6px | Keycaps, example-code blocks |
| `{rounded.group}` | 12px | Inset grouped-list cards |
| `{rounded.button}` | 12px | The "Clean Now" primary button |
| `{rounded.sheet}` | 18px | The glass-sheet helper (and the popover content inset) |
| `{rounded.pill}` | 9999px | Toggles, status pills, the recorder field — capsule controls |
| `{rounded.full}` | 9999px / 50% | The state dot, toggle knob |

Continuous corners. All rounded rectangles use SwiftUI's `.continuous` (squircle) style,
matching the macOS system look. Radius grows with scale: 6px keycap → 12px button/group →
18px sheet → the OS's own popover radius. Capsule controls (toggle, pill, recorder) go
straight to a full pill — no "slightly rounded" middle ground for switch-like elements.

### Mark & Icon Geometry
- Brand mark: the `lollipop-off` glyph centered on a solid `{colors.mark-tile}` tile, continuous corner (size × 0.3), glyph inset ~20%, soft drop shadow. The About / onboarding lockup.
- Menu-bar glyph: the plain `lollipop` at rest, a monochrome template image at the system tint, 18px. NEVER glass, NEVER gradient, NEVER colored at rest.
- Sugar-row glyphs: small monochrome type-style indicators (B, I, U, S, #) at the row leading edge, 16px, tertiary — they echo the formatting they strip.
- State dot: a 6px filled circle tracking monitor state (cotton active, amber idle, hollow paused).

## Components

### Container & Chrome

`popover-window` — The single app surface. A 320px-wide `NSPopover` whose own vibrant
`Material` is the glass (the desktop bleeds through). Content is inset 18px; the Aurora bloom
(`{colors.aura-pink}` + `{colors.aura-amber}` radial gradients) is painted over the glass
behind the content. No title bar, no traffic lights — chrome-free by construction.

`glass-sheet` — A reusable floating glass panel helper (`surfaceSheet()`): `regularMaterial`
fill, a 0.75px `{colors.glass-edge}` specular stroke, 18px continuous radius, and a soft
float shadow (`0 12px 22px rgba(0,0,0,0.20)`). The popover content uses the popover's own
material directly; this helper is the standalone-panel equivalent.

`glass-group` — An inset grouped-list card (`surfaceBlock()`) used inside the panel to
cluster rows (the Sugars and Transforms lists). 12px radius, `{colors.group-fill}` film, 1px
`{colors.hairline}` border, 12px horizontal padding, internal `Divider`s between rows. The
System-Settings inset-group pattern.

### Header

`brand-mark` — The lollipop-off glyph on a solid `{colors.mark-tile}` tile, continuous
corner, soft drop shadow. The About / onboarding lockup (not shown in the popover header).

`wordmark` — "sugarfree", lowercase, DynaPuff 600, tracking -0.2px, painted with the cotton
gradient clipped to the glyphs, 22px. The largest brand gesture; one of five sanctioned
gradient surfaces.

`status-pill` — A capsule status tag, SF 10px / 600 / uppercase, at the header's trailing
edge, now with a faint matching specular stroke. Three states:
- `status-pill-active` — `{colors.cotton-tint}` fill, `{colors.cotton-ink}` text, cotton-ring stroke ("ACTIVE").
- `status-pill-paused` — `{colors.hairline}`-at-60% fill, `{colors.secondary}` text ("PAUSED").
- `status-pill-idle` — amber-16% fill, `{colors.idle-amber}` text, amber stroke (on, nothing selected).

### Status Block

`count-figure` — The cumulative cleaned count, SF Mono 15px / 600 in `{colors.text}`, with a
"cleaned" suffix in `{typography.meta-mono}`. Pops + fires a cotton confetti burst on each
clean.

`status-headline` + sub-line — A live sentence ("Auto-cleaned Bold") in
`{typography.status-headline}` (13px / 500), a `{typography.body-small}` detail line in
`{colors.secondary}`, and a `{typography.meta-mono}` timestamp. What / detail / when.

### Controls (native, cotton-tinted)

`toggle-on` — The "Automatic cleanup" switch and per-row sugar/transform toggles: native
SwiftUI `.switch` style, `.tint(Cotton.accent)`. The ON pink is the clearest "this is live"
signal.

`segmented-picker` — "CHECK INTERVAL" (0.25 / 0.5 / 1.0 / 1.5s) and the transform list-format
picker: native `.segmented` style on glass, selection tinted `{colors.cotton-accent}`.

`button-primary` — "Clean Now". Full-width, `{colors.cotton-btn-1}`→`{colors.cotton-btn-2}`
gradient, a white specular sheen across the top half (the liquid highlight), a 0.5px white
edge, 12px continuous radius, and the one brand-colored glow (`{colors.cotton-ring}`).
Pressed → 0.7 opacity; disabled → 0.35. The single primary action; fifth sanctioned gradient
surface counting the aura.

`checkbox` / sugar toggle — Per-sugar enable uses the native switch tinted
`{colors.cotton-accent}`; Bold ships on by default.

### Shortcuts

`shortcut-recorder` — A native `KeyboardShortcuts.Recorder` per action (toggle cleanup /
clean now / open dashboard), `.controlSize(.small)`, `.tint(Cotton.accent)`, with a trailing
↺ reset button. Layout reference: `Design/shortcut-recorder.html`.

`keycap` — A single keyboard glyph rendered as a small glass capsule: `ultraThinMaterial`
fill, 0.75px `{colors.hairline}` edge, 6px radius, soft `0 1px 2px` drop. Used in static
shortcut *hints* (`ShortcutHint`), distinct from the interactive recorder.

### Lists

`sugar-row` — One row per strippable sugar (Bold / Italic / Underline / Strikethrough /
Headers), inside the `glass-group` card. Structure: `[type glyph 16px tertiary] [name
{typography.toggle-label}] [inline mono example, e.g. **bold**, tertiary] [spacer] [native
toggle]`. Rows separated by `Divider`, 7px vertical padding. The inline mono example *shows*
the syntax the row strips.

`example-code-block` — In the table-transform preview: mono text on an `ultraThinMaterial`
inset with a hairline edge, 6px radius. Shows the Markdown → YAML/TOML conversion.

`hairline-rule` — A 1px `{colors.hairline}` line (`SurfaceRule`). The separator between major
sections; `Divider` does the same inside grouped cards.

### Footer

`footer-action` — Plain text "About" (leading) and "Quit" (trailing) in
`{typography.footer-action}` (11.5px / 500) `{colors.secondary}`, below a final separator. No
buttons, no fills — quiet text affordances.

### Menu-Bar Glyph (outside the popover)

`menubar-glyph` — The status-item icon, the only always-visible Sugarfree surface and
deliberately exempt from the glass language. The plain `lollipop` mark as a monochrome
template image following the system tint; its opacity encodes state (active 1.0 / idle 0.85 /
paused 0.5). On each clean it does a one-shot discrete flip to the `lollipop-off` mark tinted
`{colors.cotton-accent}` for ~0.5s — the single documented exception to "the menu bar is
always monochrome." Source of truth: `MenuBarStatusIcon` / `MenuBarStatusItemController`.

## Do's and Don'ts

### Do
- Let the popover's own vibrant `Material` be the glass — paint only the Aurora bloom over it; never cover it with an opaque fill.
- Restrict the cotton gradient to exactly five surfaces: wordmark, ON toggle, "Clean Now" button, active status pill, and the header aura. Everything else is neutral glass.
- Use a thin `{colors.glass-edge}` specular stroke (white ~22%, ≤1px) for glass edges, and soft float shadows for depth.
- Set section headers in native SF (`{typography.section-label}`) — uppercase, +0.5px tracking, secondary — the System Settings grouped-header look.
- Use system label colors (`{colors.text}` / `{colors.secondary}` / `{colors.tertiary}`) so text stays vibrant and legible over translucent glass in both modes.
- Group multi-row lists (Sugars, Transforms) in an inset `glass-group` card with `Divider`s — the native inset grouped-list pattern.
- Keep native controls (switch, segmented, recorder) and just tint them `{colors.cotton-accent}`; don't reinvent them.
- Keep the menu-bar glyph monochrome at rest; let opacity carry state, with the pink flip only as the momentary clean cue.

### Don't
- Don't reintroduce the paper theme's hard ink borders or hard offset shadow — the glass language is bevel highlight + soft float, no hard edges.
- Don't wash a glass surface, row, or group card with the gradient. The candy is an accent event and the header aura; the body glass stays neutral.
- Don't add a second brand accent. Pink (Cotton) is "action/active"; amber (`{colors.idle-amber}`) is "attention" only, never an action.
- Don't use DynaPuff anywhere but the wordmark / icon lockup. Body and UI text are always SF Pro Text.
- Don't set section headers in mono — that was the paper theme; glass headers are native SF. Mono is reserved for the count, keycaps, timestamps, and literal markup.
- Don't put glass or gradient on the menu-bar glyph at rest — it is a monochrome template image; only the ~0.5s clean flip is colored.
- Don't hardcode a hex in a view. Add the token to `Surface` / `Cotton` in `Theme.swift` first, then reference it. A mock and `Theme.swift` disagreeing is drift — fix both in one change.
- Don't widen, scroll, or multi-column the popover. It is a fixed 320px single-column panel by design.

## Appearance & Sizing Behavior

> Sugarfree is a fixed-size native popover, not a responsive web layout — no width
> breakpoints; the column is always 320px. The two axes that vary are system appearance
> (light/dark) and monitor state (active/idle/paused).

### Appearance (light ↔ dark)

| Appearance | Panel | Text | Edge | Gradient |
|---|---|---|---|---|
| Light | vibrant `Material` (light, desktop-tinted) | `.primary` near-black | white 22% specular | #FF6FB5 → #FF9A6B → #FFC857 |
| Dark | vibrant `Material` (dark, desktop-tinted) | `.primary` near-white | white 22% specular | #FF8AC4 → #FFB07A → #FFD879 (brightened) |

Glass and semantic colors re-resolve automatically; the structure, radii, spacing, specular
edge, and soft shadow are identical across appearances. Only the cotton stops carry explicit
brightened dark values so the candy reads on the darker glass.

### State (the real "responsive" axis)

| State | Status pill | Toggle | Menu-bar glyph opacity | Meaning |
|---|---|---|---|---|
| Active | `status-pill-active` (cotton) | ON (`{colors.cotton-accent}`) | 1.0 | Auto-cleanup running, sugars selected |
| Idle | `status-pill-idle` (amber) | ON | 0.85 | Auto-cleanup on, nothing selected to strip |
| Paused | `status-pill-paused` (gray) | OFF | 0.5 | Auto-cleanup off |

State is the axis that actually changes the UI's color — only through the sanctioned accent
surfaces plus the menu-bar glyph's opacity. The layout never reflows.

### Click Targets
- Pointer surface; no touch. Native control sizes (switch, ~28px segmented, recorder).
- The primary button spans the full content width — the largest, most deliberate target.

## Iteration Guide

1. Focus on ONE component at a time. Reference its YAML key directly (`{component.glass-group}`, `{component.button-primary}`).
2. State variants (`-active`, `-idle`, `-paused`, `-on`, `-off`) live as separate entries in `components:`.
3. Use `{token.refs}` everywhere — never inline a hex. New color → add it to `Surface` / `Cotton` in `Theme.swift` first.
4. Document default and pressed/state only — never hover. The meaningful variants are monitor *states*.
5. The gradient is allowed on exactly five surfaces (wordmark, ON toggle, primary button, active pill, header aura) plus the momentary menu-bar flash. Adding a sixth is a brand change → follow the CLAUDE.md design contract (mock → name → approve → build → verify).
6. Depth is specular edge + soft float shadow + the popover's own material. No hard borders, no offset block. The only brand-colored shadow is the button glow.
7. When in doubt about emphasis: add a native section label and group the rows in a glass card before you add a fill or color. Structure over chrome.

## Known Gaps

- This document describes one surface (the menu-bar popover) plus the onboarding window, because the app has no other screens.
- Real Apple "Liquid Glass" system APIs (e.g. `glassEffect`) are macOS 26+; the app targets macOS 13, so the glass is built with `Material` (`regularMaterial` / `ultraThinMaterial`) + specular edge + soft shadow. The look approximates Liquid Glass within the deployment target; on newer OSes the native material simply renders richer.
- The popover's exact translucency/blur is the system's (`NSPopover` vibrant material) — not a token we own; it varies with OS version and what's behind it.
- The onboarding window is a real (opaque) window, so its `regularMaterial` reads as a neutral frosted panel rather than fully desktop-see-through glass; making it truly transparent would need `NSWindow.isOpaque = false` plumbing, not yet done.
- The `KeyboardShortcuts.Recorder` is third-party (sindresorhus/KeyboardShortcuts); its internal recording/empty/conflict states are package-styled — only the outer tint and reset affordance are owned here.
- Native control metrics (switch, segmented) inherit system sizing and may shift with OS version; the values listed are rendered defaults, not Sugarfree tokens.
- The celebratory confetti / menu-bar crush-shard burst uses the discrete `Cotton.candy` stops; its keyframe timing lives in `CrushAnimator` / the confetti views, not as design tokens.
- App-icon master geometry (paper squircle + cotton-gradient lollipop) lives in `Design/AppIcon-master.svg`; this doc covers the in-app mark, not the multi-resolution export.
