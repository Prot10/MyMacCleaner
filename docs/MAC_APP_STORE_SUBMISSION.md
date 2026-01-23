# Mac App Store Submission Guide for MyMacCleaner

## Overview

This document outlines the process to submit MyMacCleaner to the Mac App Store. Due to mandatory sandboxing requirements, this requires creating a **limited "App Store Edition"** that runs alongside the existing full-featured direct distribution.

---

## The Trade-off

| Distribution | Features | Reach |
|-------------|----------|-------|
| **Direct (current)** | 100% - Full Disk Access, all cleaning | GitHub/Website users |
| **App Store (new)** | ~30-40% - User files only | Millions of Mac users |

**Recommendation:** Maintain both. The App Store version serves as marketing/discovery to drive users to the full version.

---

## Implementation Plan

### Phase 1: Apple Developer Setup

#### 1.1 Create App Store Distribution Certificate
1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. Certificates → Create → "Apple Distribution"
3. Download and install in Keychain

#### 1.2 Create App Store Provisioning Profile
1. Profiles → Create → "Mac App Store"
2. Select App ID: `com.mymaccleaner.MyMacCleaner`
3. Select your Apple Distribution certificate
4. Download and install

#### 1.3 Register App in App Store Connect
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. My Apps → "+" → New App
3. Platform: macOS
4. Bundle ID: `com.mymaccleaner.MyMacCleaner`
5. Name: "MyMacCleaner" (or "MyMacCleaner Lite" if keeping names distinct)

---

### Phase 2: Create App Store Build Configuration

#### 2.1 Create Sandboxed Entitlements File

Create `MyMacCleaner/MyMacCleaner-AppStore.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

#### 2.2 Add App Store Build Configuration in Xcode

1. Open Project Settings → Info tab
2. Under "Configurations", click "+" and duplicate "Release"
3. Name it "Release-AppStore"
4. For the MyMacCleaner target in Release-AppStore:
   - Set `CODE_SIGN_ENTITLEMENTS` = `MyMacCleaner/MyMacCleaner-AppStore.entitlements`
   - Set `CODE_SIGN_IDENTITY` = `Apple Distribution`
   - Set `CODE_SIGN_STYLE` = `Automatic`
   - Add `SWIFT_ACTIVE_COMPILATION_CONDITIONS` = `APPSTORE_BUILD`

#### 2.3 Create App Store Scheme
1. Product → Scheme → Manage Schemes
2. Duplicate "MyMacCleaner" scheme
3. Name: "MyMacCleaner-AppStore"
4. Edit scheme → Archive → Build Configuration: "Release-AppStore"

---

### Phase 3: Code Changes for Sandbox Compatibility

#### 3.1 Add Feature Detection

Create `Core/Services/AppDistribution.swift`:

```swift
enum AppDistribution {
    static var isAppStore: Bool {
        #if APPSTORE_BUILD
        return true
        #else
        return false
        #endif
    }
}
```

#### 3.2 Disable Unsupported Features in App Store Build

Add `#if !APPSTORE_BUILD` guards to:

| File | What to Hide |
|------|-------------|
| `ContentView.swift` | Hide navigation sections: Orphaned Files, Port Management, Startup Items, Permissions |
| `HomeView.swift` | Hide FDA prompts, permission banners |
| `DiskCleanerView.swift` | Hide system caches, Xcode cleanup categories |
| `PerformanceView.swift` | Hide maintenance tab, purge cache button |
| `ApplicationsView.swift` | Hide homebrew tab, uninstall functionality |
| `AppCard.swift` | Hide uninstall button |
| `MyMacCleanerApp.swift` | Conditionally disable Sparkle, menu bar |

Example pattern:
```swift
#if !APPSTORE_BUILD
// Direct distribution only code
PermissionBanner(permissionsService: PermissionsService.shared)
#endif
```

#### 3.3 Conditionally Disable Sparkle

In `MyMacCleanerApp.swift`:
```swift
#if !APPSTORE_BUILD
import Sparkle
@State private var updateManager = UpdateManager()
#endif
```

---

### Phase 4: App Store Metadata

#### 4.1 Required Assets
- **App Icon**: Already have (1024x1024 in Assets.xcassets)
- **Screenshots**: 5-10 at 1280x800 or 1440x900 minimum
- **Preview Video**: Optional (15-30 seconds)

#### 4.2 App Store Description

```
MyMacCleaner is a modern, lightweight macOS utility for cleaning
and optimizing your Mac.

Features:
• Clean user caches and temporary files
• Find duplicate files in your folders
• Monitor memory and CPU usage
• Visualize disk space usage
• Manage startup items

Built with SwiftUI featuring an elegant Liquid Glass design.

Note: This App Store edition focuses on user-level cleanup.
For full system cleaning capabilities, visit our website.
```

#### 4.3 Category and Keywords
- **Category**: Utilities
- **Keywords**: cleaner, disk, space, cache, cleanup, optimizer, mac

---

### Phase 5: Build and Upload

#### 5.1 Create Export Options Plist

Create `ExportOptions-AppStore.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>7K4SKUHU47</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```

#### 5.2 Archive for App Store

```bash
xcodebuild archive \
    -project MyMacCleaner.xcodeproj \
    -scheme "MyMacCleaner-AppStore" \
    -configuration Release-AppStore \
    -archivePath build/MyMacCleaner-AppStore.xcarchive
```

#### 5.3 Export for App Store

```bash
xcodebuild -exportArchive \
    -archivePath build/MyMacCleaner-AppStore.xcarchive \
    -exportPath build/AppStore \
    -exportOptionsPlist ExportOptions-AppStore.plist
```

#### 5.4 Upload
- **Via Xcode**: Window → Organizer → Select archive → Distribute App → App Store Connect
- **Via Transporter**: Download from Mac App Store, drag & drop the .pkg

---

### Phase 6: Submit for Review

1. In App Store Connect, select the uploaded build
2. Complete all required metadata
3. Answer export compliance questions (typically "No" for encryption)
4. Submit for review

---

## Features Available in App Store Version

| Feature | Status | Notes |
|---------|--------|-------|
| User cache cleanup | ✅ | `~/Library/Caches` only |
| Downloads cleanup | ✅ | |
| Trash management | ✅ | |
| RAM monitoring | ✅ | Read-only |
| Disk space visualization | ⚠️ | User folders only |
| Duplicate finder | ⚠️ | User-selected folders only |
| App list viewing | ✅ | |
| System caches | ❌ | Blocked by sandbox |
| Xcode cleanup | ❌ | Blocked by sandbox |
| Orphaned files | ❌ | Blocked by sandbox |
| Maintenance tasks | ❌ | Require admin |
| Port management | ❌ | Require lsof |
| App uninstall | ❌ | Blocked by sandbox |

---

## Files to Create/Modify Summary

| File | Action |
|------|--------|
| `MyMacCleaner-AppStore.entitlements` | Create |
| `ExportOptions-AppStore.plist` | Create |
| `Core/Services/AppDistribution.swift` | Create |
| `project.pbxproj` | Add Release-AppStore config |
| `Features/*/` views | Add `#if !APPSTORE_BUILD` guards |
| `App/MyMacCleanerApp.swift` | Conditional Sparkle import |

---

## Verification Checklist

- [ ] Build App Store version locally with Release-AppStore configuration
- [ ] Run from archive to verify sandboxing works
- [ ] Verify no crashes from blocked file access
- [ ] Verify disabled features are hidden in UI
- [ ] Test all remaining features work correctly
- [ ] Validate in Xcode Organizer before upload
- [ ] Monitor App Store Connect for review feedback

---

## Timeline Estimate

| Phase | Duration |
|-------|----------|
| Apple Developer setup | Same day |
| Build configuration | 1-2 hours |
| Code changes | 4-8 hours |
| Metadata preparation | 1-2 hours |
| Build & submit | 1 hour |
| Apple review | 1-3 days |

---

## Notes

- Keep both distribution channels: Direct (full features) and App Store (limited)
- Use App Store as discovery/marketing to drive users to the full version
- Consider adding an "Upgrade to Full Version" link in the App Store edition
- Test thoroughly in sandbox before submitting to avoid rejection
