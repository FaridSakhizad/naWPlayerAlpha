import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var sort: TrackSort = .dateAdded
    @Published var importError: String?
    @Published var isImporting = false

    private let importer = DocumentImportService()
    let store: LibraryStore

    init(store: LibraryStore) {
        self.store = store
    }

    func importFiles(from urls: [URL]) {
        isImporting = true
        Task {
            let result = await importer.importFiles(from: urls, into: store)
            isImporting = false
            switch result {
            case .success(let importResult):
                if !importResult.skipped.isEmpty {
                    importError = Self.partialImportMessage(for: importResult)
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
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
        sort = .custom
        store.reorderTracks(to: orderedTracks)
    }

    private static func partialImportMessage(for result: DocumentImportService.ImportResult) -> String {
        let importedCount = result.imported.count
        let skippedCount = result.skipped.count
        let skippedNames = result.skipped
            .prefix(3)
            .map { "\($0.fileName): \($0.reason)" }
            .joined(separator: "\n")
        let suffix = skippedCount > 3 ? "\nAnd \(skippedCount - 3) more." : ""
        return "Imported \(importedCount) file(s). Skipped \(skippedCount):\n\(skippedNames)\(suffix)"
    }
}
