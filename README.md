# NoBold

<img width="160" height="233" alt="SCR-20260603-lbid" src="https://github.com/user-attachments/assets/bb4be89e-efa5-46a4-8cc3-0e796c8ffe36" />

A tiny macOS menu bar app that strips bold formatting from whatever you copy.

AI chat tools (Claude, ChatGPT, Gemini) love to copy text with bold styling
baked in — HTML `<strong>`/`<b>`, RTF bold font traits, markdown `**`/`__`.
That bold leaks into every app you paste into. NoBold sits in your menu bar,
watches the clipboard, and quietly removes the bold so the text you paste is
the text you wanted.

## Features

- Menu bar only — no Dock icon, no window clutter (`LSUIElement` agent app).
- Automatic cleanup — polls `NSPasteboard` and rewrites copied text in place.
- Three formats, independently toggleable:
  - Rich text (RTF) — removes the `.bold` symbolic trait from font descriptors.
  - HTML — strips `<strong>`/`<b>` tags and `font-weight` inline styles.
  - Markdown — removes `text` and `text` emphasis markers.
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

Download the latest `NoBold.app` from the
[Releases page](https://github.com/donny-son/nobold-mac/releases), unzip it,
and drag it into `/Applications`.

> The app is distributed unsigned. On first launch macOS Gatekeeper may block
> it. Right-click the app → Open, then confirm. (Or run
> `xattr -dr com.apple.quarantine /Applications/NoBold.app`.)

### From source

```bash
git clone https://github.com/donny-son/nobold-mac.git
cd nobold-mac
./build.sh            # generates the Xcode project and builds Debug
./build.sh --run      # build and launch
```

The build script runs XcodeGen against `project.yml`, then `xcodebuild`. The
built app lands at `build/DerivedData/Build/Products/Debug/NoBold.app`.

To work in Xcode:

```bash
xcodegen generate     # regenerate NoBold.xcodeproj from project.yml
open NoBold.xcodeproj
```

## Usage

1. Launch NoBold. The stars-off icon appears in the menu bar with a status dot
   (green = active, amber = no format enabled, grey = paused).
2. Click the icon to open the dashboard: toggle automatic cleanup, run
   "Clean Now", and choose which formats to strip.
3. Open Settings… for the polling interval and an activity summary.
4. Copy bold text from anywhere — paste it, and the bold is gone.

## How it works

NoBold polls `NSPasteboard.general.changeCount` on the chosen interval. When
the clipboard changes, it inspects the RTF, HTML, and plain-text
representations, strips bold from the enabled ones, and writes the cleaned
versions back. A `selfWriteCount` guard ignores the app's own writes so it
never loops on itself. Representations it doesn't touch are left intact.

## Companion: Chrome extension

NoBold has a sibling Chrome extension (Manifest V3 content script) that strips
bold at *copy time*, before text ever reaches the system clipboard. The two
coexist cleanly: the extension handles copies made inside Chrome, and this app
handles copies from every other application. If the extension already cleaned
a copy, this app sees no bold and skips it.

## Project layout

```
NoBold/                  Swift sources
  NoBoldApp.swift          @main app, MenuBarExtra scene, onboarding
  PasteboardMonitor.swift  clipboard polling + bold-stripping logic
  MenuBarDashboard.swift   menu bar dashboard UI
  SettingsView.swift       native Settings window
  OnboardingView.swift     first-launch welcome
Configs/                 xcconfig build settings
Design/                  logo + app icon master SVGs
project.yml              XcodeGen spec
build.sh                 generate + build script
```

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
