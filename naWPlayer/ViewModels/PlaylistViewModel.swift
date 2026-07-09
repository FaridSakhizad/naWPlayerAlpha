import Foundation

@MainActor
final class PlaylistViewModel: ObservableObject {
    let store: LibraryStore

    init(store: LibraryStore) {
        self.store = store
    }

    func tracks(for playlist: Playlist) -> [AudioTrack] {
        playlist.trackIDs.compactMap { id in
            store.tracks.first { $0.id == id }
        }
    }

    func add(_ track: AudioTrack, to playlist: Playlist) {
        var ids = playlist.trackIDs
        ids.append(track.id)
        store.setTrackIDs(ids, for: playlist)
    }

    func remove(at offsets: IndexSet, from playlist: Playlist) {
        var ids = playlist.trackIDs
        ids.remove(atOffsets: offsets)
        store.setTrackIDs(ids, for: playlist)
    }

    func move(from source: IndexSet, to destination: Int, in playlist: Playlist) {
        var ids = playlist.trackIDs
        ids.move(fromOffsets: source, toOffset: destination)
        store.setTrackIDs(ids, for: playlist)
    }
}
