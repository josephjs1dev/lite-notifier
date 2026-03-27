# lite-notifier

Minimal macOS notification CLI. Sends desktop notifications with a title, message, and optional image thumbnail. Clicking the notification can bring a specified app to front.

No external dependencies — requires only `swiftc` (ships with Xcode Command Line Tools).

## Requirements

- macOS 12+
- Xcode Command Line Tools: `xcode-select --install`

## Install

```bash
git clone <repo> lite-notifier
cd lite-notifier
bash build.sh
```

`build.sh` compiles the Swift source, assembles `lite-notifier.app`, ad-hoc signs it, and symlinks the binary to `~/.local/bin/lite-notifier`.

**Grant notification permission (one-time):**

```bash
lite-notifier --title "Test" --message "Hello"
```

macOS will prompt for notification permission on first run. If no dialog appears, open **System Settings → Notifications → lite-notifier** and enable it manually.

## Usage

```bash
lite-notifier --title <text> [--message <text>] [--icon <path>] [--activate <bundle-id>]
```

| Flag | Description |
|---|---|
| `--title` | Notification title *(required)* |
| `--message` | Notification body |
| `--icon` | Path to image file (PNG/JPEG/ICNS) — shown as thumbnail |
| `--activate` | Bundle ID of app to bring to front when notification is clicked |

**Examples:**

```bash
# Basic
lite-notifier --title "Build done" --message "All tests passed"

# With icon
lite-notifier --title "Claude Code" --message "Task complete" --icon ~/icons/claude.png

# Click to focus Ghostty
lite-notifier --title "Claude Code" --message "Done" --activate com.mitchellh.ghostty

# Click to focus the current terminal (from a shell hook)
lite-notifier --title "Claude Code" --message "Done" --activate "${__CFBundleIdentifier}"
```

## Rebuild after source changes

```bash
bash build.sh
```

The symlink at `~/.local/bin/lite-notifier` updates automatically.

## Uninstall

```bash
bash uninstall.sh
```

This:
1. Unregisters `lite-notifier.app` from macOS Launch Services
2. Removes the `~/.local/bin/lite-notifier` symlink
3. Removes the `lite-notifier.app` bundle

The **System Settings → Notifications** entry is managed by macOS and clears automatically after the next logout or reboot once the app is unregistered. There is no API to force-remove it immediately.

To remove the entire source directory afterward:

```bash
rm -rf lite-notifier
```
