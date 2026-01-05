import SwiftUI

// MARK: - Startup Items View Model

@MainActor
class StartupItemsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var items: [StartupItem] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedType: StartupItemType? = nil
    @Published var showSystemItems = false
    @Published var sortOrder: SortOrder = .name

    // Confirmation dialogs
    @Published var showRemoveConfirmation = false
    @Published var itemToRemove: StartupItem?
    @Published var showDisableConfirmation = false
    @Published var itemToToggle: StartupItem?

    // Toast
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success

    enum ToastType {
        case success, error, info
    }

    enum SortOrder: String, CaseIterable {
        case name
        case type
        case status

        var icon: String {
            switch self {
            case .name: return "textformat"
            case .type: return "folder"
            case .status: return "circle.lefthalf.filled"
            }
        }

        var localizedName: String {
            L(key: "startupItems.sortOrder.\(rawValue)")
        }
    }

    // MARK: - Computed Properties

    var filteredItems: [StartupItem] {
        var result = items

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.label.localizedCaseInsensitiveContains(searchText) ||
                ($0.developer?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Filter by type
        if let type = selectedType {
            result = result.filter { $0.type == type }
        }

        // Filter system items
        if !showSystemItems {
            result = result.filter { !$0.isSystemItem }
        }

        // Sort
        switch sortOrder {
        case .name:
            result.sort { $0.displayName.lowercased() < $1.displayName.lowercased() }
        case .type:
            result.sort { ($0.type.rawValue, $0.displayName.lowercased()) < ($1.type.rawValue, $1.displayName.lowercased()) }
        case .status:
            result.sort { ($0.isEnabled ? 0 : 1, $0.displayName.lowercased()) < ($1.isEnabled ? 0 : 1, $1.displayName.lowercased()) }
        }

        return result
    }

    var enabledCount: Int {
        items.filter { $0.isEnabled && !$0.isSystemItem }.count
    }

    var disabledCount: Int {
        items.filter { !$0.isEnabled && !$0.isSystemItem }.count
    }

    var runningCount: Int {
        items.filter { $0.isRunning }.count
    }

    var itemsByType: [StartupItemType: [StartupItem]] {
        Dictionary(grouping: filteredItems, by: { $0.type })
    }

    // MARK: - Private Properties

    private let service = StartupItemsService.shared

    // MARK: - Initialization

    init() {
        // Don't auto-scan, wait for user to trigger
    }

    // MARK: - Public Methods

    func scanItems() {
        guard !isLoading else { return }

        isLoading = true

        Task {
            let scannedItems = await service.scanAllItems()
            items = scannedItems
            isLoading = false

            if scannedItems.isEmpty {
                showToastMessage(L("startupItems.toast.noItemsFound"), type: .info)
            }
        }
    }

    func refreshItems() {
        scanItems()
    }

    func prepareToggle(_ item: StartupItem) {
        // System items cannot be toggled
        if item.isSystemItem {
            showToastMessage(L("startupItems.toast.systemCannotModify"), type: .info)
            return
        }

        itemToToggle = item
        showDisableConfirmation = true
    }

    func confirmToggle() {
        guard let item = itemToToggle else { return }

        Task {
            let newState = !item.isEnabled

            // For BTM login items, we open System Settings
            if item.id.hasPrefix("btm:") && item.type == .loginItem {
                _ = await service.setItemEnabled(item, enabled: newState)
                showToastMessage(LFormat("startupItems.toast.openSystemSettings %@", item.displayName), type: .info)
                showDisableConfirmation = false
                itemToToggle = nil
                return
            }

            let success = await service.setItemEnabled(item, enabled: newState)

            if success {
                // Update the item in our list
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    items[index] = StartupItem(
                        id: item.id,
                        name: item.name,
                        label: item.label,
                        type: item.type,
                        path: item.path,
                        executablePath: item.executablePath,
                        isEnabled: newState,
                        isRunning: newState ? item.isRunning : false,
                        isSystemItem: item.isSystemItem,
                        developer: item.developer,
                        bundleIdentifier: item.bundleIdentifier
                    )
                }

                if newState {
                    showToastMessage(L("startupItems.toast.enabled \(item.displayName)"), type: .success)
                } else {
                    showToastMessage(L("startupItems.toast.disabled \(item.displayName)"), type: .success)
                }
            } else {
                showToastMessage(L("startupItems.toast.modifyFailed \(item.displayName)"), type: .error)
            }

            showDisableConfirmation = false
            itemToToggle = nil
        }
    }

    func cancelToggle() {
        showDisableConfirmation = false
        itemToToggle = nil
    }

    func prepareRemove(_ item: StartupItem) {
        // System items cannot be removed
        if item.isSystemItem {
            showToastMessage(L("startupItems.toast.systemCannotRemove"), type: .info)
            return
        }

        itemToRemove = item
        showRemoveConfirmation = true
    }

    func confirmRemove() {
        guard let item = itemToRemove else { return }

        Task {
            let success = await service.removeItem(item)

            if success {
                items.removeAll { $0.id == item.id }
                showToastMessage(L("startupItems.toast.removed \(item.displayName)"), type: .success)
            } else {
                showToastMessage(L("startupItems.toast.removeFailed \(item.displayName)"), type: .error)
            }

            showRemoveConfirmation = false
            itemToRemove = nil
        }
    }

    func cancelRemove() {
        showRemoveConfirmation = false
        itemToRemove = nil
    }

    func revealInFinder(_ item: StartupItem) {
        Task {
            await service.revealInFinder(item)
        }
    }

    func showToastMessage(_ message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        showToast = true

        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showToast = false
        }
    }

    func dismissToast() {
        showToast = false
    }
}
