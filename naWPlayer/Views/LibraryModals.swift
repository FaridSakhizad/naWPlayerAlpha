import SwiftUI

struct SortOptionsView: View {
    @Binding var selectedSort: TrackSort
    @Environment(\.playerTheme) private var theme

    var body: some View {
        List {
            Section("Sort Library By") {
                ForEach(TrackSort.allCases) { sort in
                    Button {
                        selectedSort = sort
                    } label: {
                        HStack {
                            Text(sort.rawValue)
                            Spacer()
                            if selectedSort == sort {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(theme.palette.accent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Sort")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SearchTracksView: View {
    let tracks: [AudioTrack]
    let onSelect: (AudioTrack) -> Void
    @Environment(\.playerTheme) private var theme
    @State private var query = ""
    @FocusState private var isSearchFocused: Bool

    private var results: [AudioTrack] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return tracks.filter { track in
            track.title.localizedCaseInsensitiveContains(trimmed) ||
            track.artist.localizedCaseInsensitiveContains(trimmed) ||
            track.album.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(theme.palette.mutedText)
                    TextField("Title, artist, album", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isSearchFocused)
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(theme.palette.mutedText)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear Search")
                    }
                }
            }

            Section {
                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    EmptyView()
                } else if results.isEmpty {
                    Text("no results")
                        .font(.subheadline)
                        .foregroundStyle(theme.palette.mutedText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    ForEach(results) { track in
                        Button {
                            onSelect(track)
                        } label: {
                            TrackRow(track: track)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFocused = true
            }
        }
    }
}

struct AddTracksToPlaylistView: View {
    let tracks: [AudioTrack]
    let onAdd: ([AudioTrack]) -> Void
    @Environment(\.playerTheme) private var theme
    @State private var query = ""
    @State private var selectedTrackIDs: Set<AudioTrack.ID> = []
    @FocusState private var isSearchFocused: Bool

    private var selectedTracks: [AudioTrack] {
        tracks.filter { selectedTrackIDs.contains($0.id) }
    }

    private var results: [AudioTrack] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return tracks }
        return tracks.filter { track in
            track.title.localizedCaseInsensitiveContains(trimmed) ||
            track.artist.localizedCaseInsensitiveContains(trimmed) ||
            track.album.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(theme.palette.mutedText)
                    TextField("Title, artist, album", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isSearchFocused)
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(theme.palette.mutedText)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear Search")
                    }
                }
            }

            Section {
                if results.isEmpty {
                    Text("no results")
                        .font(.subheadline)
                        .foregroundStyle(theme.palette.mutedText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    ForEach(results) { track in
                        Button {
                            toggleSelection(for: track)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedTrackIDs.contains(track.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(selectedTrackIDs.contains(track.id) ? theme.palette.accent : theme.palette.mutedText)
                                    .frame(width: 28)

                                TrackRow(track: track)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Add Tracks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Clear") {
                    selectedTrackIDs.removeAll()
                }
                .disabled(selectedTrackIDs.isEmpty)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    onAdd(selectedTracks)
                }
                .disabled(selectedTrackIDs.isEmpty)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFocused = true
            }
        }
    }

    private func toggleSelection(for track: AudioTrack) {
        if selectedTrackIDs.contains(track.id) {
            selectedTrackIDs.remove(track.id)
        } else {
            selectedTrackIDs.insert(track.id)
        }
    }
}
