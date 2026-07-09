import SwiftUI

struct VolumeSliderView: View {
    @EnvironmentObject private var player: AudioPlayerService
    @Environment(\.playerTheme) private var theme
    @State private var draftVolume: Double?

    private var displayedVolume: Double {
        draftVolume ?? Double(player.volume)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: player.volume == 0 ? "speaker.slash.fill" : "speaker.wave.1.fill")
                .foregroundStyle(theme.palette.mutedText)
                .frame(width: 22)

            Slider(
                value: Binding(
                    get: { displayedVolume },
                    set: {
                        draftVolume = $0
                        player.setVolume(Float($0))
                    }
                ),
                in: 0...1,
                onEditingChanged: { isEditing in
                    if !isEditing {
                        let finalVolume = Float(displayedVolume)
                        player.setVolume(finalVolume, persist: true)
                        draftVolume = nil
                    }
                }
            )

            Image(systemName: "speaker.wave.3.fill")
                .foregroundStyle(theme.palette.mutedText)
                .frame(width: 22)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Volume")
    }
}
