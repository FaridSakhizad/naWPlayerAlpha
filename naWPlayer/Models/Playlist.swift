import Foundation

struct Playlist: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var trackIDs: [UUID]
    var dateCreated: Date

    init(id: UUID = UUID(), name: String, trackIDs: [UUID] = [], dateCreated: Date = .now) {
        self.id = id
        self.name = name
        self.trackIDs = trackIDs
        self.dateCreated = dateCreated
    }
}
