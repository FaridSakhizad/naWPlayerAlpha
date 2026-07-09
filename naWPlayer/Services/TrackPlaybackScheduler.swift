import Foundation

@MainActor
final class TrackPlaybackScheduler {
    private let audioEngineService: AudioEngineService

    init(audioEngineService: AudioEngineService) {
        self.audioEngineService = audioEngineService
    }

    func schedule(
        track: AudioTrack,
        startTime: TimeInterval,
        store: LibraryStore,
        startsPlayback: Bool,
        completion: @escaping () -> Void
    ) throws {
        let url = store.fileURL(for: track)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PlaybackError.missingFile
        }

        let playable = try AudioCodecRegistry.shared.openPlayableFile(at: url)
        try audioEngineService.schedule(
            file: playable.file,
            format: playable.format,
            startTime: startTime,
            startsPlayback: startsPlayback,
            completion: completion
        )
    }
}
