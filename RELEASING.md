# Releasing Sugarfree

Sugarfree ships on **two independent release tracks** — they never share a tag or a
GitHub release:

| Track | Tag prefix | Produced by | Assets |
|---|---|---|---|
| macOS app | `app-v<version>` | `./release.sh` (local, notarized) | `Sugarfree-<version>.dmg` |
| Cross-platform CLI | `cli-v<version>` | `.github/workflows/release.yml` (CI) | `sugarfree-<version>-<platform>` tarballs/zip + `.sha256` |

The two are still **independent tracks** — separate tags, separate GitHub releases,
separate build pipelines — but as of 1.5.1 they **share a single version number**:
bump both together and release them at the same version (`app-v<ver>` + `cli-v<ver>`).
The app DMG still bundles a copy of the CLI inside it, but the standalone CLI binaries
are a separate, CI-built release. The rest of this doc covers the **macOS app** track;
the CLI track is just "push a `cli-v*` tag" (see the bottom).

How to cut a signed, **notarized** `.dmg` and publish it. The whole pipeline is one
command — `./release.sh` — once the one-time setup below is in place.

## One-time setup

All of this is done once per machine; none of it is in the repo.

1. **Apple Developer Program** membership (paid — required for Developer ID + notarization).
2. **Developer ID Application certificate** in your login keychain
   (Xcode → Settings → Accounts → Manage Certificates → ＋ → *Developer ID Application*).
   Verify with:
   ```bash
   security find-identity -v -p codesigning | grep "Developer ID Application"
   ```
3. **App Store Connect API key** for notarization (passwordless). Create at
   App Store Connect → Users and Access → Integrations → App Store Connect API
   (role: Developer), then store the pieces in a directory — default
   `~/.secrets/notarytool/`:
   ```
   AuthKey_XXXXXXXXXX.p8   # the downloaded key; key ID is read from the filename
   issuer_id               # one line: the Issuer ID (UUID)
   team_id                 # one line: your 10-char Team ID
   ```
   Point elsewhere with `NOTARY_KEY_DIR=/path ./release.sh`.
4. **Tooling:** `brew install xcodegen create-dmg`.

> The release script needs no `LocalSigning.xcconfig` — it passes `DEVELOPMENT_TEAM`
> (from `team_id`) to `xcodebuild` and signs with the keychain cert directly.

## Cut a release

1. **Bump the version** in **all** places — the app and CLI share one version number,
   so bump them together:
   - `Configs/Base.xcconfig` → `MARKETING_VERSION` (and bump `CURRENT_PROJECT_VERSION`)
   - `project.yml` → `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`
   - `Sources/sugarfree/Sugarfree.swift` → `CommandConfiguration(version:)` (CLI)
2. **Build the notarized DMG:**
   ```bash
   ./release.sh
   ```
   This generates the project, archives the Release config (Developer ID signed,
   hardened runtime), exports the app, **builds the universal `sugarfree` CLI and
   embeds it in the app bundle** (`Contents/Resources/sugarfree`, signed; the app is
   re-signed to reseal its resources), packages a styled DMG with `create-dmg`,
   submits it to Apple's notary service (`notarytool --wait`), then staples and
   validates the ticket. Output: `dist/Sugarfree-<version>.dmg`.

   > Because the CLI ships inside the app, a DMG install also provides the
   > command line: the app symlinks it to `/usr/local/bin/sugarfree` on first launch
   > (`CLIInstaller`, prompting for admin only if that directory isn't writable).
   > Standalone CLI binaries for Linux/Windows (and a macOS-only tarball) are a
   > **separate track** — pushed as `cli-v*` tags (see below), never mixed into the
   > app's `app-v*` release.

## Verify (already done by the script, but to double-check)

```bash
# Ticket is attached to the DMG:
xcrun stapler validate dist/Sugarfree-<version>.dmg

# The app inside assesses as notarized (mount the DMG first):
spctl -a -t exec -vv "/Volumes/Sugarfree <version>/Sugarfree.app"
# expect:  source=Notarized Developer ID
```

Note: `spctl -t open` on the **DMG** reports "no usable signature" — that's expected
(the DMG isn't code-signed; it carries a stapled notarization ticket). The
authoritative checks are `stapler validate` and the app's `Notarized Developer ID`
assessment above.

## Publish the app to GitHub (`app-v*` track)

```bash
gh release upload app-v<version> dist/Sugarfree-<version>.dmg --clobber
# or, for a brand-new tag:
git tag app-v<version> && git push origin app-v<version>
gh release create app-v<version> dist/Sugarfree-<version>.dmg \
  --title "Sugarfree <version>" --generate-notes
```

## Cut a CLI release (`cli-v*` track)

The CLI is built entirely by CI — no local toolchain dance. Just push a `cli-v*` tag
and `.github/workflows/release.yml` builds macOS-universal, Linux x86_64/arm64, and
Windows, then attaches the archives (+ `.sha256`) to a `cli-v<version>` GitHub release:

```bash
# bump version: Sources/sugarfree/Sugarfree.swift (CommandConfiguration version:)
git tag cli-v<version> && git push origin cli-v<version>
```

Watch it: `gh run watch "$(gh run list --workflow=release.yml -L1 --json databaseId -q '.[0].databaseId')"`.
Windows is `continue-on-error` (the least-stable leg), so it never blocks the release.

## Troubleshooting

- **Notarization rejected** — get the details with the submission ID printed by the run:
  ```bash
  xcrun notarytool log <submission-id> \
    --key ~/.secrets/notarytool/AuthKey_*.p8 \
    --key-id <KEYID> --issuer "$(cat ~/.secrets/notarytool/issuer_id)"
  ```
- **No Developer ID cert** — the script stops early; (re)create it via step 2 above.
- **`create-dmg` not found** — `brew install create-dmg`.
