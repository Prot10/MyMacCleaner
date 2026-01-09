import AppKit
import SwiftUI

// MARK: - Menu Bar Controller

/// Controls the menu bar status item and popover
class MenuBarController: NSObject, ObservableObject {
    static let shared = MenuBarController()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?

    @Published var isVisible = false
    @Published var displayMode: DisplayMode = .cpuAndRam

    private let statsProvider = SystemStatsProvider.shared

    enum DisplayMode: String, CaseIterable {
        case cpuOnly = "CPU"
        case ramOnly = "RAM"
        case cpuAndRam = "CPU & RAM"
        case compact = "Compact"

        var localizedName: String {
            switch self {
            case .cpuOnly: return L("menuBar.displayMode.cpuOnly")
            case .ramOnly: return L("menuBar.displayMode.ramOnly")
            case .cpuAndRam: return L("menuBar.displayMode.cpuAndRam")
            case .compact: return L("menuBar.displayMode.compact")
            }
        }
    }

    override private init() {
        super.init()
    }

    // MARK: - Setup

    func setup() {
        guard statusItem == nil else { return }

        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.action = #selector(togglePopover)
            button.target = self
            updateButtonTitle()
        }

        // Create popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 280, height: 480)
        popover?.behavior = .transient
        popover?.animates = true

        // Set popover content
        let menuBarView = MenuBarView()
        popover?.contentViewController = NSHostingController(rootView: menuBarView)

        // Start monitoring
        statsProvider.startMonitoring(interval: 2.0)

        // Observe stats changes
        Task { @MainActor in
            for await _ in statsProvider.$stats.values {
                self.updateButtonTitle()
            }
        }

        isVisible = true

        // Event monitor to close popover when clicking outside
        setupEventMonitor()
    }

    func teardown() {
        statsProvider.stopMonitoring()

        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
        popover = nil

        removeEventMonitor()
        isVisible = false
    }

    // MARK: - Display Update

    private func updateButtonTitle() {
        guard let button = statusItem?.button else { return }

        let stats = statsProvider.stats

        switch displayMode {
        case .cpuOnly:
            button.title = "CPU \(Int(stats.cpuUsage))%"

        case .ramOnly:
            button.title = "RAM \(stats.formattedMemory)"

        case .cpuAndRam:
            button.title = "CPU \(Int(stats.cpuUsage))% | RAM \(stats.formattedMemory)"

        case .compact:
            // Use symbols for compact mode
            let cpuIcon = stats.cpuUsage > 80 ? "🔴" : (stats.cpuUsage > 50 ? "🟡" : "🟢")
            let memIcon = stats.memoryUsagePercent > 80 ? "🔴" : (stats.memoryUsagePercent > 50 ? "🟡" : "🟢")
            button.title = "\(cpuIcon)\(Int(stats.cpuUsage))% \(memIcon)\(Int(stats.memoryUsagePercent))%"
        }
    }

    func setDisplayMode(_ mode: DisplayMode) {
        displayMode = mode
        updateButtonTitle()
        UserDefaults.standard.set(mode.rawValue, forKey: "menuBarDisplayMode")
    }

    func loadSavedDisplayMode() {
        if let savedMode = UserDefaults.standard.string(forKey: "menuBarDisplayMode"),
           let mode = DisplayMode(rawValue: savedMode) {
            displayMode = mode
        }
    }

    // MARK: - Popover

    @objc private func togglePopover() {
        if let popover = popover {
            if popover.isShown {
                closePopover()
            } else {
                showPopover()
            }
        }
    }

    private func showPopover() {
        if let button = statusItem?.button {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
    }

    // MARK: - Event Monitor

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.popover?.isShown == true {
                self?.closePopover()
            }
        }
    }

    private func removeEventMonitor() {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        eventMonitor = nil
    }
}
