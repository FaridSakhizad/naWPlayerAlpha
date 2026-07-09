import SwiftUI

struct ArtworkView: View {
    let track: AudioTrack?
    let store: LibraryStore
    var size: CGFloat = 64

    var body: some View {
        Group {
            if
                let track,
                let url = store.artworkURL(for: track),
                let image = UIImage(contentsOfFile: url.path)
            {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "waveform")
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: size, height: size)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
