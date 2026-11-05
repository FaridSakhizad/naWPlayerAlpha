import SwiftUI

struct LibraryTrackRow: View {
    let track: AudioTrack
    let isCurrent: Bool
    let isPlaying: Bool
    let isSelected: Bool
    var isEditing = false
    var isMarkedForDeletion = false
    let onDetails: () -> Void
    let onPlay: () -> Void
    let onDelete: () -> Void
    var onToggleMarkedForDeletion: (() -> Void)?
    @Environment(\.playerTheme) private var theme
    private let rowMinHeight: CGFloat = 50
    private let playButtonSize = CGSize(width: 34, height: 44)
    private let durationWidth: CGFloat = 38

    var body: some View {
        HStack(spacing: 10) {
            if isEditing, let onToggleMarkedForDeletion {
                Button(action: onToggleMarkedForDeletion) {
                    Image(systemName: isMarkedForDeletion ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isMarkedForDeletion ? theme.palette.accent : theme.palette.mutedText)
                        .frame(width: 28, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isMarkedForDeletion ? "Unmark Track" : "Mark Track")
            }

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

            if isEditing {
                Image(systemName: "line.3.horizontal")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isCurrent ? Color.white.opacity(0.72) : theme.palette.mutedText)
                    .frame(width: 24, height: 44)
                    .accessibilityHidden(true)
            }

            if !isEditing {
                Button(action: onPlay) {
                    Image(systemName: isCurrent && isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .frame(width: playButtonSize.width, height: playButtonSize.height)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isCurrent && isPlaying ? "Pause Track" : "Play Track")
                .accessibilityHint("\(track.title) by \(track.artist)")
            }
        }
        .frame(minHeight: rowMinHeight)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !isEditing {
                Button(action: onPlay) {
                    Label(
                        isCurrent && isPlaying ? "Pause" : "Play",
                        systemImage: isCurrent && isPlaying ? "pause.fill" : "play.fill"
                    )
                }
                .tint(theme.palette.accent)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !isEditing {
                Button(action: onDetails) {
                    Label("Details", systemImage: "info.circle")
                }
                .tint(theme.palette.accent)

                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
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
