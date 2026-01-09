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
        case icon = "Icon"

        var localizedName: String {
            switch self {
            case .cpuOnly: return L("menuBar.displayMode.cpuOnly")
            case .ramOnly: return L("menuBar.displayMode.ramOnly")
            case .cpuAndRam: return L("menuBar.displayMode.cpuAndRam")
            case .icon: return L("menuBar.displayMode.icon")
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
            button.imagePosition = .imageLeft
            updateButtonDisplay()
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
                self.updateButtonDisplay()
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

    private func updateButtonDisplay() {
        guard let button = statusItem?.button else { return }

        let stats = statsProvider.stats

        // Reset button state
        button.image = nil
        button.title = ""

        switch displayMode {
        case .cpuOnly:
            // CPU icon + percentage
            let image = NSImage(systemSymbolName: "cpu", accessibilityDescription: "CPU")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageLeft
            button.title = " \(Int(stats.cpuUsage))%"
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

        case .ramOnly:
            // Memory icon + percentage
            let image = NSImage(systemSymbolName: "memorychip", accessibilityDescription: "Memory")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageLeft
            button.title = " \(Int(stats.memoryUsagePercent))%"
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

        case .cpuAndRam:
            // Both icons with percentages using attributed string
            let attachment1 = NSTextAttachment()
            attachment1.image = createTemplateImage(systemName: "cpu")

            let attachment2 = NSTextAttachment()
            attachment2.image = createTemplateImage(systemName: "memorychip")

            let attributedString = NSMutableAttributedString()

            // CPU icon
            attributedString.append(NSAttributedString(attachment: attachment1))
            // CPU percentage
            attributedString.append(NSAttributedString(string: " \(Int(stats.cpuUsage))%  "))
            // Memory icon
            attributedString.append(NSAttributedString(attachment: attachment2))
            // Memory percentage
            attributedString.append(NSAttributedString(string: " \(Int(stats.memoryUsagePercent))%"))

            // Apply monospaced digit font
            let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            attributedString.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedString.length))

            button.attributedTitle = attributedString
            button.image = nil

        case .icon:
            // Just the app icon from Assets (colored, not template)
            if let image = NSImage(named: "MenuBarIcon") {
                image.isTemplate = false  // Keep original colors
                image.size = NSSize(width: 18, height: 18)  // Proper menu bar size
                button.image = image
            } else {
                // Fallback to SF Symbol if custom icon not found
                let image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "MyMacCleaner")
                image?.isTemplate = true
                button.image = image
            }
            button.imagePosition = .imageOnly
            button.title = ""
        }
    }

    /// Creates a template image from SF Symbol for use in attributed strings
    private func createTemplateImage(systemName: String) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: NSFont.systemFontSize, weight: .regular)
        let image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)?
            .withSymbolConfiguration(config)
        // Note: Template mode is handled by the system for menu bar items
        return image
    }

    func setDisplayMode(_ mode: DisplayMode) {
        displayMode = mode
        updateButtonDisplay()
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
