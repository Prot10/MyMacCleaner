# MyMacCleaner

A native macOS maintenance utility built with Swift and SwiftUI. Clean your Mac, uninstall apps completely, optimize memory, and manage launch agents — all in one beautiful app.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5-green)

## Features

### Dashboard
- Real-time system monitoring (CPU, Memory, Storage)
- One-click Smart Scan to find cleanable files
- CleanMyMac-style interface with beautiful gauges and charts

### System Cleaner
- Clean system and user caches
- Remove application logs
- Clear Xcode derived data and archives
- Clean package manager caches (Homebrew, npm, pip)
- Empty Trash

### App Uninstaller
- Browse all installed applications
- Find leftover files after uninstallation
- Confidence-based leftover detection (high/medium/low)
- Complete removal of app traces from Library folders

### Optimizer
- View detailed memory breakdown
- Free up RAM (requires privileged helper)
- Manage Launch Agents
- Quick access to Login Items settings

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0+ (for building)

## Building

1. Clone the repository:
```bash
git clone https://github.com/Prot10/MyMacCleaner.git
cd MyMacCleaner
```

2. Open in Xcode:
```bash
open MyMacCleaner.xcodeproj
```

3. Build and run (⌘R)

## Project Structure

```
MyMacCleaner/
├── App/                    # App entry point and navigation
├── Features/
│   ├── Dashboard/          # Main dashboard with system stats
│   ├── Cleaner/            # System cleanup functionality
│   ├── Uninstaller/        # App uninstallation with leftover detection
│   ├── Optimizer/          # Memory and launch agent management
│   └── Settings/           # App preferences and permissions
├── Core/
│   ├── Services/           # Helper connection, permissions, updates
│   └── Repositories/       # System stats data access
└── SharedKit/
    ├── Models/             # Data models
    ├── XPC/                # XPC communication definitions
    ├── Utilities/          # Path validation and helpers
    └── Configuration/      # Cleanup path definitions
```

## Architecture

- **UI Framework**: SwiftUI with Swift Charts
- **State Management**: @Observable (Swift 5.9+)
- **Architecture Pattern**: MVVM with Use Cases
- **Privileged Operations**: SMAppService + XPC (macOS 13+)

## Permissions

For full functionality, MyMacCleaner may request:

- **Full Disk Access**: To scan protected Library directories
- **Login Items**: To enable the privileged helper for root operations

## Roadmap

- [ ] Privileged Helper for root operations (memory purge, system cleanup)
- [ ] Trash monitoring with cleanup notifications (Sentinel)
- [ ] Sparkle auto-updates
- [ ] Finder extension for right-click uninstall
- [ ] Disk space visualization by folder

## License

MIT License

## Acknowledgments

Inspired by:
- [Pearcleaner](https://github.com/alienator88/Pearcleaner) - Leftover detection patterns
- [Stats](https://github.com/exelban/stats) - System monitoring implementation
- [CleanMyMac](https://macpaw.com/cleanmymac) - UI/UX design inspiration
