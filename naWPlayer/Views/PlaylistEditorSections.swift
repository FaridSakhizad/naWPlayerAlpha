import SwiftUI

struct PlaylistSelectorSection: View {
    @Binding var newPlaylistName: String
    @Binding var selectedPlaylistID: Playlist.ID?
    let selectedPlaylist: Playlist?
    @EnvironmentObject private var store: LibraryStore

    var body: some View {
        Section("Playlists") {
            HStack {
                TextField("New playlist", text: $newPlaylistName)
                Button {
                    store.createPlaylist(named: newPlaylistName)
                    selectedPlaylistID = store.playlists.last?.id
                    newPlaylistName = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Create Playlist")
            }

            Picker("Active", selection: Binding(
                get: { selectedPlaylist?.id },
                set: { selectedPlaylistID = $0 }
            )) {
                Text("Current Queue").tag(Optional<Playlist.ID>.none)
                ForEach(store.playlists) { playlist in
                    Text(playlist.name).tag(Optional(playlist.id))
                }
            }
        }
    }
}

struct PlaylistTracksSection: View {
    let tracks: [AudioTrack]
    let onPlay: (AudioTrack) -> Void
    let onMove: (IndexSet, Int) -> Void
    let onDelete: (IndexSet) -> Void
    @EnvironmentObject private var player: AudioPlayerService

    var body: some View {
        Section("Playlist Editor") {
            if tracks.isEmpty {
                PlayerEmptyStateView(
                    title: "Empty",
                    systemImage: "text.badge.plus",
                    message: "Add tracks from the library or play a queue."
                )
            } else {
                ForEach(tracks) { track in
                    Button {
                        onPlay(track)
                    } label: {
                        TrackRow(track: track, isCurrent: track == player.currentTrack)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Play \(track.title)")
                }
                .onMove(perform: onMove)
                .onDelete(perform: onDelete)
            }
        }
    }
}

struct PlaylistAddTracksSection: View {
    let selectedPlaylist: Playlist
    let onAdd: (AudioTrack) -> Void
    @EnvironmentObject private var store: LibraryStore

    var body: some View {
        Section("Add Tracks") {
            ForEach(store.tracks) { track in
                Button {
                    onAdd(track)
                } label: {
                    Label(track.title, systemImage: "plus")
                }
                .accessibilityLabel("Add \(track.title)")
            }
        }
    }
}
