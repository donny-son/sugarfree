# Releasing Sugarfree

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

1. **Bump the version** in **both** places (kept in sync per `CLAUDE.md`):
   - `Configs/Base.xcconfig` → `MARKETING_VERSION` (and bump `CURRENT_PROJECT_VERSION`)
   - `project.yml` → `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`
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
   > Standalone CLI binaries for Linux/Windows (and a macOS-only tarball) come from
   > the separate `.github/workflows/release.yml` tag build.

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

## Publish to GitHub

```bash
gh release upload v<version> dist/Sugarfree-<version>.dmg --clobber
# or, for a brand-new tag:
gh release create v<version> dist/Sugarfree-<version>.dmg --title "Sugarfree v<version>" --generate-notes
```

## Troubleshooting

- **Notarization rejected** — get the details with the submission ID printed by the run:
  ```bash
  xcrun notarytool log <submission-id> \
    --key ~/.secrets/notarytool/AuthKey_*.p8 \
    --key-id <KEYID> --issuer "$(cat ~/.secrets/notarytool/issuer_id)"
  ```
- **No Developer ID cert** — the script stops early; (re)create it via step 2 above.
- **`create-dmg` not found** — `brew install create-dmg`.
