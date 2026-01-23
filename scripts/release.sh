#!/bin/bash
set -e

# =============================================================================
# MyMacCleaner Release Script
# =============================================================================
# This script automates the complete release process:
# 1. Updates version numbers in Xcode project
# 2. Builds, signs, and notarizes the app
# 3. Creates DMG and ZIP packages
# 4. Signs the ZIP for Sparkle auto-updates
# 5. Updates appcast.xml and releases.json
# 6. Creates GitHub release with assets
# 7. Commits and pushes all changes
#
# Usage: ./scripts/release.sh <version> "<changelog>"
# Example: ./scripts/release.sh 0.1.0 "Initial release with core features"
#
# Prerequisites:
# - .env file with Apple credentials and Sparkle key
# - Keychain profile 'notary-profile' configured
# - gh CLI authenticated
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Create .env from .env.example and fill in your credentials"
    exit 1
fi

# Validate required environment variables
if [ -z "$MACOS_CERTIFICATE_SHA1" ]; then
    echo -e "${RED}Error: MACOS_CERTIFICATE_SHA1 not set in .env${NC}"
    echo "Run 'security find-identity -v -p codesigning' to find your certificate SHA-1"
    exit 1
fi

if [ -z "$APPLE_TEAM_ID" ]; then
    echo -e "${RED}Error: APPLE_TEAM_ID not set in .env${NC}"
    exit 1
fi

if [ -z "$SPARKLE_PRIVATE_KEY" ]; then
    echo -e "${RED}Error: SPARKLE_PRIVATE_KEY not set in .env${NC}"
    exit 1
fi

# Configuration
APP_NAME="MyMacCleaner"
SCHEME="MyMacCleaner"
REPO="Prot10/MyMacCleaner"
VERSION="${1:-}"
CHANGELOG="${2:-}"

# Validate arguments
if [ -z "$VERSION" ]; then
    echo -e "${YELLOW}Usage: ./scripts/release.sh <version> \"<changelog>\"${NC}"
    echo "Example: ./scripts/release.sh 0.1.0 \"Initial release\""
    exit 1
fi

if [ -z "$CHANGELOG" ]; then
    echo -e "${YELLOW}Warning: No changelog provided. Using default message.${NC}"
    CHANGELOG="Release v${VERSION}"
fi

# Get current build number and increment
CURRENT_BUILD=$(grep -m1 "CURRENT_PROJECT_VERSION = " "${APP_NAME}.xcodeproj/project.pbxproj" | sed 's/.*= \([0-9]*\);/\1/')
NEW_BUILD=$((CURRENT_BUILD + 1))

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  MyMacCleaner Release v${VERSION}${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo -e "Version: ${GREEN}${VERSION}${NC}"
echo -e "Build:   ${GREEN}${NEW_BUILD}${NC}"
echo -e "Changelog: ${CHANGELOG}"
echo ""

# =============================================================================
# Step 1: Update version in Xcode project
# =============================================================================
echo -e "${YELLOW}[1/10] Updating version in Xcode project...${NC}"

# Update MARKETING_VERSION (display version)
sed -i '' "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = ${VERSION};/g" "${APP_NAME}.xcodeproj/project.pbxproj"

# Update CURRENT_PROJECT_VERSION (build number)
sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = ${NEW_BUILD};/g" "${APP_NAME}.xcodeproj/project.pbxproj"

echo -e "${GREEN}Version updated to ${VERSION} (build ${NEW_BUILD})${NC}"

# =============================================================================
# Step 2: Clean and build
# =============================================================================
echo ""
echo -e "${YELLOW}[2/10] Building and archiving...${NC}"

rm -rf build
mkdir -p build

xcodebuild archive \
    -project "${APP_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -archivePath "build/${APP_NAME}.xcarchive" \
    -configuration Release \
    CODE_SIGN_IDENTITY="${MACOS_CERTIFICATE_SHA1}" \
    DEVELOPMENT_TEAM="${APPLE_TEAM_ID}" \
    CODE_SIGN_STYLE=Manual \
    OTHER_CODE_SIGN_FLAGS="--options runtime --timestamp" \
    ONLY_ACTIVE_ARCH=NO \
    2>&1 | tee build/build.log | grep -E "^(Build|Archive|error:|warning:)" || true

if [ ! -d "build/${APP_NAME}.xcarchive" ]; then
    echo -e "${RED}Build failed. Check build/build.log for details.${NC}"
    exit 1
fi

echo -e "${GREEN}Archive created successfully${NC}"

# =============================================================================
# Step 3: Export signed app
# =============================================================================
echo ""
echo -e "${YELLOW}[3/10] Exporting signed app...${NC}"

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
    -exportOptionsPlist build/ExportOptions.plist \
    2>&1 | tee -a build/build.log | grep -E "^(Export|error:)" || true

if [ ! -d "build/export/${APP_NAME}.app" ]; then
    echo -e "${RED}Export failed. Check build/build.log for details.${NC}"
    exit 1
fi

echo -e "${GREEN}App exported successfully${NC}"

# =============================================================================
# Step 4: Notarize the app
# =============================================================================
echo ""
echo -e "${YELLOW}[4/10] Notarizing app...${NC}"

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

echo -e "${GREEN}App notarized and stapled successfully${NC}"

# =============================================================================
# Step 5: Create DMG
# =============================================================================
echo ""
echo -e "${YELLOW}[5/10] Creating DMG...${NC}"

mkdir -p build/dmg-contents
cp -R "build/export/${APP_NAME}.app" build/dmg-contents/
ln -s /Applications build/dmg-contents/Applications

hdiutil create -volname "${APP_NAME}" \
    -srcfolder build/dmg-contents \
    -ov -format UDZO \
    "build/${APP_NAME}-v${VERSION}.dmg"

echo -e "${GREEN}DMG created successfully${NC}"

# =============================================================================
# Step 6: Sign and notarize DMG
# =============================================================================
echo ""
echo -e "${YELLOW}[6/10] Signing and notarizing DMG...${NC}"

codesign --force --sign "${MACOS_CERTIFICATE_SHA1}" \
    --options runtime --timestamp \
    "build/${APP_NAME}-v${VERSION}.dmg"

xcrun notarytool submit "build/${APP_NAME}-v${VERSION}.dmg" \
    --keychain-profile "notary-profile" \
    --wait

xcrun stapler staple "build/${APP_NAME}-v${VERSION}.dmg"

echo -e "${GREEN}DMG signed and notarized successfully${NC}"

# =============================================================================
# Step 7: Create ZIP for Sparkle and sign
# =============================================================================
echo ""
echo -e "${YELLOW}[7/10] Creating Sparkle update ZIP...${NC}"

cd build/export
zip -r -y "../${APP_NAME}-v${VERSION}.zip" "${APP_NAME}.app"
cd "$PROJECT_DIR"

# Find or download Sparkle sign_update tool
SPARKLE_SIGN=$(find ~/Library/Developer/Xcode/DerivedData -name "sign_update" -path "*/Sparkle.framework/*" 2>/dev/null | head -1)

if [ -z "$SPARKLE_SIGN" ]; then
    echo "Downloading Sparkle tools..."
    curl -L -s -o /tmp/sparkle.tar.xz "https://github.com/sparkle-project/Sparkle/releases/download/2.6.4/Sparkle-2.6.4.tar.xz"
    mkdir -p /tmp/sparkle
    tar -xf /tmp/sparkle.tar.xz -C /tmp/sparkle
    SPARKLE_SIGN="/tmp/sparkle/bin/sign_update"
fi

# Sign with Sparkle
echo "$SPARKLE_PRIVATE_KEY" > /tmp/sparkle_key
SIGNATURE_OUTPUT=$("$SPARKLE_SIGN" --ed-key-file /tmp/sparkle_key "build/${APP_NAME}-v${VERSION}.zip")
rm -f /tmp/sparkle_key

# Parse signature from output (format: sparkle:edSignature="..." length="...")
ED_SIGNATURE=$(echo "$SIGNATURE_OUTPUT" | grep -o 'sparkle:edSignature="[^"]*"' | cut -d'"' -f2)
FILE_SIZE=$(stat -f%z "build/${APP_NAME}-v${VERSION}.zip")
DMG_SIZE=$(stat -f%z "build/${APP_NAME}-v${VERSION}.dmg")
DMG_SIZE_MB=$(echo "scale=1; $DMG_SIZE / 1048576" | bc)

echo -e "${GREEN}ZIP created and signed for Sparkle${NC}"
echo "Signature: ${ED_SIGNATURE:0:20}..."

# =============================================================================
# Step 8: Update appcast.xml
# =============================================================================
echo ""
echo -e "${YELLOW}[8/10] Updating appcast.xml...${NC}"

# Get current date in RFC 2822 format
PUB_DATE=$(date -R)

# Create the new item entry
NEW_ITEM=$(cat << EOF
        <item>
            <title>Version ${VERSION}</title>
            <pubDate>${PUB_DATE}</pubDate>
            <sparkle:version>${NEW_BUILD}</sparkle:version>
            <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
            <description><![CDATA[
                <h2>What's New in Version ${VERSION}</h2>
                <ul>
                    <li>${CHANGELOG}</li>
                </ul>
            ]]></description>
            <enclosure url="https://github.com/${REPO}/releases/download/v${VERSION}/${APP_NAME}-v${VERSION}.zip" sparkle:edSignature="${ED_SIGNATURE}" length="${FILE_SIZE}" type="application/octet-stream"/>
        </item>
EOF
)

# Insert new item after the comment line
if grep -q "<!-- Releases will be added here" appcast.xml; then
    # Fresh appcast, replace the comment
    sed -i '' "s|<!-- Releases will be added here by the release script -->|${NEW_ITEM}|" appcast.xml
else
    # Add new item at the top (after <language>en</language>)
    ESCAPED_ITEM=$(echo "$NEW_ITEM" | sed 's/[&/\]/\\&/g' | tr '\n' '\r')
    sed -i '' "/<language>en<\/language>/a\\
\\
${NEW_ITEM}
" appcast.xml
fi

echo -e "${GREEN}appcast.xml updated${NC}"

# =============================================================================
# Step 9: Update releases.json
# =============================================================================
echo ""
echo -e "${YELLOW}[9/10] Updating releases.json...${NC}"

RELEASE_DATE=$(date +%Y-%m-%d)

# Read current releases
CURRENT_RELEASES=$(cat website/public/data/releases.json)

# Mark all existing releases as not latest
UPDATED_RELEASES=$(echo "$CURRENT_RELEASES" | sed 's/"latest": true/"latest": false/g')

# Determine changelog type based on keywords
if echo "$CHANGELOG" | grep -qi "fix"; then
    CHANGE_TYPE="fixed"
elif echo "$CHANGELOG" | grep -qi "improve\|enhance\|update"; then
    CHANGE_TYPE="changed"
else
    CHANGE_TYPE="added"
fi

# Create new release entry
NEW_RELEASE=$(cat << EOF
{
      "version": "${VERSION}",
      "date": "${RELEASE_DATE}",
      "latest": true,
      "minOS": "macOS 14.0+",
      "architecture": "Universal (Apple Silicon + Intel)",
      "downloads": {
        "dmg": {
          "url": "https://github.com/${REPO}/releases/download/v${VERSION}/${APP_NAME}-v${VERSION}.dmg",
          "size": "${DMG_SIZE_MB} MB"
        }
      },
      "changelog": [
        { "type": "${CHANGE_TYPE}", "description": "${CHANGELOG}" }
      ]
    }
EOF
)

# Check if releases array is empty
if echo "$UPDATED_RELEASES" | grep -q '"releases": \[\]'; then
    # Empty releases array
    echo "{
  \"releases\": [
    ${NEW_RELEASE}
  ]
}" > website/public/data/releases.json
else
    # Add to existing releases (insert at beginning of array)
    echo "$UPDATED_RELEASES" | sed "s/\"releases\": \[/\"releases\": [\n    ${NEW_RELEASE},/" > website/public/data/releases.json
fi

echo -e "${GREEN}releases.json updated${NC}"

# =============================================================================
# Step 10: Create GitHub release and push
# =============================================================================
echo ""
echo -e "${YELLOW}[10/10] Creating GitHub release and pushing changes...${NC}"

# Create GitHub release
gh release create "v${VERSION}" \
    "build/${APP_NAME}-v${VERSION}.dmg" \
    "build/${APP_NAME}-v${VERSION}.zip" \
    --repo "${REPO}" \
    --title "${APP_NAME} v${VERSION}" \
    --notes "${CHANGELOG}"

echo -e "${GREEN}GitHub release created${NC}"

# Git commit and push
git add -A
git commit -m "release: v${VERSION}

${CHANGELOG}

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

git push origin main

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  Release v${VERSION} Complete!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo "Files created:"
ls -lh "build/${APP_NAME}-v${VERSION}.dmg" "build/${APP_NAME}-v${VERSION}.zip"
echo ""
echo -e "GitHub Release: ${BLUE}https://github.com/${REPO}/releases/tag/v${VERSION}${NC}"
echo ""
