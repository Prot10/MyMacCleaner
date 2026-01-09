# Startup Items

Manage applications and services that launch automatically when you log in.

## Overview

Startup Items helps you control what runs when your Mac starts, improving boot time and reducing resource usage.

## Quick Stats

The dashboard shows four key metrics:

| Stat | Description |
|------|-------------|
| **Total** | Number of user startup items |
| **Enabled** | Items that will run at login |
| **Disabled** | Items currently turned off |
| **Running** | Items currently active |

## Types of Startup Items

### Login Items

Apps configured to open at login via System Settings.

| Property | Value |
|----------|-------|
| Location | System Settings > General > Login Items |
| Scope | Current user |
| Control | Enable/Disable via toggle |

### User LaunchAgents

Background services for the current user.

| Property | Value |
|----------|-------|
| Location | `~/Library/LaunchAgents` |
| Scope | Current user |
| Format | Property list (.plist) files |

### System LaunchAgents

Background services for all users.

| Property | Value |
|----------|-------|
| Location | `/Library/LaunchAgents` |
| Scope | All users |
| Requires | Admin privileges to modify |

### System Items

Apple system services (read-only).

| Property | Value |
|----------|-------|
| Location | `/System/Library/LaunchAgents` |
| Scope | System-wide |
| Control | Cannot be modified |

## Interface Features

### Search & Filter

- **Search** - Find items by name or identifier
- **Type Filter** - Show only specific item types
- **Sort Order** - Sort by name, status, or type
- **Show System Items** - Toggle visibility of Apple system items

### Item Information

Each item displays:

| Info | Description |
|------|-------------|
| **Name** | Display name or filename |
| **Label** | Bundle identifier or plist name |
| **Developer** | Vendor (when detectable) |
| **Type** | Login Item, LaunchAgent, etc. |
| **Status** | Enabled or Disabled |
| **Running** | Green dot if currently active |

### Expanded Details

Click any item to see:
- Full file path
- Executable path
- Bundle identifier
- Additional metadata

## Managing Items

### Enable/Disable

1. Find the item in the list
2. Click the play/pause button
3. Confirm the action
4. Item state updated

**Note:** Changes take effect at next login.

### Remove Item

1. Find the item in the list
2. Click the ellipsis menu (...)
3. Select "Remove"
4. Confirm deletion

**Warning:** Only remove items you recognize. Some are required for apps to function properly.

### Reveal in Finder

1. Click the ellipsis menu (...)
2. Select "Show in Finder"
3. Opens the item's location

## Common Startup Items

### Safe to Disable

- Cloud storage sync (Dropbox, Google Drive) - if not needed immediately
- Chat applications (Slack, Discord)
- Music services (Spotify)
- Development tools (Docker)

### Usually Required

- Security software (antivirus, firewall)
- Backup services (Time Machine helpers)
- Display/audio drivers
- Printer services

### Never Disable

- Apple system items (shown with "System" badge)
- Items you don't recognize (research first)

## Identifying Unknown Items

### By Developer

Startup Items shows the vendor when detectable:
- **Apple Inc.** - System components
- **Known vendors** - Third-party software
- **Unknown** - Investigate before removing

### By Bundle Identifier

Look at the label/identifier:
- `com.apple.*` - Apple system
- `com.adobe.*` - Adobe software
- `com.spotify.*` - Spotify
- `com.docker.*` - Docker

### Research Unknown Items

1. Note the item name and bundle ID
2. Search online for information
3. Check if associated with installed app
4. Remove only if confirmed unnecessary

## Troubleshooting

### Item Won't Disable

Some items may require:
- Admin password (system LaunchAgents)
- App to be closed first
- Restart to take effect

### Item Keeps Coming Back

The parent application may recreate the item:
- Disable within the app's preferences instead
- Or uninstall the application entirely

### Too Many Items

If you have many startup items:
1. Disable items you don't need immediately
2. Consider uninstalling unused apps
3. Review periodically after installing new software

## Tips

1. **Fewer is better** - Disable unnecessary items for faster boot
2. **Test changes** - Restart after disabling to verify no issues
3. **Keep security items** - Antivirus and firewall should stay enabled
4. **Check after installing apps** - New apps often add startup items
5. **Use the Running indicator** - Green dot shows what's actually active

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd + F` | Focus search field |
| `Cmd + R` | Refresh list |
