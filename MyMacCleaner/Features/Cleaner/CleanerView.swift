import SwiftUI

struct CleanerView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = CleanerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Cleaner")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Select categories to clean")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.isScanning {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button("Scan") {
                        Task { await viewModel.scan() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()

            Divider()

            // Category List
            if viewModel.categories.isEmpty && !viewModel.isScanning {
                ContentUnavailableView(
                    "No Items Found",
                    systemImage: "sparkles",
                    description: Text("Click Scan to find cleanable items")
                )
            } else {
                List {
                    ForEach($viewModel.categories) { $category in
                        CleanerCategoryRow(category: $category)
                    }
                }
                .listStyle(.inset)
            }

            // Footer with total and clean button
            if viewModel.totalSelectedSize > 0 {
                Divider()

                HStack {
                    VStack(alignment: .leading) {
                        Text("Selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(ByteCountFormatter.string(fromByteCount: viewModel.totalSelectedSize, countStyle: .file))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    Button("Clean Selected") {
                        Task { await viewModel.clean() }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.isCleaning)
                }
                .padding()
            }
        }
    }
}

// MARK: - Category Row

struct CleanerCategoryRow: View {
    @Binding var category: CleanerCategory

    var body: some View {
        HStack(spacing: 12) {
            Toggle(isOn: $category.isSelected) {
                EmptyView()
            }
            .toggleStyle(.checkbox)

            Image(systemName: category.icon)
                .font(.title3)
                .foregroundStyle(category.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.body)

                Text("\(category.itemCount) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(category.formattedSize)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CleanerView()
        .environment(AppState())
        .frame(width: 600, height: 500)
}
