import Foundation

struct TrackFileAccess {
    let url: URL
    private let stopAccessing: (() -> Void)?

    init(url: URL, stopAccessing: (() -> Void)? = nil) {
        self.url = url
        self.stopAccessing = stopAccessing
    }

    func stop() {
        stopAccessing?()
    }
}

@MainActor
struct TrackFileResolver {
    let store: LibraryStore

    func accessFile(for track: AudioTrack) throws -> TrackFileAccess {
        switch track.storageLocation {
        case .sandbox(let fileName):
            let url = store.tracksDirectory.appendingPathComponent(fileName)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw PlaybackError.missingFile
            }
            return TrackFileAccess(url: url)

        case .externalBookmark(let bookmarkData, _):
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            guard !isStale else {
                throw PlaybackError.linkedFileUnavailable
            }
            let didAccess = url.startAccessingSecurityScopedResource()
            guard FileManager.default.fileExists(atPath: url.path) else {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
                throw PlaybackError.linkedFileUnavailable
            }
            return TrackFileAccess(url: url) {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
    }
}
