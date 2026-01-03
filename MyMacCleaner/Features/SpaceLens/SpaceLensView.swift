import SwiftUI

// MARK: - Space Lens View

struct SpaceLensView: View {
    @StateObject private var viewModel = SpaceLensViewModel()
    @State private var isVisible = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(Theme.Spacing.lg)

                Divider()

                if viewModel.rootNode == nil && !viewModel.isScanning {
                    // Initial state
                    startScanSection
                } else if let current = viewModel.currentNode {
                    // Treemap view
                    VStack(spacing: 0) {
                        // Breadcrumb navigation
                        breadcrumbSection
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.vertical, Theme.Spacing.sm)

                        // Treemap
                        GeometryReader { geometry in
                            TreemapView(
                                nodes: current.children,
                                totalSize: current.size,
                                size: geometry.size,
                                onSelect: { node in
                                    if node.isDirectory {
                                        viewModel.navigateTo(node)
                                    } else {
                                        viewModel.selectNode(node)
                                    }
                                },
                                onHover: { viewModel.hoverNode($0) },
                                onContextMenu: { node in
                                    viewModel.prepareDelete(node)
                                }
                            )
                        }
                        .padding(Theme.Spacing.md)
                    }

                    // Info bar
                    infoBar
                }
            }

            // Scanning overlay
            if viewModel.isScanning {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)

                ScanningOverlay(
                    progress: viewModel.scanProgress,
                    category: viewModel.currentPath
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(Theme.Animation.springSmooth, value: viewModel.isScanning)
        .alert("Delete Item?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelDelete()
            }
            Button("Move to Trash", role: .destructive) {
                viewModel.confirmDelete()
            }
        } message: {
            if let node = viewModel.nodeToDelete {
                Text("Move \"\(node.name)\" (\(node.formattedSize)) to Trash?")
            }
        }
        .navigationTitle("Space Lens")
        .onAppear {
            withAnimation(Theme.Animation.springSmooth) {
                isVisible = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Space Lens")
                    .font(Theme.Typography.largeTitle)

                Text("Visualize what's using your disk space")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.rootNode != nil {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.formattedCurrentSize)
                        .font(Theme.Typography.title)
                        .foregroundStyle(.blue)

                    Text(viewModel.currentNode?.name ?? "")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Start Scan Section

    private var startScanSection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 80, height: 80)

                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.blue.gradient)
                }
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("Visualize Disk Usage")
                    .font(Theme.Typography.title2)

                Text("See a treemap of your files and folders, sized by their disk usage")
                    .font(Theme.Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            Button(action: viewModel.scanHomeDirectory) {
                HStack(spacing: 8) {
                    Image(systemName: "house.fill")
                    Text("Scan Home Folder")
                }
                .font(Theme.Typography.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            }
            .buttonStyle(.plain)
            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)

            Spacer()
        }
        .padding(Theme.Spacing.xl)
    }

    // MARK: - Breadcrumb Section

    private var breadcrumbSection: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(Array(viewModel.breadcrumbs.enumerated()), id: \.element.id) { index, node in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Button(action: { viewModel.navigateTo(node) }) {
                    HStack(spacing: 4) {
                        Image(systemName: index == 0 ? "house.fill" : "folder.fill")
                            .font(.caption)

                        Text(node.name)
                            .font(Theme.Typography.subheadline)
                    }
                    .foregroundStyle(index == viewModel.breadcrumbs.count - 1 ? .primary : .secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if viewModel.navigationStack.count > 1 {
                Button(action: viewModel.navigateUp) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                        Text("Up")
                    }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - Info Bar

    private var infoBar: some View {
        HStack {
            if let hovered = viewModel.hoveredNode {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: hovered.icon)
                        .foregroundStyle(hovered.color)

                    Text(hovered.name)
                        .font(Theme.Typography.subheadline)
                        .lineLimit(1)

                    Text("·")
                        .foregroundStyle(.tertiary)

                    Text(hovered.formattedSize)
                        .font(Theme.Typography.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)

                    if let parent = viewModel.currentNode, parent.size > 0 {
                        Text("(\(Int(Double(hovered.size) / Double(parent.size) * 100))%)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            } else {
                Text("Hover over items to see details")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Legend
            HStack(spacing: Theme.Spacing.md) {
                legendItem(color: .blue, label: "Folders")
                legendItem(color: .purple, label: "Apps")
                legendItem(color: .pink, label: "Videos")
                legendItem(color: .green, label: "Audio")
                legendItem(color: .cyan, label: "Images")
                legendItem(color: .gray, label: "Other")
            }
        }
        .padding(Theme.Spacing.md)
        .background(.ultraThinMaterial)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Treemap View

struct TreemapView: View {
    let nodes: [FileNode]
    let totalSize: Int64
    let size: CGSize
    let onSelect: (FileNode) -> Void
    let onHover: (FileNode?) -> Void
    let onContextMenu: (FileNode) -> Void

    var body: some View {
        let rects = TreemapLayout.calculate(
            nodes: nodes,
            in: CGRect(origin: .zero, size: size),
            totalSize: totalSize
        )

        ZStack(alignment: .topLeading) {
            ForEach(Array(zip(nodes.prefix(rects.count), rects)), id: \.0.id) { node, rect in
                TreemapCell(
                    node: node,
                    rect: rect,
                    onSelect: { onSelect(node) },
                    onHover: { hovering in onHover(hovering ? node : nil) },
                    onContextMenu: { onContextMenu(node) }
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }
}

// MARK: - Treemap Cell

struct TreemapCell: View {
    let node: FileNode
    let rect: CGRect
    let onSelect: () -> Void
    let onHover: (Bool) -> Void
    let onContextMenu: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(node.color.opacity(isHovered ? 0.9 : 0.7))

                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)

                if rect.width > 60 && rect.height > 40 {
                    VStack(spacing: 2) {
                        if rect.width > 40 && rect.height > 50 {
                            Image(systemName: node.icon)
                                .font(.system(size: min(rect.width, rect.height) * 0.2))
                                .foregroundStyle(.white.opacity(0.9))
                        }

                        Text(node.name)
                            .font(.system(size: max(9, min(12, rect.width * 0.08))))
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        if rect.height > 50 {
                            Text(node.formattedSize)
                                .font(.system(size: max(8, min(10, rect.width * 0.06))))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(4)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: rect.width - 2, height: rect.height - 2)
        .position(x: rect.midX, y: rect.midY)
        .onHover { hovering in
            isHovered = hovering
            onHover(hovering)
        }
        .contextMenu {
            Button("Reveal in Finder") {
                NSWorkspace.shared.selectFile(node.url.path, inFileViewerRootedAtPath: node.url.deletingLastPathComponent().path)
            }

            Divider()

            Button("Move to Trash", role: .destructive) {
                onContextMenu()
            }
        }
    }
}

// MARK: - Treemap Layout

enum TreemapLayout {
    static func calculate(nodes: [FileNode], in rect: CGRect, totalSize: Int64) -> [CGRect] {
        guard !nodes.isEmpty, totalSize > 0 else { return [] }

        // Filter nodes with size > 0 and limit to top items for performance
        let validNodes = nodes.filter { $0.size > 0 }.prefix(50)
        guard !validNodes.isEmpty else { return [] }

        let normalizedSizes = validNodes.map { Double($0.size) / Double(totalSize) }

        return squarify(
            sizes: Array(normalizedSizes),
            in: rect
        )
    }

    private static func squarify(sizes: [Double], in rect: CGRect) -> [CGRect] {
        guard !sizes.isEmpty else { return [] }

        var rects: [CGRect] = []
        var remaining = sizes
        var currentRect = rect

        while !remaining.isEmpty {
            let isHorizontal = currentRect.width >= currentRect.height

            // Find the best row
            var row: [Double] = []
            var rowTotal: Double = 0
            var bestAspectRatio = Double.infinity

            for size in remaining {
                let testRow = row + [size]
                let testTotal = rowTotal + size

                let aspectRatio = worstAspectRatio(row: testRow, totalSize: testTotal, length: isHorizontal ? currentRect.height : currentRect.width)

                if aspectRatio <= bestAspectRatio {
                    row = testRow
                    rowTotal = testTotal
                    bestAspectRatio = aspectRatio
                } else {
                    break
                }
            }

            // Layout the row
            let rowRects = layoutRow(row: row, totalSize: rowTotal, in: currentRect, horizontal: isHorizontal)
            rects.append(contentsOf: rowRects)

            // Remove processed items and update rect
            remaining.removeFirst(row.count)

            if isHorizontal {
                let rowWidth = currentRect.width * CGFloat(rowTotal)
                currentRect = CGRect(
                    x: currentRect.minX + rowWidth,
                    y: currentRect.minY,
                    width: currentRect.width - rowWidth,
                    height: currentRect.height
                )
            } else {
                let rowHeight = currentRect.height * CGFloat(rowTotal)
                currentRect = CGRect(
                    x: currentRect.minX,
                    y: currentRect.minY + rowHeight,
                    width: currentRect.width,
                    height: currentRect.height - rowHeight
                )
            }
        }

        return rects
    }

    private static func worstAspectRatio(row: [Double], totalSize: Double, length: CGFloat) -> Double {
        guard !row.isEmpty, totalSize > 0 else { return .infinity }

        let rowLength = CGFloat(totalSize) * length
        var worst: Double = 0

        for size in row {
            let itemLength = CGFloat(size / totalSize) * rowLength
            let itemWidth = length * CGFloat(size)

            let aspectRatio = max(Double(itemLength / itemWidth), Double(itemWidth / itemLength))
            worst = max(worst, aspectRatio)
        }

        return worst
    }

    private static func layoutRow(row: [Double], totalSize: Double, in rect: CGRect, horizontal: Bool) -> [CGRect] {
        guard !row.isEmpty, totalSize > 0 else { return [] }

        var rects: [CGRect] = []
        var offset: CGFloat = 0

        let dimension = horizontal ? rect.width * CGFloat(totalSize) : rect.height * CGFloat(totalSize)

        for size in row {
            let itemSize = CGFloat(size / totalSize)

            let itemRect: CGRect
            if horizontal {
                itemRect = CGRect(
                    x: rect.minX,
                    y: rect.minY + offset * rect.height,
                    width: dimension,
                    height: itemSize * rect.height
                )
            } else {
                itemRect = CGRect(
                    x: rect.minX + offset * rect.width,
                    y: rect.minY,
                    width: itemSize * rect.width,
                    height: dimension
                )
            }

            rects.append(itemRect)
            offset += itemSize
        }

        return rects
    }
}

// MARK: - Preview

#Preview {
    SpaceLensView()
        .frame(width: 900, height: 700)
}
