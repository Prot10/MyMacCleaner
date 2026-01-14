import SwiftUI

// MARK: - Language Switcher Button

struct LanguageSwitcherButton: View {
    @Environment(LocalizationManager.self) var localization
    @State private var showingPopover = false

    var body: some View {
        Button {
            showingPopover.toggle()
        } label: {
            HStack(spacing: Theme.Spacing.xxxs) {
                Image(systemName: "globe")

                Text(localization.currentLanguage.shortCode)

                Image(systemName: "chevron.down")
                    .font(Theme.Typography.size10)
                    .opacity(0.7)
            }
        }
        .popover(isPresented: $showingPopover, arrowEdge: .bottom) {
            LanguagePickerView(showingPopover: $showingPopover)
                .environment(localization)
        }
    }
}

// MARK: - Language Picker View (Popover Content)

struct LanguagePickerView: View {
    @Environment(LocalizationManager.self) var localization
    @Binding var showingPopover: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            ForEach(AppLanguage.allCases) { language in
                LanguagePickerRow(
                    language: language,
                    isSelected: localization.currentLanguage == language
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        localization.setLanguage(language)
                    }
                    showingPopover = false
                }
            }
        }
        .padding(Theme.Spacing.xxxs)
        .frame(width: 140)
    }
}

// MARK: - Language Picker Row

struct LanguagePickerRow: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(language.nativeName)
                    .font(isSelected ? Theme.Typography.size13Semibold : Theme.Typography.size13)
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(Theme.Typography.size11Semibold)
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                if isHovered || isSelected {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(isSelected ? Theme.Colors.accent.opacity(0.15) : Color.white.opacity(0.08))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Preview

#Preview("Language Switcher") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: Theme.Spacing.xl) {
            LanguageSwitcherButton()
                .environment(LocalizationManager.shared)
        }
    }
    .frame(width: 300, height: 200)
}
