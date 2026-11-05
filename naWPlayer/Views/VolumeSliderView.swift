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
            Button {
                draftVolume = nil
                player.setVolume(0, persist: true)
            } label: {
                Image(systemName: player.volume == 0 ? "speaker.slash.fill" : "speaker.wave.1.fill")
                    .foregroundStyle(theme.palette.mutedText)
                    .frame(width: 22)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mute")

            PlayerTappableSlider(
                value: Binding(
                    get: { displayedVolume },
                    set: {
                        draftVolume = $0
                        player.setVolume(Float($0))
                    }
                ),
                range: 0...1,
                onEditingEnded: {
                    let finalVolume = Float(displayedVolume)
                    player.setVolume(finalVolume, persist: true)
                    draftVolume = nil
                }
            )

            Button {
                draftVolume = nil
                player.setVolume(1, persist: true)
            } label: {
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(theme.palette.mutedText)
                    .frame(width: 22)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Maximum Volume")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Volume")
    }
}

struct PlayerTappableSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var onEditingEnded: () -> Void = {}
    @Environment(\.playerTheme) private var theme

    private let thumbSize: CGFloat = 22
    private let trackHeight: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let fraction = normalizedFraction(for: value)
            let thumbX = max(0, width - thumbSize) * fraction

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(theme.palette.mutedText.opacity(0.28))
                    .frame(height: trackHeight)

                Capsule()
                    .fill(theme.palette.accent)
                    .frame(width: max(trackHeight, width * fraction), height: trackHeight)

                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
                    .offset(x: thumbX)
            }
            .frame(height: thumbSize)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        updateValue(locationX: gesture.location.x, width: width)
                    }
                    .onEnded { gesture in
                        updateValue(locationX: gesture.location.x, width: width)
                        onEditingEnded()
                    }
            )
        }
        .frame(height: thumbSize)
    }

    private func normalizedFraction(for value: Double) -> CGFloat {
        guard range.upperBound > range.lowerBound else { return 0 }
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        return CGFloat((clamped - range.lowerBound) / (range.upperBound - range.lowerBound))
    }

    private func updateValue(locationX: CGFloat, width: CGFloat) {
        let fraction = min(max(Double(locationX / max(width, 1)), 0), 1)
        value = range.lowerBound + (range.upperBound - range.lowerBound) * fraction
    }
}
