# MyMacCleaner Release Guide

This guide explains how to create new releases for MyMacCleaner with proper versioning, code signing, notarization, and auto-update support via Sparkle.

## Prerequisites

### 1. Environment Setup

Create a `.env` file in the project root (copy from `.env.example`):

```bash
cp .env.example .env
```

Required variables in `.env`:

```bash
# Apple Developer credentials
APPLE_TEAM_ID=YOUR_TEAM_ID           # e.g., 7K4SKUHU47
MACOS_CERTIFICATE_SHA1=YOUR_CERT_SHA1 # Run: security find-identity -v -p codesigning

# Sparkle EdDSA key for signing updates (base64 encoded)
SPARKLE_PRIVATE_KEY=YOUR_PRIVATE_KEY  # Generate with: ./bin/generate_keys
```

### 2. Keychain Profile for Notarization

Set up a notarization profile (one-time setup):

```bash
xcrun notarytool store-credentials "notary-profile" \
  --apple-id "your@email.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "app-specific-password"
```

Create an app-specific password at: https://appleid.apple.com/account/manage

### 3. GitHub CLI Authentication

```bash
gh auth login
```

### 4. Sparkle EdDSA Keys

If you don't have Sparkle keys yet:

```bash
# Download Sparkle tools
curl -L -o /tmp/sparkle.tar.xz https://github.com/sparkle-project/Sparkle/releases/download/2.6.4/Sparkle-2.6.4.tar.xz
mkdir -p ./bin && tar -xf /tmp/sparkle.tar.xz -C ./bin

# Generate new keys
./bin/generate_keys
```

Save the private key to your `.env` file and add the public key to your app's `Info.plist` as `SUPublicEDKey`.

---

## Release Process

### Quick Release (Recommended)

**Step 1:** Update `CHANGELOG.md` during development. Add your changes to the `[Unreleased]` section:

```markdown
## [Unreleased]

- [added] New feature description
- [fixed] Bug fix description
- [changed] Improvement description
- [removed] Removed feature description
```

**Step 2:** When ready to release, run:

```bash
./scripts/release.sh <version>
```

**Examples:**

```bash
# Patch release (bug fixes)
./scripts/release.sh 0.1.2

# Minor release (new features)
./scripts/release.sh 0.2.0

# Major release
./scripts/release.sh 1.0.0
```

The script automatically:
1. Reads changelog from `CHANGELOG.md` `[Unreleased]` section
2. Increments the build number
3. Updates version in Xcode project
4. Builds and archives the app
5. Signs with Developer ID certificate
6. Notarizes with Apple
7. Creates DMG and ZIP packages
8. Signs ZIP for Sparkle auto-updates
9. Updates `appcast.xml` for Sparkle
10. Updates `website/public/data/releases.json`
11. Creates GitHub release with assets
12. Updates `CHANGELOG.md` (moves `[Unreleased]` to versioned section)
13. Commits and pushes all changes

---

## Manual Release Steps (If Needed)

If you need to do a manual release or the script fails partway through:

### Step 1: Update Version Numbers

Edit `MyMacCleaner.xcodeproj/project.pbxproj`:
- `MARKETING_VERSION` = display version (e.g., "0.1.2")
- `CURRENT_PROJECT_VERSION` = build number (integer, e.g., 3)

Or use sed:
```bash
sed -i '' 's/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = 0.1.2;/g' MyMacCleaner.xcodeproj/project.pbxproj
sed -i '' 's/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = 3;/g' MyMacCleaner.xcodeproj/project.pbxproj
```

### Step 2: Build and Archive

```bash
xcodebuild archive \
  -project MyMacCleaner.xcodeproj \
  -scheme MyMacCleaner \
  -archivePath build/MyMacCleaner.xcarchive \
  -configuration Release \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID"
```

### Step 3: Export Signed App

```bash
xcodebuild -exportArchive \
  -archivePath build/MyMacCleaner.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
```

### Step 4: Notarize

```bash
# Create ZIP for notarization
ditto -c -k --keepParent build/export/MyMacCleaner.app build/notarization.zip

# Submit for notarization
xcrun notarytool submit build/notarization.zip \
  --keychain-profile "notary-profile" \
  --wait

# Staple the ticket
xcrun stapler staple build/export/MyMacCleaner.app
```

### Step 5: Create DMG

```bash
create-dmg \
  --volname "MyMacCleaner" \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "MyMacCleaner.app" 150 200 \
  --app-drop-link 450 200 \
  build/MyMacCleaner-v0.1.2.dmg \
  build/export/MyMacCleaner.app

# Sign and notarize DMG
codesign --force --sign "Developer ID Application: Your Name (TEAM_ID)" build/MyMacCleaner-v0.1.2.dmg
xcrun notarytool submit build/MyMacCleaner-v0.1.2.dmg --keychain-profile "notary-profile" --wait
xcrun stapler staple build/MyMacCleaner-v0.1.2.dmg
```

### Step 6: Create Sparkle ZIP

```bash
cd build/export
zip -r ../MyMacCleaner-v0.1.2.zip MyMacCleaner.app
cd ../..

# Sign with Sparkle EdDSA key
./bin/sign_update build/MyMacCleaner-v0.1.2.zip
```

### Step 7: Update appcast.xml

Add new item at the TOP of the channel (most recent first):

```xml
<item>
    <title>Version 0.1.2</title>
    <pubDate>Fri, 24 Jan 2026 10:00:00 +0100</pubDate>
    <sparkle:version>3</sparkle:version>
    <sparkle:shortVersionString>0.1.2</sparkle:shortVersionString>
    <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
    <description><![CDATA[
        <h2>What's New in Version 0.1.2</h2>
        <ul>
            <li>Your changelog here</li>
        </ul>
    ]]></description>
    <enclosure
        url="https://github.com/Prot10/MyMacCleaner/releases/download/v0.1.2/MyMacCleaner-v0.1.2.zip"
        sparkle:edSignature="YOUR_SIGNATURE_HERE"
        length="FILE_SIZE_IN_BYTES"
        type="application/octet-stream"/>
</item>
```

### Step 8: Create GitHub Release

```bash
gh release create v0.1.2 \
  --title "MyMacCleaner v0.1.2" \
  --notes "Your changelog here" \
  build/MyMacCleaner-v0.1.2.dmg \
  build/MyMacCleaner-v0.1.2.zip
```

### Step 9: Commit and Push

```bash
git add -A
git commit -m "release: v0.1.2"
git push
```

---

## Version Numbering

Follow semantic versioning (MAJOR.MINOR.PATCH):

| Type | When to Use | Example |
|------|-------------|---------|
| PATCH | Bug fixes, minor improvements | 0.1.1 → 0.1.2 |
| MINOR | New features, backward compatible | 0.1.2 → 0.2.0 |
| MAJOR | Breaking changes, major rewrites | 0.2.0 → 1.0.0 |

**Build numbers** are always incremented (never reset) and are used internally for update comparison.

---

## How Auto-Updates Work

1. **On app launch**: `UpdateManager` fetches `appcast.xml` from GitHub
2. **Version comparison**: Compares `sparkle:version` (build number) with current app's `CFBundleVersion`
3. **If update available**: Sets `updateAvailable = true`, button appears in toolbar
4. **User clicks button**: Shows update sheet with version details
5. **User clicks "Download & Install"**: Sparkle handles download, verification, and installation

### Key Files for Auto-Updates

| File | Purpose |
|------|---------|
| `appcast.xml` | Sparkle feed with version info and signatures |
| `Info.plist` → `SUFeedURL` | URL to appcast.xml |
| `Info.plist` → `SUPublicEDKey` | Public key for signature verification |
| `UpdateManager.swift` | Fetches appcast, compares versions |
| `UpdateAvailableButton.swift` | UI for update notification |

---

## Troubleshooting

### Update button doesn't appear

1. **Check build numbers**: The appcast `sparkle:version` must be greater than the app's `CFBundleVersion`
2. **Check appcast URL**: Verify `SUFeedURL` in Info.plist points to raw GitHub URL
3. **Check Console logs**: Filter for `[UpdateManager]` to see fetch results
4. **Clear cache**: The app uses cache-busting, but try quitting and restarting

### Notarization fails

1. **Check credentials**: Run `xcrun notarytool history --keychain-profile "notary-profile"`
2. **Check entitlements**: Ensure hardened runtime is enabled
3. **Check signing**: Run `codesign -dvvv build/export/MyMacCleaner.app`

### Sparkle signature error

1. **Check key match**: Public key in Info.plist must match private key used for signing
2. **Re-sign the ZIP**: `./bin/sign_update build/MyMacCleaner-vX.X.X.zip`
3. **Update appcast**: Ensure `sparkle:edSignature` matches the new signature

### GitHub release issues

1. **Check authentication**: Run `gh auth status`
2. **Check repository**: Ensure you're in the correct repo
3. **Delete and retry**: `gh release delete vX.X.X --yes` then re-run script

---

## Clean Slate Release

If you need to start fresh (delete all releases and re-release):

```bash
# Delete all GitHub releases
gh release list | awk '{print $3}' | xargs -I {} gh release delete {} --yes

# Delete all tags
git tag -l | xargs -I {} git tag -d {}
git tag -l | xargs -I {} git push origin --delete {}

# Clear appcast.xml (keep only channel header)
cat > appcast.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>MyMacCleaner Updates</title>
        <link>https://github.com/Prot10/MyMacCleaner</link>
        <description>Most recent changes with links to updates.</description>
        <language>en</language>

    </channel>
</rss>
EOF

# Set version to X.Y.Z with build 0 (script will increment to 1)
sed -i '' 's/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = 0.1.0;/g' MyMacCleaner.xcodeproj/project.pbxproj
sed -i '' 's/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = 0;/g' MyMacCleaner.xcodeproj/project.pbxproj

# Reset CHANGELOG.md
cat > CHANGELOG.md << 'EOF'
# Changelog

All notable changes to MyMacCleaner will be documented in this file.

## [Unreleased]

- [added] Initial release with auto-update functionality

EOF

# Commit and push
git add -A && git commit -m "chore: prepare for fresh release" && git push

# Release first version
./scripts/release.sh 0.1.0

# Update CHANGELOG.md for second version
cat > CHANGELOG.md << 'EOF'
# Changelog

All notable changes to MyMacCleaner will be documented in this file.

## [Unreleased]

- [changed] Update notification improvements

## [0.1.0] - 2026-01-23

- [added] Initial release with auto-update functionality

EOF

git add CHANGELOG.md && git commit -m "docs: prepare changelog for v0.1.1" && git push

# Release second version (for testing updates)
./scripts/release.sh 0.1.1
```

---

## Quick Reference

```bash
# 1. Update CHANGELOG.md with your changes during development
# 2. When ready to release:
./scripts/release.sh 0.1.2

# Check current version
grep -m1 "MARKETING_VERSION" MyMacCleaner.xcodeproj/project.pbxproj
grep -m1 "CURRENT_PROJECT_VERSION" MyMacCleaner.xcodeproj/project.pbxproj

# List GitHub releases
gh release list

# View appcast
cat appcast.xml

# View changelog
cat CHANGELOG.md

# Check notarization history
xcrun notarytool history --keychain-profile "notary-profile"
```
