import AVFoundation
import Foundation
import UniformTypeIdentifiers

struct DocumentImportService {
    enum ImportMode: String, CaseIterable, Identifiable {
        case copyIntoApp
        case linkInPlace

        var id: String { rawValue }

        var title: String {
            switch self {
            case .copyIntoApp:
                "Copy Into App"
            case .linkInPlace:
                "Link Files in Place"
            }
        }
    }

    enum ImportError: LocalizedError {
        case unsupportedFile
        case noImportableFiles([SkippedImport])

        var errorDescription: String? {
            switch self {
            case .unsupportedFile:
                "The selected file is not a supported audio file."
            case .noImportableFiles(let skipped):
                Self.noImportableFilesMessage(skipped)
            }
        }

        private static func noImportableFilesMessage(_ skipped: [SkippedImport]) -> String {
            guard !skipped.isEmpty else {
                return "None of the selected files could be imported."
            }
            let details = skipped
                .prefix(3)
                .map { "\($0.fileName): \($0.reason)" }
                .joined(separator: "\n")
            let suffix = skipped.count > 3 ? "\nAnd \(skipped.count - 3) more." : ""
            return "None of the selected files could be imported.\n\(details)\(suffix)"
        }
    }

    static let supportedTypes: [UTType] = AudioCodecRegistry.shared.supportedFormats.map(\.defaultUTType)

    struct ImportResult {
        let imported: [AudioTrack]
        let skipped: [SkippedImport]
    }

    struct SkippedImport: Identifiable, Equatable {
        let id = UUID()
        let fileName: String
        let reason: String
    }

    func importFiles(from urls: [URL], into store: LibraryStore, mode: ImportMode) async -> Result<ImportResult, Error> {
        do {
            try await MainActor.run { try store.ensureDirectories() }
            var imported: [AudioTrack] = []
            var skipped: [SkippedImport] = []
            for url in urls {
                do {
                    let track = try await importOne(url: url, into: store, mode: mode)
                    imported.append(track)
                } catch {
                    skipped.append(SkippedImport(
                        fileName: url.lastPathComponent,
                        reason: error.localizedDescription
                    ))
                }
            }
            let tracksToAdd = imported
            if !tracksToAdd.isEmpty {
                await MainActor.run { store.addTracks(tracksToAdd) }
                return .success(ImportResult(imported: imported, skipped: skipped))
            }
            return .failure(ImportError.noImportableFiles(skipped))
        } catch {
            return .failure(error)
        }
    }

    private func importOne(url: URL, into store: LibraryStore, mode: ImportMode) async throws -> AudioTrack {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard AudioFileFormat.from(url: url) != nil else {
            throw ImportError.unsupportedFile
        }

        switch mode {
        case .copyIntoApp:
            return try await copyIntoApp(url: url, store: store)
        case .linkInPlace:
            return try await linkInPlace(url: url, store: store)
        }
    }

    private func copyIntoApp(url: URL, store: LibraryStore) async throws -> AudioTrack {
        let fileID = UUID()
        let ext = url.pathExtension.isEmpty ? "m4a" : url.pathExtension
        let destinationName = "\(fileID.uuidString).\(ext)"
        let destinationURL = await MainActor.run {
            store.tracksDirectory.appendingPathComponent(destinationName)
        }
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: url, to: destinationURL)
        do {
            try AudioCodecRegistry.shared.validateFile(at: destinationURL)
        } catch {
            try? FileManager.default.removeItem(at: destinationURL)
            throw ImportError.unsupportedFile
        }

        let metadata = await readMetadata(from: destinationURL)
        let artworkFileName = try await saveArtwork(metadata.artworkData, id: fileID, store: store)

        return AudioTrack(
            id: fileID,
            title: metadata.title.isEmpty ? url.deletingPathExtension().lastPathComponent : metadata.title,
            artist: metadata.artist,
            album: metadata.album,
            duration: metadata.duration,
            storageLocation: .sandbox(fileName: destinationName),
            artworkFileName: artworkFileName
        )
    }

    private func linkInPlace(url: URL, store: LibraryStore) async throws -> AudioTrack {
        do {
            try AudioCodecRegistry.shared.validateFile(at: url)
        } catch {
            throw ImportError.unsupportedFile
        }

        let fileID = UUID()
        let bookmarkData = try url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        let metadata = await readMetadata(from: url)
        let artworkFileName = try await saveArtwork(metadata.artworkData, id: fileID, store: store)

        return AudioTrack(
            id: fileID,
            title: metadata.title.isEmpty ? url.deletingPathExtension().lastPathComponent : metadata.title,
            artist: metadata.artist,
            album: metadata.album,
            duration: metadata.duration,
            storageLocation: .externalBookmark(bookmarkData: bookmarkData, displayName: url.lastPathComponent),
            artworkFileName: artworkFileName
        )
    }

    private func readMetadata(from url: URL) async -> (title: String, artist: String, album: String, duration: TimeInterval, artworkData: Data?) {
        let asset = AVURLAsset(url: url)
        var duration: TimeInterval = 0
        if let loadedDuration = try? await asset.load(.duration) {
            duration = CMTimeGetSeconds(loadedDuration)
        }

        var title = ""
        var artist = ""
        var album = ""
        var artworkData: Data?
        if let metadata = try? await asset.load(.metadata) {
            for item in metadata {
                guard let key = item.commonKey?.rawValue else { continue }
                switch key {
                case AVMetadataKey.commonKeyTitle.rawValue:
                    title = (try? await item.load(.stringValue)) ?? title
                case AVMetadataKey.commonKeyArtist.rawValue:
                    artist = (try? await item.load(.stringValue)) ?? artist
                case AVMetadataKey.commonKeyAlbumName.rawValue:
                    album = (try? await item.load(.stringValue)) ?? album
                case AVMetadataKey.commonKeyArtwork.rawValue:
                    artworkData = (try? await item.load(.dataValue)) ?? artworkData
                default:
                    break
                }
            }
        }
        return (title, artist, album, duration.isFinite ? duration : 0, artworkData)
    }

    private func saveArtwork(_ data: Data?, id: UUID, store: LibraryStore) async throws -> String? {
        guard let data else { return nil }
        let fileName = "\(id.uuidString).artwork"
        let url = await MainActor.run {
            store.artworkDirectory.appendingPathComponent(fileName)
        }
        try data.write(to: url, options: .atomic)
        return fileName
    }
}
