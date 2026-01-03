# System Health

Monitor system performance and manage startup items.

## Overview

System Health provides real-time monitoring of your Mac's vital statistics and control over what runs at startup.

## System Monitor

### CPU Usage

Real-time CPU utilization graph showing:

| Metric | Description |
|--------|-------------|
| **User** | Applications and processes |
| **System** | macOS kernel operations |
| **Idle** | Unused capacity |

### Memory Stats

| Metric | Description |
|--------|-------------|
| **Used** | Memory in active use |
| **App Memory** | Memory used by apps |
| **Wired** | Memory that can't be compressed |
| **Compressed** | Memory compressed to save space |
| **Cached** | Files cached for quick access |
| **Free** | Available memory |

### Memory Pressure

Color-coded indicator:
- **Green** - Normal, plenty of memory available
- **Yellow** - Warning, memory getting constrained
- **Red** - Critical, system using swap heavily

### Disk Health

- **Used/Available** space
- **Read/Write** speeds
- **S.M.A.R.T. status** (if supported)

### Battery Health (MacBooks)

- **Cycle Count** - Total charge cycles
- **Condition** - Normal, Service Recommended, etc.
- **Capacity** - Current vs. original capacity

## Startup Manager

### What Are Startup Items?

Programs that launch automatically when you:
- Turn on your Mac
- Log into your account

Too many startup items slow down boot time and use resources.

### Types of Startup Items

| Type | Location | Scope |
|------|----------|-------|
| **Login Items** | System Settings | Current user |
| **User LaunchAgents** | `~/Library/LaunchAgents` | Current user |
| **System LaunchAgents** | `/Library/LaunchAgents` | All users |
| **LaunchDaemons** | `/Library/LaunchDaemons` | System-wide |

### Managing Startup Items

#### View All Items

1. Open System Health
2. Go to Startup Items tab
3. See all items with status

#### Disable an Item

1. Find item in list
2. Toggle the switch to OFF
3. Item won't run at next startup

#### Enable an Item

1. Find disabled item
2. Toggle the switch to ON
3. Item will run at next startup

#### Remove an Item

1. Select item
2. Click Remove
3. Confirm deletion

**Warning:** Only remove items you recognize. Some are required for apps to function.

### Item Information

For each startup item, you can see:

| Info | Description |
|------|-------------|
| **Name** | Display name or filename |
| **Vendor** | Company that created it |
| **Path** | File location |
| **Type** | LaunchAgent, Daemon, etc. |
| **Status** | Enabled or Disabled |
| **Run At** | Login, Boot, or Both |

### Common Startup Items

#### Safe to Disable

- Cloud storage sync (Dropbox, Google Drive) - if not needed at login
- Chat applications
- Music services
- Development tools

#### Usually Required

- Security software
- Backup services (Time Machine helpers)
- Display/audio drivers
- Printer services

#### Never Disable

- Apple system items in `/System/Library/`
- Items you don't recognize (research first)

## Identifying Unknown Items

### By Vendor

Startup Manager shows vendor when detectable:
- **Apple Inc.** - System components
- **Known vendors** - Third-party software
- **Unknown** - Investigate before removing

### By Path

Look at the file path:
- `/Library/LaunchAgents/com.adobe.*` - Adobe software
- `~/Library/LaunchAgents/com.spotify.*` - Spotify

### Research Unknown Items

1. Note the item name/path
2. Search online for information
3. Check if associated with installed app
4. Remove only if confirmed unnecessary

## Tips

1. **Fewer is better** - Disable unnecessary startup items
2. **Test changes** - Restart after disabling to verify
3. **Keep security items** - Antivirus, firewall, etc.
4. **Monitor memory pressure** - Yellow/red indicates issues
5. **Check after installing apps** - New apps often add startup items

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd + R` | Refresh stats |
| `Cmd + 1` | System Monitor tab |
| `Cmd + 2` | Startup Items tab |
| `Space` | Toggle selected item |
