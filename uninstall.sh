#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/lite-notifier.app"
LINK="$HOME/.local/bin/lite-notifier"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

# Unregister from Launch Services (clears the Notifications entry in System Settings)
# macOS removes the System Settings entry automatically after logout/reboot once the app is gone.
if [[ -d "$APP" ]]; then
  "$LSREGISTER" -u "$APP" 2>/dev/null && echo "Unregistered from Launch Services"
fi

# Remove symlink
if [[ -L "$LINK" ]]; then
  rm "$LINK" && echo "Removed: $LINK"
fi

# Remove app bundle
if [[ -d "$APP" ]]; then
  rm -rf "$APP" && echo "Removed: $APP"
fi

echo ""
echo "Done. The 'lite-notifier' entry in System Settings → Notifications will"
echo "disappear automatically after your next logout or reboot."
