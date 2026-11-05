import Foundation

private struct LibrarySnapshot: Codable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var tracks: [AudioTrack]
    var playlists: [Playlist]

    init(schemaVersion: Int = Self.currentSchemaVersion, tracks: [AudioTrack], playlists: [Playlist]) {
        self.schemaVersion = schemaVersion
        self.tracks = tracks
        self.playlists = playlists
    }
}

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var tracks: [AudioTrack] = []
    @Published private(set) var playlists: [Playlist] = []

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fileManager = FileManager.default

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        load()
    }

    var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var tracksDirectory: URL {
        documentsURL.appendingPathComponent("ImportedTracks", isDirectory: true)
    }

    var artworkDirectory: URL {
        documentsURL.appendingPathComponent("Artwork", isDirectory: true)
    }

    private var librarySnapshotURL: URL {
        documentsURL.appendingPathComponent("library.json")
    }

    private var libraryBackupSnapshotURL: URL {
        documentsURL.appendingPathComponent("library.backup.json")
    }

    private var legacyTracksURL: URL {
        documentsURL.appendingPathComponent("tracks.json")
    }

    private var legacyPlaylistsURL: URL {
        documentsURL.appendingPathComponent("playlists.json")
    }

    func artworkURL(for track: AudioTrack) -> URL? {
        guard let artworkFileName = track.artworkFileName else { return nil }
        return artworkDirectory.appendingPathComponent(artworkFileName)
    }

    func addTracks(_ newTracks: [AudioTrack]) {
        tracks.append(contentsOf: newTracks)
        save()
    }

    func updateTrack(_ updatedTrack: AudioTrack) {
        guard let index = tracks.firstIndex(where: { $0.id == updatedTrack.id }) else { return }
        tracks[index] = updatedTrack
        save()
    }

    func deleteTracks(at offsets: IndexSet, from sortedTracks: [AudioTrack]) {
        let deletedTracks = offsets.compactMap { sortedTracks.indices.contains($0) ? sortedTracks[$0] : nil }
        let ids = Set(deletedTracks.map(\.id))
        tracks.removeAll { ids.contains($0.id) }
        playlists = playlists.map { playlist in
            var copy = playlist
            copy.trackIDs.removeAll { ids.contains($0) }
            return copy
        }
        removeFiles(for: deletedTracks)
        save()
    }

    func reorderTracks(to orderedTracks: [AudioTrack]) {
        let orderedIDs = Set(orderedTracks.map(\.id))
        let remainingTracks = tracks.filter { !orderedIDs.contains($0.id) }
        tracks = orderedTracks + remainingTracks
        save()
    }

    @discardableResult
    func createPlaylist(named name: String, trackIDs: [UUID] = []) -> Playlist? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let playlist = Playlist(name: trimmed, trackIDs: trackIDs)
        playlists.append(playlist)
        save()
        return playlist
    }

    func renamePlaylist(_ playlist: Playlist, to name: String) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[index].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        save()
    }

    func deletePlaylists(at offsets: IndexSet) {
        playlists.remove(atOffsets: offsets)
        save()
    }

    func movePlaylists(from source: IndexSet, to destination: Int) {
        playlists.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func setTrackIDs(_ trackIDs: [UUID], for playlist: Playlist) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[index].trackIDs = trackIDs
        save()
    }

    func addTrackIDs(_ trackIDs: [UUID], toPlaylistID playlistID: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        playlists[index].trackIDs.append(contentsOf: trackIDs)
        save()
    }

    func clearLibrary() {
        tracks.removeAll()
        playlists.removeAll()
        try? fileManager.removeItem(at: tracksDirectory)
        try? fileManager.removeItem(at: artworkDirectory)
        save()
    }

    func ensureDirectories() throws {
        try fileManager.createDirectory(at: tracksDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: artworkDirectory, withIntermediateDirectories: true)
    }

    func save() {
        do {
            try ensureDirectories()
            let snapshot = LibrarySnapshot(tracks: tracks, playlists: playlists)
            try backupCurrentSnapshotIfNeeded()
            try encoder.encode(snapshot).write(to: librarySnapshotURL, options: .atomic)
        } catch {
            print("Library save failed: \(error)")
        }
    }

    private func load() {
        do {
            try ensureDirectories()
            if fileManager.fileExists(atPath: librarySnapshotURL.path) {
                try loadSnapshot(from: librarySnapshotURL)
            } else {
                try loadLegacyFiles()
                save()
            }
        } catch {
            recoverAfterLoadFailure(error)
        }
    }

    private func loadSnapshot(from url: URL) throws {
        let snapshot = try decoder.decode(LibrarySnapshot.self, from: Data(contentsOf: url))
        switch snapshot.schemaVersion {
        case LibrarySnapshot.currentSchemaVersion:
            tracks = snapshot.tracks
            playlists = snapshot.playlists
        default:
            // TODO: Add schema migrations when LibrarySnapshot evolves beyond v1.
            tracks = snapshot.tracks
            playlists = snapshot.playlists
        }
    }

    private func backupCurrentSnapshotIfNeeded() throws {
        guard fileManager.fileExists(atPath: librarySnapshotURL.path) else { return }
        if fileManager.fileExists(atPath: libraryBackupSnapshotURL.path) {
            try fileManager.removeItem(at: libraryBackupSnapshotURL)
        }
        try fileManager.copyItem(at: librarySnapshotURL, to: libraryBackupSnapshotURL)
    }

    private func recoverAfterLoadFailure(_ error: Error) {
        print("Library load failed: \(error)")

        do {
            if fileManager.fileExists(atPath: libraryBackupSnapshotURL.path) {
                try loadSnapshot(from: libraryBackupSnapshotURL)
                try restoreBackupSnapshot()
                print("Library recovered from backup snapshot.")
                return
            }

            try loadLegacyFiles()
            save()
            print("Library recovered from legacy files.")
        } catch {
            tracks = []
            playlists = []
            print("Library recovery failed: \(error)")
        }
    }

    private func restoreBackupSnapshot() throws {
        if fileManager.fileExists(atPath: librarySnapshotURL.path) {
            try fileManager.removeItem(at: librarySnapshotURL)
        }
        try fileManager.copyItem(at: libraryBackupSnapshotURL, to: librarySnapshotURL)
    }

    private func loadLegacyFiles() throws {
        if fileManager.fileExists(atPath: legacyTracksURL.path) {
            tracks = try decoder.decode([AudioTrack].self, from: Data(contentsOf: legacyTracksURL))
        }
        if fileManager.fileExists(atPath: legacyPlaylistsURL.path) {
            playlists = try decoder.decode([Playlist].self, from: Data(contentsOf: legacyPlaylistsURL))
        }
    }

    private func removeFiles(for tracks: [AudioTrack]) {
        for track in tracks {
            if case .sandbox(let fileName) = track.storageLocation {
                try? fileManager.removeItem(at: tracksDirectory.appendingPathComponent(fileName))
            }
            if let artworkURL = artworkURL(for: track) {
                try? fileManager.removeItem(at: artworkURL)
            }
        }
    }
}
