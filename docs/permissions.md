# Permissions Guide

Understanding and managing permissions for MyMacCleaner.

## Overview

MyMacCleaner needs certain permissions to access system files and perform cleanup operations. This guide explains what permissions are needed, why, and how to grant them.

## Our Permission Philosophy

1. **Request only when needed** - We never ask for permissions on app launch
2. **Explain before asking** - You'll always know why we need access
3. **Graceful degradation** - The app works with limited features if you decline
4. **Minimal access** - We request only what's necessary for each feature

## Required Permissions

### Full Disk Access (FDA)

**What it is:** System-wide permission to read files in protected locations.

**Why we need it:**
- Scan system caches (`/Library/Caches`)
- Scan system logs (`/Library/Logs`)
- Access Mail attachments
- Read application containers
- Scan for app leftovers during uninstall

**Features requiring FDA:**
- Disk Cleaner (system categories)
- Smart Scan (complete scan)
- Application Uninstaller (complete leftover detection)
- Space Lens (full disk scanning)

**Features that work without FDA:**
- User caches and logs
- Xcode cleanup
- RAM management
- Port management
- Startup items (partial)

### How to Grant Full Disk Access

1. MyMacCleaner will prompt you when FDA is needed
2. Click "Open System Settings" in the prompt
3. System Settings opens to Privacy & Security > Full Disk Access
4. Click the lock icon and authenticate
5. Find MyMacCleaner in the list
6. Toggle the switch ON
7. Return to MyMacCleaner

**Manual Path:**
```
System Settings > Privacy & Security > Full Disk Access
```

### Automation Permission

**What it is:** Permission to control other applications.

**Why we need it:**
- Quit apps before uninstalling
- Clean up app-specific data

**When requested:**
- When uninstalling apps that are currently running

**How to grant:**
- A system dialog will appear automatically
- Click "OK" to allow

## Checking Permission Status

### In MyMacCleaner

Go to **Settings > Permissions** to see:
- Current permission status
- Which features are affected
- Quick links to grant permissions

### In System Settings

1. Open System Settings
2. Go to Privacy & Security
3. Check relevant categories:
   - Full Disk Access
   - Automation
   - Files and Folders

## Administrator Password

Some operations require your administrator password:

| Operation | Why |
|-----------|-----|
| Free Memory | `sudo purge` command |
| Flush DNS | System cache access |
| Rebuild Spotlight | Index modification |
| Kill system processes | Elevated privileges |

**Security notes:**
- Password is never stored
- Used only for immediate operation
- Handled securely via macOS APIs

## Privacy & Security

### What We Access

| Data Type | Purpose | Stored? |
|-----------|---------|---------|
| File paths | Scanning | No |
| File sizes | Display | No |
| Process list | Port management | No |
| App list | Uninstaller | No |

### What We Never Do

- Send data to external servers
- Store your files or data
- Access personal documents content
- Track your usage
- Collect analytics

### Data Handling

- All scanning happens locally
- No cloud services required
- No account needed
- Completely offline capable

## Troubleshooting

### "Operation not permitted"

**Cause:** Missing Full Disk Access

**Solution:**
1. Grant FDA (see instructions above)
2. Restart MyMacCleaner
3. Try operation again

### Permission Not Appearing

**Cause:** App not recognized by macOS

**Solution:**
1. Quit MyMacCleaner completely
2. Open System Settings > Privacy & Security > Full Disk Access
3. Click + button
4. Navigate to Applications and select MyMacCleaner
5. Restart the app

### Changes Not Taking Effect

**Cause:** macOS caching permission state

**Solution:**
1. Fully quit MyMacCleaner (Cmd + Q)
2. Toggle permission OFF then ON
3. Relaunch the app

### App Crashes After Granting

**Cause:** Permission change during operation

**Solution:**
1. Quit and relaunch MyMacCleaner
2. If persists, remove and re-add permission
3. Restart Mac if needed

## Revoking Permissions

You can revoke permissions anytime:

1. Open System Settings
2. Go to Privacy & Security
3. Select the permission category
4. Toggle MyMacCleaner OFF

**Note:** Some features will become unavailable.

## FAQ

**Q: Is it safe to grant Full Disk Access?**
A: Yes, for trusted apps. FDA is read access to protected locations. MyMacCleaner is open-source, so you can verify exactly what we do with this access.

**Q: Why doesn't MyMacCleaner appear in FDA list?**
A: You need to trigger an FDA request first, or manually add the app using the + button.

**Q: Can I use MyMacCleaner without any permissions?**
A: Yes, with limited functionality. User-level cleanup, RAM management, and port management work without special permissions.

**Q: Is my password stored?**
A: Never. It's used once for the specific operation and immediately discarded.
