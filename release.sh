#!/bin/zsh

# Build, sign, package, and notarize a distributable Sugarfree DMG.
#
# Auth comes from an App Store Connect API key directory (no passwords, no
# keychain profile). Default location: ~/.secrets/notarytool/ containing:
#     AuthKey_XXXXXXXXXX.p8   (the API key; key ID is taken from the filename)
#     issuer_id               (one line: the Issuer ID)
#     team_id                 (one line: your 10-char Team ID)
# Override the directory with:  NOTARY_KEY_DIR=/path ./release.sh
#
# Also required (one-time):
#   - Apple Developer Program membership
#   - a "Developer ID Application" certificate in your login keychain
#   - create-dmg:  brew install create-dmg

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_NAME="Sugarfree"
PROJECT_FILE="$SCRIPT_DIR/$PROJECT_NAME.xcodeproj"
BUILD_DIR="$SCRIPT_DIR/build"
DIST_DIR="$SCRIPT_DIR/dist"
ARCHIVE_PATH="$BUILD_DIR/$PROJECT_NAME.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
EXPORT_OPTIONS="$BUILD_DIR/ExportOptions.plist"
APP_PATH="$EXPORT_DIR/$PROJECT_NAME.app"
NOTARY_KEY_DIR="${NOTARY_KEY_DIR:-$HOME/.secrets/notarytool}"

# --- preflight ----------------------------------------------------------------

require() {
    command -v "$1" >/dev/null 2>&1 || { echo "error: '$1' is required ($2)" >&2; exit 1; }
}
require xcodegen "brew install xcodegen"
require create-dmg "brew install create-dmg"
require xcrun "install Xcode command line tools"

# Notary credentials (App Store Connect API key).
NOTARY_KEY=$(print -r -- "$NOTARY_KEY_DIR"/AuthKey_*.p8(N) | head -n1)
if [[ -z "$NOTARY_KEY" || ! -f "$NOTARY_KEY" ]]; then
    echo "error: no AuthKey_*.p8 found in $NOTARY_KEY_DIR" >&2
    exit 1
fi
# Key ID is embedded in the filename: AuthKey_<KEYID>.p8
NOTARY_KEY_ID=$(basename "$NOTARY_KEY" | sed -E 's/^AuthKey_//; s/\.p8$//')
NOTARY_ISSUER=$(tr -d '[:space:]' < "$NOTARY_KEY_DIR/issuer_id")
TEAM_ID=$(tr -d '[:space:]' < "$NOTARY_KEY_DIR/team_id")
if [[ -z "$NOTARY_ISSUER" || -z "$TEAM_ID" ]]; then
    echo "error: issuer_id or team_id missing/empty in $NOTARY_KEY_DIR" >&2
    exit 1
fi

# Signing certificate must be present in the keychain.
if ! security find-identity -v -p codesigning 2>/dev/null \
        | grep -q "Developer ID Application"; then
    echo "error: no 'Developer ID Application' certificate in your keychain." >&2
    echo "       Xcode > Settings > Accounts > Manage Certificates > + > Developer ID Application" >&2
    exit 1
fi

VERSION=$(grep -E '^[[:space:]]*MARKETING_VERSION[[:space:]]*=' "$SCRIPT_DIR/Configs/Base.xcconfig" \
    | head -n1 | sed -E 's/.*=[[:space:]]*//; s/[[:space:]]*$//')
VERSION="${VERSION:-0.0.0}"
DMG_PATH="$DIST_DIR/$PROJECT_NAME-$VERSION.dmg"

echo "==> Releasing $PROJECT_NAME $VERSION (team $TEAM_ID, key $NOTARY_KEY_ID)"

# --- 1. generate project ------------------------------------------------------

rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR"
xcodegen generate --spec "$SCRIPT_DIR/project.yml" --project "$SCRIPT_DIR"

# --- 2. archive (Release, signed with the Developer ID cert) ------------------

echo "==> Archiving..."
xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme "$PROJECT_NAME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    archive

# --- 3. export a Developer ID app from the archive ----------------------------

cat > "$EXPORT_OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
</dict>
</plist>
PLIST

echo "==> Exporting signed app..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS"

# --- 3.5 embed the universal CLI in the app bundle ----------------------------
#
# Ship `sugarfree` (the cross-platform CLI) inside the app so a DMG install also
# provides the command line. The app symlinks it onto PATH on first launch
# (CLIInstaller). The binary is signed (hardened runtime) and the app is then
# re-signed so its resource seal covers the new file — both required for
# notarization.

echo "==> Building universal sugarfree CLI..."
require swift "install Xcode command line tools"
swift build -c release --arch arm64 --arch x86_64 --product sugarfree
CLI_SRC="$SCRIPT_DIR/.build/apple/Products/Release/sugarfree"
if [[ ! -f "$CLI_SRC" ]]; then
    echo "error: built CLI not found at $CLI_SRC" >&2
    exit 1
fi

CLI_DEST="$APP_PATH/Contents/Resources/sugarfree"
cp "$CLI_SRC" "$CLI_DEST"
chmod +x "$CLI_DEST"

# Resolve the Developer ID Application identity (SHA-1) for signing.
SIGN_HASH=$(security find-identity -v -p codesigning \
    | awk '/Developer ID Application/ {print $2; exit}')
if [[ -z "$SIGN_HASH" ]]; then
    echo "error: could not resolve a Developer ID Application identity" >&2
    exit 1
fi

echo "==> Signing embedded CLI..."
codesign --force --options runtime --timestamp -s "$SIGN_HASH" "$CLI_DEST"

echo "==> Re-signing app bundle (resealing resources)..."
APP_ENT="$BUILD_DIR/app-entitlements.plist"
codesign -d --entitlements - --xml "$APP_PATH" > "$APP_ENT" 2>/dev/null || true
if [[ -s "$APP_ENT" ]]; then
    codesign --force --options runtime --timestamp \
        --entitlements "$APP_ENT" -s "$SIGN_HASH" "$APP_PATH"
else
    codesign --force --options runtime --timestamp -s "$SIGN_HASH" "$APP_PATH"
fi
codesign --verify --deep --strict "$APP_PATH"

# --- 4. package a styled DMG --------------------------------------------------

echo "==> Building DMG..."
rm -f "$DMG_PATH"
create-dmg \
    --volname "$PROJECT_NAME $VERSION" \
    --window-size 540 380 \
    --icon-size 110 \
    --icon "$PROJECT_NAME.app" 150 190 \
    --app-drop-link 390 190 \
    "$DMG_PATH" \
    "$APP_PATH"

# --- 5. notarize the DMG (API key), then staple -------------------------------

echo "==> Notarizing..."
xcrun notarytool submit "$DMG_PATH" \
    --key "$NOTARY_KEY" \
    --key-id "$NOTARY_KEY_ID" \
    --issuer "$NOTARY_ISSUER" \
    --wait

echo "==> Stapling..."
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

echo ""
echo "Done: $DMG_PATH"
