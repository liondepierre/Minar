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

echo "Creating distribution zip for sharing..."
(cd build && rm -f Minar.zip && zip -rq Minar.zip Minar.app)

echo "Done! App built: $APP_DIR"
echo "Distribution archive: build/Minar.zip"
