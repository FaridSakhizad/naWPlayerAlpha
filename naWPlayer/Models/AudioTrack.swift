import Foundation

enum TrackStorageLocation: Codable, Equatable, Hashable {
    case sandbox(fileName: String)
    case externalBookmark(bookmarkData: Data, displayName: String)

    var displayName: String {
        switch self {
        case .sandbox(let fileName):
            fileName
        case .externalBookmark(_, let displayName):
            displayName
        }
    }
}

struct AudioTrack: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var storageLocation: TrackStorageLocation
    var artworkFileName: String?
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        title: String,
        artist: String = "Unknown Artist",
        album: String = "Unknown Album",
        duration: TimeInterval = 0,
        storageLocation: TrackStorageLocation,
        artworkFileName: String? = nil,
        dateAdded: Date = .now
    ) {
        self.id = id
        self.title = title
        self.artist = artist.isEmpty ? "Unknown Artist" : artist
        self.album = album.isEmpty ? "Unknown Album" : album
        self.duration = duration
        self.storageLocation = storageLocation
        self.artworkFileName = artworkFileName
        self.dateAdded = dateAdded
    }
}

enum TrackSort: String, CaseIterable, Identifiable {
    case custom = "Custom Order"
    case title = "Title"
    case artist = "Artist"
    case album = "Album"
    case dateAdded = "Date Added"

    var id: String { rawValue }
}
