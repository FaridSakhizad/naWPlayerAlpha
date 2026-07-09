import SwiftUI

struct CompactTransportControls: View {
    let onMenu: () -> Void
    let onSearch: () -> Void
    @EnvironmentObject private var player: AudioPlayerService
    @Environment(\.playerTheme) private var theme
    private let sideControlSize = CGSize(width: 34, height: 28)
    private let transportControlSize = CGSize(width: 44, height: 36)

    var body: some View {
        HStack(spacing: 16) {
            Spacer()
            playbackModeControls
            previousButton
            playPauseButton
            nextButton
            navigationControls
            Spacer()
        }
    }

    private var playbackModeControls: some View {
        VStack(spacing: 8) {
            Button {
                player.shuffleEnabled.toggle()
            } label: {
                Image(systemName: player.shuffleEnabled ? "shuffle.circle.fill" : "shuffle")
                    .frame(width: sideControlSize.width, height: sideControlSize.height)
            }
            .accessibilityLabel("Shuffle")
            .accessibilityValue(player.shuffleEnabled ? "On" : "Off")

            Button {
                let all = RepeatMode.allCases
                let index = all.firstIndex(of: player.repeatMode) ?? 0
                player.repeatMode = all[(index + 1) % all.count]
            } label: {
                Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                    .foregroundStyle(player.repeatMode == .off ? theme.palette.mutedText : theme.palette.accent)
                    .frame(width: sideControlSize.width, height: sideControlSize.height)
            }
            .accessibilityLabel("Repeat")
            .accessibilityValue(repeatAccessibilityValue)
        }
        .buttonStyle(.borderless)
    }

    private var previousButton: some View {
        Button {
            player.previous()
        } label: {
            Image(systemName: "backward.fill")
                .frame(width: transportControlSize.width, height: transportControlSize.height)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("Previous Track")
    }

    private var playPauseButton: some View {
        Button {
            player.togglePlayPause()
        } label: {
            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                .font(.title3)
                .frame(width: transportControlSize.width, height: transportControlSize.height)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
    }

    private var nextButton: some View {
        Button {
            player.next()
        } label: {
            Image(systemName: "forward.fill")
                .frame(width: transportControlSize.width, height: transportControlSize.height)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("Next Track")
    }

    private var navigationControls: some View {
        VStack(spacing: 8) {
            Button(action: onSearch) {
                Image(systemName: "magnifyingglass")
                    .frame(width: sideControlSize.width, height: sideControlSize.height)
            }
            .accessibilityLabel("Search Library")

            Button(action: onMenu) {
                Image(systemName: "ellipsis.circle")
                    .frame(width: sideControlSize.width, height: sideControlSize.height)
            }
            .accessibilityLabel("Open Menu")
        }
        .buttonStyle(.borderless)
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
