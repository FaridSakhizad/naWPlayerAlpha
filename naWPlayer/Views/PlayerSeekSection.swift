import SwiftUI

struct PlayerSeekSection: View {
    @EnvironmentObject private var player: AudioPlayerService
    @Environment(\.playerTheme) private var theme

    var body: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { player.elapsed },
                    set: { player.seek(to: $0) }
                ),
                in: 0...max(player.currentTrack?.duration ?? 1, 1)
            )
            HStack {
                Text(formatTime(player.elapsed))
                Spacer()
                Text(formatTime(player.currentTrack?.duration ?? 0))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(theme.palette.mutedText)
        }
    }
}
