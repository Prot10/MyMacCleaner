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
    │   │   └── Animations.swift
    │   ├── Services/
    │   ├── Models/
    │   └── Extensions/
    ├── Features/
    │   ├── Home/
    │   │   ├── HomeView.swift
    │   │   └── HomeViewModel.swift
    │   ├── DiskCleaner/
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

### Current Phase: Phase 3 - Home Smart Scan (Completion)

### Overall Progress: 25% (2/8 phases complete)

### Phase Status

| Phase | Name | Status | Progress |
|-------|------|--------|----------|
| 1 | Project Setup | COMPLETED | 100% |
| 2 | UI Shell & Navigation | COMPLETED | 100% |
| 3 | Home - Smart Scan | IN PROGRESS | 80% |
| 4 | Disk Cleaner + Space Lens | NOT STARTED | 0% |
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
- [ ] Create ScanResultsCard.swift
- [x] Implement async scanning logic (basic)
- [ ] Add permission check before scanning
- [ ] Test scanning functionality

#### Phase 4: Disk Cleaner + Space Lens
- [ ] Create DiskCleanerView.swift
- [ ] Create DiskCleanerViewModel.swift
- [ ] Create CleanupCategory model
- [ ] Create CleanupCategoryCard.swift
- [ ] Implement file scanning for each category
- [ ] Create SpaceLensView.swift
- [ ] Create TreemapLayout.swift
- [ ] Implement treemap visualization
- [ ] Add safe deletion with confirmation
- [ ] Test cleanup operations

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
