# Sugarfree

## Save tokens. Save time.

<img width="160" height="235" alt="SCR-20260603-osry" src="https://github.com/user-attachments/assets/0fb53c57-4ea4-47f9-b602-382efcc78f4c" />

Sugarfree is a tiny macOS app that strips formatting "sugar" from whatever you copy and lives in your menubar.

AI chat tools (Claude, ChatGPT, Gemini) love to copy text with formatting baked
in — HTML `<strong>`/`<em>`/`<u>`/`<s>`, RTF font traits, markdown `**`/`*`/`~~`.
That styling leaks into every app you paste into. Sugarfree sits in your menu
bar, watches the clipboard, and quietly removes the sugars you choose so the
text you paste is the text you wanted.

## Features

- Menu bar only — no Dock icon, no window clutter (`LSUIElement` agent app).
- Automatic cleanup — polls `NSPasteboard` and rewrites copied text in place.
- Pick your sugars — strip any of **bold**, *italic*, underline, ~~strikethrough~~,
  each independently toggleable (bold + italic on by default).
- Works across representations — RTF font traits and underline/strikethrough
  attributes, HTML tags + inline styles, and markdown markers.
- Structural transforms — optionally reshape content after stripping. Currently
  **Tables → list**: convert Markdown/HTML tables into YAML-style or TOML-style list items.
  Transforms are lossy, so they're off by default and live in their own section.
- Non-destructive — only changed representations are rewritten; unrelated
  pasteboard types and items are preserved.
- Configurable polling interval — 0.25s / 0.5s / 1.0s / 1.5s.
- Manual mode — "Clean Now" cleans the current clipboard on demand.
- Keyboard shortcuts — `⌘⇧P` toggle automatic cleanup, `⌘⇧K` clean now.
- Activity tracking — total cleanups and last action shown in the dashboard.

## Requirements

- macOS 13 (Ventura) or later
- Xcode 15+ and the command-line tools (to build)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Install

### From a release

Download the latest `Sugarfree.app` from the
[Releases page](https://github.com/donny-son/sugarfree/releases), unzip it,
and drag it into `/Applications`.

> The app is distributed unsigned. On first launch macOS Gatekeeper may block
> it. Right-click the app → Open, then confirm. (Or run
> `xattr -dr com.apple.quarantine /Applications/Sugarfree.app`.)

### From source

```bash
git clone https://github.com/donny-son/sugarfree.git
cd sugarfree
./build.sh            # generates the Xcode project and builds Debug
./build.sh --run      # build and launch
```

The build script runs XcodeGen against `project.yml`, then `xcodebuild`. The
built app lands at `build/DerivedData/Build/Products/Debug/Sugarfree.app`.

To work in Xcode:

```bash
xcodegen generate     # regenerate Sugarfree.xcodeproj from project.yml
open Sugarfree.xcodeproj
```

## Usage

1. Launch Sugarfree. The lollipop icon appears in the menu bar with a status dot
   (pink = active, amber = no sugar enabled, grey = paused).
2. Click the icon to open the dashboard: toggle automatic cleanup, run
   "Clean Now", choose which sugars to strip, enable structural transforms,
   set the polling interval, and see an activity summary — all in one place.
3. Copy formatted text from anywhere — paste it, and the sugar is gone.

## How it works

Sugarfree polls `NSPasteboard.general.changeCount` on the chosen interval. When
the clipboard changes, it inspects the RTF, HTML, and plain-text
representations, strips the sugars you enabled from each, and writes the cleaned
versions back. A `selfWriteCount` guard ignores the app's own writes so it
never loops on itself. Representations it doesn't touch are left intact.

## Release signing

For signed builds or notarized archives, copy the signing config template and
fill in your team identity:

```bash
cp Configs/LocalSigning.xcconfig.example Configs/LocalSigning.xcconfig
# set DEVELOPMENT_TEAM and CODE_SIGN_IDENTITY
```

`Configs/Release.xcconfig` includes `LocalSigning.xcconfig` if present.

## License

[MIT](LICENSE) © 2026 Dongook Son
