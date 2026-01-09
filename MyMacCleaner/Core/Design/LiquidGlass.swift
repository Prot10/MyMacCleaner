import SwiftUI
import Combine

// MARK: - Liquid Glass Design System
// Native .glassEffect() on macOS 26+, .ultraThinMaterial fallback on older versions

// MARK: - Glass Card Modifiers

extension View {
    /// Standard glass card with rounded corners
    @ViewBuilder
    func glassCard() -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        } else {
            self
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                )
        }
    }

    /// Glass card with custom corner radius
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat) -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            self
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                )
        }
    }

    /// Prominent glass card for important elements
    @ViewBuilder
    func glassCardProminent(cornerRadius: CGFloat = 16) -> some View {
        if #available(macOS 26, *) {
            self
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        } else {
            self
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        }
    }

    /// Subtle glass card - uses clear variant for high transparency
    @ViewBuilder
    func glassCardSubtle(cornerRadius: CGFloat = 12) -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(.clear, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            self
                .background(.ultraThinMaterial.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    /// Pill-shaped glass (for tags, buttons)
    @ViewBuilder
    func glassPill() -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(.regular, in: .capsule)
        } else {
            self
                .background(.ultraThinMaterial)
                .clipShape(.capsule)
                .overlay(Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 1))
        }
    }

    /// Circle glass effect
    @ViewBuilder
    func glassCircle() -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(.regular, in: .circle)
        } else {
            self
                .background(.ultraThinMaterial)
                .clipShape(.circle)
                .overlay(Circle().strokeBorder(.white.opacity(0.15), lineWidth: 1))
        }
    }

    /// Glass effect with tint color
    @ViewBuilder
    func glassCard(tint: Color, cornerRadius: CGFloat = 16) -> some View {
        if #available(macOS 26, *) {
            self.glassEffect(.regular.tint(tint), in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            self
                .background(tint.opacity(0.1))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(tint.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Interactive Effects

extension View {
    /// Applies hover effect with scale
    func hoverEffect(isHovered: Bool, scale: CGFloat = 1.02) -> some View {
        self
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }

    /// Applies press effect
    func pressEffect(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    }

    /// Floating effect with shadow on hover
    func floatingEffect(isHovered: Bool) -> some View {
        self
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(
                color: .black.opacity(isHovered ? 0.2 : 0.1),
                radius: isHovered ? 20 : 10,
                y: isHovered ? 8 : 4
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}

// MARK: - Glass Capsule Modifier (Reusable)

struct GlassCapsuleModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.glassEffect(.regular, in: .capsule)
        } else {
            content
                .background(.ultraThinMaterial)
                .clipShape(.capsule)
                .overlay(Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 1))
        }
    }
}

// MARK: - Glass Button Style (Backward Compatible)

struct LiquidGlassButtonStyle: ButtonStyle {
    enum Variant {
        case regular
        case prominent
        case tinted(Color)
    }

    let variant: Variant
    let cornerRadius: CGFloat

    init(_ variant: Variant = .regular, cornerRadius: CGFloat = 12) {
        self.variant = variant
        self.cornerRadius = cornerRadius
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                switch variant {
                case .prominent:
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                default:
                    Color.clear
                }
            }
            .modifier(GlassEffectModifier(variant: variant, cornerRadius: cornerRadius))
            .foregroundStyle(foregroundColor)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        switch variant {
        case .regular: return .primary
        case .prominent: return .white
        case .tinted(let color): return color
        }
    }
}

// Helper modifier for button glass effect
struct GlassEffectModifier: ViewModifier {
    let variant: LiquidGlassButtonStyle.Variant
    let cornerRadius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.glassEffect(glassVariantMacOS26, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            content
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                )
        }
    }

    @available(macOS 26, *)
    private var glassVariantMacOS26: Glass {
        switch variant {
        case .regular, .prominent:
            return .regular
        case .tinted(let color):
            return .regular.tint(color)
        }
    }
}

extension ButtonStyle where Self == LiquidGlassButtonStyle {
    static var liquidGlass: LiquidGlassButtonStyle { LiquidGlassButtonStyle(.regular) }
    static var liquidGlassProminent: LiquidGlassButtonStyle { LiquidGlassButtonStyle(.prominent) }
    static func liquidGlassTinted(_ color: Color) -> LiquidGlassButtonStyle {
        LiquidGlassButtonStyle(.tinted(color))
    }
}

// MARK: - Floating Action Button (Backward Compatible)

struct FloatingActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background {
                    Circle()
                        .fill(color.gradient)
                }
                .modifier(CircleGlassModifier(color: color))
                .shadow(color: color.opacity(0.4), radius: isHovered ? 20 : 12, y: isHovered ? 8 : 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.92 : (isHovered ? 1.05 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct CircleGlassModifier: ViewModifier {
    let color: Color

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.glassEffect(.regular.tint(color), in: .circle)
        } else {
            content
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Glass Action Button (Backward Compatible)

struct GlassActionButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    var isDisabled: Bool = false

    @State private var isHovered = false
    @State private var isPressed = false

    init(_ title: String, icon: String? = nil, color: Color, disabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isDisabled = disabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isDisabled ? color.opacity(0.3) : color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(isDisabled ? 0.05 : (isHovered ? 0.2 : 0.12)))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        color.opacity(isDisabled ? 0.1 : (isHovered ? 0.5 : 0.3)),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .scaleEffect(isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isDisabled { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Glass Toolbar (Backward Compatible)

struct GlassToolbar<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 8) {
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .modifier(GlassCapsuleModifier())
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
    }
}

// MARK: - Glass Segmented Control (Backward Compatible)

struct GlassSegmentedControl<T: Hashable>: View {
    let options: [T]
    @Binding var selection: T
    let label: (T) -> String

    @Namespace private var segmentNamespace

    var body: some View {
        glassContainerWrapper {
            HStack(spacing: 4) {
                ForEach(options, id: \.self) { option in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selection = option
                        }
                    } label: {
                        Text(label(option))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(selection == option ? .primary : .secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background {
                                if selection == option {
                                    segmentBackground
                                        .matchedGeometryEffect(id: "segment", in: segmentNamespace)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color.white.opacity(0.05))
            .clipShape(.capsule)
        }
    }

    @ViewBuilder
    private func glassContainerWrapper<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(macOS 26, *) {
            GlassEffectContainer {
                content()
            }
        } else {
            content()
                .background(.ultraThinMaterial)
                .clipShape(.capsule)
        }
    }

    @ViewBuilder
    private var segmentBackground: some View {
        if #available(macOS 26, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular, in: .capsule)
        } else {
            Capsule()
                .fill(.white.opacity(0.15))
        }
    }
}

// MARK: - Glass Tab Picker (Backward Compatible)

struct GlassTabPicker<T: Hashable>: View {
    let tabs: [T]
    @Binding var selection: T
    let icon: (T) -> String
    let label: (T) -> String
    let accentColor: Color

    @Namespace private var tabNamespace

    init(
        tabs: [T],
        selection: Binding<T>,
        icon: @escaping (T) -> String,
        label: @escaping (T) -> String,
        accentColor: Color = .blue
    ) {
        self.tabs = tabs
        self._selection = selection
        self.icon = icon
        self.label = label
        self.accentColor = accentColor
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs, id: \.self) { tab in
                GlassTabButton(
                    icon: icon(tab),
                    label: label(tab),
                    isSelected: selection == tab,
                    accentColor: accentColor,
                    namespace: tabNamespace
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selection = tab
                    }
                }
            }
        }
        .padding(4)
        .modifier(GlassCapsuleModifier())
    }
}

struct GlassTabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let accentColor: Color
    let namespace: Namespace.ID
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))

                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : (isHovered ? .primary : .secondary))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(accentColor.gradient)
                        .matchedGeometryEffect(id: "selectedTab", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Glass Search Field (Backward Compatible)

struct GlassSearchField: View {
    @Binding var text: String
    let placeholder: String

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: Theme.ControlSize.controlIconSize, weight: .medium))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(Theme.ControlSize.controlFont)
                .focused($isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: Theme.ControlSize.controlIconSize))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.ControlSize.horizontalPadding)
        .padding(.vertical, Theme.ControlSize.verticalPadding)
        .frame(height: Theme.ControlSize.toolbarHeight)
        .frame(maxWidth: Theme.ControlSize.searchFieldMaxWidth)
        .modifier(SearchFieldGlassModifier(isFocused: isFocused))
        .scaleEffect(isFocused ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}

struct SearchFieldGlassModifier: ViewModifier {
    let isFocused: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.glassEffect(
                isFocused ? .regular : .clear,
                in: RoundedRectangle(cornerRadius: Theme.ControlSize.controlRadius)
            )
        } else {
            content
                .background(isFocused ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.clear))
                .clipShape(RoundedRectangle(cornerRadius: Theme.ControlSize.controlRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.ControlSize.controlRadius)
                        .strokeBorder(.white.opacity(isFocused ? 0.2 : 0.1), lineWidth: 1)
                )
        }
    }
}

// MARK: - Glass Control Modifier (Shared styling for Pickers/Toggles)

struct GlassControlModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content
                .padding(.horizontal, Theme.ControlSize.horizontalPadding)
                .padding(.vertical, Theme.ControlSize.verticalPadding)
                .frame(height: Theme.ControlSize.toolbarHeight)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Theme.ControlSize.controlRadius))
        } else {
            content
                .padding(.horizontal, Theme.ControlSize.horizontalPadding)
                .padding(.vertical, Theme.ControlSize.verticalPadding)
                .frame(height: Theme.ControlSize.toolbarHeight)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: Theme.ControlSize.controlRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.ControlSize.controlRadius)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

extension View {
    func glassControlStyle() -> some View {
        self.modifier(GlassControlModifier())
    }
}

// MARK: - Glass Picker (Native Picker with Glass Styling)

struct GlassPicker<T: Hashable, Content: View>: View {
    let icon: String
    @Binding var selection: T
    @ViewBuilder let content: () -> Content

    var body: some View {
        Picker(selection: $selection) {
            content()
        } label: {
            Image(systemName: icon)
                .font(.system(size: Theme.ControlSize.controlIconSize, weight: .medium))
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .font(Theme.ControlSize.controlFont)
        .foregroundStyle(.secondary)
        .glassControlStyle()
    }
}

// MARK: - Glass Toggle (Native Toggle with Glass Styling)

struct GlassToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(Theme.ControlSize.controlFont)
                .foregroundStyle(.secondary)

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
        }
        .glassControlStyle()
    }
}

// MARK: - Glass Menu Button (Custom Menu with Glass Styling)

struct GlassMenuButton<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: () -> Content

    @State private var isHovered = false

    var body: some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: Theme.ControlSize.controlIconSize, weight: .medium))
                Text(title)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
            }
            .font(Theme.ControlSize.controlFont)
            .foregroundStyle(.secondary)
            .padding(.horizontal, Theme.ControlSize.horizontalPadding)
            .padding(.vertical, Theme.ControlSize.verticalPadding)
            .frame(height: Theme.ControlSize.toolbarHeight)
            .modifier(GlassMenuModifier(isHovered: isHovered))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct GlassMenuModifier: ViewModifier {
    let isHovered: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.glassEffect(
                isHovered ? .regular : .clear,
                in: RoundedRectangle(cornerRadius: Theme.ControlSize.controlRadius)
            )
        } else {
            content
                .background(isHovered ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.clear))
                .clipShape(RoundedRectangle(cornerRadius: Theme.ControlSize.controlRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.ControlSize.controlRadius)
                        .strokeBorder(.white.opacity(isHovered ? 0.15 : 0.1), lineWidth: 1)
                )
        }
    }
}

// MARK: - Glass Effect Container Compatibility Wrapper

/// Wrapper that provides GlassEffectContainer on macOS 26+, passthrough on older versions
@ViewBuilder
func glassEffectContainerCompat<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    if #available(macOS 26, *) {
        GlassEffectContainer {
            content()
        }
    } else {
        content()
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.1),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
                }
                .mask(content)
            }
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Glow Effect

extension View {
    func glow(color: Color = .blue, radius: CGFloat = 10) -> some View {
        self
            .shadow(color: color.opacity(0.5), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 2)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview("Liquid Glass Components") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 24) {
            Text("Glass Card")
                .padding()
                .glassCard()

            Text("Prominent Glass")
                .padding()
                .glassCardProminent()

            Text("Glass Pill")
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .glassPill()

            HStack(spacing: 12) {
                Button("Glass") {}
                    .buttonStyle(.liquidGlass)

                Button("Prominent") {}
                    .buttonStyle(.liquidGlassProminent)

                Button("Tinted") {}
                    .buttonStyle(.liquidGlassTinted(.green))
            }

            GlassSearchField(text: .constant(""), placeholder: "Search...")
                .frame(width: 300)

            GlassSegmentedControl(
                options: ["All", "Active", "Inactive"],
                selection: .constant("All"),
                label: { $0 }
            )

            FloatingActionButton(icon: "plus", color: .blue) {}
        }
        .padding()
    }
    .frame(width: 500, height: 600)
}
