import SwiftUI

struct PlayerQueueSection: View {
    @EnvironmentObject private var player: AudioPlayerService
    @Environment(\.playerTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Up Next", systemImage: "text.line.first.and.arrowtriangle.forward")
                    .font(.headline)
                Spacer()
                Text("\((player.currentIndex ?? -1) + 1)/\(player.queue.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(theme.palette.mutedText)
            }

            ForEach(Array(player.queue.enumerated()), id: \.element.id) { index, track in
                queueRow(index: index, track: track)
            }
        }
        .playerPanel()
    }

    private func queueRow(index: Int, track: AudioTrack) -> some View {
        HStack {
            Text("\(index + 1)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(theme.palette.mutedText)
                .frame(width: 28, alignment: .trailing)

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.caption)
                    .foregroundStyle(theme.palette.mutedText)
                    .lineLimit(1)
            }

            Spacer()

            if track == player.currentTrack {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(theme.palette.accent)
            }
        }
        .padding(8)
        .background(track == player.currentTrack ? theme.palette.accent.opacity(0.14) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            player.playQueue(player.queue, startingAt: index)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(index + 1). \(track.title), \(track.artist)")
        .accessibilityValue(track == player.currentTrack ? "Currently playing" : "")
        .accessibilityHint("Plays this track from the queue")
    }
}
