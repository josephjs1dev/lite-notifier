#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/lite-notifier.app"
BINARY="$APP/Contents/MacOS/lite-notifier"
LINK="$HOME/.local/bin/lite-notifier"

echo "Building lite-notifier.app..."

# Create app bundle structure
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# Copy Info.plist
cp "$DIR/Info.plist" "$APP/Contents/Info.plist"

# Compile
SOUND_FLAG=""
[[ "${LITE_NOTIFIER_SOUND:-0}" == "1" ]] && SOUND_FLAG="-D WITH_SOUND"

swiftc "$DIR/main.swift" \
    -o "$BINARY" \
    -sdk "$(xcrun --show-sdk-path)" \
    -framework AppKit \
    -framework UserNotifications \
    -O \
    ${SOUND_FLAG:+"$SOUND_FLAG"}

echo "Compiled: $BINARY"

# Copy app icon if available
ICON_SRC="$HOME/.claude/bin/assets/AppIcon.icns"
if [[ -f "$ICON_SRC" ]]; then
  cp "$ICON_SRC" "$APP/Contents/Resources/AppIcon.icns"
  echo "Icon:     $APP/Contents/Resources/AppIcon.icns"
fi

# Ad-hoc sign (required on macOS 26+ for notification permissions)
codesign --sign - --force --deep "$APP" 2>/dev/null
echo "Signed:   $APP"

# Symlink to PATH
mkdir -p "$(dirname "$LINK")"
ln -sf "$BINARY" "$LINK"
echo "Linked: $LINK -> $BINARY"

echo "Done. Test with:"
echo "  lite-notifier --title \"Hello\" --message \"World\""
