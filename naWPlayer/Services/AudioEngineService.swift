import AVFoundation

enum AudioEngineServiceError: LocalizedError {
    case emptyFile

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            "The audio file has no playable samples."
        }
    }
}

final class AudioEngineService {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let eqNode = AVAudioUnitEQ(numberOfBands: EQPreset.bandFrequencies.count)
    private var audioFile: AVAudioFile?
    private var currentEngineFormat: AVAudioFormat?

    var volume: Float {
        get { playerNode.volume }
        set { playerNode.volume = newValue }
    }

    init() {
        configureEngine()
    }

    func play() {
        playerNode.play()
    }

    func pause() {
        playerNode.pause()
    }

    func stop() {
        playerNode.stop()
    }

    func tearDown() {
        playerNode.stop()
        engine.stop()
    }

    func schedule(
        file: AVAudioFile,
        format: AVAudioFormat,
        startTime: TimeInterval,
        startsPlayback: Bool,
        completion: @escaping () -> Void
    ) throws {
        audioFile = file
        playerNode.stop()
        try prepareEngineIfNeeded(for: format)

        let sampleRate = format.sampleRate
        let startFrame = AVAudioFramePosition(startTime * sampleRate)
        let availableFrames = max(0, file.length - startFrame)
        let frameCount = AVAudioFrameCount(min(Int64(UInt32.max), availableFrames))

        guard frameCount > 0 else {
            throw AudioEngineServiceError.emptyFile
        }

        playerNode.scheduleSegment(file, startingFrame: startFrame, frameCount: frameCount, at: nil) {
            completion()
        }

        if !engine.isRunning {
            try engine.start()
        }
        if startsPlayback {
            playerNode.play()
        }
    }

    func applyEQ(gains: [Float], isEnabled: Bool) {
        for (index, band) in eqNode.bands.enumerated() where gains.indices.contains(index) {
            band.gain = gains[index]
        }
        setEQEnabled(isEnabled)
    }

    func setEQEnabled(_ isEnabled: Bool) {
        for band in eqNode.bands {
            band.bypass = !isEnabled
        }
    }

    private func configureEngine() {
        engine.attach(playerNode)
        engine.attach(eqNode)
        for (index, band) in eqNode.bands.enumerated() {
            band.filterType = .parametric
            band.frequency = EQPreset.bandFrequencies[index]
            band.bandwidth = 0.8
            band.bypass = false
        }
    }

    private func prepareEngineIfNeeded(for format: AVAudioFormat) throws {
        let needsReconnect =
            currentEngineFormat?.sampleRate != format.sampleRate ||
            currentEngineFormat?.channelCount != format.channelCount

        if needsReconnect {
            engine.stop()
            engine.disconnectNodeOutput(playerNode)
            engine.disconnectNodeOutput(eqNode)
            engine.connect(playerNode, to: eqNode, format: format)
            engine.connect(eqNode, to: engine.mainMixerNode, format: format)
            currentEngineFormat = format
        }
    }
}
