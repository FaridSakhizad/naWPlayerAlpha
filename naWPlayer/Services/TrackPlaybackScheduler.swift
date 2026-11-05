import Foundation

@MainActor
final class TrackPlaybackScheduler {
    private let audioEngineService: AudioEngineService
    private var activeAccess: TrackFileAccess?

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
        activeAccess?.stop()
        activeAccess = nil

        let access = try TrackFileResolver(store: store).accessFile(for: track)
        let playable = try AudioCodecRegistry.shared.openPlayableFile(at: access.url)
        activeAccess = access
        try audioEngineService.schedule(
            file: playable.file,
            format: playable.format,
            startTime: startTime,
            startsPlayback: startsPlayback,
            completion: completion
        )
    }

    func stopAccessingCurrentFile() {
        activeAccess?.stop()
        activeAccess = nil
    }
}
