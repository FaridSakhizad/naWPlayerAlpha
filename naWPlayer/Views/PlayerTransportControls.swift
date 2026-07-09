import SwiftUI

struct PlayerTransportControls: View {
    @EnvironmentObject private var player: AudioPlayerService
    @Environment(\.playerTheme) private var theme
    private let primaryButtonSize: CGFloat = 74

    var body: some View {
        HStack(spacing: 26) {
            Button {
                player.shuffleEnabled.toggle()
            } label: {
                Image(systemName: player.shuffleEnabled ? "shuffle.circle.fill" : "shuffle")
            }
            .accessibilityLabel("Shuffle")
            .accessibilityValue(player.shuffleEnabled ? "On" : "Off")

            Button {
                player.previous()
            } label: {
                Image(systemName: "backward.fill")
            }
            .accessibilityLabel("Previous Track")

            Button {
                player.togglePlayPause()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 34, weight: .bold))
                    .frame(width: primaryButtonSize, height: primaryButtonSize)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(Circle())
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")

            Button {
                player.next()
            } label: {
                Image(systemName: "forward.fill")
            }
            .accessibilityLabel("Next Track")

            Button {
                let all = RepeatMode.allCases
                let index = all.firstIndex(of: player.repeatMode) ?? 0
                player.repeatMode = all[(index + 1) % all.count]
            } label: {
                Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                    .foregroundStyle(player.repeatMode == .off ? theme.palette.mutedText : theme.palette.accent)
            }
            .accessibilityLabel("Repeat")
            .accessibilityValue(repeatAccessibilityValue)
        }
        .font(.title2)
        .frame(maxWidth: .infinity)
    }

    private var repeatAccessibilityValue: String {
        switch player.repeatMode {
        case .off:
            "Off"
        case .one:
            "One"
        case .all:
            "All"
        }
    }
}
