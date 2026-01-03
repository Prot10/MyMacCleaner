# MyMacCleaner - Implementation Plan

> A modern, open-source macOS system cleaner with Apple's Liquid Glass UI design

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture & Technology Stack](#architecture--technology-stack)
3. [Open Source Resources & Attribution](#open-source-resources--attribution)
4. [Permissions Strategy](#permissions-strategy)
5. [Implementation Phases](#implementation-phases)
   - [Phase 1: Project Setup](#phase-1-project-setup)
   - [Phase 2: UI Shell & Navigation](#phase-2-ui-shell--navigation)
   - [Phase 3: Home - Smart Scan](#phase-3-home---smart-scan)
   - [Phase 4: Disk Cleaner + Space Lens](#phase-4-disk-cleaner--space-lens)
   - [Phase 5: Performance](#phase-5-performance)
   - [Phase 6: Applications Manager](#phase-6-applications-manager)
   - [Phase 7: Port Management](#phase-7-port-management)
   - [Phase 8: System Health (Suggested Feature)](#phase-8-system-health-suggested-feature)
6. [Technical Implementation Details](#technical-implementation-details)
7. [Performance Guidelines](#performance-guidelines)

---

## Project Overview

### App Sections

| Section | Description |
|---------|-------------|
| **Home** | Smart scan dashboard showing quick overview of all categories |
| **Disk Cleaner** | Clean system junk, caches, logs + Space Lens visualization |
| **Performance** | Maintenance scripts, RAM cleaning, optimization |
| **Applications** | Uninstall apps properly, check for updates |
| **Port Management** | View active processes on ports, kill processes |
| **System Health** | Startup items, login agents, system stats monitoring |

### Design Philosophy

- **Liquid Glass UI**: Replicate Apple Music's macOS Tahoe design
- **Minimal Permissions**: Request only when needed, at point of use
- **Performance First**: Async scanning, lazy loading, efficient file enumeration
- **Open Source**: Community-driven, properly attributed

---

## Architecture & Technology Stack

### Core Technologies

```
Language:       Swift 5.9+
UI Framework:   SwiftUI (macOS 13.0+ / Ventura minimum for Liquid Glass)
Target:         macOS 14.0+ (Sonoma) recommended, macOS 15+ (Sequoia) for full features
Concurrency:    Swift Concurrency (async/await, TaskGroups)
```

### Project Structure

```
MyMacCleaner/
├── App/
│   ├── MyMacCleanerApp.swift          # App entry point
│   └── ContentView.swift              # Main navigation container
├── Core/
│   ├── Design/
│   │   ├── LiquidGlass.swift          # Glass effect components
│   │   ├── Theme.swift                # Colors, typography
│   │   └── Animations.swift           # Shared animations
│   ├── Services/
│   │   ├── PermissionsService.swift   # Unified permission handling
│   │   ├── FileScanner.swift          # Async file scanning engine
│   │   ├── ProcessService.swift       # Process/port management
│   │   └── ShellService.swift         # Safe shell command execution
│   ├── Models/
│   │   └── [Domain models]
│   └── Extensions/
│       └── [Swift extensions]
├── Features/
│   ├── Home/
│   ├── DiskCleaner/
│   ├── Performance/
│   ├── Applications/
│   ├── PortManagement/
│   └── SystemHealth/
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
└── Supporting/
    └── Info.plist
```

### Key Dependencies

| Dependency | Purpose | Integration |
|------------|---------|-------------|
| [Sparkle](https://github.com/sparkle-project/Sparkle) | Auto-updates | SPM |
| [FullDiskAccess](https://github.com/inket/FullDiskAccess) | FDA permission checking | SPM |

---

## Open Source Resources & Attribution

### Projects to Learn From / Adapt Code

| Project | What to Learn | License | Link |
|---------|--------------|---------|------|
| **Pearcleaner** | App uninstallation, orphan file detection, file scanning patterns | Apache 2.0 | [GitHub](https://github.com/alienator88/Pearcleaner) |
| **Clean-Me** | Junk file categories, cleanup paths | MIT | [GitHub](https://github.com/Kevin-De-Koninck/Clean-Me) |
| **Stats** | CPU/Memory/Disk monitoring, SMC access | MIT | [GitHub](https://github.com/exelban/stats) |
| **Latest** | App update detection, Sparkle integration | MIT | [GitHub](https/github.com/mangerlahn/Latest) |
| **VizDisk** | Treemap visualization | MIT | [GitHub](https://github.com/sheafdynamics/vizdisk) |
| **GrandPerspective** | Treemap algorithm | GPL | [SourceForge](https://grandperspectiv.sourceforge.net/) |
| **PermissionsKit** | macOS permissions API wrapper | MIT | [GitHub](https://github.com/MacPaw/PermissionsKit) |
| **LiquidGlassReference** | Liquid Glass SwiftUI patterns | MIT | [GitHub](https://github.com/conorluddy/LiquidGlassReference) |

### Terminal Commands to Integrate

| Feature | Command | Purpose |
|---------|---------|---------|
| Port listing | `lsof -i -P -n` | List all network connections |
| Kill process | `kill -9 <PID>` | Force terminate process |
| Memory purge | `sudo purge` | Clear inactive memory |
| Disk usage | `du -sh <path>` | Directory size |
| Homebrew apps | `brew list --cask` | List installed casks |
| Running processes | `ps aux` | Process list |
| Startup items | `launchctl list` | LaunchAgents/Daemons |

---

## Permissions Strategy

### Permission Types Needed

| Permission | When to Request | Why Needed |
|------------|-----------------|------------|
| **Full Disk Access** | When scanning system directories | Access ~/Library, caches, logs |
| **Automation** | When managing other apps | App uninstallation cleanup |
| **Accessibility** | Optional (not required initially) | Enhanced app control |

### Best Practices (from Apple Guidelines)

1. **Request at Point of Use**: Never request permissions on app launch
2. **Explain Before Asking**: Show a custom dialog explaining why before the system prompt
3. **Graceful Degradation**: App should work with limited features if permission denied
4. **Check Status First**: Use `FullDiskAccess.isGranted` before operations

### Implementation Pattern

```swift
// Always check before requesting
if FullDiskAccess.isGranted {
    performScan()
} else {
    showExplanationDialog {
        FullDiskAccess.openSystemSettings()
    }
}
```

---

## Implementation Phases

---

### Phase 1: Project Setup

**Goal**: Create a clean, properly configured Xcode project

#### Tasks

1. **Create new Xcode project**
   - macOS App template
   - SwiftUI lifecycle
   - Bundle ID: `com.yourname.MyMacCleaner`
   - Deployment target: macOS 14.0+

2. **Configure entitlements**
   ```xml
   <!-- MyMacCleaner.entitlements -->
   <key>com.apple.security.app-sandbox</key>
   <false/>  <!-- Disabled for system access -->
   <key>com.apple.security.files.user-selected.read-write</key>
   <true/>
   ```

3. **Add Swift Package Dependencies**
   - Sparkle (for updates)
   - FullDiskAccess (for permission checking)

4. **Setup folder structure** as defined above

5. **Configure Info.plist**
   ```xml
   <key>NSAppleEventsUsageDescription</key>
   <string>MyMacCleaner needs automation access to help manage applications.</string>
   ```

---

### Phase 2: UI Shell & Navigation

**Goal**: Create the full UI navigation with Liquid Glass design, all pages showing "Coming Soon"

#### Design Reference

Based on the Apple Music screenshot:
- Left sidebar with navigation items
- Main content area with large title
- Dark theme with translucent glass effects
- Rounded cards with glass material

#### Liquid Glass Implementation

```swift
// Core glass effect modifier (macOS 15+)
extension View {
    func glassCard() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }

    // For macOS 26+ (Tahoe) - native Liquid Glass
    @available(macOS 26, *)
    func liquidGlass() -> some View {
        self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}
```

#### Navigation Structure

```swift
enum NavigationSection: String, CaseIterable, Identifiable {
    case home = "Home"
    case diskCleaner = "Disk Cleaner"
    case performance = "Performance"
    case applications = "Applications"
    case portManagement = "Port Management"
    case systemHealth = "System Health"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .diskCleaner: return "internaldrive.fill"
        case .performance: return "gauge.with.needle.fill"
        case .applications: return "square.grid.2x2.fill"
        case .portManagement: return "network"
        case .systemHealth: return "heart.text.square.fill"
        }
    }
}
```

#### Sidebar Design (Apple Music Style)

```swift
struct Sidebar: View {
    @Binding var selection: NavigationSection

    var body: some View {
        List(NavigationSection.allCases, selection: $selection) { section in
            Label(section.rawValue, systemImage: section.icon)
                .tag(section)
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
    }
}
```

#### Coming Soon Placeholder

```swift
struct ComingSoonView: View {
    let title: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Coming Soon")
                .font(.largeTitle.bold())

            Text(title)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

#### Tasks

1. Create `Theme.swift` with color palette matching Apple Music dark theme
2. Create `LiquidGlass.swift` with glass effect view modifiers
3. Create `Sidebar.swift` with navigation
4. Create `ContentView.swift` with NavigationSplitView
5. Create placeholder views for each section
6. Add smooth page transitions with matched geometry

---

### Phase 3: Home - Smart Scan

**Goal**: Dashboard showing quick overview with smart scan functionality

#### Features

- **Quick Stats Cards**: Storage used, RAM usage, apps count, system health
- **Smart Scan Button**: One-click scan of all categories
- **Recent Activity**: Last cleanup results
- **Quick Actions**: Shortcuts to common tasks

#### UI Components

```swift
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero scan button
                SmartScanButton(isScanning: $viewModel.isScanning) {
                    viewModel.startSmartScan()
                }

                // Quick stats grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                    StatCard(title: "Storage", value: viewModel.storageUsed, icon: "internaldrive")
                    StatCard(title: "Memory", value: viewModel.memoryUsed, icon: "memorychip")
                    StatCard(title: "Junk Files", value: viewModel.junkSize, icon: "trash")
                    StatCard(title: "Apps", value: "\(viewModel.appCount)", icon: "app.badge")
                }

                // Scan results (when available)
                if let results = viewModel.scanResults {
                    ScanResultsCard(results: results)
                }
            }
            .padding()
        }
    }
}
```

#### Smart Scan Categories

```swift
struct SmartScanCategory {
    let name: String
    let paths: [String]
    let estimatedSize: Int64
    let isCleanable: Bool
}

// Categories to scan
let smartScanCategories = [
    "System Cache",
    "User Cache",
    "Application Logs",
    "Xcode Derived Data",
    "Browser Cache",
    "Downloads (old files)",
    "Trash"
]
```

#### Tasks

1. Create `HomeView.swift` with dashboard layout
2. Create `HomeViewModel.swift` with scanning logic
3. Create `SmartScanButton.swift` with animated scan button
4. Create `StatCard.swift` glass card component
5. Implement async scanning with progress
6. Add permission check before scanning protected directories

---

### Phase 4: Disk Cleaner + Space Lens

**Goal**: Deep cleaning functionality with visual disk space analysis

#### Features

##### Disk Cleaner
- **System Junk**: Caches, logs, temporary files
- **User Junk**: Downloads, mail attachments, old files
- **Application Junk**: App caches, crashed reports
- **Xcode Junk**: DerivedData, Archives, Simulators
- **Browser Cleanup**: Safari, Chrome, Firefox caches

##### Space Lens (Treemap Visualization)
- Interactive treemap showing disk usage
- Drill-down into folders
- Quick delete from visualization
- File type color coding

#### Junk File Categories (from Clean-Me research)

```swift
struct CleanupCategory: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let paths: [String]
    let icon: String
    let requiresFullDiskAccess: Bool
}

let cleanupCategories = [
    CleanupCategory(
        name: "System Cache",
        description: "System-level cached data",
        paths: ["/Library/Caches", "~/Library/Caches"],
        icon: "folder.badge.gearshape",
        requiresFullDiskAccess: true
    ),
    CleanupCategory(
        name: "Application Logs",
        description: "App crash reports and logs",
        paths: ["~/Library/Logs", "/Library/Logs"],
        icon: "doc.text",
        requiresFullDiskAccess: true
    ),
    CleanupCategory(
        name: "Xcode Data",
        description: "DerivedData, archives, simulators",
        paths: [
            "~/Library/Developer/Xcode/DerivedData",
            "~/Library/Developer/Xcode/Archives",
            "~/Library/Developer/CoreSimulator/Devices"
        ],
        icon: "hammer",
        requiresFullDiskAccess: false
    ),
    // ... more categories
]
```

#### Space Lens Treemap Algorithm

```swift
// Based on squarified treemap algorithm
struct TreemapItem: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
    let path: URL
    let children: [TreemapItem]?
    var rect: CGRect = .zero
}

class TreemapLayout {
    func layout(items: [TreemapItem], in rect: CGRect) -> [TreemapItem] {
        // Squarified treemap algorithm
        // Reference: https://www.win.tue.nl/~vanwijk/stm.pdf
    }
}
```

#### Efficient File Scanning

```swift
actor FileScanner {
    func scanDirectory(_ url: URL) async throws -> [ScannedItem] {
        let resourceKeys: Set<URLResourceKey> = [
            .fileSizeKey,
            .isDirectoryKey,
            .contentModificationDateKey,
            .totalFileAllocatedSizeKey
        ]

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var items: [ScannedItem] = []

        for case let fileURL as URL in enumerator {
            let resources = try fileURL.resourceValues(forKeys: resourceKeys)
            // Process file...
        }

        return items
    }
}
```

#### Tasks

1. Create `DiskCleanerView.swift` with category list
2. Create `DiskCleanerViewModel.swift` with scanning/cleaning logic
3. Create `CleanupCategoryCard.swift` component
4. Create `SpaceLensView.swift` with treemap visualization
5. Create `TreemapLayout.swift` with squarified algorithm
6. Implement safe deletion with confirmation
7. Add undo functionality for accidental deletions

---

### Phase 5: Performance

**Goal**: System optimization and maintenance tools

#### Features

- **RAM Cleaning**: Free up inactive memory
- **Maintenance Scripts**: Run periodic maintenance (pre-Sequoia)
- **DNS Cache Flush**: Clear DNS cache
- **Spotlight Reindex**: Rebuild Spotlight index
- **Disk Permissions**: Repair permissions (older macOS)

#### Maintenance Tasks

```swift
enum MaintenanceTask: CaseIterable, Identifiable {
    case freeRAM
    case flushDNS
    case rebuildSpotlight
    case rebuildLaunchServices
    case clearFontCache

    var id: Self { self }

    var name: String {
        switch self {
        case .freeRAM: return "Free Up Memory"
        case .flushDNS: return "Flush DNS Cache"
        case .rebuildSpotlight: return "Rebuild Spotlight Index"
        case .rebuildLaunchServices: return "Rebuild Launch Services"
        case .clearFontCache: return "Clear Font Cache"
        }
    }

    var command: String {
        switch self {
        case .freeRAM: return "sudo purge"
        case .flushDNS: return "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
        case .rebuildSpotlight: return "sudo mdutil -E /"
        case .rebuildLaunchServices: return "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user"
        case .clearFontCache: return "sudo atsutil databases -remove"
        }
    }

    var requiresSudo: Bool {
        switch self {
        case .freeRAM, .flushDNS, .rebuildSpotlight, .clearFontCache: return true
        case .rebuildLaunchServices: return false
        }
    }
}
```

#### RAM Monitor (from Stats research)

```swift
import Darwin

struct MemoryStats {
    let total: UInt64
    let used: UInt64
    let free: UInt64
    let active: UInt64
    let inactive: UInt64
    let wired: UInt64
    let compressed: UInt64

    static func current() -> MemoryStats {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryStats(total: 0, used: 0, free: 0, active: 0, inactive: 0, wired: 0, compressed: 0)
        }

        let pageSize = UInt64(vm_page_size)

        return MemoryStats(
            total: ProcessInfo.processInfo.physicalMemory,
            used: UInt64(stats.active_count + stats.wire_count) * pageSize,
            free: UInt64(stats.free_count) * pageSize,
            active: UInt64(stats.active_count) * pageSize,
            inactive: UInt64(stats.inactive_count) * pageSize,
            wired: UInt64(stats.wire_count) * pageSize,
            compressed: UInt64(stats.compressor_page_count) * pageSize
        )
    }
}
```

#### Tasks

1. Create `PerformanceView.swift` with task list
2. Create `PerformanceViewModel.swift` with task execution
3. Create `MemoryMonitor.swift` for RAM stats
4. Create `MaintenanceTaskCard.swift` component
5. Implement secure sudo command execution
6. Add real-time memory usage chart
7. Show warnings for destructive operations

---

### Phase 6: Applications Manager

**Goal**: Properly uninstall apps and check for updates

#### Features

##### App Uninstaller
- List all installed applications
- Detect app leftovers (preferences, caches, support files)
- Complete uninstall with all related files
- Drag-and-drop support

##### App Updater
- Detect apps with available updates
- Support Mac App Store apps
- Support Sparkle-based apps
- One-click update all

#### App Detection Paths (from Pearcleaner research)

```swift
struct AppLeftoverPaths {
    static let searchPaths = [
        "~/Library/Application Support/{bundleID}",
        "~/Library/Application Support/{appName}",
        "~/Library/Caches/{bundleID}",
        "~/Library/Caches/{appName}",
        "~/Library/Preferences/{bundleID}.plist",
        "~/Library/Preferences/com.{appName}.plist",
        "~/Library/Saved Application State/{bundleID}.savedState",
        "~/Library/Containers/{bundleID}",
        "~/Library/Group Containers/*.{bundleID}",
        "~/Library/Cookies/{bundleID}.binarycookies",
        "~/Library/WebKit/{bundleID}",
        "/Library/Application Support/{appName}",
        "/Library/Caches/{bundleID}",
        "/Library/Preferences/{bundleID}.plist",
        "/Library/LaunchAgents/*{bundleID}*.plist",
        "/Library/LaunchDaemons/*{bundleID}*.plist",
        "~/Library/LaunchAgents/*{bundleID}*.plist"
    ]
}
```

#### App Model

```swift
struct InstalledApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let version: String
    let path: URL
    let icon: NSImage?
    let size: Int64
    let lastUsed: Date?
    var leftovers: [LeftoverFile] = []
    var hasUpdate: Bool = false
}

struct LeftoverFile: Identifiable {
    let id = UUID()
    let path: URL
    let size: Int64
    let type: LeftoverType

    enum LeftoverType {
        case preferences
        case cache
        case applicationSupport
        case container
        case launchAgent
        case other
    }
}
```

#### Update Detection (from Latest research)

```swift
class AppUpdateChecker {
    // Check Mac App Store apps
    func checkMASUpdates() async -> [AppUpdate] {
        // Use CKSoftwareMap private framework or
        // parse ~/Library/Receipts/InstallHistory.plist
    }

    // Check Sparkle-based apps
    func checkSparkleUpdates(for app: InstalledApp) async -> AppUpdate? {
        // Parse app's Info.plist for SUFeedURL
        // Fetch and parse appcast.xml
    }
}
```

#### Tasks

1. Create `ApplicationsView.swift` with app grid/list
2. Create `ApplicationsViewModel.swift` with app scanning
3. Create `AppCard.swift` component with app icon
4. Create `UninstallSheet.swift` showing leftovers
5. Create `AppUpdateChecker.swift` for update detection
6. Implement Homebrew cask integration (`brew list --cask`)
7. Add search and filter functionality
8. Implement batch operations

---

### Phase 7: Port Management

**Goal**: View and manage processes using network ports

#### Features

- List all active network connections
- Show process using each port
- Filter by port number, process name, connection state
- Kill processes by port
- Copy port/process info

#### Port/Process Model

```swift
struct NetworkConnection: Identifiable {
    let id = UUID()
    let protocol: ConnectionProtocol
    let localAddress: String
    let localPort: Int
    let remoteAddress: String?
    let remotePort: Int?
    let state: ConnectionState
    let pid: Int32
    let processName: String

    enum ConnectionProtocol: String {
        case tcp = "TCP"
        case udp = "UDP"
    }

    enum ConnectionState: String {
        case listen = "LISTEN"
        case established = "ESTABLISHED"
        case timeWait = "TIME_WAIT"
        case closeWait = "CLOSE_WAIT"
        case closed = "CLOSED"
        case unknown = "UNKNOWN"
    }
}
```

#### Port Scanning Implementation

```swift
actor PortScanner {
    func getActiveConnections() async throws -> [NetworkConnection] {
        // Use lsof -i -P -n for comprehensive output
        let output = try await shell("lsof -i -P -n")
        return parseConnections(output)
    }

    private func parseConnections(_ output: String) -> [NetworkConnection] {
        // Parse lsof output format:
        // COMMAND   PID USER   FD   TYPE    DEVICE SIZE/OFF NODE NAME
        // Safari    123 user   45u  IPv4    0x...  0t0      TCP  127.0.0.1:8080 (LISTEN)
    }

    func killProcess(pid: Int32, force: Bool = false) async throws {
        let signal = force ? "-9" : "-15"
        try await shell("kill \(signal) \(pid)")
    }
}
```

#### UI Design

```swift
struct PortManagementView: View {
    @StateObject private var viewModel = PortManagementViewModel()
    @State private var searchText = ""
    @State private var filterState: ConnectionState? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar with search and filters
            HStack {
                TextField("Search port or process...", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                Picker("State", selection: $filterState) {
                    Text("All").tag(nil as ConnectionState?)
                    ForEach(ConnectionState.allCases, id: \.self) { state in
                        Text(state.rawValue).tag(state as ConnectionState?)
                    }
                }

                Button("Refresh") {
                    Task { await viewModel.refresh() }
                }
            }
            .padding()

            // Connection list
            Table(viewModel.filteredConnections) {
                TableColumn("Port") { conn in
                    Text("\(conn.localPort)")
                        .monospacedDigit()
                }
                TableColumn("Process", value: \.processName)
                TableColumn("PID") { conn in
                    Text("\(conn.pid)")
                }
                TableColumn("Protocol", value: \.protocol.rawValue)
                TableColumn("State", value: \.state.rawValue)
                TableColumn("Actions") { conn in
                    Button("Kill") {
                        viewModel.killProcess(conn)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
    }
}
```

#### Tasks

1. Create `PortManagementView.swift` with table view
2. Create `PortManagementViewModel.swift` with scanning logic
3. Create `PortScanner.swift` actor for shell commands
4. Create `ConnectionRow.swift` component
5. Implement filtering and search
6. Add kill confirmation dialog
7. Implement auto-refresh option
8. Add common ports reference (80, 443, 3000, 8080, etc.)

---

### Phase 8: System Health (Suggested Feature)

**Goal**: Monitor system health and manage startup items

#### Features

##### Startup Manager
- View all login items
- View LaunchAgents and LaunchDaemons
- Enable/disable startup items
- Identify potentially unwanted startup items

##### System Monitor
- CPU usage (real-time graph)
- Memory pressure indicator
- Disk health status
- Battery health (if laptop)

#### Startup Items Detection

```swift
struct StartupItem: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let type: StartupType
    let enabled: Bool
    let vendor: String?

    enum StartupType {
        case loginItem          // ~/Library/LaunchAgents (user-level)
        case launchAgent        // /Library/LaunchAgents (system-level)
        case launchDaemon       // /Library/LaunchDaemons (root-level)
        case appLoginItem       // System Settings > Login Items
    }
}

actor StartupItemsManager {
    func getStartupItems() async -> [StartupItem] {
        var items: [StartupItem] = []

        // User LaunchAgents
        items += scanDirectory("~/Library/LaunchAgents", type: .loginItem)

        // System LaunchAgents
        items += scanDirectory("/Library/LaunchAgents", type: .launchAgent)

        // LaunchDaemons (requires FDA)
        items += scanDirectory("/Library/LaunchDaemons", type: .launchDaemon)

        // Modern Login Items (macOS 13+)
        items += getModernLoginItems()

        return items
    }

    func toggleStartupItem(_ item: StartupItem, enabled: Bool) async throws {
        // Use launchctl to load/unload
        let action = enabled ? "load" : "unload"
        try await shell("launchctl \(action) '\(item.path.path)'")
    }
}
```

#### System Stats (from Stats research)

```swift
struct SystemStats {
    let cpuUsage: Double
    let memoryPressure: MemoryPressure
    let diskSpace: DiskSpace
    let batteryHealth: BatteryHealth?

    enum MemoryPressure {
        case normal
        case warning
        case critical
    }
}

class SystemMonitor: ObservableObject {
    @Published var stats: SystemStats
    private var timer: Timer?

    func startMonitoring(interval: TimeInterval = 2.0) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.stats = await self?.fetchStats() ?? self?.stats ?? SystemStats.empty
            }
        }
    }
}
```

#### Tasks

1. Create `SystemHealthView.swift` with dashboard
2. Create `SystemHealthViewModel.swift` with monitoring
3. Create `StartupItemsManager.swift` actor
4. Create `StartupItemRow.swift` component
5. Create `SystemStatsWidget.swift` with charts
6. Implement safe enable/disable for startup items
7. Add vendor identification for startup items
8. Create CPU/Memory usage charts with Swift Charts

---

## Technical Implementation Details

### Safe Shell Command Execution

```swift
actor ShellService {
    func execute(_ command: String, requiresSudo: Bool = false) async throws -> String {
        let task = Process()
        let pipe = Pipe()

        if requiresSudo {
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = [
                "-e",
                "do shell script \"\(command.escapedForAppleScript)\" with administrator privileges"
            ]
        } else {
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
            task.arguments = ["-c", command]
        }

        task.standardOutput = pipe
        task.standardError = pipe

        try task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
```

### Concurrent File Scanning

```swift
actor FileScanner {
    func scanDirectories(_ urls: [URL], progress: @escaping (Double) -> Void) async throws -> [ScannedItem] {
        try await withThrowingTaskGroup(of: [ScannedItem].self) { group in
            for (index, url) in urls.enumerated() {
                group.addTask {
                    let items = try await self.scanDirectory(url)
                    await MainActor.run {
                        progress(Double(index + 1) / Double(urls.count))
                    }
                    return items
                }
            }

            var allItems: [ScannedItem] = []
            for try await items in group {
                allItems.append(contentsOf: items)
            }
            return allItems
        }
    }
}
```

### Error Handling Pattern

```swift
enum MyMacCleanerError: LocalizedError {
    case permissionDenied(String)
    case fileNotFound(URL)
    case shellCommandFailed(String, Int32)
    case scanFailed(URL, Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let resource):
            return "Permission denied for \(resource). Please grant Full Disk Access."
        case .fileNotFound(let url):
            return "File not found: \(url.path)"
        case .shellCommandFailed(let command, let code):
            return "Command '\(command)' failed with code \(code)"
        case .scanFailed(let url, let error):
            return "Failed to scan \(url.path): \(error.localizedDescription)"
        }
    }
}
```

---

## Performance Guidelines

### File Operations

1. **Use URL-based APIs**: `enumerator(at:includingPropertiesForKeys:)` is faster than path-based
2. **Prefetch resource keys**: Always specify needed keys upfront
3. **Use TaskGroups**: Parallelize scanning of independent directories
4. **Batch UI updates**: Don't update UI for every file found

### Memory Management

1. **Use actors**: Prevent data races in concurrent scanning
2. **Stream results**: Don't load all files into memory at once
3. **Cancel on navigation**: Cancel ongoing scans when user leaves view
4. **Lazy loading**: Use `LazyVGrid`/`LazyVStack` for large lists

### UI Responsiveness

1. **Main actor isolation**: Keep UI updates on main thread
2. **Progress indication**: Always show progress for long operations
3. **Cancelable operations**: Allow users to cancel long scans
4. **Skeleton views**: Show placeholders while loading

### Best Practices from Research

| Practice | Source | Benefit |
|----------|--------|---------|
| Modular enable/disable | Stats | Up to 50% resource reduction |
| Actor-based services | Swift best practices | Thread safety |
| Prefetch URL keys | Apple docs | 2-3x faster scanning |
| TaskGroups for parallel scanning | MacPaw research | 2-3x faster than serial |

---

## Next Steps

After this plan is approved:

1. **Phase 1**: Set up project structure and dependencies
2. **Phase 2**: Build UI shell with navigation and glass effects
3. Continue with each phase sequentially

Each phase should be a separate PR with:
- Implementation
- Basic tests
- Documentation updates

---

## License

This project is open source under MIT License.

## Attribution

See [Open Source Resources](#open-source-resources--attribution) section for projects and code that inspired or contributed to this app.
