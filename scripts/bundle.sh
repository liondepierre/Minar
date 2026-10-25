#!/bin/bash
set -e
cd "$(dirname "$0")/.."

echo "Compiling Universal binary (Apple Silicon + Intel)..."
swift build -c release --arch arm64 --arch x86_64

APP_DIR="build/Minar.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp .build/out/Products/Release/Minar "$APP_DIR/Contents/MacOS/Minar"
chmod +x "$APP_DIR/Contents/MacOS/Minar"

# Copy App Icon
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

cat << 'EOF' > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Minar</string>
    <key>CFBundleIdentifier</key>
    <string>com.user.Minar</string>
    <key>CFBundleName</key>
    <string>Minar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "Signing app with local ad-hoc certificate..."
codesign --force --deep -s - "$APP_DIR"

echo "Creating distribution zip..."
(cd build && rm -f Minar.zip && zip -rq Minar.zip Minar.app)

echo "Generating themed DMG installer..."
if [ ! -f "Resources/dmg_background.png" ]; then
    swift scripts/generate_dmg_background.swift
fi

DMG_TEMP="/tmp/minar_temp_$$.dmg"
rm -f "$DMG_TEMP"
hdiutil create -size 60m -volname "Minar" -fs HFS+ -ov "$DMG_TEMP" > /dev/null
MOUNT_DIR=$(hdiutil attach "$DMG_TEMP" -nobrowse -noverify -noautoopen | grep -E '/Volumes/' | awk '{print $NF}')

cp -R "$APP_DIR" "$MOUNT_DIR/"
ln -s /Applications "$MOUNT_DIR/Applications"
mkdir -p "$MOUNT_DIR/.background"
cp Resources/dmg_background.png "$MOUNT_DIR/.background/background.png"
chflags hidden "$MOUNT_DIR/.background"

# Style the Finder window to compact 540x340 Navy theme
osascript -e '
tell application "Finder"
  tell disk "Minar"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {450, 220, 990, 560}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 84
    set background picture of viewOptions to file ".background:background.png"
    set position of item "Minar.app" of container window to {135, 170}
    set position of item "Applications" of container window to {405, 170}
    try
      set position of item ".background" of container window to {1500, 1500}
    end try
    update without registering applications
    delay 1
    close
  end tell
end tell' > /dev/null 2>&1 || true

sync
sleep 1
hdiutil detach "$MOUNT_DIR" > /dev/null 2>&1 || true

rm -f build/Minar.dmg
hdiutil convert "$DMG_TEMP" -format UDZO -imagekey zlib-level=9 -o build/Minar.dmg > /dev/null
rm -f "$DMG_TEMP"

echo "Done! App built: $APP_DIR"
echo "Distribution archive: build/Minar.zip"
echo "Distribution disk image: build/Minar.dmg"
