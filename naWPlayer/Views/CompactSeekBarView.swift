import SwiftUI

struct CompactSeekBarView: View {
    @EnvironmentObject private var player: AudioPlayerService
    @Environment(\.playerTheme) private var theme

    private var duration: TimeInterval {
        player.currentTrack?.duration ?? 0
    }

    private var remaining: TimeInterval {
        duration - player.elapsed
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(formatTime(duration))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(theme.palette.mutedText)
                .frame(width: 34, alignment: .leading)

            PlayerTappableSlider(
                value: Binding(
                    get: { player.elapsed },
                    set: { player.seek(to: min(max($0, 0), duration)) }
                ),
                range: 0...max(duration, 1)
            )

            Text("-\(formatTime(remaining))")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(theme.palette.mutedText)
                .frame(width: 38, alignment: .trailing)
        }
    }
}
