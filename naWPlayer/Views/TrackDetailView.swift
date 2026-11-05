import SwiftUI

struct TrackDetailView: View {
    let track: AudioTrack
    @EnvironmentObject private var store: LibraryStore
    @EnvironmentObject private var player: AudioPlayerService
    @Environment(\.playerTheme) private var theme
    @State private var isLinkedFileUnavailable = false
    @State private var isRelinkPickerPresented = false

    private var currentTrack: AudioTrack {
        store.tracks.first(where: { $0.id == track.id }) ?? track
    }

    private var isLinkedTrack: Bool {
        if case .externalBookmark = currentTrack.storageLocation {
            return true
        }
        return false
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    ArtworkView(track: currentTrack, store: store, size: 180)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("Metadata") {
                LabeledContent("Title", value: currentTrack.title)
                LabeledContent("Artist", value: currentTrack.artist)
                LabeledContent("Album", value: currentTrack.album)
                LabeledContent("Duration", value: formatTime(currentTrack.duration))
                LabeledContent("Date Added", value: currentTrack.dateAdded.formatted(date: .abbreviated, time: .shortened))
            }

            Section("File") {
                LabeledContent("Storage", value: storageDescription(for: currentTrack))
                LabeledContent("Source", value: currentTrack.storageLocation.displayName)

                if isLinkedTrack, isLinkedFileUnavailable {
                    Button {
                        isRelinkPickerPresented = true
                    } label: {
                        Label("Choose File Again", systemImage: "link.badge.plus")
                    }
                }

                if isLinkedTrack, !isLinkedFileUnavailable {
                    Button {
                        copyLinkedFileIntoApp()
                    } label: {
                        Label("Copy File Into App", systemImage: "square.and.arrow.down")
                    }
                }
            }

            Section {
                Button {
                    player.play(track: currentTrack, in: store.tracks)
                } label: {
                    Label("Play Track", systemImage: "play.fill")
                }
            }
        }
        .navigationTitle(currentTrack.title)
        .navigationBarTitleDisplayMode(.inline)
        .foregroundStyle(theme.palette.text)
        .task(id: currentTrack.storageLocation) {
            checkLinkedFileAvailability()
        }
        .sheet(isPresented: $isRelinkPickerPresented) {
            DocumentPickerView(
                allowedContentTypes: DocumentImportService.supportedTypes,
                asCopy: false
            ) { result in
                isRelinkPickerPresented = false
                if case .success(let urls) = result, let url = urls.first {
                    relinkTrack(to: url)
                }
            }
        }
    }

    private func storageDescription(for track: AudioTrack) -> String {
        switch track.storageLocation {
        case .sandbox:
            "Copied Into App"
        case .externalBookmark:
            "Linked In Place"
        }
    }

    private func checkLinkedFileAvailability() {
        guard isLinkedTrack else {
            isLinkedFileUnavailable = false
            return
        }

        do {
            let access = try TrackFileResolver(store: store).accessFile(for: currentTrack)
            access.stop()
            isLinkedFileUnavailable = false
        } catch {
            isLinkedFileUnavailable = true
        }
    }

    private func relinkTrack(to url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard AudioFileFormat.from(url: url) != nil else { return }
        do {
            try AudioCodecRegistry.shared.validateFile(at: url)
            let bookmarkData = try url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            var updatedTrack = currentTrack
            updatedTrack.storageLocation = .externalBookmark(
                bookmarkData: bookmarkData,
                displayName: url.lastPathComponent
            )
            store.updateTrack(updatedTrack)
            isLinkedFileUnavailable = false
        } catch {
            isLinkedFileUnavailable = true
        }
    }

    private func copyLinkedFileIntoApp() {
        guard isLinkedTrack else { return }

        do {
            try store.ensureDirectories()
            let access = try TrackFileResolver(store: store).accessFile(for: currentTrack)
            defer { access.stop() }

            let fileExtension = access.url.pathExtension.isEmpty ? "m4a" : access.url.pathExtension
            let destinationName = "\(currentTrack.id.uuidString).\(fileExtension)"
            let destinationURL = store.tracksDirectory.appendingPathComponent(destinationName)

            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: access.url, to: destinationURL)
            try AudioCodecRegistry.shared.validateFile(at: destinationURL)

            var updatedTrack = currentTrack
            updatedTrack.storageLocation = .sandbox(fileName: destinationName)
            store.updateTrack(updatedTrack)
            isLinkedFileUnavailable = false
        } catch {
            isLinkedFileUnavailable = true
        }
    }
}
