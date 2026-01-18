#!/bin/bash
set -e

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

if [ -f .env ]; then
  set -a
  source .env
  set +a
else
  echo "Error: .env file not found"
  exit 1
fi

# Configuration
APP_NAME="MyMacCleaner"
SCHEME="MyMacCleaner"
VERSION="${1:-}"

if [ -z "$VERSION" ]; then
  echo "Usage: ./scripts/release.sh <version>"
  echo "Example: ./scripts/release.sh 1.1.0"
  exit 1
fi

echo "=========================================="
echo "Building MyMacCleaner v${VERSION}"
echo "=========================================="

# Clean build directory
rm -rf build
mkdir -p build

# Step 1: Build and Archive
echo ""
echo "[1/7] Building and archiving..."
xcodebuild archive \
  -project "${APP_NAME}.xcodeproj" \
  -scheme "${SCHEME}" \
  -archivePath "build/${APP_NAME}.xcarchive" \
  -configuration Release \
  CODE_SIGN_IDENTITY="${MACOS_CERTIFICATE_NAME}" \
  DEVELOPMENT_TEAM="${APPLE_TEAM_ID}" \
  CODE_SIGN_STYLE=Manual \
  OTHER_CODE_SIGN_FLAGS="--options runtime --timestamp" \
  ONLY_ACTIVE_ARCH=NO \
  | xcpretty || xcodebuild archive \
  -project "${APP_NAME}.xcodeproj" \
  -scheme "${SCHEME}" \
  -archivePath "build/${APP_NAME}.xcarchive" \
  -configuration Release \
  CODE_SIGN_IDENTITY="${MACOS_CERTIFICATE_NAME}" \
  DEVELOPMENT_TEAM="${APPLE_TEAM_ID}" \
  CODE_SIGN_STYLE=Manual \
  OTHER_CODE_SIGN_FLAGS="--options runtime --timestamp" \
  ONLY_ACTIVE_ARCH=NO

echo "Archive created successfully"

# Step 2: Export signed app
echo ""
echo "[2/7] Exporting signed app..."
mkdir -p build/export

cat > build/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID}</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Developer ID Application</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
  -archivePath "build/${APP_NAME}.xcarchive" \
  -exportPath build/export \
  -exportOptionsPlist build/ExportOptions.plist

echo "App exported successfully"

# Step 3: Notarize the app
echo ""
echo "[3/7] Notarizing app (this may take a few minutes)..."
cd build/export
ditto -c -k --keepParent "${APP_NAME}.app" "../notarization.zip"
cd ..

xcrun notarytool submit notarization.zip \
  --keychain-profile "notary-profile" \
  --wait

echo "Stapling notarization ticket..."
xcrun stapler staple "export/${APP_NAME}.app"
xcrun stapler validate "export/${APP_NAME}.app"
cd "$PROJECT_DIR"

echo "App notarized and stapled successfully"

# Step 4: Create DMG
echo ""
echo "[4/7] Creating DMG..."
mkdir -p build/dmg-contents
cp -R "build/export/${APP_NAME}.app" build/dmg-contents/
ln -s /Applications build/dmg-contents/Applications

hdiutil create -volname "${APP_NAME}" \
  -srcfolder build/dmg-contents \
  -ov -format UDZO \
  "build/${APP_NAME}-v${VERSION}.dmg"

echo "DMG created successfully"

# Step 5: Sign the DMG
echo ""
echo "[5/7] Signing DMG..."
codesign --force --sign "${MACOS_CERTIFICATE_NAME}" \
  --options runtime --timestamp \
  "build/${APP_NAME}-v${VERSION}.dmg"

echo "DMG signed successfully"

# Step 6: Notarize the DMG
echo ""
echo "[6/7] Notarizing DMG..."
xcrun notarytool submit "build/${APP_NAME}-v${VERSION}.dmg" \
  --keychain-profile "notary-profile" \
  --wait

xcrun stapler staple "build/${APP_NAME}-v${VERSION}.dmg"

echo "DMG notarized and stapled successfully"

# Step 7: Create ZIP for Sparkle and sign
echo ""
echo "[7/7] Creating Sparkle update ZIP..."
cd build/export
zip -r -y "../${APP_NAME}-v${VERSION}.zip" "${APP_NAME}.app"
cd "$PROJECT_DIR"

# Sign with Sparkle (if sign_update is available)
echo "Signing update for Sparkle..."

# Try to find sign_update
SPARKLE_SIGN=$(find ~/Library/Developer/Xcode/DerivedData -name "sign_update" -path "*/Sparkle.framework/*" 2>/dev/null | head -1)

if [ -z "$SPARKLE_SIGN" ]; then
  # Download Sparkle if not found
  echo "Downloading Sparkle tools..."
  curl -L -o /tmp/sparkle.tar.xz "https://github.com/sparkle-project/Sparkle/releases/download/2.6.4/Sparkle-2.6.4.tar.xz"
  mkdir -p /tmp/sparkle
  tar -xf /tmp/sparkle.tar.xz -C /tmp/sparkle
  SPARKLE_SIGN="/tmp/sparkle/bin/sign_update"
fi

# Create temp file for private key
echo "$SPARKLE_PRIVATE_KEY" > /tmp/sparkle_key
SIGNATURE=$("$SPARKLE_SIGN" --ed-key-file /tmp/sparkle_key "build/${APP_NAME}-v${VERSION}.zip")
rm -f /tmp/sparkle_key

echo ""
echo "=========================================="
echo "BUILD COMPLETE!"
echo "=========================================="
echo ""
echo "Files created in build/:"
ls -lh "build/${APP_NAME}-v${VERSION}.dmg" "build/${APP_NAME}-v${VERSION}.zip"
echo ""
echo "Sparkle signature:"
echo "$SIGNATURE"
echo ""
FILE_SIZE=$(stat -f%z "build/${APP_NAME}-v${VERSION}.zip")
echo "File size: $FILE_SIZE bytes"
echo ""
echo "Appcast XML snippet:"
echo "----------------------------------------"
cat << EOF
<item>
  <title>Version ${VERSION}</title>
  <pubDate>$(date -R)</pubDate>
  <sparkle:version>${VERSION}</sparkle:version>
  <enclosure
    url="https://github.com/Prot10/MyMacCleaner/releases/download/v${VERSION}/${APP_NAME}-v${VERSION}.zip"
    ${SIGNATURE}
    length="${FILE_SIZE}"
    type="application/octet-stream"/>
</item>
EOF
echo "----------------------------------------"
echo ""
echo "Next steps:"
echo "1. Create GitHub release: gh release create v${VERSION} build/${APP_NAME}-v${VERSION}.dmg build/${APP_NAME}-v${VERSION}.zip --title 'MyMacCleaner v${VERSION}'"
echo "2. Update appcast.xml with the snippet above"
