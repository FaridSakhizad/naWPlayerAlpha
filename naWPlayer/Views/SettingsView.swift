import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var confirmClear = false
    // TODO: Re-enable when theme selection returns to the Settings UX.
    private let showsThemeSettings = false

    init(store: LibraryStore, player: AudioPlayerService, themeManager: ThemeManager) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(
            store: store,
            player: player,
            themeManager: themeManager
        ))
    }

    var body: some View {
        List {
            if showsThemeSettings {
                Section("Theme") {
                    Picker("Skin", selection: $themeManager.selectedTheme) {
                        ForEach(PlayerTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }

            Section("Library") {
                Picker("Add Music", selection: $viewModel.defaultImportMode) {
                    ForEach(DocumentImportService.ImportMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }

                Button(role: .destructive) {
                    confirmClear = true
                } label: {
                    Label("Clear Library", systemImage: "trash")
                }
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
