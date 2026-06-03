# NoBold

Strip bold formatting from clipboard content. Two independent tools that solve the same problem at different layers.

## Why

AI chat tools (Claude, ChatGPT, Gemini) copy text with bold formatting (HTML `<strong>`/`<b>`, RTF bold traits, markdown `**`/`__`). This is annoying when pasting into other apps.

## Architecture

### Chrome Extension (`chrome-extension/`)
- Manifest V3 content script, no popup/background/permissions
- Intercepts `copy` event in capture phase, strips bold from HTML and plain text before it hits the system clipboard
- Covers all copies within Chrome

### Mac Menubar App (`mac-app/NoBold/`)
- SwiftUI `MenuBarExtra` utility (macOS 13+), `LSUIElement` (no Dock icon)
- Uses a custom menu bar dashboard plus a native Settings window for status, controls, and format preferences
- Built as a real Xcode macOS app target generated from `mac-app/project.yml` via XcodeGen
- Polls `NSPasteboard.general.changeCount` on a configurable interval
- Strips bold from RTF (font descriptor traits), HTML (tag/style removal), and plain text (markdown markers)
- Rewrites only changed clipboard representations and preserves unrelated pasteboard types/items
- Tracks `selfWriteCount` to prevent infinite loops
- Covers copies from any app outside Chrome

### How they coexist
Chrome extension strips at copy time (before system pasteboard). Mac app strips from the pasteboard after any app writes. If both active, Chrome handles Chrome copies, Mac app handles everything else. If Chrome already cleaned it, Mac app sees no bold and skips.

## Build

```bash
# Chrome extension: load unpacked at chrome://extensions
# Mac app:
cd mac-app
./build.sh
# Optional: ./build.sh --run
# Open in Xcode:
open NoBold.xcodeproj
```

For release signing, copy `mac-app/Configs/LocalSigning.xcconfig.example` to `mac-app/Configs/LocalSigning.xcconfig` and fill in your team identity.

## Design workflow (contract)

Any visual / branding change MUST follow this loop. These are rules, not suggestions.

1. Mock before you build. Prototype design directions as a self-contained HTML/CSS file in `Design/` (e.g. `Design/theme-options.html`). Render the *real* UI surfaces (the menu-bar popover, settings) so type, color, and weight are judged in context — not abstract swatches.
2. Name every option. Each direction gets a stable name (e.g. Ink, Graphite, Daylight). The user approves exactly one by name before any native code changes. Do not start the SwiftUI work until a named option is chosen.
3. Single source of truth for tokens. `NoBold/Theme.swift` (the `Ink` enum + reusable views: `BrandMark`, `inkSheet()`, `StatusPill`, `InkPrimaryButtonStyle`, `SectionLabel`, `InkRule`) is the canonical home for the palette and shared styles.
   - Component views MUST reference `Theme.swift` tokens — never hardcode a hex value in a view. New color/spacing → add it to the `Ink` enum first, then use it.
   - HTML mocks must mirror the same token values. If a mock and `Theme.swift` disagree, that's drift — fix it in the same change.
4. Verify before claiming done. After implementing, `./build.sh` must succeed, then relaunch (`pkill -x NoBold; open build/DerivedData/Build/Products/Debug/NoBold.app`) and visually confirm the popover. Report build status honestly.
5. Keep platforms in parity. The Mac app and Chrome extension solve the same problem; a behavior change to bold-stripping in one should be mirrored (or consciously noted) in the other. Keep "Bold types handled" below accurate.

### Brand assets
- Logo source: `Design/logo-stars-off.svg` (tabler `stars-off`). In-app it ships as the `StarsOff` template imageset in `Assets.xcassets`, tinted via `.renderingMode(.template)`.
- App icon master: `Design/AppIcon-master.svg` (ink squircle + paper line mark). Regenerate the `AppIcon.appiconset` PNGs from it with:
  ```bash
  for s in 16 32 64 128 256 512 1024; do \
    rsvg-convert -w $s -h $s Design/AppIcon-master.svg \
      -o NoBold/Assets.xcassets/AppIcon.appiconset/icon-$s.png; done
  ```
- AccentColor carries explicit light/dark values so controls stay visible in both appearances; keep it aligned with the `Ink` palette.

## Bold types handled
- HTML: `<strong>`, `<b>` tags, `font-weight` inline styles
- RTF: `.bold` symbolic trait on `NSFontDescriptor`
- Plain text: `text` and `text` markdown markers
