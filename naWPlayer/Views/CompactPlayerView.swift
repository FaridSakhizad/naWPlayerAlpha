import SwiftUI

struct CompactPlayerView: View {
    let selectedSection: AppSection
    let isLibraryEditing: Bool
    let onEditLibrary: () -> Void
    let onSortLibrary: () -> Void
    let onImportLibrary: () -> Void
    let onMenu: () -> Void
    let onSearch: () -> Void
    @EnvironmentObject private var player: AudioPlayerService
    @State private var isShowingPlayer = false

    var body: some View {
        VStack(spacing: 12) {
            CompactPlayerToolbar(
                selectedSection: selectedSection,
                isLibraryEditing: isLibraryEditing,
                onEditLibrary: onEditLibrary,
                onSortLibrary: onSortLibrary,
                onImportLibrary: onImportLibrary
            )

            VolumeSliderView()

            CompactTrackTitleView(track: player.currentTrack) {
                isShowingPlayer = true
            }

            CompactSeekBarView()

            CompactTransportControls(onMenu: onMenu, onSearch: onSearch)
        }
        .playerPanel()
        .sheet(isPresented: $isShowingPlayer) {
            NavigationStack {
                PlayerView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                isShowingPlayer = false
                            }
                        }
                    }
            }
        }
    }
}
