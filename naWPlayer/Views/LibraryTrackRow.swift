import SwiftUI

struct LibraryTrackRow: View {
    let track: AudioTrack
    let isCurrent: Bool
    let isSelected: Bool
    let onDetails: () -> Void
    let onPlay: () -> Void
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.playerTheme) private var theme
    private let artworkSize: CGFloat = 44
    private let rowMinHeight: CGFloat = 50
    private let detailsButtonSize = CGSize(width: 28, height: 44)
    private let playButtonSize = CGSize(width: 34, height: 44)
    private let durationWidth: CGFloat = 38

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onDetails) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: detailsButtonSize.width, height: detailsButtonSize.height)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Track Details")
            .accessibilityHint("\(track.title) by \(track.artist)")

            ArtworkView(track: track, store: store, size: artworkSize)

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryTextColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("\(track.artist) • \(track.album)")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            Text(formatTime(track.duration))
                .font(.caption.monospacedDigit())
                .foregroundStyle(isCurrent ? Color.white : theme.palette.mutedText)
                .frame(width: durationWidth, alignment: .trailing)

            Button(action: onPlay) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: playButtonSize.width, height: playButtonSize.height)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play Track")
            .accessibilityHint("\(track.title) by \(track.artist)")
        }
        .frame(minHeight: rowMinHeight)
    }

    private var primaryTextColor: Color {
        isCurrent ? .white : .black
    }

    private var secondaryTextColor: Color {
        isCurrent ? .white.opacity(0.72) : .black.opacity(0.62)
    }

    private var iconColor: Color {
        isCurrent ? .white : theme.palette.accent
    }
}

struct TrackRow: View {
    let track: AudioTrack
    var isCurrent: Bool = false
    @EnvironmentObject private var store: LibraryStore
    @Environment(\.playerTheme) private var theme
    private let artworkSize: CGFloat = 48

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(track: track, store: store, size: artworkSize)
            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(track.artist) • \(track.album)")
                    .font(.caption)
                    .foregroundStyle(theme.palette.mutedText)
                    .lineLimit(1)
            }
            Spacer()
            Text(formatTime(track.duration))
                .font(.caption.monospacedDigit())
                .foregroundStyle(isCurrent ? theme.palette.accent : theme.palette.mutedText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(track.title), \(track.artist), \(track.album)")
        .accessibilityValue(formatTime(track.duration))
    }
}
