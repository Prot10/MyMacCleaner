import SwiftUI

// MARK: - Update Available Toolbar Item
// This wrapper handles conditional visibility in the toolbar

struct UpdateToolbarItem: View {
    @Environment(UpdateManager.self) var updateManager
    @State private var forceRefresh = false

    var body: some View {
        // Use both @Observable and notification-based refresh
        let _ = forceRefresh // Force view to depend on this state

        Group {
            if updateManager.updateAvailable {
                UpdateAvailableButton()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .updateAvailabilityChanged)) { _ in
            // Force refresh when notification is received
            print("[UpdateToolbarItem] Received update availability notification, updateAvailable: \(updateManager.updateAvailable)")
            forceRefresh.toggle()
        }
        .onAppear {
            print("[UpdateToolbarItem] onAppear, updateAvailable: \(updateManager.updateAvailable)")
        }
    }
}

// MARK: - Update Available Button

struct UpdateAvailableButton: View {
    @Environment(UpdateManager.self) var updateManager
    @State private var showingSheet = false
    @State private var isHovered = false

    var body: some View {
        Button {
            showingSheet = true
        } label: {
            HStack(spacing: Theme.Spacing.xxxs) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.orange)

                // Show version number
                if let version = updateManager.availableVersion {
                    Text("v\(version)")
                        .foregroundStyle(.orange)
                }
            }
        }
        .help(L("update.tooltip"))
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { isHovered = $0 }
        .sheet(isPresented: $showingSheet) {
            UpdateAvailableSheet()
                .environment(updateManager)
        }
    }
}

// MARK: - Update Available Sheet

struct UpdateAvailableSheet: View {
    @Environment(UpdateManager.self) var updateManager
    @Environment(\.dismiss) var dismiss
    @State private var isHovered = false

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
            }
            .padding(.top, Theme.Spacing.lg)

            // Title
            Text(L("update.sheet.title"))
                .font(Theme.Typography.size22Semibold)

            // Version info
            VStack(spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.md) {
                    VStack(spacing: Theme.Spacing.tiny) {
                        Text(L("update.sheet.current"))
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                        Text("v\(currentVersion)")
                            .font(Theme.Typography.size15Semibold)
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: "arrow.right")
                        .font(Theme.Typography.size18)
                        .foregroundStyle(.tertiary)

                    VStack(spacing: Theme.Spacing.tiny) {
                        Text(L("update.sheet.new"))
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                        if let newVersion = updateManager.availableVersion {
                            Text("v\(newVersion)")
                                .font(Theme.Typography.size15Semibold)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .fill(Color.orange.opacity(0.08))
                )
            }

            // Description
            Text(L("update.sheet.description"))
                .font(Theme.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            // Buttons
            VStack(spacing: Theme.Spacing.sm) {
                Button {
                    updateManager.checkForUpdates()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.to.line")
                        Text(L("update.sheet.download"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                .onHover { isHovered = $0 }

                Button {
                    dismiss()
                } label: {
                    Text(L("update.sheet.later"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.lg)
        }
        .frame(width: 340, height: 420)
    }
}

// MARK: - Preview

#Preview("Update Available Button") {
    HStack {
        UpdateAvailableButton()
    }
    .padding()
    .environment(UpdateManager())
}

#Preview("Update Available Sheet") {
    UpdateAvailableSheet()
        .environment(UpdateManager())
}
