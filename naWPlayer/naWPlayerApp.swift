import SwiftUI

@main
struct naWPlayerApp: App {
    @StateObject private var store = LibraryStore()
    @StateObject private var player = AudioPlayerService()
    @StateObject private var themeManager = ThemeManager()

    init() {
        // TODO: Enable the "Audio, AirPlay, and Picture in Picture" background mode in Xcode Signing & Capabilities.
        // TODO: Test document picker access on a physical device with files from iCloud Drive and local storage.
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(player)
                .environmentObject(themeManager)
                .task {
                    player.attachStore(store)
                }
        }
    }
}
