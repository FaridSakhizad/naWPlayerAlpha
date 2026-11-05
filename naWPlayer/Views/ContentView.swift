import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case library = "Library"
    case playlist = "Playlist"
    case equalizer = "EQ"
    case settings = "Settings"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .library:
            "music.note.list"
        case .playlist:
            "text.line.first.and.arrowtriangle.forward"
        case .equalizer:
            "slider.vertical.3"
        case .settings:
            "gearshape"
        case .about:
            "info.circle"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: LibraryStore
    @EnvironmentObject private var player: AudioPlayerService
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedSection: AppSection = .library
    @State private var showingAppMenu = false
    @State private var showingSearch = false
    @State private var libraryScrollTargetID: AudioTrack.ID?
    @State private var libraryEditMode: EditMode = .inactive
    @State private var markedLibraryTrackIDs: Set<AudioTrack.ID> = []
    @State private var showingMarkedTracksDeletionConfirmation = false
    @State private var showingCreatePlaylistFromMarkedTracks = false
    @State private var playlistNameFromMarkedTracks = ""
    @State private var playlistEditMode: EditMode = .inactive
    @State private var activePlaylistID: Playlist.ID?
    @State private var showingLibraryImport = false
    @State private var libraryImportMode: DocumentImportService.ImportMode = PlayerSettingsStore().loadDefaultImportMode()
    @State private var showingLibrarySort = false
    @State private var showingPlaylistTrackPicker = false
    @State private var importError: String?
    @State private var isImporting = false
    private let importer = DocumentImportService()

    var body: some View {
        ThemedRoot {
            VStack(spacing: 0) {
                NavigationStack {
                    Group {
                        switch selectedSection {
                        case .library:
                            LibraryView(
                                store: store,
                                scrollTargetID: $libraryScrollTargetID,
                                isImportingPresented: $showingLibraryImport,
                                importMode: $libraryImportMode,
                                isSortPresented: $showingLibrarySort,
                                libraryEditMode: $libraryEditMode,
                                markedTrackIDs: $markedLibraryTrackIDs
                            )
                        case .playlist:
                            PlaylistEditorView(
                                store: store,
                                activePlaylistID: $activePlaylistID,
                                playlistEditMode: $playlistEditMode
                            )
                        case .equalizer:
                            EqualizerView()
                        case .settings:
                            SettingsView(store: store, player: player, themeManager: themeManager)
                        case .about:
                            AboutView()
                        }
                    }
                }

                CompactPlayerView(
                    selectedSection: selectedSection,
                    isLibraryEditing: libraryEditMode.isEditing,
                    onEditLibrary: {
                        withAnimation {
                            libraryEditMode = libraryEditMode.isEditing ? .inactive : .active
                        }
                    },
                    markedLibraryTrackCount: markedLibraryTrackIDs.count,
                    areAllLibraryTracksMarked: areAllLibraryTracksMarked,
                    onToggleMarkAllLibraryTracks: {
                        toggleMarkAllLibraryTracks()
                    },
                    onInvertLibraryTrackSelection: {
                        invertLibraryTrackSelection()
                    },
                    onCreatePlaylistFromMarkedLibraryTracks: {
                        playlistNameFromMarkedTracks = ""
                        showingCreatePlaylistFromMarkedTracks = true
                    },
                    onDeleteMarkedLibraryTracks: {
                        showingMarkedTracksDeletionConfirmation = true
                    },
                    onSortLibrary: {
                        showingLibrarySort = true
                    },
                    onAddMusic: {
                        libraryImportMode = PlayerSettingsStore().loadDefaultImportMode()
                        showingLibraryImport = true
                    },
                    onAddTrackToPlaylist: {
                        showingPlaylistTrackPicker = true
                    },
                    onMenu: {
                        showingAppMenu = true
                    },
                    onSearch: {
                        showingSearch = true
                    },
                    onFocusCurrentTrack: {
                        guard let track = player.currentTrack else { return }
                        selectedSection = .library
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            libraryScrollTargetID = track.id
                        }
                    },
                    hasActivePlaylist: activePlaylistID != nil
                )
                .padding(.bottom, 8)
            }
            .alert("Playback Error", isPresented: Binding(
                get: { player.playbackError != nil },
                set: { if !$0 { player.dismissPlaybackError() } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(player.playbackError ?? "Unknown playback error.")
            }
            .alert("Import Error", isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importError ?? "Unknown error")
            }
            .confirmationDialog(
                "Delete \(markedLibraryTrackIDs.count) selected track(s)?",
                isPresented: $showingMarkedTracksDeletionConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Tracks", role: .destructive) {
                    deleteMarkedLibraryTracks()
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Create Playlist", isPresented: $showingCreatePlaylistFromMarkedTracks) {
                TextField("Name", text: $playlistNameFromMarkedTracks)
                Button("Create") {
                    createPlaylistFromMarkedTracks()
                }
                .disabled(playlistNameFromMarkedTracks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The selected tracks will be added to the new playlist.")
            }
            .sheet(isPresented: $showingLibraryImport) {
                DocumentPickerView(
                    allowedContentTypes: DocumentImportService.supportedTypes,
                    asCopy: libraryImportMode == .copyIntoApp
                ) { result in
                    showingLibraryImport = false
                    if case .success(let urls) = result, !urls.isEmpty {
                        importFiles(urls)
                    } else if case .failure(let error) = result {
                        importError = error.localizedDescription
                    }
                }
            }
            .sheet(isPresented: $showingAppMenu) {
                AppMenuView(selectedSection: selectedSection) { section in
                    selectedSection = section
                    showingAppMenu = false
                }
                .presentationDetents([.medium])
            }
            .fullScreenCover(isPresented: $showingPlaylistTrackPicker) {
                NavigationStack {
                    AddTracksToPlaylistView(tracks: store.tracks) { tracks in
                        if let activePlaylistID {
                            store.addTrackIDs(tracks.map(\.id), toPlaylistID: activePlaylistID)
                        }
                        showingPlaylistTrackPicker = false
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingPlaylistTrackPicker = false
                            }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingSearch) {
                NavigationStack {
                    SearchTracksView(tracks: store.tracks) { track in
                        showingSearch = false
                        selectedSection = .library
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            libraryScrollTargetID = track.id
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingSearch = false
                            }
                        }
                    }
                }
            }
            .overlay {
                if isImporting {
                    ProgressView("Importing")
                        .playerPanel()
                }
            }
        }
    }

    private func importFiles(_ urls: [URL]) {
        isImporting = true
        let playlistIDForImport = selectedSection == .playlist ? activePlaylistID : nil
        Task {
            let result = await importer.importFiles(from: urls, into: store, mode: libraryImportMode)
            isImporting = false
            switch result {
            case .success(let importResult):
                if let playlistIDForImport {
                    store.addTrackIDs(importResult.imported.map(\.id), toPlaylistID: playlistIDForImport)
                }
                if !importResult.skipped.isEmpty {
                    importError = Self.partialImportMessage(for: importResult)
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
    }

    private func deleteMarkedLibraryTracks() {
        let tracks = store.tracks
        let offsets = IndexSet(tracks.indices.filter { markedLibraryTrackIDs.contains(tracks[$0].id) })
        guard !offsets.isEmpty else { return }

        let deletedIDs = Set(offsets.map { tracks[$0].id })
        store.deleteTracks(at: offsets, from: tracks)
        player.removeTracks(withIDs: deletedIDs)
        markedLibraryTrackIDs.removeAll()
        libraryEditMode = .inactive
    }

    private var areAllLibraryTracksMarked: Bool {
        !store.tracks.isEmpty && markedLibraryTrackIDs.count == store.tracks.count
    }

    private func toggleMarkAllLibraryTracks() {
        if areAllLibraryTracksMarked {
            markedLibraryTrackIDs.removeAll()
        } else {
            markedLibraryTrackIDs = Set(store.tracks.map(\.id))
        }
    }

    private func invertLibraryTrackSelection() {
        let allTrackIDs = Set(store.tracks.map(\.id))
        markedLibraryTrackIDs = allTrackIDs.subtracting(markedLibraryTrackIDs)
    }

    private func createPlaylistFromMarkedTracks() {
        let trackIDs = store.tracks
            .filter { markedLibraryTrackIDs.contains($0.id) }
            .map(\.id)
        guard !trackIDs.isEmpty else { return }

        store.createPlaylist(named: playlistNameFromMarkedTracks, trackIDs: trackIDs)
        markedLibraryTrackIDs.removeAll()
        libraryEditMode = .inactive
    }

    private static func partialImportMessage(for result: DocumentImportService.ImportResult) -> String {
        let skippedNames = result.skipped
            .prefix(3)
            .map { "\($0.fileName): \($0.reason)" }
            .joined(separator: "\n")
        let suffix = result.skipped.count > 3 ? "\nAnd \(result.skipped.count - 3) more." : ""
        return "Imported \(result.imported.count) file(s). Skipped \(result.skipped.count):\n\(skippedNames)\(suffix)"
    }
}

private struct AppMenuView: View {
    let selectedSection: AppSection
    let onSelect: (AppSection) -> Void
    @Environment(\.playerTheme) private var theme

    var body: some View {
        List {
            Section {
                ForEach(AppSection.allCases) { section in
                    Button {
                        onSelect(section)
                    } label: {
                        HStack {
                            Label(section.rawValue, systemImage: section.icon)
                            Spacer()
                            if selectedSection == section {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(theme.palette.accent)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct AboutView: View {
    var body: some View {
        List {
            Section {
                LabeledContent("App", value: "naWPlayer")
                LabeledContent("Minimum iOS", value: "16+")
                Text("A local music player with queue-first controls, playlist editing, themes, lock screen metadata, and a 10-band equalizer.")
                    .font(.footnote)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
