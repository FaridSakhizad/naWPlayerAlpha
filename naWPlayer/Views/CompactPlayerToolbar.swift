import SwiftUI

struct CompactPlayerToolbar: View {
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
    let hasActivePlaylist: Bool
    @Environment(\.playerTheme) private var theme

    var body: some View {
        if selectedSection == .library || (selectedSection == .playlist && hasActivePlaylist) {
            HStack(spacing: 22) {
                if selectedSection == .library {
                    Button(action: onEditLibrary) {
                        Image(systemName: isLibraryEditing ? "checkmark.circle" : "pencil.circle")
                            .frame(width: 38, height: 30)
                    }
                    .accessibilityLabel(isLibraryEditing ? "Done Editing" : "Edit Library")

                    if isLibraryEditing {
                        Button(action: onToggleMarkAllLibraryTracks) {
                            Image(systemName: areAllLibraryTracksMarked ? "xmark.circle" : "checkmark.circle")
                                .frame(width: 38, height: 30)
                        }
                        .accessibilityLabel(areAllLibraryTracksMarked ? "Clear Track Selection" : "Select All Tracks")

                        Button(action: onInvertLibraryTrackSelection) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .frame(width: 38, height: 30)
                        }
                        .accessibilityLabel("Invert Track Selection")

                        if markedLibraryTrackCount > 0 {
                            Button(action: onCreatePlaylistFromMarkedLibraryTracks) {
                                Image(systemName: "text.badge.plus")
                                    .frame(width: 38, height: 30)
                            }
                            .accessibilityLabel("Create Playlist from \(markedLibraryTrackCount) Selected Tracks")

                            Button(action: onDeleteMarkedLibraryTracks) {
                                Image(systemName: "trash.circle")
                                    .frame(width: 38, height: 30)
                            }
                            .accessibilityLabel("Delete \(markedLibraryTrackCount) Selected Tracks")
                        }
                    } else {
                        Button(action: onSortLibrary) {
                            Image(systemName: "arrow.up.arrow.down.circle")
                                .frame(width: 38, height: 30)
                        }
                        .accessibilityLabel("Sort Library")

                        Button(action: onAddMusic) {
                            Image(systemName: "square.and.arrow.down")
                                .frame(width: 38, height: 30)
                        }
                        .accessibilityLabel("Add Music")
                    }
                }

                if selectedSection == .playlist, hasActivePlaylist {
                    Button(action: onAddTrackToPlaylist) {
                        Image(systemName: "text.badge.plus")
                            .frame(width: 38, height: 30)
                    }
                    .accessibilityLabel("Add Track to Playlist")
                }

                if selectedSection == .playlist {
                    Button(action: onAddMusic) {
                        Image(systemName: "square.and.arrow.down")
                            .frame(width: 38, height: 30)
                    }
                    .accessibilityLabel("Add Music")
                }
            }
            .font(.title3)
            .foregroundStyle(theme.palette.accent)
        }
    }
}
