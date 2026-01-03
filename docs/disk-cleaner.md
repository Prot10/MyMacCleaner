# Disk Cleaner

Deep cleaning functionality to remove junk files and free up disk space.

## Overview

Disk Cleaner provides granular control over what gets cleaned, with detailed categories and safe deletion practices.

## Categories

### System Junk

System-level cached and temporary files.

| Item | Location | Safe to Delete |
|------|----------|----------------|
| System Cache | `/Library/Caches` | Yes |
| User Cache | `~/Library/Caches` | Yes |
| System Logs | `/Library/Logs` | Yes |
| User Logs | `~/Library/Logs` | Yes |
| Temporary Files | `/tmp`, `/var/folders` | Yes |

### Application Junk

Application-specific cleanup.

| Item | Location | Safe to Delete |
|------|----------|----------------|
| App Caches | `~/Library/Caches/[AppName]` | Yes |
| Crash Reports | `~/Library/Logs/DiagnosticReports` | Yes |
| Saved States | `~/Library/Saved Application State` | Yes |
| App Cookies | `~/Library/Cookies` | Caution |

### Development Files

For developers using Xcode and related tools.

| Item | Location | Safe to Delete |
|------|----------|----------------|
| DerivedData | `~/Library/Developer/Xcode/DerivedData` | Yes |
| Archives | `~/Library/Developer/Xcode/Archives` | Caution |
| Simulators | `~/Library/Developer/CoreSimulator/Devices` | Yes (unused) |
| CocoaPods Cache | `~/Library/Caches/CocoaPods` | Yes |
| Carthage | `~/Library/Caches/org.carthage.CarthageKit` | Yes |
| SPM Cache | `~/Library/Caches/org.swift.swiftpm` | Yes |

### Browser Data

Web browser caches and data.

| Browser | Cache Location |
|---------|----------------|
| Safari | `~/Library/Caches/com.apple.Safari` |
| Chrome | `~/Library/Caches/Google/Chrome` |
| Firefox | `~/Library/Caches/Firefox` |
| Edge | `~/Library/Caches/Microsoft Edge` |

### Mail Attachments

Email attachments that take up space.

| Item | Location |
|------|----------|
| Mail Downloads | `~/Library/Containers/com.apple.mail/Data/Library/Mail Downloads` |
| Mail Attachments | `~/Library/Mail/V*/Mailboxes` |

## How to Use

1. Navigate to **Disk Cleaner** in the sidebar
2. Select categories you want to scan
3. Click **Scan** to analyze
4. Review items in each category
5. Uncheck items you want to keep
6. Click **Clean** to delete selected items

## Safety Features

### Pre-deletion Checks
- Files are verified before deletion
- System-critical files are protected
- Recently modified files are flagged

### Undo Support
- Deleted items are moved to a recovery location
- 24-hour recovery window
- Permanent deletion after confirmation

### Size Thresholds
- Items under 1MB grouped as "Small Files"
- Large files (>100MB) highlighted
- Total savings calculated in real-time

## Best Practices

1. **Don't delete everything** - Some caches improve app performance
2. **Review before cleaning** - Check flagged items carefully
3. **Xcode DerivedData** - Safe to delete, rebuilds automatically
4. **Browser caches** - Will slow down frequently visited sites temporarily
5. **Mail attachments** - Ensure emails are synced before cleaning

## Permissions Required

Full Disk Access is required to scan:
- System caches (`/Library/Caches`)
- System logs (`/Library/Logs`)
- Mail data
- Some application containers

See [Permissions Guide](permissions.md) for setup instructions.
