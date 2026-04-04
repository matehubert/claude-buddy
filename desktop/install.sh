#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="ClaudeBuddy"
APP_DIR="$SCRIPT_DIR/.build/$APP_NAME.app"
INSTALL_DIR="$HOME/Applications"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.claude.buddy.plist"
PLIST_PATH="$PLIST_DIR/$PLIST_NAME"

# Step 1: Build
echo "==> Step 1: Building..."
bash "$SCRIPT_DIR/build.sh"

# Step 2: Kill any running instances
echo "==> Step 2: Stopping running instances..."
killall ClaudeBuddy 2>/dev/null || true
sleep 1

# Step 3: Copy to ~/Applications
echo "==> Step 3: Installing to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "$APP_DIR" "$INSTALL_DIR/$APP_NAME.app"

INSTALLED_APP="$INSTALL_DIR/$APP_NAME.app"

# Step 4: Create LaunchAgent for auto-start on login
echo "==> Step 4: Setting up LaunchAgent..."
mkdir -p "$PLIST_DIR"

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claude.buddy</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALLED_APP/Contents/MacOS/ClaudeBuddy</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF

# Register LaunchAgent (RunAtLoad=true means it starts immediately + on every login)
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

echo "==> Done!"
echo "    App installed to: $INSTALLED_APP"
echo "    LaunchAgent: $PLIST_PATH (auto-starts on login)"
