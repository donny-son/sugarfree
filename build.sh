#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_NAME="Sugarfree"
PROJECT_FILE="$SCRIPT_DIR/$PROJECT_NAME.xcodeproj"
BUILD_DIR="$SCRIPT_DIR/build"
DERIVED_DATA_DIR="$BUILD_DIR/DerivedData"
CONFIGURATION="${CONFIGURATION:-Debug}"
APP_DIR="$DERIVED_DATA_DIR/Build/Products/$CONFIGURATION/$PROJECT_NAME.app"
XCODEGEN_BIN=$(command -v xcodegen || true)
ARCH=$(uname -m)

mkdir -p "$BUILD_DIR"

if [[ -z "$XCODEGEN_BIN" ]]; then
    echo "xcodegen is required to generate $PROJECT_NAME.xcodeproj" >&2
    exit 1
fi

"$XCODEGEN_BIN" generate --spec "$SCRIPT_DIR/project.yml" --project "$SCRIPT_DIR"

xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme "$PROJECT_NAME" \
    -configuration "$CONFIGURATION" \
    -destination "platform=macOS,arch=$ARCH" \
    -derivedDataPath "$DERIVED_DATA_DIR" \
    build

echo "Built $APP_DIR"

if [[ "${1:-}" == "--run" ]]; then
    open "$APP_DIR"
fi
