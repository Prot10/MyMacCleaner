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
│   ├── performance.md
│   ├── applications.md
│   ├── port-management.md
│   ├── system-health.md
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
    │   │   └── PermissionsService.swift
    │   ├── Models/
    │   │   └── ScanResult.swift
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
    │   │   └── Components/
    │   │       └── CleanupCategoryCard.swift
    │   ├── SpaceLens/
    │   │   ├── SpaceLensView.swift
    │   │   └── SpaceLensViewModel.swift
    │   ├── Performance/
    │   ├── Applications/
    │   ├── PortManagement/
    │   └── SystemHealth/
    ├── Resources/
    │   └── Assets.xcassets/
    └── MyMacCleaner.entitlements
```

---

## TODO Tracker

### Current Phase: Phase 5 - Performance

### Overall Progress: 50% (4/8 phases complete)

### Phase Status

| Phase | Name | Status | Progress |
|-------|------|--------|----------|
| 1 | Project Setup | COMPLETED | 100% |
| 2 | UI Shell & Navigation | COMPLETED | 100% |
| 3 | Home - Smart Scan | COMPLETED | 100% |
| 4 | Disk Cleaner + Space Lens | COMPLETED | 100% |
| 5 | Performance | NOT STARTED | 0% |
| 6 | Applications Manager | NOT STARTED | 0% |
| 7 | Port Management | NOT STARTED | 0% |
| 8 | System Health | NOT STARTED | 0% |

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
- [ ] Create PerformanceView.swift
- [ ] Create PerformanceViewModel.swift
- [ ] Create MaintenanceTask enum
- [ ] Create MaintenanceTaskCard.swift
- [ ] Create MemoryMonitor.swift
- [ ] Implement RAM freeing functionality
- [ ] Implement DNS flush
- [ ] Implement Spotlight rebuild
- [ ] Add real-time memory chart
- [ ] Test all maintenance tasks

#### Phase 6: Applications Manager
- [ ] Create ApplicationsView.swift
- [ ] Create ApplicationsViewModel.swift
- [ ] Create InstalledApp model
- [ ] Create AppCard.swift component
- [ ] Implement app scanning
- [ ] Create UninstallSheet.swift
- [ ] Implement leftover detection
- [ ] Create AppUpdateChecker.swift
- [ ] Add Homebrew integration
- [ ] Test uninstall functionality

#### Phase 7: Port Management
- [ ] Create PortManagementView.swift
- [ ] Create PortManagementViewModel.swift
- [ ] Create NetworkConnection model
- [ ] Create PortScanner.swift actor
- [ ] Implement lsof parsing
- [ ] Create ConnectionRow.swift
- [ ] Implement process killing
- [ ] Add filtering and search
- [ ] Test port scanning and killing

#### Phase 8: System Health
- [ ] Create SystemHealthView.swift
- [ ] Create SystemHealthViewModel.swift
- [ ] Create StartupItem model
- [ ] Create StartupItemsManager.swift
- [ ] Implement startup item detection
- [ ] Create StartupItemRow.swift
- [ ] Create SystemMonitor.swift
- [ ] Implement CPU/Memory monitoring
- [ ] Add system stats charts
- [ ] Test startup item management

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
