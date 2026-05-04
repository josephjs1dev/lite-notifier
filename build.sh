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

# Copy app icon
# Override default by setting ICON_VARIANT=<name> (without .icns extension).
# Available variants: light_mono_v1, dark_neon_v1, light_gradient_v1, brushed_metal_v1
ICON_VARIANT="${ICON_VARIANT:-light_mono_v1}"
ICON_SRC="$DIR/assets/${ICON_VARIANT}.icns"
if [[ ! -f "$ICON_SRC" ]]; then
  echo "Error: icon variant '${ICON_VARIANT}' not found at $ICON_SRC" >&2
  echo "Available variants: $(ls "$DIR/assets/"*.icns | xargs -n1 basename | sed 's/\.icns//')" >&2
  exit 1
fi
cp "$ICON_SRC" "$APP/Contents/Resources/AppIcon.icns"
echo "Icon:     ${ICON_VARIANT} -> $APP/Contents/Resources/AppIcon.icns"

# Ad-hoc sign (required on macOS 26+ for notification permissions)
codesign --sign - --force --deep "$APP" 2>/dev/null
echo "Signed:   $APP"

# Symlink to PATH
mkdir -p "$(dirname "$LINK")"
ln -sf "$BINARY" "$LINK"
echo "Linked: $LINK -> $BINARY"

echo "Done. Test with:"
echo "  lite-notifier --title \"Hello\" --message \"World\""
