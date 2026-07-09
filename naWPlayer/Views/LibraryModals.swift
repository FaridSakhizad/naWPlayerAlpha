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
