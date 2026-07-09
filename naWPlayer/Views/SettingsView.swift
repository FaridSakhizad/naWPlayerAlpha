import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var confirmClear = false

    init(store: LibraryStore, player: AudioPlayerService, themeManager: ThemeManager) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(
            store: store,
            player: player,
            themeManager: themeManager
        ))
    }

    var body: some View {
        List {
            Section("Theme") {
                Picker("Skin", selection: $themeManager.selectedTheme) {
                    ForEach(PlayerTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.inline)
            }

            Section("Playback") {
                Toggle("Equalizer", isOn: Binding(
                    get: { viewModel.player.equalizerEnabled },
                    set: { viewModel.player.equalizerEnabled = $0 }
                ))
            }

            Section("Library") {
                Button(role: .destructive) {
                    confirmClear = true
                } label: {
                    Label("Clear Library", systemImage: "trash")
                }
            }

            Section("About") {
                LabeledContent("App", value: "naWPlayer")
                LabeledContent("Minimum iOS", value: "16+")
                Text("A local music player with queue-first controls, playlist editing, themes, lock screen metadata, and a 10-band equalizer.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Clear all imported tracks and playlists?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear Library", role: .destructive) {
                viewModel.clearLibrary()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
