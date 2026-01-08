# CLAUDE.md - Project Instructions

> This file is automatically read by Claude Code at the start of every conversation.
> **CRITICAL**: Update the TODO Tracker and Changelog at the end of every coding session.

## Project Overview

**MyMacCleaner** - A modern, open-source macOS system utility app with Apple's Liquid Glass UI design.

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Target**: macOS 14.0+ (Sonoma)
- **Design**: Apple Liquid Glass (macOS Tahoe style)

## Mandatory Update Rules

### At Every Iteration, You MUST:

1. **Update the TODO Tracker** (below) with:
   - Tasks completed in this session
   - New tasks discovered
   - Current progress percentage
   - Any blockers or issues

2. **Update Documentation** if you:
   - Add new features
   - Change existing functionality
   - Modify user-facing behavior
   - Files to update: relevant `docs/*.md` and `README.md`

3. **Update the Changelog** (below) with:
   - Date
   - What was done
   - Files modified

4. **Keep IMPLEMENTATION_PLAN.md Updated**:
   - Mark completed phases
   - Add any new requirements discovered
   - Note deviations from original plan

---

## Project Structure

```
MyMacCleaner/
├── README.md                    # Project overview
├── LICENSE                      # MIT License
├── IMPLEMENTATION_PLAN.md       # Detailed implementation guide
├── CLAUDE.md                    # THIS FILE - Update every session!
├── docs/                        # User documentation
│   ├── home.md
│   ├── disk-cleaner.md
│   ├── space-lens.md
│   ├── orphaned-files.md
│   ├── duplicates.md
│   ├── performance.md
│   ├── applications.md
│   ├── port-management.md
│   ├── system-health.md
│   ├── menu-bar.md
│   └── permissions.md
├── MyMacCleaner.xcodeproj/      # Xcode project
├── MyMacCleanerTests/           # Unit tests
├── MyMacCleanerUITests/         # UI tests
└── MyMacCleaner/                # Source code
    ├── App/
    │   ├── MyMacCleanerApp.swift
    │   └── ContentView.swift
    ├── Core/
    │   ├── Design/
    │   │   ├── Theme.swift
    │   │   ├── LiquidGlass.swift
    │   │   ├── Animations.swift
    │   │   └── ToastView.swift
    │   ├── Services/
    │   │   ├── FileScanner.swift
    │   │   ├── PermissionsService.swift
    │   │   ├── AuthorizationService.swift
    │   │   ├── AppUpdateChecker.swift
    │   │   ├── HomebrewService.swift
    │   │   ├── LocalizationManager.swift
    │   │   ├── BrowserCleanerService.swift
    │   │   ├── OrphanedFilesScanner.swift
    │   │   ├── DuplicateScanner.swift
    │   │   └── SystemStatsProvider.swift
    │   ├── Models/
    │   │   ├── ScanResult.swift
    │   │   └── PermissionCategory.swift
    │   └── Extensions/
    ├── Features/
    │   ├── Home/
    │   │   ├── HomeView.swift
    │   │   ├── HomeViewModel.swift
    │   │   └── Components/
    │   │       ├── ScanResultsCard.swift
    │   │       └── PermissionPromptView.swift
    │   ├── DiskCleaner/
    │   │   ├── DiskCleanerView.swift
    │   │   ├── DiskCleanerViewModel.swift
    │   │   ├── BrowserPrivacyView.swift
    │   │   └── Components/
    │   │       └── CleanupCategoryCard.swift
    │   ├── SpaceLens/
    │   │   ├── SpaceLensView.swift
    │   │   └── SpaceLensViewModel.swift
    │   ├── OrphanedFiles/
    │   │   ├── OrphanedFilesView.swift
    │   │   └── OrphanedFilesViewModel.swift
    │   ├── Duplicates/
    │   │   ├── DuplicatesView.swift
    │   │   └── DuplicatesViewModel.swift
    │   ├── Performance/
    │   ├── Applications/
    │   ├── PortManagement/
    │   ├── SystemHealth/
    │   ├── StartupItems/
    │   └── Permissions/
    │       ├── PermissionsView.swift
    │       ├── PermissionsViewModel.swift
    │       └── Components/
    │           ├── PermissionCategoryCard.swift
    │           └── PermissionFolderRow.swift
    ├── MenuBar/
    │   ├── MenuBarController.swift
    │   └── MenuBarView.swift
    ├── Resources/
    │   └── Assets.xcassets/
    └── MyMacCleaner.entitlements
```

---

## TODO Tracker

### Current Phase: ALL PHASES COMPLETE

### Overall Progress: 100% (8/8 phases complete)

### Phase Status

| Phase | Name | Status | Progress |
|-------|------|--------|----------|
| 1 | Project Setup | COMPLETED | 100% |
| 2 | UI Shell & Navigation | COMPLETED | 100% |
| 3 | Home - Smart Scan | COMPLETED | 100% |
| 4 | Disk Cleaner + Space Lens | COMPLETED | 100% |
| 5 | Performance | COMPLETED | 100% |
| 6 | Applications Manager | COMPLETED | 100% |
| 7 | Port Management | COMPLETED | 100% |
| 8 | System Health | COMPLETED | 100% |

### Detailed Task List

#### Phase 1: Project Setup
- [x] Create new Xcode project with SwiftUI
- [x] Configure bundle identifier (com.mymaccleaner.MyMacCleaner)
- [x] Configure deployment target (macOS 14.0+)
- [x] Disable App Sandbox in entitlements
- [x] Add Sparkle package dependency (ready to add in Xcode)
- [x] Add FullDiskAccess package dependency (ready to add in Xcode)
- [x] Create folder structure (App/, Core/, Features/, Resources/)
- [x] Configure Info.plist with usage descriptions
- [x] Test build succeeds

#### Phase 2: UI Shell & Navigation
- [x] Create Theme.swift with color palette
- [x] Create LiquidGlass.swift with glass effect modifiers
- [x] Create Animations.swift with page transitions
- [x] Create NavigationSection enum with colors
- [x] Create SidebarView with hover effects
- [x] Create ContentView.swift with NavigationSplitView
- [x] Create ComingSoonView.swift with animations
- [x] Create placeholder views for all 6 sections
- [x] Add page transition animations (staggered, slide, fade)
- [x] Test navigation works correctly

#### Phase 3: Home - Smart Scan
- [x] Create HomeView.swift
- [x] Create HomeViewModel.swift
- [x] Create SmartScanButton.swift (integrated in HomeView)
- [x] Create StatCard.swift component
- [x] Create ScanResultsCard.swift
- [x] Implement async scanning logic (real FileScanner actor)
- [x] Add permission check before scanning (PermissionsService, PermissionPromptView)
- [x] Test scanning functionality (build verified)

#### Phase 4: Disk Cleaner + Space Lens
- [x] Create DiskCleanerView.swift (with tab picker for Cleaner/Space Lens)
- [x] Create DiskCleanerViewModel.swift
- [x] Reuse ScanCategory from Phase 3
- [x] Create CleanupCategoryCard.swift (expandable with file list)
- [x] Create CategoryDetailSheet.swift (full file list with search/sort)
- [x] Create SpaceLensView.swift
- [x] Create SpaceLensViewModel.swift
- [x] Implement TreemapLayout squarified algorithm
- [x] Implement treemap visualization with color coding
- [x] Add safe deletion with confirmation dialogs
- [x] Add reveal in Finder context menu
- [x] Test cleanup operations (build verified)

#### Phase 5: Performance
- [x] Create PerformanceView.swift (with Memory, Processes, Maintenance tabs)
- [x] Create PerformanceViewModel.swift
- [x] Create MaintenanceTask model
- [x] Create MaintenanceTaskCard.swift component
- [x] Create AuthorizationService.swift for single password prompts
- [x] Implement RAM monitoring via vm_statistics64 (Active + Wired + Compressed)
- [x] Implement swap monitoring via sysctlbyname
- [x] Implement DNS flush, Spotlight rebuild, and other maintenance tasks
- [x] Implement "Run All" button with batch admin commands (single password prompt)
- [x] Add Processes tab with htop-like view (top 10 by memory, auto-refresh 2s)
- [x] Test all maintenance tasks (build verified)

#### Phase 6: Applications Manager
- [x] Create ApplicationsView.swift (with tabs: All Apps, Updates, Homebrew)
- [x] Create ApplicationsViewModel.swift
- [x] Create AppInfo model (with icon, version, size, dates)
- [x] Create AppCard.swift component
- [x] Implement app scanning (background discovery + full analysis)
- [x] Create UninstallConfirmationSheet.swift
- [x] Implement leftover detection (Library, Preferences, Caches, etc.)
- [x] Create AppUpdateChecker.swift (Sparkle appcast.xml parsing)
- [x] Create HomebrewService.swift (list, upgrade, uninstall casks)
- [x] Add Homebrew integration UI (outdated casks, upgrade all, cleanup)
- [x] Test uninstall functionality (build verified)

#### Phase 7: Port Management
- [x] Create PortManagementView.swift
- [x] Create PortManagementViewModel.swift
- [x] Create NetworkConnection model
- [x] Implement lsof parsing for port scanning
- [x] Create PortStatCard component
- [x] Implement process killing with confirmation
- [x] Add filtering by protocol (TCP/UDP) and search
- [x] Test port scanning and killing (build verified)

#### Phase 8: System Health
- [x] Create SystemHealthView.swift
- [x] Create SystemHealthViewModel.swift
- [x] Create HealthCheck model with status enum
- [x] Create DiskInfo and BatteryInfo models
- [x] Implement health checks (disk space, memory, battery, etc.)
- [x] Create HealthCheckCard.swift component
- [x] Create DiskInfoCard, BatteryInfoCard, MacInfoCard components
- [x] Implement circular health score gauge
- [x] Add system information display (macOS version, model, memory)
- [x] Test health monitoring (build verified)

### Current Blockers

*None currently*

### Notes & Decisions

*Add important decisions made during development here*

---

## Changelog

### 2026-01-03 - Initial Setup

**Session Goal**: Delete old code and create comprehensive project plan

**Completed**:
- Deleted all existing source code
- Created IMPLEMENTATION_PLAN.md with detailed 8-phase plan
- Created README.md with project overview
- Created docs/ folder with 8 documentation files:
  - home.md
  - disk-cleaner.md
  - space-lens.md
  - performance.md
  - applications.md
  - port-management.md
  - system-health.md
  - permissions.md
- Created claude.md (this file) for tracking

**Research Conducted**:
- Analyzed Pearcleaner, Clean-Me, Stats for implementation patterns
- Researched Liquid Glass SwiftUI implementation
- Researched macOS permission best practices
- Researched port management commands (lsof)
- Researched RAM cleaning and system maintenance

**Files Created**:
- `IMPLEMENTATION_PLAN.md`
- `README.md`
- `claude.md`
- `docs/home.md`
- `docs/disk-cleaner.md`
- `docs/space-lens.md`
- `docs/performance.md`
- `docs/applications.md`
- `docs/port-management.md`
- `docs/system-health.md`
- `docs/permissions.md`

**Files Deleted**:
- All Swift source files
- All test files
- Old README.md

**Next Steps**:
- Begin Phase 1: Project Setup

---

### 2026-01-03 - Phase 1 Complete + Phase 2/3 Started

**Session Goal**: Complete Phase 1 project setup and start building the UI

**Completed**:
- Created complete folder structure (App/, Core/, Features/, Resources/)
- Created MyMacCleaner.entitlements with sandbox disabled
- Created MyMacCleanerApp.swift with window configuration and Settings
- Created ContentView.swift with NavigationSplitView and sidebar
- Created NavigationSection enum with all 6 sections
- Created ComingSoonView.swift placeholder component
- Created HomeView.swift with dashboard layout
- Created HomeViewModel.swift with system stats
- Created StatCard.swift and QuickActionButton.swift components
- Created Assets.xcassets with AppIcon and AccentColor
- Created test files for unit and UI tests
- Updated deployment target to macOS 14.0
- Added Info.plist usage descriptions
- Build verified successful

**Files Created**:
- `MyMacCleaner/MyMacCleaner.entitlements`
- `MyMacCleaner/App/MyMacCleanerApp.swift`
- `MyMacCleaner/App/ContentView.swift`
- `MyMacCleaner/Features/Home/HomeView.swift`
- `MyMacCleaner/Features/Home/HomeViewModel.swift`
- `MyMacCleaner/Resources/Assets.xcassets/*`
- `MyMacCleanerTests/MyMacCleanerTests.swift`
- `MyMacCleanerUITests/MyMacCleanerUITests.swift`

**Files Modified**:
- `MyMacCleaner.xcodeproj/project.pbxproj` (deployment target, Info.plist keys)

**Next Steps**:
- Complete Phase 2: Add LiquidGlass.swift, page transitions
- Complete Phase 3: Add permission checks, scan results card
- Begin Phase 4: Disk Cleaner

---

### 2026-01-03 - Phase 2 Complete

**Session Goal**: Complete UI shell with Liquid Glass design system

**Completed**:
- Created Theme.swift with complete design system:
  - Colors (accent, backgrounds, surfaces, semantic, category)
  - Typography system
  - Spacing constants
  - Corner radius values
  - Shadow styles
  - Animation presets
- Created LiquidGlass.swift with glass effects:
  - glassCard(), glassCardProminent(), glassCardSubtle()
  - glassPill() for buttons/tags
  - hoverEffect(), pressEffect()
  - GlassCard component
  - GlassButtonStyle
  - Shimmer, Glow, AnimatedBorder effects
- Created Animations.swift with transitions:
  - PageTransition, SlideTransition, ScaleFadeTransition
  - StaggeredAnimation for lists
  - PulseAnimation, BreathingAnimation
  - LoadingDotsView, ProgressRing
  - ConfettiView for celebrations
- Updated ContentView with:
  - Improved sidebar with app header
  - Section colors per navigation item
  - Hover effects on sidebar rows
  - System status badge
  - Page transitions on navigation
- Updated HomeView with:
  - Staggered animations on load
  - SystemHealthPill component
  - Improved SmartScanButton with press states
  - Updated StatCard with glass effects
  - QuickActionButton with colors and hover

**Files Created**:
- `MyMacCleaner/Core/Design/Theme.swift`
- `MyMacCleaner/Core/Design/LiquidGlass.swift`
- `MyMacCleaner/Core/Design/Animations.swift`

**Files Modified**:
- `MyMacCleaner/App/ContentView.swift` (complete rewrite)
- `MyMacCleaner/Features/Home/HomeView.swift` (complete rewrite)

**Build Status**: SUCCESS

**Next Steps**:
- Complete Phase 3: Add scan results card, permission checks
- Begin Phase 4: Disk Cleaner with Space Lens

---

### 2026-01-03 - Phase 3 Complete

**Session Goal**: Complete Home Smart Scan with real file scanning

**Completed**:
- Created PermissionsService.swift:
  - FDA (Full Disk Access) checking via test paths
  - openFullDiskAccessSettings() to open System Preferences
  - PermissionStatus enum with colors and icons
  - PermissionInfo struct for feature descriptions
- Created ScanResult.swift models:
  - ScanResult with category and items
  - ScanCategory enum with 8 categories (systemCache, userCache, applicationLogs, xcodeData, browserCache, trash, downloads, mailAttachments)
  - CleanableItem with name, path, size, date, category
  - ScanSummary for totals and breakdown
  - Each category has paths, colors, icons, FDA requirements
- Created FileScanner.swift actor:
  - scanAllCategories() with progress callback
  - scanCategory() for individual categories
  - scanDirectory() with depth limiting
  - quickEstimate() for fast size totals
  - deleteItems() and trashItems() for cleanup
  - emptyTrash() and getTrashSize()
- Created ScanResultsCard.swift:
  - Displays scan results by category
  - Shows total cleanable size
  - Clean button with selected size
  - ScanResultRow for each category
  - CompactScanSummary variant
- Created PermissionPromptView.swift:
  - Modal overlay for FDA request
  - PermissionBanner for inline warning
  - PermissionStatusView pill component
  - Lists features requiring FDA
  - Open System Settings button
  - Continue with limited scan option
- Updated HomeViewModel.swift:
  - Integrated FileScanner actor
  - Real memory stats via host_statistics64
  - Permission checking and prompting
  - Quick estimate on launch
  - cleanSelectedItems() for cleanup
  - refreshPermissions() on app activation
- Updated HomeView.swift:
  - Integrated permission banner
  - Permission prompt overlay
  - Shows scan results after scanning
  - Displays current category during scan
  - Error display for scan failures
  - Refreshes permissions on app activation

**Files Created**:
- `MyMacCleaner/Core/Services/PermissionsService.swift`
- `MyMacCleaner/Core/Services/FileScanner.swift`
- `MyMacCleaner/Core/Models/ScanResult.swift`
- `MyMacCleaner/Features/Home/Components/ScanResultsCard.swift`
- `MyMacCleaner/Features/Home/Components/PermissionPromptView.swift`

**Files Modified**:
- `MyMacCleaner/Features/Home/HomeViewModel.swift` (complete rewrite with real scanning)
- `MyMacCleaner/Features/Home/HomeView.swift` (added permission + results UI)

**Build Status**: SUCCESS

**Next Steps**:
- Begin Phase 4: Disk Cleaner with Space Lens visualization
- Create treemap layout for space visualization
- Implement category-based cleanup interface

---

### 2026-01-03 - Phase 4 Complete

**Session Goal**: Build Disk Cleaner and Space Lens visualization

**Completed**:
- Created DiskCleanerView.swift with tab picker:
  - Tab switcher between "Cleaner" and "Space Lens" modes
  - Initial scan prompt with styled button
  - Category list with expand/collapse
  - Selection controls (Select All, Deselect All, Rescan)
  - Clean button with item count and size
  - Confirmation dialog before cleaning
- Created DiskCleanerViewModel.swift:
  - Category-based scanning
  - Item selection per category
  - Batch cleaning with progress
  - Toast notifications for results
- Created CleanupCategoryCard.swift:
  - Expandable card showing files
  - Checkbox for category/item selection
  - Shows first 5 items inline
  - "View all" button for detail sheet
- Created CategoryDetailSheet.swift:
  - Full file list with search
  - Sort by size/date/name
  - Toggle individual items
- Created SpaceLensView.swift:
  - Scan home folder button
  - Breadcrumb navigation
  - Treemap visualization
  - Legend with file type colors
  - Hover to see file details
  - Info bar with current selection
- Created SpaceLensViewModel.swift:
  - Builds file tree from directory scan
  - Navigation through folder hierarchy
  - File node with size, color, icon
  - Delete and reveal in Finder actions
- Created TreemapLayout algorithm:
  - Squarified treemap for better aspect ratios
  - Dynamic layout based on container size
  - Top 50 items for performance
- Added cleaning feedback (from earlier):
  - Progress overlay with animated ring
  - Toast notifications (success/error/info)
  - Auto-dismiss after 3 seconds

**Files Created**:
- `MyMacCleaner/Features/DiskCleaner/DiskCleanerView.swift`
- `MyMacCleaner/Features/DiskCleaner/DiskCleanerViewModel.swift`
- `MyMacCleaner/Features/DiskCleaner/Components/CleanupCategoryCard.swift`
- `MyMacCleaner/Features/SpaceLens/SpaceLensView.swift`
- `MyMacCleaner/Features/SpaceLens/SpaceLensViewModel.swift`
- `MyMacCleaner/Core/Design/ToastView.swift`

**Files Modified**:
- `MyMacCleaner/App/ContentView.swift` (wired DiskCleanerView)
- `MyMacCleaner/Features/Home/HomeView.swift` (added cleaning progress)
- `MyMacCleaner/Features/Home/HomeViewModel.swift` (added toast support)

**Build Status**: SUCCESS

**Next Steps**:
- Phase 5: Performance (RAM, maintenance scripts)
- Phase 6: Applications Manager
- Phase 7: Port Management
- Phase 8: System Health

---

### 2026-01-04 - Phase 5, 7, 8 Complete

**Session Goal**: Complete Performance, Port Management, and System Health features

**Completed**:

**Phase 5 - Performance:**
- Created PerformanceView.swift with three tabs:
  - Memory: Real-time RAM monitoring with circular gauge
  - Processes: htop-like view with top 10 processes by memory, auto-refresh every 2s
  - Maintenance: 8 maintenance tasks with "Run All" button
- Created PerformanceViewModel.swift:
  - RAM calculation fixed: used = active + wired + compressed (matches htop)
  - Swap monitoring via sysctlbyname("vm.swapusage")
  - Process monitoring using ps with awk for reliable parsing
  - Batch admin commands for single password prompt
- Created AuthorizationService.swift:
  - runBatchCommands() runs multiple admin commands with ONE password prompt
  - Uses AppleScript "do shell script with administrator privileges"
- Created MaintenanceTaskCard, ProcessRow, RunAllProgressView components
- Fixed purge command path: /usr/sbin/purge (not /usr/bin/purge)

**Phase 7 - Port Management:**
- Created PortManagementView.swift with connection list
- Created PortManagementViewModel.swift with lsof parsing
- Created PortStatCard component (renamed from StatCard to avoid conflict)
- Implemented process killing with confirmation dialogs
- Added filtering by protocol (TCP/UDP) and search

**Phase 8 - System Health:**
- Created SystemHealthView.swift with health dashboard
- Created SystemHealthViewModel.swift with health checks
- Created HealthCheckCard, DiskInfoCard, BatteryInfoCard, MacInfoCard components
- Implemented circular health score gauge (0-100)
- Added system info display (macOS version, model, memory)

**Files Created**:
- `MyMacCleaner/Features/Performance/PerformanceView.swift`
- `MyMacCleaner/Features/Performance/PerformanceViewModel.swift`
- `MyMacCleaner/Features/PortManagement/PortManagementView.swift`
- `MyMacCleaner/Features/PortManagement/PortManagementViewModel.swift`
- `MyMacCleaner/Features/SystemHealth/SystemHealthView.swift`
- `MyMacCleaner/Features/SystemHealth/SystemHealthViewModel.swift`
- `MyMacCleaner/Core/Services/AuthorizationService.swift`

**Files Modified**:
- `MyMacCleaner/App/ContentView.swift` (wired all new views)

**Key Technical Decisions**:
- Memory calculation: Active + Wired + Compressed (excludes Inactive/Cached)
- Batch admin commands use single AppleScript call with semicolon-joined commands
- Process monitoring uses `ps -axo` with awk instead of `top` for reliable parsing
- Auto-refresh processes every 2 seconds with Timer

**Build Status**: SUCCESS

**Next Steps**:
- Complete Phase 6: Applications Manager
- Implement app scanning and uninstall functionality
- Add Homebrew integration for updates

---

### 2026-01-05 - Language Switcher Feature

**Session Goal**: Add multi-language support with runtime language switching

**Completed**:
- Created LocalizationManager.swift:
  - AppLanguage enum with English, Italian, Spanish
  - Flag emojis and native language names
  - @Observable class with @AppStorage persistence
  - System locale detection on first launch
  - Runtime language switching without restart
- Created LanguageSwitcherButton.swift:
  - Liquid Glass styled button for top-right corner
  - Globe icon with language code (EN/IT/ES)
  - Popover with language picker
  - Hover and press effects matching design system
- Created Localizable.xcstrings String Catalog:
  - Navigation section names and descriptions
  - Settings labels and descriptions
  - Common UI strings (Cancel, Delete, Clean, etc.)
  - Coming Soon placeholder strings
  - All strings translated to EN/IT/ES
- Updated MyMacCleanerApp.swift:
  - Integrated LocalizationManager as environment
  - Applied .environment(\.locale, ...) at root
  - Added Language tab to Settings window
  - Localized all Settings tab labels
- Updated ContentView.swift:
  - Added LanguageSwitcherButton overlay in top-right
  - Full-screen aware positioning (36pt top in fullscreen)
  - Localized NavigationSection names and descriptions
  - Localized System Status badge text
  - Localized ComingSoonView strings

**Files Created**:
- `MyMacCleaner/Core/Services/LocalizationManager.swift`
- `MyMacCleaner/Core/Design/LanguageSwitcherButton.swift`
- `MyMacCleaner/Resources/Localizable.xcstrings`

**Files Modified**:
- `MyMacCleaner/App/MyMacCleanerApp.swift` (environment, settings tab)
- `MyMacCleaner/App/ContentView.swift` (toolbar item, localized strings)

**Key Technical Decisions**:
- Uses Apple's String Catalogs (.xcstrings) - modern approach
- Runtime switching via SwiftUI .environment(\.locale, ...)
- @AppStorage for persistence across launches
- Auto-detects system language on first launch (EN/IT/ES only)
- Language switcher in toolbar using `.toolbar { ToolbarItem(placement: .primaryAction) }`
- Gets automatic Liquid Glass styling from macOS 26 toolbar system

**Build Status**: SUCCESS

**Next Steps**:
- Localize remaining feature views (Home, Disk Cleaner, Performance, etc.)
- Complete Phase 6: Applications Manager

---

### 2026-01-05 - Phase 6 Applications Manager Complete

**Session Goal**: Complete Phase 6 - Applications Manager with update checking and Homebrew integration

**Completed**:

**UI Consistency Audit**:
- Fixed fullscreen top bar issue by adding conditional 28pt padding when in fullscreen mode
- Standardized all scan prompt cards (Home, Disk Cleaner, Applications, Startup Items) with consistent styling:
  - Circle with blur effect background
  - Inner ultraThinMaterial circle with 80pt size
  - 32pt icon with gradient
  - 20pt semibold title
  - 14pt secondary subtitle
  - GlassActionButton

**Phase 6 - Applications Manager**:
- Created AppUpdateChecker.swift:
  - Sparkle appcast.xml parsing via XMLParserDelegate
  - checkSparkleUpdate() for individual apps
  - checkUpdates() for batch checking with progress callback
  - AppUpdate model with version comparison
  - Supports download URL and release notes
- Created HomebrewService.swift:
  - isHomebrewInstalled() detection (Apple Silicon + Intel paths)
  - listInstalledCasks() with detailed info
  - getOutdatedCasks() for update checking
  - upgradeCask(), upgradeAllCasks(), uninstallCask()
  - cleanup() for cache cleaning
  - HomebrewCask and HomebrewFormula models
- Updated ApplicationsViewModel.swift:
  - Integrated AppUpdateChecker and HomebrewService
  - checkForUpdates() method with progress tracking
  - loadHomebrewStatus() for cask management
  - upgradeCask(), upgradeAllCasks(), uninstallCask(), cleanupHomebrew() methods
- Updated ApplicationsView.swift:
  - Added tab picker (All Apps, Updates, Homebrew)
  - Created updatesSection with update checking UI
  - Created homebrewSection with cask management
  - Added UpdateRow component for displaying updates
  - Added HomebrewCaskRow component with upgrade/uninstall actions
  - Badge counts on tabs for available updates and outdated casks

**Files Created**:
- `MyMacCleaner/Core/Services/AppUpdateChecker.swift`
- `MyMacCleaner/Core/Services/HomebrewService.swift`

**Files Modified**:
- `MyMacCleaner/App/ContentView.swift` (fullscreen padding fix)
- `MyMacCleaner/Features/Home/HomeView.swift` (scan prompt styling)
- `MyMacCleaner/Features/Applications/ApplicationsView.swift` (tabs, updates, homebrew UI)
- `MyMacCleaner/Features/Applications/ApplicationsViewModel.swift` (update + homebrew methods)
- `MyMacCleaner/Features/DiskCleaner/DiskCleanerView.swift` (scan prompt styling)
- `MyMacCleaner/Features/StartupItems/StartupItemsView.swift` (scan prompt styling)

**Key Technical Decisions**:
- Sparkle update checking parses SUFeedURL from app's Info.plist
- Homebrew service detects both /opt/homebrew/bin/brew (ARM) and /usr/local/bin/brew (Intel)
- Uses Swift actors for thread-safe service implementations
- Tab-based UI for Applications page to separate concerns
- Homebrew cask operations run via Process with proper PATH setup

**Build Status**: SUCCESS

**Project Status**: ALL 8 PHASES COMPLETE (100%)

---

### 2026-01-05 - Deployment & Auto-Update Setup

**Session Goal**: Add backward compatibility for macOS 14.0+ and Sparkle auto-update integration

**Completed**:

**Phase 1 - Backward Compatibility:**
- Changed deployment target from macOS 26.0 to 14.0 (Sonoma)
- Refactored LiquidGlass.swift with `#available(macOS 26, *)` checks:
  - `glassCard()`, `glassCardProminent()`, `glassCardSubtle()` modifiers
  - `glassPill()`, `glassCircle()` shape modifiers
  - `GlassSegmentedControl`, `GlassTabPicker`, `GlassSearchField` components
  - `LiquidGlassButtonStyle`, `FloatingActionButton`, `GlassToolbar` components
  - Fallback to `.ultraThinMaterial` on macOS 14-15, native `.glassEffect()` on 26+
- Fixed all direct `.glassEffect()` calls in feature views (10 files)
- Fixed `ToolbarSpacer(.flexible)` usage (macOS 26 only) in ContentView
- Fixed `Material.opacity` type error in LiquidGlass.swift

**Phase 2 - Sparkle Integration:**
- Created UpdateManager.swift with conditional compilation:
  - Uses Sparkle when available (via `#if canImport(Sparkle)`)
  - Fallback implementation when Sparkle not installed
  - `checkForUpdates()` and `checkForUpdatesInBackground()` methods
- Updated MyMacCleanerApp.swift:
  - Added UpdateManager as environment object
  - Added "Check for Updates..." menu command (Cmd+U)
- Added UpdateSettingsView to Settings:
  - Automatic update check toggle
  - Check Now button
  - Last check date display

**Phase 3 - CI/CD Pipeline:**
- Created `.github/workflows/build-release.yml`:
  - Triggers on version tags (v*)
  - Builds unsigned app for free distribution
  - Creates DMG with Applications symlink
  - Creates ZIP for Sparkle updates
  - Auto-generates release notes from commits
  - Uploads to GitHub Releases
  - Includes commented signed build job for future Apple Developer setup
- Created `ExportOptions.plist` for signed exports
- Created `appcast.xml` template for Sparkle update feed

**Localization:**
- Added update settings strings (EN/IT/ES):
  - settings.updates, settings.autoCheckUpdates, settings.checkNow
  - settings.lastChecked, settings.updatesDescription

**Files Created**:
- `MyMacCleaner/Core/Services/UpdateManager.swift`
- `.github/workflows/build-release.yml`
- `ExportOptions.plist`
- `appcast.xml`

**Files Modified**:
- `MyMacCleaner.xcodeproj/project.pbxproj` (deployment target 14.0)
- `MyMacCleaner/Core/Design/LiquidGlass.swift` (complete rewrite for compatibility)
- `MyMacCleaner/App/ContentView.swift` (fixed ToolbarSpacer)
- `MyMacCleaner/App/MyMacCleanerApp.swift` (added UpdateManager, menu command)
- `MyMacCleaner/Features/*/` (8 feature views - replaced .glassEffect() calls)
- `MyMacCleaner/Resources/Localizable.xcstrings` (added update strings)

**Key Technical Decisions**:
- Target macOS 14.0+ with runtime availability checks
- Native Liquid Glass on macOS 26 Tahoe, material fallback on older versions
- Single binary works on all supported versions
- Sparkle via conditional compilation to allow building without it
- GitHub Releases for update distribution (free, no Apple Developer fee)

**Build Status**: SUCCESS

**Next Steps for User**:
1. In Xcode: File > Add Package Dependencies > https://github.com/sparkle-project/Sparkle
2. Run Sparkle's generate_keys tool to create EdDSA key pair
3. Add SUFeedURL and SUPublicEDKey to Info.plist
4. Push to GitHub and create first tag (v1.0.0) to trigger release workflow

---

### 2026-01-05 - v1.0.0 Release & Documentation Update

**Session Goal**: Complete v1.0.0 release setup and update documentation

**Completed**:

**Release Setup:**
- Generated EdDSA signature for v1.0.0 release ZIP
- Updated appcast.xml with correct signature and file length
- Updated README.md with Gatekeeper bypass instructions
- Successfully released v1.0.0 on GitHub

**Documentation Updates:**
- Updated `.github/workflows/build-release.yml`:
  - Expanded installation instructions in release notes
  - Added explanation of WHY Gatekeeper blocks the app (unsigned, open-source, no $99 fee)
  - Added step-by-step bypass instructions with formatting
  - Added link to source code for transparency
- Updated `docs/disk-cleaner.md`:
  - Replaced "Undo Support" with "Trash Option" (matches actual implementation)
- Updated `docs/performance.md`:
  - Removed "Scheduled Maintenance" section (not implemented)
  - Added "Run All Feature" section documenting batch execution
- Updated `docs/permissions.md`:
  - Corrected Settings > Permissions description
- Fixed GitHub URL in AboutSettingsView (yourusername → Prot10)

**Files Modified**:
- `.github/workflows/build-release.yml`
- `appcast.xml`
- `README.md`
- `docs/disk-cleaner.md`
- `docs/performance.md`
- `docs/permissions.md`
- `MyMacCleaner/App/MyMacCleanerApp.swift`
- `CLAUDE.md`

**Build Status**: SUCCESS

**Release Status**: v1.0.0 PUBLISHED

---

### 2026-01-05 - Permissions Management Page & Warning Fixes

**Session Goal**: Add new Permissions page for reviewing and managing folder access permissions, fix all compiler warnings

**Completed**:

**Permissions Management Page:**
- Created PermissionCategory.swift data models:
  - PermissionCategoryType enum (fullDiskAccess, userFolders, systemFolders, applicationData, startupPaths)
  - FolderAccessInfo struct (path, displayName, status, requiresFDA, canTriggerTCCDialog)
  - FolderAccessStatus enum (accessible, denied, notExists, checking)
  - PermissionCategoryState struct for UI state
- Created PermissionsViewModel.swift:
  - buildCategories() creates all 5 category states with folder paths
  - checkAllPermissions() tests actual read access to each folder
  - requestFolderAccess() triggers TCC dialog for user folders
  - revokeFolderAccess() opens appropriate System Settings pane
  - Auto-refresh on app activation
- Created PermissionFolderRow.swift component:
  - Status icon (green checkmark / red X / orange ?)
  - Folder displayName and path
  - "Grant" button (green for TCC, blue gear for FDA)
  - "Revoke" button (red, opens System Settings)
- Created PermissionCategoryCard.swift:
  - Expandable glassCard with header showing category status
  - Lists all folders with PermissionFolderRow
- Created PermissionsView.swift:
  - Header with title, subtitle, and refresh button
  - Summary card showing X/Y folders accessible
  - Expandable category cards
  - Auto-refresh on NSApplication.didBecomeActiveNotification
- Updated ContentView.swift:
  - Added NavigationSection.permissions case
  - Icon: "lock.shield.fill", Color: Theme.Colors.permissions (indigo)
- Updated AppState.swift:
  - Added permissionsViewModel property
- Updated Theme.swift:
  - Added permissions color (indigo)
- Updated Localizable.xcstrings:
  - Added 25+ translation keys (EN/IT/ES) for permissions UI

**Warning Fixes:**
- Fixed AuthorizationService.swift:73,91 - "capture of 'self' with non-Sendable type"
  - Moved escapeForAppleScript() call before async block to capture escaped string instead of self
- Fixed SpaceLensViewModel.swift:178 - "makeIterator unavailable from async"
  - Changed `for case let fileURL as URL in enumerator` to `while let fileURL = enumerator.nextObject() as? URL`
- Fixed PortManagementViewModel.swift:148 - "call to actor-isolated method"
  - Made parseLsofOutput() and parseAddressPort() nonisolated functions
- Fixed FileScanner.swift:211,298 - "makeIterator unavailable from async"
  - Changed both for-in loops to while-let pattern
- Fixed AppUpdateChecker.swift:95 - "reference to captured var"
  - Used collected.count instead of mutable captured variable
- Fixed StartupItemsService.swift:180,520 - "call to actor-isolated method"
  - Reordered modifiers to `private static nonisolated func` for parseBTMOutput and getCodeSigningTeam

**Files Created**:
- `MyMacCleaner/Core/Models/PermissionCategory.swift`
- `MyMacCleaner/Features/Permissions/PermissionsView.swift`
- `MyMacCleaner/Features/Permissions/PermissionsViewModel.swift`
- `MyMacCleaner/Features/Permissions/Components/PermissionCategoryCard.swift`
- `MyMacCleaner/Features/Permissions/Components/PermissionFolderRow.swift`

**Files Modified**:
- `MyMacCleaner/App/ContentView.swift` (added permissions navigation)
- `MyMacCleaner/App/AppState.swift` (added permissionsViewModel)
- `MyMacCleaner/Core/Design/Theme.swift` (added permissions color)
- `MyMacCleaner/Core/Services/AuthorizationService.swift` (fixed self capture warning)
- `MyMacCleaner/Core/Services/FileScanner.swift` (fixed makeIterator warning)
- `MyMacCleaner/Core/Services/AppUpdateChecker.swift` (fixed captured var warning)
- `MyMacCleaner/Core/Services/StartupItemsService.swift` (fixed actor-isolated warnings)
- `MyMacCleaner/Features/SpaceLens/SpaceLensViewModel.swift` (fixed makeIterator warning)
- `MyMacCleaner/Features/PortManagement/PortManagementViewModel.swift` (fixed actor-isolated warning)
- `MyMacCleaner/Resources/Localizable.xcstrings` (added permissions translations)

**Key Technical Decisions**:
- TCC folders (Downloads, Documents, Desktop) trigger system permission dialog via FileManager.contentsOfDirectory()
- FDA folders cannot trigger dialog programmatically - show "Open Settings" button
- Permission revocation not possible programmatically on macOS - opens appropriate System Settings pane
- Auto-refresh permissions when app becomes active (user returns from System Settings)

**Build Status**: SUCCESS (0 warnings)

---

### 2026-01-07 - Comprehensive PR CI Workflow

**Session Goal**: Add comprehensive CI checks for pull requests

**Completed**:

**PR Checks Workflow:**
- Created `.github/workflows/pr-checks.yml` with:
  - **Build Job**: Debug + Release builds on macOS 26
  - **Unit Tests**: Runs test suite with code coverage
  - **UI Tests**: Optional (continue-on-error) UI test execution
  - **Archive Test**: Verifies release archive creation works
  - **SwiftLint**: Code style checking (non-blocking)
  - **Documentation**: Verifies CLAUDE.md and README.md exist
  - **Appcast Validation**: XML validation for Sparkle feed
  - **Summary Job**: Required check for branch protection (`pr-check-complete`)

**Additional Features:**
- Concurrency control: Cancels in-progress runs for same PR
- SPM caching: Faster builds via cached dependencies
- Timeout limits: Prevents stuck jobs
- Artifact upload: Test results saved for review

**SwiftLint Configuration:**
- Created `.swiftlint.yml` with sensible defaults
- Disabled overly strict rules (line_length, file_length, etc.)
- Enabled useful opt-in rules (force_unwrapping, empty_count, etc.)
- Excluded test files and resources

**Files Created**:
- `.github/workflows/pr-checks.yml`
- `.swiftlint.yml`

**Files Modified**:
- `CLAUDE.md` (this changelog entry)

**Build Status**: SUCCESS

**Branch Protection Setup (Manual)**:
User should configure in GitHub: Settings > Branches > Add rule for `main`:
- Require pull request before merging
- Require status checks: `pr-check-complete`
- Require conversation resolution
- Restrict who can push (optional - only owner)

---

### 2026-01-08 - New Features & Documentation

**Session Goal**: Complete Phase 4 (Menu Bar) and add stability fixes for Duplicate Scanner

**Completed**:

**Phase 4 - Menu Bar Monitor:**
- Created `SystemStatsProvider.swift` - Shared service for CPU/RAM monitoring
- Created `MenuBarController.swift` - NSStatusItem controller with 4 display modes
- Created `MenuBarView.swift` - SwiftUI popover with CPU, RAM, Disk stats
- Integrated with Settings (General tab) for enable/disable and display mode
- Added localization strings for all menu bar UI (EN/ES/IT)

**Duplicate Scanner Stability Fixes:**
- Added cancellation support with cancel button during scanning
- Added symbolic link detection to prevent infinite loops
- Added file readability checks before processing
- Added skip lists for system files (.DS_Store, .localized, etc.)
- Added skip lists for temp file extensions (.tmp, .lock, etc.)
- Moved file I/O to background threads with autoreleasepool
- Added proper error handling with do-catch blocks
- Throttled progress updates to reduce UI overhead
- Added "Change Folder" button in empty state and header

**Documentation:**
- Created `docs/orphaned-files.md` - Full documentation for Orphaned Files feature
- Created `docs/duplicates.md` - Full documentation for Duplicate Finder
- Created `docs/menu-bar.md` - Full documentation for Menu Bar Monitor
- Updated `docs/disk-cleaner.md` - Added Browser Privacy section
- Updated `README.md` - Added new features to table and documentation links
- Updated `CLAUDE.md` - Updated project structure with new files

**Files Created**:
- `MyMacCleaner/Core/Services/SystemStatsProvider.swift`
- `MyMacCleaner/MenuBar/MenuBarController.swift`
- `MyMacCleaner/MenuBar/MenuBarView.swift`
- `docs/orphaned-files.md`
- `docs/duplicates.md`
- `docs/menu-bar.md`

**Files Modified**:
- `MyMacCleaner/Core/Services/DuplicateScanner.swift` (stability fixes)
- `MyMacCleaner/Features/Duplicates/DuplicatesView.swift` (cancel button, change folder)
- `MyMacCleaner/Features/Duplicates/DuplicatesViewModel.swift` (cancelScan method)
- `MyMacCleaner/Features/DiskCleaner/DiskCleanerView.swift` (ScanningOverlay cancel)
- `MyMacCleaner/App/MyMacCleanerApp.swift` (menu bar integration)
- `MyMacCleaner/Resources/Localizable.xcstrings` (menu bar + duplicates strings)
- `docs/disk-cleaner.md` (Browser Privacy section)
- `README.md` (new features)
- `CLAUDE.md` (project structure, changelog)

**Build Status**: SUCCESS

---

## Constraints & Guidelines

### Code Quality
- Use Swift modern concurrency (async/await)
- Use actors for thread-safe services
- Follow MVVM architecture
- Keep views simple, logic in ViewModels

### UI/UX
- Match Apple Music's Liquid Glass aesthetic
- Use `.ultraThinMaterial` for glass effects (macOS 14)
- Use native `.glassEffect()` on macOS 26+
- Smooth animations for all transitions
- Always show progress for long operations

### Performance
- Use `enumerator(at:includingPropertiesForKeys:)` for file scanning
- Parallelize with TaskGroups where possible
- Lazy load large lists
- Cancel operations when user navigates away

### Security
- Never store user passwords
- Request permissions at point of use only
- Protect against path traversal
- Validate all user inputs

### Documentation
- Update docs when features change
- Keep README accurate
- Update this file every session
- Comment complex code only

---

## Quick Reference

### Key Files to Know

| File | Purpose |
|------|---------|
| `IMPLEMENTATION_PLAN.md` | Full technical specification |
| `claude.md` | Session tracking (this file) |
| `README.md` | User-facing project info |
| `docs/*.md` | Feature documentation |

### Useful Commands

```bash
# Build project
xcodebuild -project MyMacCleaner.xcodeproj -scheme MyMacCleaner build

# Run tests
xcodebuild test -project MyMacCleaner.xcodeproj -scheme MyMacCleaner

# Clean build
xcodebuild clean -project MyMacCleaner.xcodeproj -scheme MyMacCleaner
```

### Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| Sparkle | 2.x | Auto-updates |
| FullDiskAccess | latest | Permission checking |

---

## How to Use This File

1. **Start of session**: Read this file to understand current state
2. **During work**: Reference TODO tracker and constraints
3. **End of session**: Update TODO tracker, changelog, and any affected docs
4. **If stuck**: Check blockers section and previous decisions

**Remember**: This file is the source of truth for project progress!
