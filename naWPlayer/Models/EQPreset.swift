import Foundation

enum EQPreset: String, CaseIterable, Identifiable, Codable {
    case flat = "Flat"
    case rock = "Rock"
    case pop = "Pop"
    case jazz = "Jazz"
    case classical = "Classical"
    case bassBoost = "Bass Boost"
    case custom = "Custom"

    var id: String { rawValue }

    static let bandFrequencies: [Float] = [31, 62, 125, 250, 500, 1_000, 2_000, 4_000, 8_000, 16_000]

    var gains: [Float] {
        switch self {
        case .flat, .custom:
            Array(repeating: 0, count: 10)
        case .rock:
            [5, 4, 3, -1, -2, 1, 3, 5, 6, 6]
        case .pop:
            [-1, 2, 4, 5, 3, 0, -1, -1, 2, 3]
        case .jazz:
            [3, 2, 1, 2, -1, -1, 0, 1, 3, 4]
        case .classical:
            [4, 3, 2, 1, -1, -1, 0, 2, 3, 4]
        case .bassBoost:
            [8, 7, 6, 4, 2, 0, 0, 0, 1, 2]
        }
    }
}
