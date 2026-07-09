import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case library = "Library"
    case playlist = "Playlist"
    case equalizer = "EQ"
    case settings = "Settings"

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
    @State private var showingLibraryImport = false
    @State private var showingLibrarySort = false

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
                                isSortPresented: $showingLibrarySort,
                                libraryEditMode: $libraryEditMode
                            )
                        case .playlist:
                            PlaylistEditorView(store: store)
                        case .equalizer:
                            EqualizerView()
                        case .settings:
                            SettingsView(store: store, player: player, themeManager: themeManager)
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
                    onSortLibrary: {
                        showingLibrarySort = true
                    },
                    onImportLibrary: {
                        showingLibraryImport = true
                    },
                    onMenu: {
                        showingAppMenu = true
                    },
                    onSearch: {
                        showingSearch = true
                    }
                )
                .padding(.horizontal)
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
            .sheet(isPresented: $showingAppMenu) {
                AppMenuView(selectedSection: selectedSection) { section in
                    selectedSection = section
                    showingAppMenu = false
                }
                .presentationDetents([.medium])
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
        }
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
