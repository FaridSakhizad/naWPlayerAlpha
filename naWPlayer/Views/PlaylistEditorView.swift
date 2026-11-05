import SwiftUI

struct PlaylistEditorView: View {
    @StateObject private var viewModel: PlaylistViewModel
    @EnvironmentObject private var store: LibraryStore
    @Binding var activePlaylistID: Playlist.ID?
    @Binding var playlistEditMode: EditMode
    @State private var isCreatePresented = false
    @State private var newPlaylistName = ""

    init(store: LibraryStore, activePlaylistID: Binding<Playlist.ID?>, playlistEditMode: Binding<EditMode>) {
        _viewModel = StateObject(wrappedValue: PlaylistViewModel(store: store))
        _activePlaylistID = activePlaylistID
        _playlistEditMode = playlistEditMode
    }

    var body: some View {
        List {
            Section {
                if store.playlists.isEmpty {
                    PlayerEmptyStateView(
                        title: "No Playlists",
                        systemImage: "music.note.list",
                        message: "Create a playlist to group tracks from your library."
                    )
                } else {
                    ForEach(store.playlists) { playlist in
                        NavigationLink {
                            PlaylistDetailView(
                                playlist: playlist,
                                viewModel: viewModel,
                                activePlaylistID: $activePlaylistID,
                                playlistEditMode: $playlistEditMode
                            )
                        } label: {
                            PlaylistSummaryRow(
                                playlist: playlist,
                                tracks: viewModel.tracks(for: playlist)
                            )
                        }
                    }
                    .onMove { source, destination in
                        store.movePlaylists(from: source, to: destination)
                    }
                    .onDelete { offsets in
                        let deletedIDs = offsets.compactMap { store.playlists.indices.contains($0) ? store.playlists[$0].id : nil }
                        store.deletePlaylists(at: offsets)
                        if let activePlaylistID, deletedIDs.contains(activePlaylistID) {
                            self.activePlaylistID = nil
                        }
                    }
                }
            }
        }
        .navigationTitle("Playlists")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $playlistEditMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    newPlaylistName = ""
                    isCreatePresented = true
                } label: {
                    Image(systemName: "plus.circle")
                }
                .accessibilityLabel("Create Playlist")
            }
        }
        .onAppear {
            activePlaylistID = nil
        }
        .alert("Create Playlist", isPresented: $isCreatePresented) {
            TextField("Name", text: $newPlaylistName)
            Button("Create") {
                store.createPlaylist(named: newPlaylistName)
                newPlaylistName = ""
            }
            .disabled(newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) {}
        }
    }
}

private struct PlaylistSummaryRow: View {
    let playlist: Playlist
    let tracks: [AudioTrack]

    private var totalDuration: TimeInterval {
        tracks.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                Text("\(tracks.count) tracks")
                    .font(.caption)
                    .foregroundStyle(.black.opacity(0.62))
            }

            Spacer()

            Text(formatTime(totalDuration))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.black.opacity(0.62))
        }
        .frame(minHeight: 44)
    }
}

private struct PlaylistDetailView: View {
    let playlist: Playlist
    @ObservedObject var viewModel: PlaylistViewModel
    @EnvironmentObject private var store: LibraryStore
    @EnvironmentObject private var player: AudioPlayerService
    @Environment(\.playerTheme) private var theme
    @Binding var activePlaylistID: Playlist.ID?
    @Binding var playlistEditMode: EditMode
    @State private var selectedTrackID: AudioTrack.ID?
    @State private var detailTrack: AudioTrack?
    @State private var renameText = ""
    @State private var isRenamePresented = false

    private var currentPlaylist: Playlist? {
        store.playlists.first { $0.id == playlist.id }
    }

    private var tracks: [AudioTrack] {
        guard let currentPlaylist else { return [] }
        return viewModel.tracks(for: currentPlaylist)
    }

    var body: some View {
        List {
            Section {
                if tracks.isEmpty {
                    PlayerEmptyStateView(
                        title: "Empty",
                        systemImage: "text.badge.plus",
                        message: "Add tracks from the player controls below."
                    )
                } else {
                    ForEach(tracks) { track in
                        LibraryTrackRow(
                            track: track,
                            isCurrent: track == player.currentTrack,
                            isPlaying: player.isPlaying,
                            isSelected: selectedTrackID == track.id,
                            onDetails: {
                                selectedTrackID = track.id
                                detailTrack = track
                            },
                            onPlay: {
                                selectedTrackID = track.id
                                if track == player.currentTrack {
                                    player.togglePlayPause()
                                } else {
                                    player.play(track: track, in: tracks)
                                }
                            },
                            onDelete: {
                                removeTrack(track)
                            }
                        )
                        .id(track.id)
                        .simultaneousGesture(TapGesture(count: 2).onEnded {
                            selectedTrackID = track.id
                            player.play(track: track, in: tracks)
                        })
                        .onTapGesture {
                            selectedTrackID = track.id
                        }
                        .listRowBackground(rowBackground(for: track))
                        .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                    }
                    .onMove(perform: moveTracks)
                    .onDelete(perform: removeTracks)
                }
            }
        }
        .navigationTitle(currentPlaylist?.name ?? playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: Binding(
            get: { detailTrack != nil },
            set: { if !$0 { detailTrack = nil } }
        )) {
            if let detailTrack {
                TrackDetailView(track: detailTrack)
            }
        }
        .environment(\.editMode, $playlistEditMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        renameText = currentPlaylist?.name ?? playlist.name
                        isRenamePresented = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        if let currentPlaylist {
                            store.deletePlaylist(currentPlaylist)
                            activePlaylistID = nil
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            activePlaylistID = playlist.id
        }
        .alert("Rename Playlist", isPresented: $isRenamePresented) {
            TextField("Name", text: $renameText)
            Button("Save") {
                if let currentPlaylist {
                    store.renamePlaylist(currentPlaylist, to: renameText)
                }
            }
            .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) {}
        }
    }

    private func moveTracks(from source: IndexSet, to destination: Int) {
        guard let currentPlaylist else { return }
        viewModel.move(from: source, to: destination, in: currentPlaylist)
    }

    private func removeTracks(at offsets: IndexSet) {
        guard let currentPlaylist else { return }
        viewModel.remove(at: offsets, from: currentPlaylist)
    }

    private func removeTrack(_ track: AudioTrack) {
        guard let index = tracks.firstIndex(where: { $0.id == track.id }) else { return }
        removeTracks(at: IndexSet(integer: index))
    }

    private func rowBackground(for track: AudioTrack) -> Color {
        if track == player.currentTrack {
            return theme.palette.panel
        }
        if selectedTrackID == track.id {
            return theme.palette.accent.opacity(0.16)
        }
        return .clear
    }
}
