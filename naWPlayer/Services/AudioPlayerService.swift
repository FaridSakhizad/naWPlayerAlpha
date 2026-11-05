import Combine
import Foundation

@MainActor
final class AudioPlayerService: ObservableObject {
    @Published private(set) var currentTrack: AudioTrack?
    @Published private(set) var isPlaying = false
    @Published private(set) var playbackState: PlaybackState = .idle
    @Published var queue: [AudioTrack] = []
    @Published var currentIndex: Int?
    @Published var elapsed: TimeInterval = 0
    @Published var repeatMode: RepeatMode = .off
    @Published var shuffleEnabled = false
    @Published var equalizerEnabled = true {
        didSet { updateEQBypass() }
    }
    @Published var eqPreset: EQPreset = .flat
    @Published var eqGains: [Float] = EQPreset.flat.gains
    @Published var playbackError: String?
    @Published private(set) var playbackFailureReason: PlaybackFailureReason?
    @Published private(set) var volume: Float = 1.0

    private let audioEngineService = AudioEngineService()
    private let audioSessionService = AudioSessionService()
    private let nowPlayingService = NowPlayingService()
    private let remoteCommandService = RemoteCommandService()
    private let settingsStore = PlayerSettingsStore()
    private lazy var trackPlaybackScheduler = TrackPlaybackScheduler(audioEngineService: audioEngineService)
    private var timer: AnyCancellable?
    private var progressTracker = PlaybackProgressTracker()
    private var store: LibraryStore?
    private var playbackQueue = PlaybackQueue()
    private var playbackToken = UUID()
    private var wasPlayingBeforeInterruption = false

    init() {
        configureAudioSession()
        configureRemoteCommands()
        loadEQSettings()
        loadVolume()
        startTimer()
    }

    deinit {
        timer?.cancel()
        audioSessionService.tearDown()
        audioEngineService.tearDown()
        remoteCommandService.removeTargets()
    }

    func attachStore(_ store: LibraryStore) {
        self.store = store
    }

    func play(track: AudioTrack, in tracks: [AudioTrack]) {
        clearPlaybackFailure()
        playbackQueue.setTracks(tracks, startingAt: tracks.firstIndex(of: track))
        syncPublishedQueueState()
        startCurrentTrack()
    }

    func playQueue(_ tracks: [AudioTrack], startingAt index: Int = 0) {
        guard tracks.indices.contains(index) else { return }
        clearPlaybackFailure()
        playbackQueue.setTracks(tracks, startingAt: index)
        syncPublishedQueueState()
        startCurrentTrack()
    }

    func togglePlayPause() {
        isPlaying ? pause() : resume()
    }

    func setVolume(_ newVolume: Float, persist: Bool = false) {
        let clampedVolume = min(max(newVolume, 0), 1)
        guard abs(volume - clampedVolume) > 0.001 else {
            if persist {
                settingsStore.saveVolume(clampedVolume)
            }
            return
        }
        volume = clampedVolume
        audioEngineService.volume = clampedVolume
        if persist {
            settingsStore.saveVolume(clampedVolume)
        }
    }

    func dismissPlaybackError() {
        clearPlaybackFailure()
    }

    func pause() {
        guard isPlaying else { return }
        progressTracker.pause(at: elapsed)
        audioEngineService.pause()
        transitionToPaused()
    }

    func resume() {
        activateAudioSession()
        guard currentTrack != nil else {
            if !playbackQueue.isEmpty {
                if currentIndex == nil {
                    playbackQueue.setTracks(playbackQueue.tracks, startingAt: 0)
                    syncPublishedQueueState()
                }
                startCurrentTrack()
            } else if let tracks = store?.tracks, !tracks.isEmpty {
                playQueue(tracks, startingAt: 0)
            } else {
                playbackState = .idle
            }
            return
        }
        audioEngineService.play()
        progressTracker.start(at: elapsed)
        transitionToPlaying()
    }

    func stop() {
        playbackToken = UUID()
        audioEngineService.stop()
        trackPlaybackScheduler.stopAccessingCurrentFile()
        elapsed = 0
        progressTracker.stop()
        transitionToStopped()
    }

    func clearPlaybackContext() {
        stop()
        playbackQueue.clear()
        syncPublishedQueueState()
        currentTrack = nil
        elapsed = 0
        progressTracker.reset()
        playbackState = .idle
        updateNowPlaying()
    }

    func next() {
        guard let nextIndex = playbackQueue.nextIndex(shuffleEnabled: shuffleEnabled, repeatMode: repeatMode) else {
            stop()
            return
        }
        playbackQueue.setTracks(playbackQueue.tracks, startingAt: nextIndex)
        syncPublishedQueueState()
        startCurrentTrack()
    }

    func previous() {
        guard !playbackQueue.isEmpty else { return }
        if elapsed > 3 {
            seek(to: 0)
            return
        }
        guard let previousIndex = playbackQueue.previousIndex(repeatMode: repeatMode) else {
            seek(to: 0)
            return
        }
        playbackQueue.setTracks(playbackQueue.tracks, startingAt: previousIndex)
        syncPublishedQueueState()
        startCurrentTrack()
    }

    func seek(to time: TimeInterval) {
        guard let track = currentTrack else { return }
        schedule(track: track, startTime: max(0, min(time, track.duration)), startsPlayback: isPlaying)
    }

    func moveQueueItems(from source: IndexSet, to destination: Int) {
        playbackQueue.moveItems(from: source, to: destination, keeping: currentTrack)
        syncPublishedQueueState()
    }

    func removeQueueItems(at offsets: IndexSet) {
        let removedCurrent = playbackQueue.removeItems(at: offsets)
        syncPublishedQueueState()
        if removedCurrent {
            playbackQueue.isEmpty ? stop() : startCurrentTrack()
        }
    }

    func removeTracks(withIDs ids: Set<AudioTrack.ID>) {
        let removedCurrent = playbackQueue.removeTracks(withIDs: ids)
        syncPublishedQueueState()

        if removedCurrent {
            currentTrack = nil
            stop()
            return
        }
        updateNowPlaying()
    }

    func applyPreset(_ preset: EQPreset) {
        eqPreset = preset
        if preset != .custom {
            eqGains = preset.gains
        }
        applyEQ()
        saveEQSettings()
    }

    func setGain(_ gain: Float, band index: Int) {
        guard eqGains.indices.contains(index) else { return }
        eqGains[index] = gain
        eqPreset = .custom
        applyEQ()
        saveEQSettings()
    }

    private func startCurrentTrack() {
        guard let track = playbackQueue.currentTrack else { return }
        currentTrack = track
        elapsed = 0
        progressTracker.reset()
        syncPublishedQueueState()
        schedule(track: track, startTime: 0, startsPlayback: true)
    }

    private func schedule(track: AudioTrack, startTime: TimeInterval, startsPlayback: Bool = true) {
        guard let store else {
            setPlaybackFailure(.missingStore)
            return
        }
        playbackState = .loading
        do {
            activateAudioSession()
            playbackToken = UUID()
            let token = playbackToken
            currentTrack = track
            try trackPlaybackScheduler.schedule(track: track, startTime: startTime, store: store, startsPlayback: startsPlayback) { [weak self] in
                Task { @MainActor in
                    self?.trackDidFinish(token: token)
                }
            }
            elapsed = startTime
            clearPlaybackFailure()
            if startsPlayback {
                progressTracker.start(at: startTime)
                transitionToPlaying()
            } else {
                progressTracker.pause(at: startTime)
                transitionToPaused()
            }
        } catch {
            print("Playback failed: \(error)")
            playbackToken = UUID()
            isPlaying = false
            progressTracker.pause(at: elapsed)
            if PlaybackFailureMapper.shouldSilentlySkip(error) {
                skipUnavailableCurrentTrack()
                return
            }
            setPlaybackFailure(PlaybackFailureMapper.reason(for: error))
            updateNowPlaying()
        }
    }

    private func skipUnavailableCurrentTrack() {
        if let currentIndex = playbackQueue.currentIndex {
            _ = playbackQueue.removeItems(at: IndexSet(integer: currentIndex))
            syncPublishedQueueState()
        }

        clearPlaybackFailure()
        guard !playbackQueue.isEmpty else {
            currentTrack = nil
            elapsed = 0
            progressTracker.reset()
            playbackState = .idle
            updateNowPlaying()
            return
        }

        startCurrentTrack()
    }

    private func trackDidFinish(token: UUID) {
        guard isPlaying, token == playbackToken else { return }
        if repeatMode == .one, let track = currentTrack {
            schedule(track: track, startTime: 0, startsPlayback: true)
        } else {
            next()
        }
    }

    private func configureAudioSession() {
        do {
            try audioSessionService.configure(
                onInterruption: { [weak self] event in
                    self?.handleAudioSessionInterruption(event)
                },
                onRouteChange: { [weak self] event in
                    self?.handleAudioRouteChange(event)
                }
            )
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    private func handleAudioSessionInterruption(_ event: AudioSessionInterruption) {
        switch event {
        case .began:
            wasPlayingBeforeInterruption = isPlaying
            if isPlaying {
                pause()
            }
        case .ended(let shouldResume):
            activateAudioSession()
            guard wasPlayingBeforeInterruption, shouldResume else {
                wasPlayingBeforeInterruption = false
                updateNowPlaying()
                return
            }
            wasPlayingBeforeInterruption = false
            resume()
        case .unknown:
            wasPlayingBeforeInterruption = false
        }
    }

    private func handleAudioRouteChange(_ event: AudioRouteChange) {
        if event == .oldDeviceUnavailable, isPlaying {
            pause()
        }
    }

    private func activateAudioSession() {
        do {
            try audioSessionService.activate()
        } catch {
            print("Audio session activation failed: \(error)")
            setPlaybackFailure(.audioSessionUnavailable)
        }
    }

    private func setPlaybackFailure(_ reason: PlaybackFailureReason) {
        playbackFailureReason = reason
        playbackError = reason.message
        playbackState = .failed
    }

    private func clearPlaybackFailure() {
        playbackFailureReason = nil
        playbackError = nil
    }

    private func transitionToPlaying() {
        isPlaying = true
        playbackState = .playing
        updateNowPlaying()
    }

    private func transitionToPaused() {
        isPlaying = false
        playbackState = .paused
        updateNowPlaying()
    }

    private func transitionToStopped() {
        isPlaying = false
        playbackState = .stopped
        updateNowPlaying()
    }

    private func applyEQ() {
        audioEngineService.applyEQ(gains: eqGains, isEnabled: equalizerEnabled)
    }

    private func updateEQBypass() {
        audioEngineService.setEQEnabled(equalizerEnabled)
        settingsStore.saveEQEnabled(equalizerEnabled)
    }

    private func startTimer() {
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.isPlaying else { return }
                guard let elapsed = self.progressTracker.elapsed(duration: self.currentTrack?.duration) else { return }
                self.elapsed = elapsed
                self.updateNowPlaying()
            }
    }

    private func syncPublishedQueueState() {
        queue = playbackQueue.tracks
        currentIndex = playbackQueue.currentIndex
    }

    private func configureRemoteCommands() {
        remoteCommandService.configure(
            play: { [weak self] in self?.resume() },
            pause: { [weak self] in self?.pause() },
            next: { [weak self] in self?.next() },
            previous: { [weak self] in self?.previous() },
            seek: { [weak self] position in self?.seek(to: position) }
        )
    }

    private func updateNowPlaying() {
        nowPlayingService.update(track: currentTrack, isPlaying: isPlaying, elapsed: elapsed, store: store)
    }

    private func loadEQSettings() {
        let settings = settingsStore.loadEQSettings()
        equalizerEnabled = settings.isEnabled
        eqPreset = settings.preset
        eqGains = settings.gains
        applyEQ()
    }

    private func saveEQSettings() {
        settingsStore.saveEQPreset(eqPreset, gains: eqGains)
    }

    private func loadVolume() {
        volume = settingsStore.loadVolume()
        audioEngineService.volume = volume
    }
}
