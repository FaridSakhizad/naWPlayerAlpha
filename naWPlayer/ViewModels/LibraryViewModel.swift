import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var sort: TrackSort = .dateAdded

    let store: LibraryStore

    init(store: LibraryStore) {
        self.store = store
    }

    func displayedTracks(from tracks: [AudioTrack]) -> [AudioTrack] {
        switch sort {
        case .custom:
            return tracks
        case .title:
            return tracks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .artist:
            return tracks.sorted { $0.artist.localizedCaseInsensitiveCompare($1.artist) == .orderedAscending }
        case .album:
            return tracks.sorted { $0.album.localizedCaseInsensitiveCompare($1.album) == .orderedAscending }
        case .dateAdded:
            return tracks.sorted { $0.dateAdded > $1.dateAdded }
        }
    }

    func moveTracks(from source: IndexSet, to destination: Int, in displayedTracks: [AudioTrack]) {
        var orderedTracks = displayedTracks
        orderedTracks.move(fromOffsets: source, toOffset: destination)
        applyCustomOrder(orderedTracks)
    }

    func applyCustomOrder(_ orderedTracks: [AudioTrack]) {
        sort = .custom
        store.reorderTracks(to: orderedTracks)
    }
}
