#!/bin/bash
set -e

SRC_ICON="$(dirname "$0")/../assets/icon/app_icon.png"
RES_DIR="$(dirname "$0")/../android/app/src/main/res"
IOS_DIR="$(dirname "$0")/../ios/Runner/Assets.xcassets/AppIcon.appiconset"

echo "Generating Android Mipmaps from $SRC_ICON..."
python3 "$(dirname "$0")/generate_android_adaptive_icons.py"

echo "Generating iOS AppIcons..."
sips -z 40 40     "$SRC_ICON" --out "$IOS_DIR/Icon-App-20x20@2x.png" >/dev/null
sips -z 60 60     "$SRC_ICON" --out "$IOS_DIR/Icon-App-20x20@3x.png" >/dev/null
sips -z 58 58     "$SRC_ICON" --out "$IOS_DIR/Icon-App-29x29@2x.png" >/dev/null
sips -z 87 87     "$SRC_ICON" --out "$IOS_DIR/Icon-App-29x29@3x.png" >/dev/null
sips -z 80 80     "$SRC_ICON" --out "$IOS_DIR/Icon-App-40x40@2x.png" >/dev/null
sips -z 120 120   "$SRC_ICON" --out "$IOS_DIR/Icon-App-40x40@3x.png" >/dev/null
sips -z 120 120   "$SRC_ICON" --out "$IOS_DIR/Icon-App-60x60@2x.png" >/dev/null
sips -z 180 180   "$SRC_ICON" --out "$IOS_DIR/Icon-App-60x60@3x.png" >/dev/null
sips -z 1024 1024 "$SRC_ICON" --out "$IOS_DIR/Icon-App-1024x1024@1x.png" >/dev/null

cat << 'EOF' > "$IOS_DIR/Contents.json"
{
  "images": [
    {
      "size": "20x20",
      "idiom": "iphone",
      "filename": "Icon-App-20x20@2x.png",
      "scale": "2x"
    },
    {
      "size": "20x20",
      "idiom": "iphone",
      "filename": "Icon-App-20x20@3x.png",
      "scale": "3x"
    },
    {
      "size": "29x29",
      "idiom": "iphone",
      "filename": "Icon-App-29x29@2x.png",
      "scale": "2x"
    },
    {
      "size": "29x29",
      "idiom": "iphone",
      "filename": "Icon-App-29x29@3x.png",
      "scale": "3x"
    },
    {
      "size": "40x40",
      "idiom": "iphone",
      "filename": "Icon-App-40x40@2x.png",
      "scale": "2x"
    },
    {
      "size": "40x40",
      "idiom": "iphone",
      "filename": "Icon-App-40x40@3x.png",
      "scale": "3x"
    },
    {
      "size": "60x60",
      "idiom": "iphone",
      "filename": "Icon-App-60x60@2x.png",
      "scale": "2x"
    },
    {
      "size": "60x60",
      "idiom": "iphone",
      "filename": "Icon-App-60x60@3x.png",
      "scale": "3x"
    },
    {
      "size": "1024x1024",
      "idiom": "ios-marketing",
      "filename": "Icon-App-1024x1024@1x.png",
      "scale": "1x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
EOF

echo "All Android & iOS icons generated successfully!"
