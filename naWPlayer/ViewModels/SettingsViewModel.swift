import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    let store: LibraryStore
    let player: AudioPlayerService
    let themeManager: ThemeManager
    @Published var defaultImportMode: DocumentImportService.ImportMode {
        didSet {
            settingsStore.saveDefaultImportMode(defaultImportMode)
        }
    }

    private let settingsStore: PlayerSettingsStore

    init(store: LibraryStore, player: AudioPlayerService, themeManager: ThemeManager) {
        let settingsStore = PlayerSettingsStore()
        self.store = store
        self.player = player
        self.themeManager = themeManager
        self.settingsStore = settingsStore
        self.defaultImportMode = settingsStore.loadDefaultImportMode()
    }

    func clearLibrary() {
        player.clearPlaybackContext()
        store.clearLibrary()
    }
}
