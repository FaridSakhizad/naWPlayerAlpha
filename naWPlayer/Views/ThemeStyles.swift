import SwiftUI

private struct PlayerThemeKey: EnvironmentKey {
    static let defaultValue = PlayerTheme.classicDark
}

extension EnvironmentValues {
    var playerTheme: PlayerTheme {
        get { self[PlayerThemeKey.self] }
        set { self[PlayerThemeKey.self] = newValue }
    }
}

struct ThemedRoot<Content: View>: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let palette = themeManager.selectedTheme.palette
        content
            .environment(\.playerTheme, themeManager.selectedTheme)
            .tint(palette.accent)
            .background(palette.background.ignoresSafeArea())
            .toolbarBackground(palette.panel, for: .tabBar, .navigationBar)
            .toolbarColorScheme(themeManager.selectedTheme == .minimalSilver ? .light : .dark, for: .tabBar, .navigationBar)
    }
}

struct PlayerEmptyStateView: View {
    let title: String
    let systemImage: String
    let message: String
    @Environment(\.playerTheme) private var theme

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(theme.palette.accent)
            Text(title)
                .font(.headline)
                .foregroundStyle(theme.palette.text)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.palette.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
}

extension View {
    func playerPanel() -> some View {
        modifier(PlayerPanelModifier())
    }
}

private struct PlayerPanelModifier: ViewModifier {
    @Environment(\.playerTheme) private var theme
    private let cornerRadius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .padding()
            .background(theme.palette.panel)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.palette.accent.opacity(0.35), lineWidth: 1)
            )
            .foregroundStyle(theme.palette.text)
    }
}

func formatTime(_ time: TimeInterval) -> String {
    guard time.isFinite else { return "0:00" }
    let total = max(0, Int(time.rounded()))
    return "\(total / 60):\(String(format: "%02d", total % 60))"
}
