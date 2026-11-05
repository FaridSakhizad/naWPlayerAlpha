import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel
    @Binding var scrollTargetID: AudioTrack.ID?
    @Binding var isImportingPresented: Bool
    @Binding var importMode: DocumentImportService.ImportMode
    @Binding var isSortPresented: Bool
    @Binding var libraryEditMode: EditMode
    @Binding var markedTrackIDs: Set<AudioTrack.ID>
    @EnvironmentObject private var store: LibraryStore
    @EnvironmentObject private var player: AudioPlayerService
    @Environment(\.playerTheme) private var theme
    @State private var detailTrack: AudioTrack?
    @State private var selectedTrackID: AudioTrack.ID?

    init(
        store: LibraryStore,
        scrollTargetID: Binding<AudioTrack.ID?>,
        isImportingPresented: Binding<Bool>,
        importMode: Binding<DocumentImportService.ImportMode>,
        isSortPresented: Binding<Bool>,
        libraryEditMode: Binding<EditMode>,
        markedTrackIDs: Binding<Set<AudioTrack.ID>>
    ) {
        _viewModel = StateObject(wrappedValue: LibraryViewModel(store: store))
        _scrollTargetID = scrollTargetID
        _isImportingPresented = isImportingPresented
        _importMode = importMode
        _isSortPresented = isSortPresented
        _libraryEditMode = libraryEditMode
        _markedTrackIDs = markedTrackIDs
    }

    private var displayedTracks: [AudioTrack] {
        viewModel.displayedTracks(from: store.tracks)
    }

    var body: some View {
        Group {
            if libraryEditMode.isEditing, !displayedTracks.isEmpty {
                BatchTrackReorderList(
                    tracks: displayedTracks,
                    markedTrackIDs: markedTrackIDs,
                    currentTrackID: player.currentTrack?.id,
                    isPlaying: player.isPlaying,
                    theme: theme,
                    onToggleMarkedTrack: toggleMarkedTrack,
                    onMoveTracks: moveMarkedTracks
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                regularLibraryList
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: Binding(
            get: { detailTrack != nil },
            set: { if !$0 { detailTrack = nil } }
        )) {
            if let detailTrack {
                TrackDetailView(track: detailTrack)
            }
        }
        .onChange(of: libraryEditMode) { editMode in
            if !editMode.isEditing {
                markedTrackIDs.removeAll()
            }
        }
        .environment(\.editMode, $libraryEditMode)
        .sheet(isPresented: $isSortPresented) {
            NavigationStack {
                SortOptionsView(selectedSort: $viewModel.sort)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                isSortPresented = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium])
        }
    }

    private var regularLibraryList: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    if displayedTracks.isEmpty {
                        VStack(spacing: 16) {
                            PlayerEmptyStateView(
                                title: "No Music",
                                systemImage: "music.note",
                                message: "Import audio files from Files to build your local library."
                            )
                            Button {
                                importMode = PlayerSettingsStore().loadDefaultImportMode()
                                isImportingPresented = true
                            } label: {
                                Label("Import Music", systemImage: "square.and.arrow.down")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 12)
                    } else {
                        ForEach(displayedTracks) { track in
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
                                        player.play(track: track, in: displayedTracks)
                                    }
                                },
                                onDelete: {
                                    deleteTrack(track)
                                }
                            )
                            .id(track.id)
                            .simultaneousGesture(TapGesture(count: 2).onEnded {
                                selectedTrackID = track.id
                                player.play(track: track, in: displayedTracks)
                            })
                            .onTapGesture {
                                selectedTrackID = track.id
                            }
                            .listRowBackground(rowBackground(for: track))
                            .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                        }
                        .onMove(perform: moveTracks)
                    }
                }
            }
            .onChange(of: scrollTargetID) { targetID in
                guard let targetID else { return }
                selectedTrackID = targetID
                withAnimation {
                    proxy.scrollTo(targetID, anchor: .center)
                }
                scrollTargetID = nil
            }
        }
    }

    private func moveTracks(from source: IndexSet, to destination: Int) {
        viewModel.moveTracks(from: source, to: destination, in: displayedTracks)
    }

    private func moveMarkedTracks(_ trackIDs: [AudioTrack.ID], to destination: Int) {
        let movedIDs = Set(trackIDs)
        let movedTracks = displayedTracks.filter { movedIDs.contains($0.id) }
        guard !movedTracks.isEmpty else { return }

        let remainingTracks = displayedTracks.filter { !movedIDs.contains($0.id) }
        let movedBeforeDestination = displayedTracks
            .prefix(min(max(destination, 0), displayedTracks.count))
            .filter { movedIDs.contains($0.id) }
            .count
        let adjustedDestination = min(
            max(destination - movedBeforeDestination, 0),
            remainingTracks.count
        )

        var reorderedTracks = remainingTracks
        reorderedTracks.insert(contentsOf: movedTracks, at: adjustedDestination)
        viewModel.applyCustomOrder(reorderedTracks)
    }

    private func deleteTrack(_ track: AudioTrack) {
        guard let index = displayedTracks.firstIndex(where: { $0.id == track.id }) else { return }
        store.deleteTracks(at: IndexSet(integer: index), from: displayedTracks)
        player.removeTracks(withIDs: [track.id])
        markedTrackIDs.remove(track.id)
    }

    private func toggleMarkedTrack(_ track: AudioTrack) {
        if markedTrackIDs.contains(track.id) {
            markedTrackIDs.remove(track.id)
        } else {
            markedTrackIDs.insert(track.id)
        }
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
