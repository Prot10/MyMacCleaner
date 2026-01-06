import SwiftUI

// MARK: - Space Lens View Model

@MainActor
class SpaceLensViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var currentPath: String = ""

    @Published var rootNode: FileNode?
    @Published var currentNode: FileNode?
    @Published var navigationStack: [FileNode] = []

    @Published var selectedNode: FileNode?
    @Published var hoveredNode: FileNode?

    @Published var showDeleteConfirmation = false
    @Published var nodeToDelete: FileNode?

    @Published var errorMessage: String?

    // MARK: - Computed Properties

    var breadcrumbs: [FileNode] {
        navigationStack
    }

    var currentChildren: [FileNode] {
        currentNode?.children ?? []
    }

    var formattedCurrentSize: String {
        guard let node = currentNode else { return "0 bytes" }
        return ByteCountFormatter.string(fromByteCount: node.size, countStyle: .file)
    }

    // MARK: - Public Methods

    func scanDirectory(_ url: URL) {
        isScanning = true
        scanProgress = 0
        errorMessage = nil

        Task {
            do {
                let node = try await buildFileTree(url: url) { [weak self] progress, path in
                    self?.scanProgress = progress
                    self?.currentPath = path
                }

                rootNode = node
                currentNode = node
                navigationStack = [node]

            } catch {
                errorMessage = "Scan failed: \(error.localizedDescription)"
            }

            isScanning = false
            currentPath = ""
        }
    }

    func scanHomeDirectory() {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        scanDirectory(homeURL)
    }

    func navigateTo(_ node: FileNode) {
        guard node.isDirectory else { return }

        withAnimation(Theme.Animation.spring) {
            currentNode = node
            if let index = navigationStack.firstIndex(where: { $0.id == node.id }) {
                navigationStack = Array(navigationStack.prefix(through: index))
            } else {
                navigationStack.append(node)
            }
        }
    }

    func navigateUp() {
        guard navigationStack.count > 1 else { return }

        withAnimation(Theme.Animation.spring) {
            navigationStack.removeLast()
            currentNode = navigationStack.last
        }
    }

    func selectNode(_ node: FileNode) {
        selectedNode = node
    }

    func hoverNode(_ node: FileNode?) {
        hoveredNode = node
    }

    func prepareDelete(_ node: FileNode) {
        nodeToDelete = node
        showDeleteConfirmation = true
    }

    func confirmDelete() {
        guard let node = nodeToDelete else { return }

        Task {
            do {
                try FileManager.default.trashItem(at: node.url, resultingItemURL: nil)

                // Remove from parent
                if let parent = currentNode,
                   let index = parent.children.firstIndex(where: { $0.id == node.id }) {
                    currentNode?.children.remove(at: index)
                    currentNode?.size -= node.size
                }

                // Propagate size change up
                for i in navigationStack.indices.reversed() {
                    navigationStack[i].size -= node.size
                }

            } catch {
                errorMessage = "Failed to delete: \(error.localizedDescription)"
            }

            nodeToDelete = nil
            showDeleteConfirmation = false
        }
    }

    func cancelDelete() {
        nodeToDelete = nil
        showDeleteConfirmation = false
    }

    func revealInFinder(_ node: FileNode) {
        NSWorkspace.shared.selectFile(node.url.path, inFileViewerRootedAtPath: node.url.deletingLastPathComponent().path)
    }

    // MARK: - Private Methods

    private func buildFileTree(
        url: URL,
        progress: @escaping (Double, String) -> Void
    ) async throws -> FileNode {
        let resourceKeys: Set<URLResourceKey> = [
            .fileSizeKey,
            .totalFileAllocatedSizeKey,
            .isDirectoryKey,
            .nameKey
        ]

        var node = FileNode(
            name: url.lastPathComponent,
            url: url,
            size: 0,
            isDirectory: true,
            children: []
        )

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return node
        }

        // Phase 1: Enumerate files (0-85%)
        var fileCount = 0
        var directoryContents: [URL: [FileNode]] = [:]
        let maxFilesForProgress = 50000 // Assume max ~50k files for smooth progress

        while let fileURL = enumerator.nextObject() as? URL {
            fileCount += 1

            if fileCount % 200 == 0 {
                let scanProgress = min(0.85, Double(fileCount) / Double(maxFilesForProgress) * 0.85)
                await MainActor.run {
                    progress(scanProgress, fileURL.lastPathComponent)
                }
            }

            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys) else {
                continue
            }

            let isDirectory = resourceValues.isDirectory ?? false
            let size = Int64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileSize ?? 0)

            let childNode = FileNode(
                name: resourceValues.name ?? fileURL.lastPathComponent,
                url: fileURL,
                size: size,
                isDirectory: isDirectory,
                children: []
            )

            let parentURL = fileURL.deletingLastPathComponent()
            if directoryContents[parentURL] == nil {
                directoryContents[parentURL] = []
            }
            directoryContents[parentURL]?.append(childNode)
        }

        // Phase 2: Building tree structure (85-100%)
        await MainActor.run {
            progress(0.90, "Building folder structure...")
        }

        node = buildTreeFromContents(root: url, contents: directoryContents)

        await MainActor.run {
            progress(1.0, "Complete")
        }

        return node
    }

    private func buildTreeFromContents(root: URL, contents: [URL: [FileNode]]) -> FileNode {
        func buildNode(url: URL) -> FileNode {
            let children = contents[url] ?? []
            var builtChildren: [FileNode] = []
            var totalSize: Int64 = 0

            for child in children {
                if child.isDirectory {
                    let builtChild = buildNode(url: child.url)
                    builtChildren.append(builtChild)
                    totalSize += builtChild.size
                } else {
                    builtChildren.append(child)
                    totalSize += child.size
                }
            }

            // Sort by size descending
            builtChildren.sort { $0.size > $1.size }

            return FileNode(
                name: url.lastPathComponent,
                url: url,
                size: totalSize,
                isDirectory: true,
                children: builtChildren
            )
        }

        return buildNode(url: root)
    }
}

// MARK: - File Node

class FileNode: Identifiable, ObservableObject {
    let id = UUID()
    let name: String
    let url: URL
    @Published var size: Int64
    let isDirectory: Bool
    @Published var children: [FileNode]

    init(name: String, url: URL, size: Int64, isDirectory: Bool, children: [FileNode]) {
        self.name = name
        self.url = url
        self.size = size
        self.isDirectory = isDirectory
        self.children = children
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var fileExtension: String {
        url.pathExtension.lowercased()
    }

    var color: Color {
        if isDirectory {
            return .blue
        }

        switch fileExtension {
        case "app": return .purple
        case "dmg", "pkg", "zip", "gz", "tar": return .orange
        case "mp4", "mov", "avi", "mkv": return .pink
        case "mp3", "wav", "aac", "m4a": return .green
        case "jpg", "jpeg", "png", "gif", "heic": return .cyan
        case "pdf": return .red
        case "doc", "docx", "txt", "rtf": return .blue
        case "xls", "xlsx", "csv": return .green
        case "ppt", "pptx": return .orange
        default: return .gray
        }
    }

    var icon: String {
        if isDirectory {
            return "folder.fill"
        }

        switch fileExtension {
        case "app": return "app"
        case "dmg": return "externaldrive"
        case "pkg": return "shippingbox"
        case "zip", "gz", "tar": return "doc.zipper"
        case "mp4", "mov", "avi", "mkv": return "film"
        case "mp3", "wav", "aac", "m4a": return "music.note"
        case "jpg", "jpeg", "png", "gif", "heic": return "photo"
        case "pdf": return "doc.richtext"
        case "doc", "docx", "txt", "rtf": return "doc.text"
        case "xls", "xlsx", "csv": return "tablecells"
        case "ppt", "pptx": return "play.rectangle"
        default: return "doc"
        }
    }
}
