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

## Browser Privacy

The Browser Privacy tab provides deep cleaning of browser data for enhanced privacy.

### Supported Browsers

| Browser | Supported |
|---------|-----------|
| Safari | Yes |
| Google Chrome | Yes |
| Mozilla Firefox | Yes |
| Microsoft Edge | Yes |

### Cleanable Data Types

| Data Type | Description | Privacy Impact |
|-----------|-------------|----------------|
| **Browsing History** | Record of visited websites | High |
| **Cookies** | Website tracking and session data | High |
| **Cache** | Cached images, scripts, stylesheets | Medium |
| **Downloads History** | Record of downloaded files | Medium |
| **Form Data** | Autofill data for forms | High |
| **Saved Passwords** | Stored login credentials | Critical |
| **Local Storage** | Website data stored locally | Medium |

### How to Use Browser Privacy

1. Navigate to **Disk Cleaner** in the sidebar
2. Click the **Browser Privacy** tab
3. Select browsers you want to clean
4. Choose data types to remove (checkboxes)
5. Click **Clean Selected**
6. Confirm the action

### Warnings

- **Close browsers first** - Browsers should be closed during cleaning
- **Saved Passwords** - Will require re-entering passwords on websites
- **Cookies** - Will log you out of websites
- **Form Data** - Will clear autofill suggestions

### Best Practices

1. Keep browsers closed during cleaning
2. Be cautious with password deletion
3. Export important bookmarks first
4. Consider which cookies you want to keep (banking sites, etc.)

### Mail Attachments

Email attachments that take up space.

| Item | Location |
|------|----------|
| Mail Downloads | `~/Library/Containers/com.apple.mail/Data/Library/Mail Downloads` |
| Mail Attachments | `~/Library/Mail/V*/Mailboxes` |

## Empty Trash

A dedicated card at the bottom of the Cleaner tab provides quick access to empty your Trash.

### Features

| Feature | Description |
|---------|-------------|
| **Size Display** | Shows current Trash size |
| **One-Click Empty** | Empty Trash with a single click |
| **Confirmation** | Asks for confirmation before permanently deleting |
| **FDA Badge** | Shows if Full Disk Access is needed for complete cleanup |

### Permission Requirements

- **With Full Disk Access**: Empties all Trash contents including protected files
- **Without Full Disk Access**: May not be able to remove some files

The "Needs FDA" badge is clickable - click it to open System Settings and grant Full Disk Access.

### How to Use

1. Check the Trash size displayed on the card
2. Click **Empty Trash** button
3. Confirm the action in the dialog
4. Wait for the operation to complete

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

### Trash Option
- Option to move items to Trash instead of permanent deletion
- Recover from Trash if needed before emptying

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
