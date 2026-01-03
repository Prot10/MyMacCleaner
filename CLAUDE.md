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
├── claude.md                    # THIS FILE - Update every session!
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
└── MyMacCleaner/                # Source code (to be created)
    ├── App/
    ├── Core/
    ├── Features/
    └── Resources/
```

---

## TODO Tracker

### Current Phase: Phase 1 - Project Setup

### Overall Progress: 0% (0/8 phases complete)

### Phase Status

| Phase | Name | Status | Progress |
|-------|------|--------|----------|
| 1 | Project Setup | NOT STARTED | 0% |
| 2 | UI Shell & Navigation | NOT STARTED | 0% |
| 3 | Home - Smart Scan | NOT STARTED | 0% |
| 4 | Disk Cleaner + Space Lens | NOT STARTED | 0% |
| 5 | Performance | NOT STARTED | 0% |
| 6 | Applications Manager | NOT STARTED | 0% |
| 7 | Port Management | NOT STARTED | 0% |
| 8 | System Health | NOT STARTED | 0% |

### Detailed Task List

#### Phase 1: Project Setup
- [ ] Create new Xcode project with SwiftUI
- [ ] Configure bundle identifier
- [ ] Configure deployment target (macOS 14.0+)
- [ ] Disable App Sandbox in entitlements
- [ ] Add Sparkle package dependency
- [ ] Add FullDiskAccess package dependency
- [ ] Create folder structure (App/, Core/, Features/, Resources/)
- [ ] Configure Info.plist with usage descriptions
- [ ] Test build succeeds

#### Phase 2: UI Shell & Navigation
- [ ] Create Theme.swift with color palette
- [ ] Create LiquidGlass.swift with glass effect modifiers
- [ ] Create NavigationSection enum
- [ ] Create Sidebar.swift component
- [ ] Create ContentView.swift with NavigationSplitView
- [ ] Create ComingSoonView.swift placeholder
- [ ] Create placeholder views for all 6 sections
- [ ] Add page transition animations
- [ ] Test navigation works correctly

#### Phase 3: Home - Smart Scan
- [ ] Create HomeView.swift
- [ ] Create HomeViewModel.swift
- [ ] Create SmartScanButton.swift
- [ ] Create StatCard.swift component
- [ ] Create ScanResultsCard.swift
- [ ] Implement async scanning logic
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
