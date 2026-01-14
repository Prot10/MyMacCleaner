import SwiftUI

// MARK: - Space Lens View

struct SpaceLensView: View {
    @ObservedObject var viewModel: SpaceLensViewModel
    @State private var isVisible = false

    var body: some View {
        ZStack {
            if viewModel.rootNode == nil && !viewModel.isScanning {
                startScanSection
                    .glassCard()
            } else if let currentNode = viewModel.currentNode {
                mainContent(currentNode)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .glassCard()
            }

            // Scanning overlay
            if viewModel.isScanning {
                ScanningOverlay(
                    progress: viewModel.scanProgress,
                    category: viewModel.currentPath,
                    accentColor: .blue
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(Theme.Animation.springSmooth, value: viewModel.isScanning)
        .alert(L("spaceLens.delete.title"), isPresented: $viewModel.showDeleteConfirmation) {
            Button(L("common.cancel"), role: .cancel) { viewModel.cancelDelete() }
            Button(L("spaceLens.delete.moveToTrash"), role: .destructive) { viewModel.confirmDelete() }
        } message: {
            if let node = viewModel.nodeToDelete {
                Text(LFormat("spaceLens.delete.confirm %@ %@", node.name, node.formattedSize))
            }
        }
        .onAppear {
            withAnimation(Theme.Animation.springSmooth) {
                isVisible = true
            }
        }
    }

    // MARK: - Main Content

    private func mainContent(_ currentNode: FileNode) -> some View {
        HStack(spacing: 0) {
            // Sidebar with file list
            sidebarView(currentNode)
                .frame(width: 280)

            Divider()

            // Bubble visualization
            VStack(spacing: 0) {
                // Header
                headerBar(currentNode)

                // Bubbles
                GeometryReader { geometry in
                    BubblePackingView(
                        nodes: viewModel.currentChildren,
                        parentSize: currentNode.size,
                        size: geometry.size,
                        onSelect: { node in
                            if node.isDirectory {
                                viewModel.navigateTo(node)
                            }
                        },
                        onHover: { viewModel.hoverNode($0) },
                        highlightedNodeId: viewModel.hoveredNode?.id
                    )
                }
                .padding(Theme.Spacing.md)
                .id("\(viewModel.sizeFilter.rawValue)-\(viewModel.ageFilter.rawValue)") // Force rebuild on filter change

                // Bottom bar
                bottomBar
            }
        }
    }

    // MARK: - Sidebar

    private func sidebarView(_ currentNode: FileNode) -> some View {
        VStack(spacing: 0) {
            // Current folder info
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "internaldrive.fill")
                        .font(Theme.Typography.size22)
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(currentNode.name)
                        .font(Theme.Typography.size15Semibold)
                        .lineLimit(1)

                    Text(LFormat("spaceLens.sizeItems %@ %lld", currentNode.formattedSize, currentNode.children.count))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(Color.white.opacity(0.03))

            // File list
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(currentNode.children.sorted(by: { $0.size > $1.size })) { child in
                        SidebarFileRow(
                            node: child,
                            isHovered: viewModel.hoveredNode?.id == child.id,
                            onTap: {
                                if child.isDirectory {
                                    viewModel.navigateTo(child)
                                }
                            },
                            onHover: { hovering in
                                viewModel.hoverNode(hovering ? child : nil)
                            },
                            onInfo: {
                                viewModel.revealInFinder(child)
                            }
                        )
                    }
                }
                .padding(.vertical, Theme.Spacing.sm)
            }
        }
    }

    // MARK: - Header Bar

    private func headerBar(_ currentNode: FileNode) -> some View {
        VStack(spacing: 0) {
            // Navigation row
            HStack {
                // Navigation button
                Button(action: viewModel.navigateUp) {
                    Image(systemName: "chevron.left")
                        .font(Theme.Typography.size14Semibold)
                        .foregroundStyle(viewModel.navigationStack.count > 1 ? .primary : .tertiary)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.navigationStack.count <= 1)

                Spacer()

                // Breadcrumb
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(Array(viewModel.breadcrumbs.enumerated()), id: \.element.id) { index, node in
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Button(action: { viewModel.navigateTo(node) }) {
                            HStack(spacing: 4) {
                                if index == 0 {
                                    Image(systemName: "internaldrive.fill")
                                        .font(.caption)
                                }
                                Text(node.name)
                                    .font(Theme.Typography.caption)
                            }
                            .foregroundStyle(index == viewModel.breadcrumbs.count - 1 ? .primary : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                // Rescan button
                Button(action: viewModel.scanHomeDirectory) {
                    Image(systemName: "arrow.clockwise")
                        .font(Theme.Typography.size12)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)

            // Filter row
            HStack(spacing: Theme.Spacing.md) {
                // Size filter
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(Theme.Typography.size10)
                        .foregroundStyle(.secondary)

                    Picker("", selection: $viewModel.sizeFilter) {
                        ForEach(SizeFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 90)
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 4)
                .background(viewModel.sizeFilter != .all ? Color.blue.opacity(0.15) : Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Age filter
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "clock")
                        .font(Theme.Typography.size10)
                        .foregroundStyle(.secondary)

                    Picker("", selection: $viewModel.ageFilter) {
                        ForEach(AgeFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 90)
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 4)
                .background(viewModel.ageFilter != .all ? Color.orange.opacity(0.15) : Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Clear filters button
                if viewModel.hasActiveFilters {
                    Button(action: viewModel.clearFilters) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(Theme.Typography.size10)
                            Text(L("spaceLens.filter.clear"))
                                .font(Theme.Typography.size11)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Filter stats
                if viewModel.hasActiveFilters {
                    Text(LFormat("spaceLens.filter.showing %lld %lld", Int64(viewModel.filteredCount), Int64(viewModel.totalCount)))
                        .font(Theme.Typography.size11)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Color.white.opacity(0.02))
        }
        .background(Color.white.opacity(0.03))
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            if let hovered = viewModel.hoveredNode {
                HStack(spacing: Theme.Spacing.sm) {
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

                    // Show last access date for files
                    if !hovered.isDirectory, let accessStr = hovered.formattedLastAccess {
                        Text("·")
                            .foregroundStyle(.tertiary)

                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(Theme.Typography.size10)
                            Text(accessStr)
                        }
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text(L("spaceLens.hoverHint"))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Legend
            HStack(spacing: Theme.Spacing.md) {
                legendItem(color: .blue, label: L("spaceLens.legend.folders"))
                legendItem(color: .purple, label: L("spaceLens.legend.apps"))
                legendItem(color: .pink, label: L("spaceLens.legend.videos"))
                legendItem(color: .green, label: L("spaceLens.legend.audio"))
                legendItem(color: .cyan, label: L("spaceLens.legend.images"))
                legendItem(color: .gray, label: L("spaceLens.legend.other"))
            }
        }
        .padding(Theme.Spacing.md)
        .background(Color.white.opacity(0.03))
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
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
                        .font(Theme.Typography.size32Medium)
                        .foregroundStyle(.blue.gradient)
                }
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text(L("spaceLens.title"))
                    .font(Theme.Typography.title2)

                Text(L("spaceLens.description"))
                    .font(Theme.Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            GlassActionButton(
                L("spaceLens.scanHome"),
                icon: "house.fill",
                color: .blue
            ) {
                viewModel.scanHomeDirectory()
            }

            Spacer()
        }
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - Sidebar File Row

struct SidebarFileRow: View {
    let node: FileNode
    let isHovered: Bool
    let onTap: () -> Void
    let onHover: (Bool) -> Void
    let onInfo: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Info button
            Button(action: onInfo) {
                Image(systemName: "info.circle")
                    .font(Theme.Typography.size12)
                    .foregroundStyle(isHovered ? .secondary : .tertiary)
            }
            .buttonStyle(.plain)

            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(node.color.opacity(0.15))
                    .frame(width: 30, height: 30)

                Image(systemName: node.icon)
                    .font(Theme.Typography.size13)
                    .foregroundStyle(node.color)
            }

            // Name
            Text(node.name)
                .font(Theme.Typography.size13)
                .lineLimit(1)

            Spacer()

            // Size
            Text(node.formattedSize)
                .font(Theme.Typography.size12.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background {
            if isHovered {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.08))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onHover(perform: onHover)
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Bubble Packing View using AppKit for proper hit testing

struct BubblePackingView: NSViewRepresentable {
    let nodes: [FileNode]
    let parentSize: Int64
    let size: CGSize
    let onSelect: (FileNode) -> Void
    let onHover: (FileNode?) -> Void
    let highlightedNodeId: UUID?

    func makeNSView(context: Context) -> BubbleContainerView {
        let view = BubbleContainerView()
        view.onSelect = onSelect
        view.onHover = onHover
        return view
    }

    func updateNSView(_ nsView: BubbleContainerView, context: Context) {
        nsView.onSelect = onSelect
        nsView.onHover = onHover
        nsView.highlightedNodeId = highlightedNodeId
        nsView.updateBubbles(nodes: nodes, parentSize: parentSize)
    }
}

// MARK: - AppKit Container View

class BubbleContainerView: NSView {
    var onSelect: ((FileNode) -> Void)?
    var onHover: ((FileNode?) -> Void)?
    var highlightedNodeId: UUID?

    private var bubbleViews: [UUID: SingleBubbleView] = [:]
    private var currentNodes: [FileNode] = []
    private var lastLayoutSize: CGSize = .zero
    private var isUpdating = false

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [.width, .height]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateBubbles(nodes: [FileNode], parentSize: Int64) {
        guard !isUpdating else { return }

        currentNodes = nodes

        // Update highlight state only
        for (id, view) in bubbleViews {
            view.isHighlighted = (id == highlightedNodeId)
        }

        // Rebuild if nodes changed or first time
        let nodeIds = Set(nodes.map { $0.id })
        let existingIds = Set(bubbleViews.keys)

        if nodeIds != existingIds {
            rebuildBubblesIfNeeded()
        }
    }

    private func rebuildBubblesIfNeeded() {
        guard !isUpdating else { return }
        guard bounds.width > 100, bounds.height > 100 else { return }
        guard !currentNodes.isEmpty else { return }

        isUpdating = true
        defer { isUpdating = false }

        // Remove old views
        for view in bubbleViews.values {
            view.removeFromSuperview()
        }
        bubbleViews.removeAll()

        let positions = computePositions(nodes: currentNodes, parentSize: 1, in: bounds.size)

        for (node, pos) in positions {
            let bubbleView = SingleBubbleView(
                frame: NSRect(
                    x: pos.x - pos.radius,
                    y: pos.y - pos.radius,
                    width: pos.radius * 2,
                    height: pos.radius * 2
                )
            )
            bubbleView.node = node
            bubbleView.radius = pos.radius
            bubbleView.isHighlighted = (node.id == highlightedNodeId)
            bubbleView.onSelect = { [weak self] in self?.onSelect?(node) }
            bubbleView.onHover = { [weak self] hovering in
                self?.onHover?(hovering ? node : nil)
            }
            bubbleView.translatesAutoresizingMaskIntoConstraints = true

            addSubview(bubbleView)
            bubbleViews[node.id] = bubbleView
        }

        lastLayoutSize = bounds.size
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)

        // Only rebuild if size changed significantly and not currently updating
        if !isUpdating && !currentNodes.isEmpty {
            let sizeDiff = abs(newSize.width - lastLayoutSize.width) + abs(newSize.height - lastLayoutSize.height)
            if sizeDiff > 50 {
                rebuildBubblesIfNeeded()
            }
        }
    }

    private func computePositions(nodes: [FileNode], parentSize: Int64, in size: CGSize) -> [(FileNode, BubblePosition)] {
        let sortedNodes = nodes.sorted { $0.size > $1.size }
        let topNodes = Array(sortedNodes.prefix(20))

        let centerX = size.width / 2
        let centerY = size.height / 2
        let containerRadius = min(size.width, size.height) / 2 - 40

        var result: [(FileNode, BubblePosition)] = []
        var placedBubbles: [(x: CGFloat, y: CGFloat, r: CGFloat)] = []

        let totalSize = topNodes.reduce(Int64(0)) { $0 + $1.size }
        guard totalSize > 0 else { return [] }

        let minRadius: CGFloat = 24
        let maxBubbleRadius = containerRadius * 0.42

        for (index, node) in topNodes.enumerated() {
            let sizeRatio = sqrt(Double(node.size) / Double(totalSize))
            let radius = max(minRadius, min(maxBubbleRadius, CGFloat(sizeRatio) * containerRadius * 1.4))

            var placed = false
            var finalX = centerX
            var finalY = centerY

            if index == 0 {
                placed = true
            } else {
                let padding: CGFloat = 10

                outer: for dist in stride(from: CGFloat(0), to: containerRadius, by: 8) {
                    let angleCount = max(16, Int(dist / 6))
                    for a in 0..<angleCount {
                        let angle = CGFloat(a) * (2 * .pi / CGFloat(angleCount))
                        let testX = centerX + cos(angle) * dist
                        let testY = centerY + sin(angle) * dist

                        let distFromCenter = hypot(testX - centerX, testY - centerY)
                        if distFromCenter + radius > containerRadius {
                            continue
                        }

                        var overlaps = false
                        for other in placedBubbles {
                            let d = hypot(testX - other.x, testY - other.y)
                            if d < radius + other.r + padding {
                                overlaps = true
                                break
                            }
                        }

                        if !overlaps {
                            finalX = testX
                            finalY = testY
                            placed = true
                            break outer
                        }
                    }
                }
            }

            if placed {
                result.append((node, BubblePosition(x: finalX, y: finalY, radius: radius)))
                placedBubbles.append((x: finalX, y: finalY, r: radius))
            }
        }

        return result
    }
}

struct BubblePosition {
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
}

// MARK: - Single Bubble NSView

class SingleBubbleView: NSView {
    var node: FileNode?
    var radius: CGFloat = 0
    var isHighlighted: Bool = false { didSet { needsDisplay = true } }
    var onSelect: (() -> Void)?
    var onHover: ((Bool) -> Void)?

    private var isHovered: Bool = false { didSet { needsDisplay = true } }
    private var trackingArea: NSTrackingArea?

    private var isActive: Bool { isHovered || isHighlighted }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInActiveApp],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        onHover?(true)
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        onHover?(false)
    }

    override func mouseDown(with event: NSEvent) {
        // Highlight on press
    }

    override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        if bounds.contains(location) {
            onSelect?()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext, let node = node else { return }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let r = radius

        // Outer glow
        ctx.saveGState()
        let glowColor = node.color.cgColor?.copy(alpha: isActive ? 0.5 : 0.15) ?? CGColor(gray: 0.5, alpha: 0.15)
        ctx.setShadow(offset: .zero, blur: isActive ? 20 : 10, color: glowColor)
        ctx.setFillColor(glowColor)
        ctx.fillEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        ctx.restoreGState()

        // Main bubble gradient
        let colors: [CGColor] = [
            node.color.cgColor?.copy(alpha: isActive ? 0.95 : 0.6) ?? CGColor(gray: 0.5, alpha: 0.6),
            node.color.cgColor?.copy(alpha: isActive ? 0.7 : 0.35) ?? CGColor(gray: 0.5, alpha: 0.35)
        ]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!

        ctx.saveGState()
        ctx.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        ctx.clip()
        ctx.drawRadialGradient(gradient, startCenter: CGPoint(x: center.x - r * 0.3, y: center.y - r * 0.3), startRadius: 0, endCenter: center, endRadius: r, options: [])
        ctx.restoreGState()

        // Shine
        ctx.saveGState()
        let shineColors: [CGColor] = [
            CGColor(gray: 1, alpha: isActive ? 0.5 : 0.25),
            CGColor(gray: 1, alpha: 0)
        ]
        let shineGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: shineColors as CFArray, locations: [0, 1])!
        ctx.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        ctx.clip()
        ctx.drawLinearGradient(shineGradient, start: CGPoint(x: center.x - r, y: center.y - r), end: center, options: [])
        ctx.restoreGState()

        // Border
        ctx.saveGState()
        ctx.setLineWidth(isActive ? 3 : 2)
        let borderColor = CGColor(gray: 1, alpha: isActive ? 0.9 : 0.5)
        ctx.setStrokeColor(borderColor)
        ctx.strokeEllipse(in: CGRect(x: center.x - r + 1, y: center.y - r + 1, width: r * 2 - 2, height: r * 2 - 2))
        ctx.restoreGState()

        // Draw text content
        drawContent(in: ctx, center: center, radius: r)
    }

    private func drawContent(in ctx: CGContext, center: CGPoint, radius: CGFloat) {
        guard let node = node else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byTruncatingTail

        // Icon background
        if radius > 32 {
            let iconSize = min(radius * 0.45, 40)
            let iconRect = CGRect(
                x: center.x - iconSize / 2,
                y: center.y - iconSize / 2 - radius * 0.15,
                width: iconSize,
                height: iconSize
            )

            ctx.saveGState()
            ctx.setFillColor(CGColor(gray: 1, alpha: isActive ? 0.4 : 0.25))
            let path = NSBezierPath(roundedRect: iconRect, xRadius: 6, yRadius: 6)
            ctx.addPath(path.cgPath)
            ctx.fillPath()
            ctx.restoreGState()

            // Draw SF Symbol
            let config = NSImage.SymbolConfiguration(pointSize: min(radius * 0.2, 18), weight: .semibold)
            if let image = NSImage(systemSymbolName: node.icon, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
                let imageRect = CGRect(
                    x: center.x - image.size.width / 2,
                    y: center.y - image.size.height / 2 - radius * 0.15,
                    width: image.size.width,
                    height: image.size.height
                )
                image.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1.0)
            }
        }

        // Name
        if radius > 25 {
            let fontSize = min(radius * 0.12, 11)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraphStyle
            ]
            let nameStr = node.name as NSString
            let nameSize = nameStr.size(withAttributes: attrs)
            let nameRect = CGRect(
                x: center.x - min(nameSize.width, radius * 1.4) / 2,
                y: center.y + (radius > 32 ? radius * 0.2 : 0) - nameSize.height / 2,
                width: min(nameSize.width, radius * 1.4),
                height: nameSize.height
            )
            nameStr.draw(in: nameRect, withAttributes: attrs)
        }

        // Size
        if radius > 38 {
            let fontSize = min(radius * 0.09, 9)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: NSColor.white.withAlphaComponent(0.9),
                .paragraphStyle: paragraphStyle
            ]
            let sizeStr = node.formattedSize as NSString
            let sizeSize = sizeStr.size(withAttributes: attrs)
            let sizeRect = CGRect(
                x: center.x - sizeSize.width / 2,
                y: center.y + radius * 0.35,
                width: sizeSize.width,
                height: sizeSize.height
            )
            sizeStr.draw(in: sizeRect, withAttributes: attrs)
        }
    }
}

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0..<elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo: path.move(to: points[0])
            case .lineTo: path.addLine(to: points[0])
            case .curveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath: path.closeSubpath()
            case .cubicCurveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo: path.addQuadCurve(to: points[1], control: points[0])
            @unknown default: break
            }
        }
        return path
    }
}

// MARK: - Preview

#Preview {
    SpaceLensView(viewModel: SpaceLensViewModel())
        .frame(width: 1000, height: 700)
}
