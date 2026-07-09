import SwiftUI

enum PlayerTheme: String, CaseIterable, Identifiable, Codable {
    case classicDark = "Classic Dark"
    case neonGreen = "Neon Green"
    case minimalSilver = "Minimal Silver"

    var id: String { rawValue }

    var palette: PlayerPalette {
        switch self {
        case .classicDark:
            PlayerPalette(
                background: Color(red: 0.07, green: 0.08, blue: 0.10),
                panel: Color(red: 0.13, green: 0.15, blue: 0.18),
                accent: Color(red: 0.97, green: 0.64, blue: 0.21),
                secondaryAccent: Color(red: 0.28, green: 0.70, blue: 0.94),
                text: .white,
                mutedText: Color(red: 0.66, green: 0.69, blue: 0.74)
            )
        case .neonGreen:
            PlayerPalette(
                background: Color(red: 0.02, green: 0.06, blue: 0.04),
                panel: Color(red: 0.05, green: 0.12, blue: 0.08),
                accent: Color(red: 0.16, green: 0.96, blue: 0.42),
                secondaryAccent: Color(red: 0.15, green: 0.66, blue: 1.0),
                text: Color(red: 0.88, green: 1.0, blue: 0.90),
                mutedText: Color(red: 0.58, green: 0.78, blue: 0.63)
            )
        case .minimalSilver:
            PlayerPalette(
                background: Color(red: 0.92, green: 0.93, blue: 0.94),
                panel: Color(red: 0.98, green: 0.98, blue: 0.99),
                accent: Color(red: 0.18, green: 0.38, blue: 0.68),
                secondaryAccent: Color(red: 0.42, green: 0.48, blue: 0.56),
                text: Color(red: 0.10, green: 0.11, blue: 0.13),
                mutedText: Color(red: 0.42, green: 0.45, blue: 0.50)
            )
        }
    }
}

struct PlayerPalette {
    let background: Color
    let panel: Color
    let accent: Color
    let secondaryAccent: Color
    let text: Color
    let mutedText: Color
}
