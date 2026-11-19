#!/usr/bin/env bash
# Installs Vale and the Omni style guide on macOS.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/exploreomni/vale-style-guide/main/install.sh | bash
#
# Options:
#   --auto-update      Sync the style guide every Monday without asking
#   --no-auto-update   Don't set up automatic updates, and remove them if they exist

set -euo pipefail

PACKAGE_URL="${OMNI_VALE_PACKAGE:-https://github.com/exploreomni/vale-style-guide/releases/latest/download/omni.zip}"
VALE_DIR="$HOME/Library/Application Support/vale"
CONFIG="$VALE_DIR/.vale.ini"
AGENT_LABEL="co.omni.vale-sync"
AGENT_PLIST="$HOME/Library/LaunchAgents/$AGENT_LABEL.plist"

auto_update=""
for arg in "$@"; do
  case "$arg" in
    --auto-update) auto_update="yes" ;;
    --no-auto-update) auto_update="no" ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

if [[ "$(uname)" != "Darwin" ]]; then
  echo "This script only works on macOS." >&2
  exit 1
fi

# Install Vale
if ! command -v vale >/dev/null 2>&1; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required. Install it from https://brew.sh, then run this script again." >&2
    exit 1
  fi
  echo "Installing Vale..."
  brew install vale
fi
VALE_BIN="$(command -v vale)"

# Write the global config. Vale uses it in every folder.
mkdir -p "$VALE_DIR"
if [[ -f "$CONFIG" ]]; then
  backup="$CONFIG.backup-$(date +%Y%m%d%H%M%S)"
  cp "$CONFIG" "$backup"
  echo "Saved your existing Vale config to $backup"
fi

cat > "$CONFIG" <<EOF
MinAlertLevel = suggestion
Packages = $PACKAGE_URL
Vocab = Omni

[formats]
mdx = md

[*.{md,mdx,txt}]
BasedOnStyles = omni, ai-tells
EOF

echo "Downloading the Omni style guide..."
"$VALE_BIN" --config "$CONFIG" sync

# Automatic updates
if [[ -z "$auto_update" ]]; then
  if [[ -r /dev/tty ]]; then
    read -r -p "Update the style guide automatically every Monday? [y/N] " answer </dev/tty
    [[ "$answer" =~ ^[Yy] ]] && auto_update="yes" || auto_update="no"
  else
    auto_update="no"
  fi
fi

launchctl bootout "gui/$(id -u)/$AGENT_LABEL" >/dev/null 2>&1 || true

if [[ "$auto_update" == "yes" ]]; then
  mkdir -p "$(dirname "$AGENT_PLIST")"
  cat > "$AGENT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$AGENT_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$VALE_BIN</string>
    <string>--config</string>
    <string>$CONFIG</string>
    <string>sync</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key>
    <integer>1</integer>
    <key>Hour</key>
    <integer>10</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
</dict>
</plist>
EOF
  launchctl bootstrap "gui/$(id -u)" "$AGENT_PLIST"
  echo "Automatic updates are on. To turn them off, run this script again with --no-auto-update."
else
  rm -f "$AGENT_PLIST"
  echo "Automatic updates are off. To get updates, run: vale --config \"$CONFIG\" sync"
fi

echo "Done. To check a file, run: vale <file>"
