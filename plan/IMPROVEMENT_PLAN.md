# MyMacCleaner Competitive Analysis & Improvement Plan

## Executive Summary

After researching CleanMyMac, BuhoCleaner, Pearcleaner, OnyX, Stats, and various CLI tools, I've identified gaps and opportunities for MyMacCleaner. Your app has a solid foundation but is missing several key features that competitors offer.

---

## Current MyMacCleaner Features (What You Have)

| Feature | Status | Notes |
|---------|--------|-------|
| Smart Scan (Home) | ✅ | Scans caches, logs, trash, downloads |
| Disk Cleaner | ✅ | Category-based cleanup |
| Space Lens | ✅ | Treemap visualization |
| Performance (RAM) | ✅ | Memory monitoring |
| Performance (Processes) | ✅ | Top processes by memory |
| Maintenance Tasks | ✅ | DNS flush, Spotlight rebuild, etc. |
| Applications Manager | ✅ | App list with uninstall |
| Leftover Detection | ✅ | Library, Preferences, Caches |
| Sparkle Update Checker | ✅ | Checks app updates |
| Homebrew Integration | ✅ | List, upgrade, uninstall casks |
| Port Management | ✅ | lsof-based port scanning |
| System Health | ✅ | Health score, disk/battery info |
| Localization | ✅ | EN/IT/ES with runtime switching |
| Liquid Glass UI | ✅ | macOS 26 native design |

---

## Competitive Gap Analysis

### 🔴 Critical Missing Features (High Impact)

#### 1. **Orphaned Files Scanner**
**What competitors have**: Pearcleaner's killer feature is finding leftover files from *previously deleted* apps - not just for apps you're about to uninstall.

**Your gap**: You only detect leftovers when uninstalling. You don't scan for orphans from past deletions.

**Implementation**:
- Scan `~/Library/Application Support/`, `~/Library/Preferences/`, `~/Library/Caches/`, etc.
- Cross-reference with currently installed apps (bundle IDs)
- Files with no matching app = orphans
- Show file age and size to help user decide

#### 2. **Duplicate File Finder**
**What competitors have**: CleanMyMac, BuhoCleaner, and dedicated apps like Gemini 2 find duplicate photos, documents, and files using byte-by-byte comparison.

**Your gap**: No duplicate detection at all.

**Implementation**:
- Hash-based detection (MD5/SHA256) for exact duplicates
- Optional "similar files" for photos (perceptual hashing)
- Filter by file type, size threshold, location
- Smart selection (keep newest, keep in preferred folder)

#### 3. **Menu Bar Monitor**
**What competitors have**: BuhoCleaner, Stats, and iStat Menus provide real-time CPU/RAM/Network/Temperature in the menu bar.

**Your gap**: No menu bar presence. App must be open to see stats.

**Implementation**:
- Lightweight menu bar extra showing CPU%, RAM%, Network speed
- Click to expand with more details
- Quick access to cleanup actions
- Optional temperature sensors (requires SMC access)

#### 4. **Privacy/Browser Cleaner**
**What competitors have**: CleanMyMac cleans browser history, cookies, autofill, downloads history from Safari/Chrome/Firefox.

**Your gap**: No browser-specific cleanup.

**Implementation**:
- Safari: `~/Library/Safari/History.db`, cookies, cache
- Chrome: `~/Library/Application Support/Google/Chrome/Default/`
- Firefox: `~/Library/Application Support/Firefox/Profiles/`
- Let user choose what to clean (history, cookies, cache separately)

---

### 🟡 Important Missing Features (Medium Impact)

#### 5. **Large & Old Files Finder**
**What competitors have**: CleanMyMac and BuhoCleaner specifically highlight large files AND old files (not accessed in X days).

**Your gap**: Space Lens shows size but doesn't filter by age or highlight "forgotten" files.

**Enhancement**:
- Add "Large Files" tab (>100MB, >500MB, >1GB filters)
- Add "Old Files" filter (not accessed in 30/60/90/365 days)
- Show last accessed date prominently

#### 6. **Startup Items Manager**
**What competitors have**: BuhoCleaner, CleanMyMac show both Login Items AND hidden Launch Agents/Daemons.

**Your gap**: You have Startup Items in System Health but unclear if it includes Launch Agents.

**Enhancement**:
- Show `~/Library/LaunchAgents/`
- Show `/Library/LaunchAgents/`
- Show Login Items from `SMAppService`
- Enable/disable toggle for each

#### 7. **Scheduled/Automatic Cleaning**
**What competitors have**: CleanMyMac runs cleanup weekly in background. BuhoCleaner has Sentinel Monitor.

**Your gap**: Manual-only cleaning.

**Implementation**:
- Background agent that runs weekly scan
- Notification when cleanable space exceeds threshold
- Optional auto-clean for safe categories (caches, logs)

#### 8. **File Shredder (Secure Delete)**
**What competitors have**: BuhoCleaner, CleanMyMac offer secure deletion (multiple overwrites).

**Your gap**: Standard Trash-based deletion only.

**Implementation**:
- Use `srm` command or manual overwrite
- Option for DoD 5220.22-M standard (3 passes)
- Useful for sensitive files

---

### 🟢 Nice-to-Have Features (Lower Priority)

#### 9. **Malware Scanner**
**What competitors have**: CleanMyMac has Moonlock Engine (though it failed EICAR tests).

**Recommendation**: Skip this unless you want to invest heavily. Most users have XProtect. Focus on optimization instead.

#### 10. **iOS Device Backup Cleaner**
**What competitors have**: CleanMyMac scans for old iOS backups in `~/Library/Application Support/MobileSync/Backup/`.

**Your current**: You may already scan this in caches. If not, add it.

#### 11. **App Lipo (Architecture Stripping)**
**What Pearcleaner has**: Remove unused architectures (x86_64 on Apple Silicon).

**Implementation**: Use `lipo` command to strip unused architectures from universal binaries.

#### 12. **Mail Attachments Cleaner**
**What competitors have**: CleanMyMac scans Mail downloads and attachments.

**Your current**: You have `mailAttachments` category - verify it's comprehensive.

---

## Things You're Doing Right ✅

1. **Liquid Glass UI** - Competitors are still catching up to macOS 26 design
2. **Open Source** - Major differentiator vs CleanMyMac ($10/month)
3. **Homebrew Integration** - BuhoCleaner doesn't have this
4. **Port Management** - Unique feature most cleaners don't have
5. **No Malware Scanner Bloat** - Keeps app focused and fast
6. **Localization** - Runtime language switching is polished

---

## Things to Reconsider ⚠️

### 1. **Scan Categories**
Your current categories seem good, but verify you're scanning:
- [ ] Xcode derived data (`~/Library/Developer/Xcode/DerivedData/`)
- [ ] iOS Simulators (`~/Library/Developer/CoreSimulator/`)
- [ ] npm/yarn cache (`~/.npm/`, `~/.yarn/cache/`)
- [ ] CocoaPods cache (`~/Library/Caches/CocoaPods/`)
- [ ] Homebrew cache (`~/Library/Caches/Homebrew/`)
- [ ] Docker images (`~/Library/Containers/com.docker.docker/`)

### 2. **App Uninstall Completeness**
Verify leftover detection includes:
- [ ] `~/Library/Containers/[bundle.id]/`
- [ ] `~/Library/Group Containers/`
- [ ] `~/Library/Saved Application State/[bundle.id].savedState/`
- [ ] `~/Library/HTTPStorages/[bundle.id]/`
- [ ] `~/Library/WebKit/[bundle.id]/`
- [ ] `/Library/Application Support/` (system-wide)
- [ ] LaunchAgents with matching bundle ID

### 3. **Safety Considerations**
- Always move to Trash (never permanent delete by default)
- Exclude system-critical paths
- Show file paths before deletion
- Add "undo" capability (or rely on Trash)

---

## Implementation Roadmap

### Phase 1: Quick Wins

#### 1.1 Expand Scan Categories
Add missing developer-focused scan targets:

**Files to modify:**
- `MyMacCleaner/Core/Models/ScanResult.swift` - Add new categories
- `MyMacCleaner/Core/Services/FileScanner.swift` - Add scan paths

**New categories to add:**
```swift
case npmCache           // ~/.npm/
case yarnCache          // ~/.yarn/cache/
case cocoapodsCache     // ~/Library/Caches/CocoaPods/
case homebrewCache      // ~/Library/Caches/Homebrew/
case dockerData         // ~/Library/Containers/com.docker.docker/
case iosSimulators      // ~/Library/Developer/CoreSimulator/
case iosBackups         // ~/Library/Application Support/MobileSync/Backup/
```

#### 1.2 Large & Old Files Filter
Enhance Space Lens with age filtering:

**Files to modify:**
- `MyMacCleaner/Features/SpaceLens/SpaceLensView.swift`
- `MyMacCleaner/Features/SpaceLens/SpaceLensViewModel.swift`

**Implementation:**
- Add filter buttons: "Large Files" (>100MB, >500MB, >1GB)
- Add "Old Files" filter (not accessed in 30/60/90/365 days)
- Use `URLResourceKey.contentAccessDateKey` for last access date
- Show last accessed date in file details

#### 1.3 Browser Privacy Cleaner
Add browser data cleanup:

**Files to create:**
- `MyMacCleaner/Core/Services/BrowserCleanerService.swift`

**Files to modify:**
- `MyMacCleaner/Features/DiskCleaner/DiskCleanerView.swift` - Add Privacy tab

**Browser paths:**
```swift
// Safari
~/Library/Safari/History.db
~/Library/Safari/LocalStorage/
~/Library/Cookies/Cookies.binarycookies

// Chrome
~/Library/Application Support/Google/Chrome/Default/History
~/Library/Application Support/Google/Chrome/Default/Cookies
~/Library/Application Support/Google/Chrome/Default/Cache/

// Firefox
~/Library/Application Support/Firefox/Profiles/*/places.sqlite
~/Library/Application Support/Firefox/Profiles/*/cookies.sqlite
```

#### 1.4 Improve Leftover Detection
Add missing paths to app uninstaller:

**Files to modify:**
- `MyMacCleaner/Features/Applications/ApplicationsViewModel.swift`

**Add these search paths:**
```swift
~/Library/Containers/[bundle.id]/
~/Library/Group Containers/[group.bundle.id]/
~/Library/Saved Application State/[bundle.id].savedState/
~/Library/HTTPStorages/[bundle.id]/
~/Library/WebKit/[bundle.id]/
/Library/Application Support/[app.name]/
~/Library/LaunchAgents/[bundle.id]*.plist
```

---

### Phase 2: Orphaned Files Scanner

**New feature**: Scan for leftovers from previously deleted apps.

**Files to create:**
- `MyMacCleaner/Features/OrphanedFiles/OrphanedFilesView.swift`
- `MyMacCleaner/Features/OrphanedFiles/OrphanedFilesViewModel.swift`
- `MyMacCleaner/Core/Services/OrphanedFilesScanner.swift`

**Files to modify:**
- `MyMacCleaner/App/ContentView.swift` - Add navigation item

**Algorithm:**
```swift
actor OrphanedFilesScanner {
    func scan() async -> [OrphanedFile] {
        // 1. Get all installed app bundle IDs
        let installedBundleIDs = getInstalledAppBundleIDs()

        // 2. Scan Library folders
        let libraryPaths = [
            "~/Library/Application Support/",
            "~/Library/Preferences/",
            "~/Library/Caches/",
            "~/Library/Containers/",
            "~/Library/Saved Application State/",
            "~/Library/LaunchAgents/"
        ]

        // 3. For each item, extract bundle ID pattern
        // 4. If not in installedBundleIDs → orphan
        // 5. Filter: only show files > 30 days old
        // 6. Return with size, path, last modified date
    }
}
```

**UI Design:**
- List of orphaned items grouped by suspected app name
- Checkbox selection
- Show size, path, last modified
- "Clean Selected" button

---

### Phase 3: Duplicate File Finder

**New feature**: Find and remove duplicate files.

**Files to create:**
- `MyMacCleaner/Features/Duplicates/DuplicatesView.swift`
- `MyMacCleaner/Features/Duplicates/DuplicatesViewModel.swift`
- `MyMacCleaner/Core/Services/DuplicateScanner.swift`

**Files to modify:**
- `MyMacCleaner/App/ContentView.swift` - Add navigation item

**Algorithm (optimized):**
```swift
actor DuplicateScanner {
    func scan(at path: URL, minSize: Int64 = 1024) async -> [DuplicateGroup] {
        // 1. Enumerate files, group by size
        var sizeGroups: [Int64: [URL]] = [:]

        // 2. For groups with 2+ files, calculate partial hash (first 4KB)
        // 3. For matching partial hashes, calculate full SHA256
        // 4. Group by full hash = exact duplicates

        // Return groups with 2+ files
    }

    func partialHash(_ url: URL) -> Data? {
        // Read first 4KB and hash
    }

    func fullHash(_ url: URL) -> Data? {
        // SHA256 of entire file
    }
}
```

**UI Design:**
- Scan location picker (Home, specific folder)
- Progress indicator during scan
- Results grouped by duplicate sets
- For each set: show all copies with path, size, date
- Smart selection: "Keep Newest", "Keep in [folder]"
- Preview files before deletion

---

### Phase 4: Menu Bar Monitor

**New feature**: Lightweight system monitor in menu bar.

**Files to create:**
- `MyMacCleaner/MenuBar/MenuBarController.swift`
- `MyMacCleaner/MenuBar/MenuBarView.swift`
- `MyMacCleaner/MenuBar/SystemStatsProvider.swift`

**Files to modify:**
- `MyMacCleaner/App/MyMacCleanerApp.swift` - Initialize menu bar

**Implementation:**
```swift
class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var statsProvider: SystemStatsProvider

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Update every 2 seconds
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.updateDisplay()
        }
    }

    func updateDisplay() {
        let cpu = statsProvider.cpuUsage()
        let ram = statsProvider.ramUsage()

        // Display: "CPU 45% | RAM 8.2GB"
        statusItem?.button?.title = "CPU \(cpu)% | RAM \(ram)"
    }
}

actor SystemStatsProvider {
    func cpuUsage() -> Int {
        // Use host_processor_info()
    }

    func ramUsage() -> String {
        // Use host_statistics64() - reuse from PerformanceViewModel
    }

    func networkSpeed() -> (download: String, upload: String) {
        // Use getifaddrs() for network stats
    }
}
```

**Menu bar popup (on click):**
- CPU usage with per-core breakdown
- RAM usage (Used/Total)
- Network speed (↓ download, ↑ upload)
- Disk usage
- Quick actions: "Run Smart Scan", "Open App"

**Settings:**
- Show/hide in menu bar toggle
- Choose what to display (CPU, RAM, Network)
- Update interval (1s, 2s, 5s)

---

### Phase 5: Startup Items Enhancement

**Enhancement**: Show Launch Agents alongside Login Items.

**Files to modify:**
- `MyMacCleaner/Features/SystemHealth/SystemHealthView.swift`
- `MyMacCleaner/Features/SystemHealth/SystemHealthViewModel.swift`

**Implementation:**
```swift
struct StartupItem: Identifiable {
    let id: UUID
    let name: String
    let path: URL
    let type: StartupItemType // .loginItem, .launchAgent, .launchDaemon
    let isEnabled: Bool
    let bundleID: String?
}

enum StartupItemType {
    case loginItem      // SMAppService
    case launchAgent    // ~/Library/LaunchAgents/, /Library/LaunchAgents/
    case launchDaemon   // /Library/LaunchDaemons/ (requires admin)
}

func loadStartupItems() async -> [StartupItem] {
    var items: [StartupItem] = []

    // 1. Login Items via SMAppService
    // 2. User Launch Agents
    let userAgents = FileManager.default.contentsOfDirectory(
        at: URL(fileURLWithPath: "~/Library/LaunchAgents/")
    )
    // 3. System Launch Agents
    // 4. Parse plist files for Label, Program, ProgramArguments

    return items
}

func toggleStartupItem(_ item: StartupItem) async {
    // For LaunchAgents: launchctl load/unload
    // For LoginItems: SMAppService
}
```

---

## File Summary

### New Files to Create
```
MyMacCleaner/
├── Core/Services/
│   ├── BrowserCleanerService.swift
│   ├── OrphanedFilesScanner.swift
│   └── DuplicateScanner.swift
├── Features/
│   ├── OrphanedFiles/
│   │   ├── OrphanedFilesView.swift
│   │   └── OrphanedFilesViewModel.swift
│   └── Duplicates/
│       ├── DuplicatesView.swift
│       └── DuplicatesViewModel.swift
└── MenuBar/
    ├── MenuBarController.swift
    ├── MenuBarView.swift
    └── SystemStatsProvider.swift
```

### Files to Modify
```
MyMacCleaner/App/ContentView.swift         - Add navigation for new features
MyMacCleaner/App/MyMacCleanerApp.swift     - Initialize menu bar
MyMacCleaner/Core/Models/ScanResult.swift  - Add new scan categories
MyMacCleaner/Core/Services/FileScanner.swift - Add new scan paths
MyMacCleaner/Features/SpaceLens/*          - Add age filtering
MyMacCleaner/Features/DiskCleaner/*        - Add Privacy tab
MyMacCleaner/Features/Applications/*       - Improve leftover detection
MyMacCleaner/Features/SystemHealth/*       - Launch Agents UI
```

---

## Technical Implementation Notes

### Orphaned Files Detection Algorithm
```
1. Build set of installed app bundle IDs
2. Scan Library folders for all identifiable items
3. Extract bundle ID from folder/file names
4. If bundle ID not in installed set → orphan candidate
5. Filter by age (only show files > 30 days old)
6. Present to user with size and path
```

### Duplicate Finder Algorithm
```
1. Group files by size (same size = potential duplicate)
2. For each group, calculate partial hash (first 4KB)
3. If partial hash matches, calculate full hash
4. Group by full hash = exact duplicates
5. Present groups, let user select which to keep
```

### Menu Bar Implementation
```swift
// Use NSStatusItem for menu bar
// Create lightweight monitoring daemon
// Use XPC for communication with main app
// Sample CPU/RAM every 2-3 seconds
// For temperature: IOKit SMC access
```

---

## Sources

- [CleanMyMac Review - Macworld](https://www.macworld.com/article/352922/cleanmymac-x-review-macos.html)
- [BuhoCleaner Official](https://www.drbuho.com/buhocleaner)
- [Pearcleaner GitHub](https://github.com/alienator88/Pearcleaner)
- [OnyX - Titanium Software](https://www.titanium-software.fr/en/onyx.html)
- [Stats GitHub](https://github.com/exelban/stats)
- [Gemini 2 - MacPaw](https://macpaw.com/gemini)
- [mac-cleaner-cli GitHub](https://github.com/guhcostan/mac-cleaner-cli)

---

## Summary

**Your app is 70% competitive** with paid alternatives. The main gaps are:

| Missing Feature | Impact | Effort |
|-----------------|--------|--------|
| Orphaned Files Scanner | 🔴 High | Medium |
| Duplicate Finder | 🔴 High | Medium |
| Menu Bar Monitor | 🔴 High | High |
| Browser Cleaner | 🟡 Medium | Low |
| Large/Old Files Filter | 🟡 Medium | Low |
| Startup Items (Launch Agents) | 🟡 Medium | Low |

**Biggest differentiators you already have**:
- Free & Open Source (vs $10+/month competitors)
- Liquid Glass UI (ahead of most competitors)
- Port Management (unique feature)
- Homebrew integration (developer-friendly)
