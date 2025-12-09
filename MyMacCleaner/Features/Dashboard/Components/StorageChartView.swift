import SwiftUI
import Charts

/// Card showing storage breakdown by category
struct StorageBreakdownCard: View {
    let categories: [DiskCategory]
    @State private var showFDASheet = false

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
                        angle: .value("Size", max(category.sizeBytes, category.needsPermission ? 1_000_000_000 : 0)), // Show placeholder size for FDA categories
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .cornerRadius(4)
                    .foregroundStyle(category.needsPermission ? Color.gray.opacity(0.3) : colorForCategory(category.colorName))
                }
                .frame(width: 140, height: 140)

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(categories.prefix(5)) { category in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(category.needsPermission ? Color.gray.opacity(0.3) : colorForCategory(category.colorName))
                                .frame(width: 10, height: 10)

                            Text(category.name)
                                .font(.system(size: 12))
                                .foregroundStyle(category.needsPermission ? .secondary : .primary)

                            Spacer()

                            if category.needsPermission {
                                Button {
                                    showFDASheet = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 9))
                                        Text("Grant Access")
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.orange.opacity(0.15), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text(category.formattedSize)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
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
        .sheet(isPresented: $showFDASheet) {
            FDAPermissionSheet()
        }
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

// MARK: - FDA Permission Sheet

struct FDAPermissionSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .orange.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                // Title & Description
                VStack(spacing: 12) {
                    Text("Full Disk Access Required")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("To accurately scan your Documents, Downloads, and other personal folders, MyMacCleaner needs Full Disk Access permission.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Steps
                VStack(alignment: .leading, spacing: 14) {
                    FDAStepRow(number: 1, text: "Click \"Open System Settings\" below")
                    FDAStepRow(number: 2, text: "Click the \"+\" button at the bottom of the list")
                    FDAStepRow(number: 3, text: "Navigate to and select MyMacCleaner")
                    FDAStepRow(number: 4, text: "Toggle the switch to enable access")
                    FDAStepRow(number: 5, text: "Return here and click \"Restart App\"")
                }
                .padding(.vertical, 8)

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        openFDASettings()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "gear")
                            Text("Open System Settings")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.orange, .orange.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        restartApp()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Restart App")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)

                    Button("Maybe Later") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }
            }
            .padding(36)
        }
        .frame(width: 480, height: 580)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func openFDASettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }

    private func restartApp() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()

        NSApplication.shared.terminate(nil)
    }
}

struct FDAStepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Text("\(number)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Color.orange.gradient, in: Circle())

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
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
