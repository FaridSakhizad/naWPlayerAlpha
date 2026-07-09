import Foundation

@MainActor
final class ThemeManager: ObservableObject {
    @Published var selectedTheme: PlayerTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        }
    }

    init() {
        if
            let rawValue = UserDefaults.standard.string(forKey: "selectedTheme"),
            let theme = PlayerTheme(rawValue: rawValue)
        {
            selectedTheme = theme
        } else {
            selectedTheme = .classicDark
        }
    }
}
