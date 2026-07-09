import SwiftUI

struct TrackDetailView: View {
    let track: AudioTrack
    @EnvironmentObject private var store: LibraryStore
    @EnvironmentObject private var player: AudioPlayerService
    @Environment(\.playerTheme) private var theme

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    ArtworkView(track: track, store: store, size: 180)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("Metadata") {
                LabeledContent("Title", value: track.title)
                LabeledContent("Artist", value: track.artist)
                LabeledContent("Album", value: track.album)
                LabeledContent("Duration", value: formatTime(track.duration))
                LabeledContent("Date Added", value: track.dateAdded.formatted(date: .abbreviated, time: .shortened))
            }

            Section {
                Button {
                    player.play(track: track, in: store.tracks)
                } label: {
                    Label("Play Track", systemImage: "play.fill")
                }
            }
        }
        .navigationTitle(track.title)
        .navigationBarTitleDisplayMode(.inline)
        .foregroundStyle(theme.palette.text)
    }
}
