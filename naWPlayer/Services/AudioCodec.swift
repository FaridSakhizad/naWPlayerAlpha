import AVFoundation
import Foundation

struct PlayableAudioFile {
    let file: AVAudioFile
    let format: AVAudioFormat

    var frameLength: AVAudioFramePosition {
        file.length
    }
}

protocol AudioCodec {
    var id: String { get }
    var supportedFormats: Set<AudioFileFormat> { get }

    func canHandle(format: AudioFileFormat) -> Bool
    func openPlayableFile(at url: URL) throws -> PlayableAudioFile
    func validateFile(at url: URL) throws
}

extension AudioCodec {
    func canHandle(format: AudioFileFormat) -> Bool {
        supportedFormats.contains(format)
    }

    func validateFile(at url: URL) throws {
        let playable = try openPlayableFile(at: url)
        guard playable.frameLength > 0 else {
            throw AudioCodecError.emptyFile
        }
    }
}

enum AudioCodecError: LocalizedError {
    case unsupportedExtension(String)
    case noCodec(AudioFileFormat)
    case emptyFile
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .unsupportedExtension(let ext):
            "No audio format is registered for .\(ext)."
        case .noCodec(let format):
            "No codec is registered for .\(format.fileExtension)."
        case .emptyFile:
            "The audio file has no playable samples."
        case .invalidFormat:
            "The audio file format is invalid or unsupported."
        }
    }
}

struct NativeAVAudioCodec: AudioCodec {
    let id = "native-avfoundation"
    let supportedFormats: Set<AudioFileFormat> = [
        .mp3,
        .m4a,
        .aac,
        .wav,
        .aiff,
        .aif,
        .caf,
        .au,
        .flac
    ]

    func openPlayableFile(at url: URL) throws -> PlayableAudioFile {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw AudioCodecError.invalidFormat
        }
        return PlayableAudioFile(file: file, format: format)
    }
}

struct AudioCodecRegistry {
    static let shared = AudioCodecRegistry(codecs: [
        NativeAVAudioCodec()
    ])

    let codecs: [AudioCodec]

    var supportedFormats: [AudioFileFormat] {
        let formats = Set(codecs.flatMap(\.supportedFormats))
        return AudioFileFormat.allCases.filter { formats.contains($0) }
    }

    func codec(for url: URL) throws -> AudioCodec {
        let ext = url.pathExtension.lowercased()
        guard let format = AudioFileFormat(rawValue: ext) else {
            throw AudioCodecError.unsupportedExtension(ext.isEmpty ? "unknown" : ext)
        }
        guard let codec = codecs.first(where: { $0.canHandle(format: format) }) else {
            throw AudioCodecError.noCodec(format)
        }
        return codec
    }

    func openPlayableFile(at url: URL) throws -> PlayableAudioFile {
        try codec(for: url).openPlayableFile(at: url)
    }

    func validateFile(at url: URL) throws {
        try codec(for: url).validateFile(at: url)
    }
}
