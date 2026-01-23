# MyMacCleaner - Project Specification

## Overview

**MyMacCleaner** - Open-source macOS system utility with Apple's Liquid Glass UI design.

| Attribute | Value |
|-----------|-------|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Target | macOS 14.0+ (Sonoma) |
| Design | Liquid Glass (native on macOS 26+, material fallback on 14-15) |
| Architecture | MVVM with Swift actors for services |
| Status | Beta (v0.1.x) |

## Features

| Feature | Description |
|---------|-------------|
| **Home** | Smart Scan dashboard with system stats, permission prompts |
| **Disk Cleaner** | Category-based cleanup (caches, logs, Xcode, browser data, trash) |
| **Space Lens** | Treemap visualization of disk usage with squarified algorithm |
| **Orphaned Files** | Detect leftover files from uninstalled apps |
| **Duplicates** | Find duplicate files by hash with cancellation support |
| **Performance** | RAM monitoring, process list (htop-like), 8 maintenance tasks |
| **Applications** | App manager with Sparkle update checking, Homebrew cask integration |
| **Port Management** | Network connections via lsof, process killing |
| **System Health** | Health score gauge, disk/battery/system info |
| **Startup Items** | Login item management via BTM |
| **Permissions** | FDA and folder access management with TCC dialog triggers |
| **Menu Bar** | Real-time CPU/RAM/Disk stats with 4 display modes |
| **Localization** | EN/IT/ES with runtime switching |

## Project Structure

```
MyMacCleaner/
├── App/                    # MyMacCleanerApp.swift, ContentView.swift
├── Core/
│   ├── Design/            # Theme, LiquidGlass, Animations, ToastView
│   ├── Services/          # FileScanner, PermissionsService, AuthorizationService,
│   │                      # AppUpdateChecker, HomebrewService, LocalizationManager,
│   │                      # BrowserCleanerService, OrphanedFilesScanner,
│   │                      # DuplicateScanner, SystemStatsProvider
│   ├── Models/            # ScanResult, PermissionCategory
│   └── Extensions/
├── Features/
│   ├── Home/              # HomeView, HomeViewModel, ScanResultsCard, PermissionPromptView
│   ├── DiskCleaner/       # DiskCleanerView, BrowserPrivacyView, CleanupCategoryCard
│   ├── SpaceLens/         # SpaceLensView, TreemapLayout
│   ├── OrphanedFiles/     # OrphanedFilesView
│   ├── Duplicates/        # DuplicatesView
│   ├── Performance/       # PerformanceView (Memory, Processes, Maintenance tabs)
│   ├── Applications/      # ApplicationsView (All Apps, Updates, Homebrew tabs)
│   ├── PortManagement/    # PortManagementView
│   ├── SystemHealth/      # SystemHealthView
│   ├── StartupItems/      # StartupItemsView
│   └── Permissions/       # PermissionsView
├── MenuBar/               # MenuBarController, MenuBarView
└── Resources/             # Assets.xcassets, Localizable.xcstrings
```

## Key Technical Decisions

- **Memory calculation**: Active + Wired + Compressed (matches htop)
- **Admin commands**: Single AppleScript password prompt for batch operations
- **File iteration**: `while let obj = enumerator.nextObject()` pattern for async safety
- **Homebrew detection**: Checks both `/opt/homebrew/bin/brew` (ARM) and `/usr/local/bin/brew` (Intel)
- **Permissions**: TCC folders trigger dialog via `FileManager.contentsOfDirectory()`, FDA requires System Settings
- **Liquid Glass**: `#available(macOS 26, *)` checks with `.ultraThinMaterial` fallback

## Build Commands

```bash
xcodebuild -project MyMacCleaner.xcodeproj -scheme MyMacCleaner build
xcodebuild test -project MyMacCleaner.xcodeproj -scheme MyMacCleaner
```

## Release Process

The release script automates the complete release workflow:

```bash
./scripts/release.sh <version> "<changelog>"
# Example: ./scripts/release.sh 0.1.1 "Fixed bug in file scanner"
```

### What the script does:
1. Updates version in Xcode project (version string + build number)
2. Builds and archives the app
3. Signs with Developer ID certificate
4. Notarizes with Apple (app + DMG)
5. Creates DMG and ZIP packages
6. Signs ZIP for Sparkle auto-updates
7. Updates `appcast.xml` and `website/public/data/releases.json`
8. Creates GitHub release with assets
9. Commits and pushes all changes

### Prerequisites:
1. Copy `.env.example` to `.env` and fill in credentials
2. Set up notarization profile: `xcrun notarytool store-credentials "notary-profile" --apple-id YOUR_APPLE_ID --team-id YOUR_TEAM_ID`
3. Authenticate gh CLI: `gh auth login`
4. Find certificate SHA-1: `security find-identity -v -p codesigning`

### Environment Variables (.env):
| Variable | Description |
|----------|-------------|
| `APPLE_ID` | Apple Developer email |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password for notarization |
| `APPLE_TEAM_ID` | 10-character Team ID |
| `MACOS_CERTIFICATE_SHA1` | 40-character SHA-1 hash of signing certificate |
| `SPARKLE_PRIVATE_KEY` | Base64 EdDSA private key for Sparkle updates |

## Dependencies

| Package | Purpose |
|---------|---------|
| Sparkle 2.x | Auto-updates (conditional import) |

## Guidelines

- Use async/await and actors for thread safety
- Keep views simple, logic in ViewModels
- Use `enumerator(at:includingPropertiesForKeys:)` for file scanning
- Cancel operations when user navigates away
- Never store passwords; request permissions at point of use
- Update `docs/*.md` when features change
