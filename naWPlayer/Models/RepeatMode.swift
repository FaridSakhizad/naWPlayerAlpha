import Foundation

enum RepeatMode: String, CaseIterable, Identifiable, Codable {
    case off = "Off"
    case one = "One"
    case all = "All"

    var id: String { rawValue }
}
