import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    let store: LibraryStore
    let player: AudioPlayerService
    let themeManager: ThemeManager

    init(store: LibraryStore, player: AudioPlayerService, themeManager: ThemeManager) {
        self.store = store
        self.player = player
        self.themeManager = themeManager
    }

    func clearLibrary() {
        player.clearPlaybackContext()
        store.clearLibrary()
    }
}
