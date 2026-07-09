import MediaPlayer
import UIKit

@MainActor
final class NowPlayingService {
    func update(track: AudioTrack?, isPlaying: Bool, elapsed: TimeInterval, store: LibraryStore?) {
        guard let track else {
            clear()
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.album,
            MPMediaItemPropertyPlaybackDuration: track.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        if
            let store,
            let artworkURL = store.artworkURL(for: track),
            let image = UIImage(contentsOfFile: artworkURL.path)
        {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func clear() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
