import SwiftUI

struct PlaylistEditorView: View {
    @StateObject private var viewModel: PlaylistViewModel
    @EnvironmentObject private var store: LibraryStore
    @EnvironmentObject private var player: AudioPlayerService
    @Environment(\.playerTheme) private var theme
    @State private var newPlaylistName = ""
    @State private var selectedPlaylistID: Playlist.ID?
    @State private var renameText = ""
    @State private var playlistToRename: Playlist?

    init(store: LibraryStore) {
        _viewModel = StateObject(wrappedValue: PlaylistViewModel(store: store))
    }

    private var selectedPlaylist: Playlist? {
        if let selectedPlaylistID {
            return store.playlists.first { $0.id == selectedPlaylistID }
        }
        return store.playlists.first
    }

    private var selectedTracks: [AudioTrack] {
        guard let selectedPlaylist else { return player.queue }
        return viewModel.tracks(for: selectedPlaylist)
    }

    var body: some View {
        List {
            PlaylistSelectorSection(
                newPlaylistName: $newPlaylistName,
                selectedPlaylistID: $selectedPlaylistID,
                selectedPlaylist: selectedPlaylist
            )

            PlaylistTracksSection(
                tracks: selectedTracks,
                onPlay: { track in
                    player.play(track: track, in: selectedTracks)
                },
                onMove: moveSelectedTracks,
                onDelete: removeSelectedTracks
            )

            if let selectedPlaylist {
                PlaylistAddTracksSection(selectedPlaylist: selectedPlaylist) { track in
                    viewModel.add(track, to: selectedPlaylist)
                }
            }
        }
        .navigationTitle("Playlist Editor")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if let selectedPlaylist {
                    Menu {
                        Button {
                            playlistToRename = selectedPlaylist
                            renameText = selectedPlaylist.name
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            store.deletePlaylist(selectedPlaylist)
                            selectedPlaylistID = store.playlists.first?.id
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Playlist Actions")
                }
            }
        }
        .onAppear {
            selectedPlaylistID = selectedPlaylistID ?? store.playlists.first?.id
        }
        .alert("Rename Playlist", isPresented: Binding(
            get: { playlistToRename != nil },
            set: { if !$0 { playlistToRename = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Save") {
                if let playlistToRename {
                    store.renamePlaylist(playlistToRename, to: renameText)
                }
                playlistToRename = nil
            }
            Button("Cancel", role: .cancel) {
                playlistToRename = nil
            }
        } message: {
            Text("Choose a short name for this playlist.")
        }
    }

    private func moveSelectedTracks(from source: IndexSet, to destination: Int) {
        if let selectedPlaylist {
            viewModel.move(from: source, to: destination, in: selectedPlaylist)
        } else {
            player.moveQueueItems(from: source, to: destination)
        }
    }

    private func removeSelectedTracks(at offsets: IndexSet) {
        if let selectedPlaylist {
            viewModel.remove(at: offsets, from: selectedPlaylist)
        } else {
            player.removeQueueItems(at: offsets)
        }
    }
}
