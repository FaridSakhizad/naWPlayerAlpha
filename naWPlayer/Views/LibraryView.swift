import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel
    @Binding var scrollTargetID: AudioTrack.ID?
    @Binding var isImportingPresented: Bool
    @Binding var isSortPresented: Bool
    @Binding var libraryEditMode: EditMode
    @EnvironmentObject private var store: LibraryStore
    @EnvironmentObject private var player: AudioPlayerService
    @Environment(\.playerTheme) private var theme
    @State private var detailTrack: AudioTrack?
    @State private var selectedTrackID: AudioTrack.ID?

    init(
        store: LibraryStore,
        scrollTargetID: Binding<AudioTrack.ID?>,
        isImportingPresented: Binding<Bool>,
        isSortPresented: Binding<Bool>,
        libraryEditMode: Binding<EditMode>
    ) {
        _viewModel = StateObject(wrappedValue: LibraryViewModel(store: store))
        _scrollTargetID = scrollTargetID
        _isImportingPresented = isImportingPresented
        _isSortPresented = isSortPresented
        _libraryEditMode = libraryEditMode
    }

    private var displayedTracks: [AudioTrack] {
        viewModel.displayedTracks(from: store.tracks)
    }

    var body: some View {
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
                                isSelected: selectedTrackID == track.id,
                                onDetails: {
                                    selectedTrackID = track.id
                                    detailTrack = track
                                },
                                onPlay: {
                                    selectedTrackID = track.id
                                    player.play(track: track, in: displayedTracks)
                                }
                            )
                            .id(track.id)
                            .swipeActions {
                                Button {
                                    selectedTrackID = track.id
                                    player.play(track: track, in: displayedTracks)
                                } label: {
                                    Label("Play", systemImage: "play.fill")
                                }
                                .tint(theme.palette.accent)
                            }
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
                        .onDelete { offsets in
                            let deletedIDs = Set(offsets.compactMap { displayedTracks.indices.contains($0) ? displayedTracks[$0].id : nil })
                            store.deleteTracks(at: offsets, from: displayedTracks)
                            player.removeTracks(withIDs: deletedIDs)
                        }
                    }
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
            .onChange(of: scrollTargetID) { targetID in
                guard let targetID else { return }
                withAnimation {
                    proxy.scrollTo(targetID, anchor: .center)
                }
                scrollTargetID = nil
            }
            .environment(\.editMode, $libraryEditMode)
            .fileImporter(
                isPresented: $isImportingPresented,
                allowedContentTypes: DocumentImportService.supportedTypes,
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    viewModel.importFiles(from: urls)
                } else if case .failure(let error) = result {
                    viewModel.importError = error.localizedDescription
                }
            }
            .alert("Import Error", isPresented: Binding(
                get: { viewModel.importError != nil },
                set: { if !$0 { viewModel.importError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.importError ?? "Unknown error")
            }
            .overlay {
                if viewModel.isImporting {
                    ProgressView("Importing")
                        .playerPanel()
                }
            }
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
    }

    private func moveTracks(from source: IndexSet, to destination: Int) {
        viewModel.moveTracks(from: source, to: destination, in: displayedTracks)
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
