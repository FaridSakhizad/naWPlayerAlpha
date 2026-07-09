import SwiftUI

struct EqualizerView: View {
    @EnvironmentObject private var player: AudioPlayerService
    @Environment(\.playerTheme) private var theme

    var body: some View {
        List {
            Section {
                Toggle("Enabled", isOn: $player.equalizerEnabled)
                Picker("Preset", selection: Binding(
                    get: { player.eqPreset },
                    set: { player.applyPreset($0) }
                )) {
                    ForEach(EQPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
            }

            Section("10-Band Equalizer") {
                ForEach(EQPreset.bandFrequencies.indices, id: \.self) { index in
                    HStack(spacing: 12) {
                        Text(label(for: EQPreset.bandFrequencies[index]))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(theme.palette.mutedText)
                            .frame(width: 38, alignment: .leading)

                        Slider(
                            value: Binding(
                                get: { Double(player.eqGains[index]) },
                                set: { player.setGain(Float($0), band: index) }
                            ),
                            in: -12...12,
                            step: 1
                        )

                        Text("\(Int(player.eqGains[index]))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(theme.palette.mutedText)
                            .frame(width: 28, alignment: .trailing)
                    }
                }
            }
        }
        .navigationTitle("Equalizer")
    }

    private func label(for frequency: Float) -> String {
        frequency >= 1_000 ? "\(Int(frequency / 1_000))k" : "\(Int(frequency))"
    }
}
