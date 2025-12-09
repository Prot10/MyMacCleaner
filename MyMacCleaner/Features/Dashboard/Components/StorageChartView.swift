import SwiftUI
import Charts

/// Card showing storage breakdown by category
struct StorageBreakdownCard: View {
    let categories: [DiskCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Storage Breakdown")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                // Pie Chart
                Chart(categories) { category in
                    SectorMark(
                        angle: .value("Size", category.sizeBytes),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .cornerRadius(4)
                    .foregroundStyle(colorForCategory(category.colorName))
                }
                .frame(width: 140, height: 140)

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(categories.prefix(5)) { category in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colorForCategory(category.colorName))
                                .frame(width: 10, height: 10)

                            Text(category.name)
                                .font(.system(size: 12))
                                .foregroundStyle(.primary)

                            Spacer()

                            Text(category.formattedSize)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }

    private func colorForCategory(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "orange": return .orange
        case "green": return .green
        case "purple": return .purple
        case "red": return .red
        case "gray": return .gray
        default: return .gray
        }
    }
}

#Preview {
    StorageBreakdownCard(categories: [
        DiskCategory(name: "Applications", sizeBytes: 45_000_000_000, colorName: "blue"),
        DiskCategory(name: "Documents", sizeBytes: 32_000_000_000, colorName: "orange"),
        DiskCategory(name: "Downloads", sizeBytes: 18_000_000_000, colorName: "green"),
        DiskCategory(name: "Library", sizeBytes: 25_000_000_000, colorName: "purple"),
        DiskCategory(name: "System", sizeBytes: 15_000_000_000, colorName: "gray"),
    ])
    .padding()
    .frame(width: 450)
    .background(Color(nsColor: .windowBackgroundColor))
}
