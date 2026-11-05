import SwiftUI

struct CompactPlayerView: View {
    let selectedSection: AppSection
    let isLibraryEditing: Bool
    let onEditLibrary: () -> Void
    let markedLibraryTrackCount: Int
    let areAllLibraryTracksMarked: Bool
    let onToggleMarkAllLibraryTracks: () -> Void
    let onInvertLibraryTrackSelection: () -> Void
    let onCreatePlaylistFromMarkedLibraryTracks: () -> Void
    let onDeleteMarkedLibraryTracks: () -> Void
    let onSortLibrary: () -> Void
    let onAddMusic: () -> Void
    let onAddTrackToPlaylist: () -> Void
    let onMenu: () -> Void
    let onSearch: () -> Void
    let onFocusCurrentTrack: () -> Void
    let hasActivePlaylist: Bool
    @EnvironmentObject private var player: AudioPlayerService

    var body: some View {
        VStack(spacing: 12) {
            CompactPlayerToolbar(
                selectedSection: selectedSection,
                isLibraryEditing: isLibraryEditing,
                onEditLibrary: onEditLibrary,
                markedLibraryTrackCount: markedLibraryTrackCount,
                areAllLibraryTracksMarked: areAllLibraryTracksMarked,
                onToggleMarkAllLibraryTracks: onToggleMarkAllLibraryTracks,
                onInvertLibraryTrackSelection: onInvertLibraryTrackSelection,
                onCreatePlaylistFromMarkedLibraryTracks: onCreatePlaylistFromMarkedLibraryTracks,
                onDeleteMarkedLibraryTracks: onDeleteMarkedLibraryTracks,
                onSortLibrary: onSortLibrary,
                onAddMusic: onAddMusic,
                onAddTrackToPlaylist: onAddTrackToPlaylist,
                hasActivePlaylist: hasActivePlaylist
            )

            VolumeSliderView()

            CompactTrackTitleView(track: player.currentTrack) {
                onFocusCurrentTrack()
            }

            CompactSeekBarView()

            CompactTransportControls(onMenu: onMenu, onSearch: onSearch)
        }
        .playerPanel()
    }
}
