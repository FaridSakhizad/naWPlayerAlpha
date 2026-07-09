import SwiftUI

struct CompactPlayerToolbar: View {
    let selectedSection: AppSection
    let isLibraryEditing: Bool
    let onEditLibrary: () -> Void
    let onSortLibrary: () -> Void
    let onImportLibrary: () -> Void
    @Environment(\.playerTheme) private var theme

    var body: some View {
        if selectedSection == .library {
            HStack(spacing: 22) {
                Button(action: onEditLibrary) {
                    Image(systemName: isLibraryEditing ? "checkmark.circle" : "pencil.circle")
                        .frame(width: 38, height: 30)
                }
                .accessibilityLabel(isLibraryEditing ? "Done Editing" : "Edit Library")

                Button(action: onSortLibrary) {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .frame(width: 38, height: 30)
                }
                .accessibilityLabel("Sort Library")

                Button(action: onImportLibrary) {
                    Image(systemName: "square.and.arrow.down")
                        .frame(width: 38, height: 30)
                }
                .accessibilityLabel("Import Music")
            }
            .font(.title3)
            .foregroundStyle(theme.palette.accent)
        }
    }
}
