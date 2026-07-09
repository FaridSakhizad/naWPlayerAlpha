import SwiftUI

struct PlayerNowPlayingSection: View {
    @EnvironmentObject private var player: AudioPlayerService
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.playerTheme) private var theme
    private let artworkSize: CGFloat = 280

    var body: some View {
        VStack(spacing: 24) {
            ArtworkView(track: player.currentTrack, store: store, size: artworkSize)
                .shadow(color: .black.opacity(0.24), radius: 16, y: 8)

            VStack(spacing: 6) {
                Text(player.currentTrack?.title ?? "No track loaded")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(player.currentTrack?.artist ?? "Import music from Files")
                    .foregroundStyle(theme.palette.mutedText)
                Text(player.currentTrack?.album ?? "")
                    .font(.footnote)
                    .foregroundStyle(theme.palette.mutedText)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
