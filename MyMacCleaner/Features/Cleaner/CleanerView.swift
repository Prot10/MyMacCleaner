import SwiftUI

struct CleanerView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = CleanerViewModel()

    var body: some View {
        content
            .onAppear {
                // Load preloaded data if available
                let preloadedData = appState.loadingState.cleaner.data
                viewModel.loadData(from: preloadedData)
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            // Header with glass effect
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("System Cleaner")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Select categories to clean up disk space")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if viewModel.isScanning {
                        HStack(spacing: 10) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Scanning...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                    } else {
                        Button {
                            Task { await viewModel.scan() }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                Text("Scan")
                            }
                            .font(.system(size: 14, weight: .semibold))
                        }
                        .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }

            // Category List
            if viewModel.categories.isEmpty && !viewModel.isScanning {
                // Empty state with glass effect
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 100, height: 100)

                        Image(systemName: "sparkles")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cleanBlue, .cleanPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 8) {
                        Text("No Items Found")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Click Scan to find cleanable files on your Mac")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach($viewModel.categories) { $category in
                            GlassCleanerCategoryRow(category: $category)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }

            // Footer with total and clean button
            if viewModel.totalSelectedSize > 0 {
                VStack(spacing: 0) {
                    Divider()

                    HStack(spacing: 20) {
                        // Selected size indicator
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected for cleanup")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)

                            Text(ByteCountFormatter.string(fromByteCount: viewModel.totalSelectedSize, countStyle: .file))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        // Clean button
                        Button {
                            Task { await viewModel.clean() }
                        } label: {
                            HStack(spacing: 10) {
                                if viewModel.isCleaning {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "trash.fill")
                                }
                                Text(viewModel.isCleaning ? "Cleaning..." : "Clean Selected")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
                        .disabled(viewModel.isCleaning)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(.ultraThinMaterial)
                }
            }
        }
    }
}

// MARK: - Glass Category Row

struct GlassCleanerCategoryRow: View {
    @Binding var category: CleanerCategory
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 16) {
            // Checkbox with animation
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    category.isSelected.toggle()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(category.isSelected ? category.color : Color.clear)
                        .frame(width: 24, height: 24)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(category.isSelected ? category.color : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if category.isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // Icon with glass background
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(category.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: category.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(category.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)

                Text("\(category.itemCount) items")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Size
            Text(category.formattedSize)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(category.isSelected ? category.color : .secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(isHovering ? 0.08 : 0.04), radius: isHovering ? 8 : 4, x: 0, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    category.isSelected
                        ? category.color.opacity(0.4)
                        : Color.white.opacity(isHovering ? 0.2 : 0.1),
                    lineWidth: 1
                )
        }
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    CleanerView()
        .environment(AppState())
        .frame(width: 650, height: 550)
}
