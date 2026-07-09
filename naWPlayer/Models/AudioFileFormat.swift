import Foundation
import UniformTypeIdentifiers

enum AudioFileFormat: String, CaseIterable, Identifiable {
    case mp3
    case m4a
    case aac
    case wav
    case aiff
    case aif
    case caf
    case au
    case flac

    var id: String { rawValue }

    var fileExtension: String { rawValue }

    var defaultUTType: UTType {
        switch self {
        case .mp3:
            .mp3
        case .m4a:
            .mpeg4Audio
        case .aac:
            UTType(filenameExtension: "aac") ?? .mpeg4Audio
        case .wav:
            .wav
        case .aiff, .aif:
            .aiff
        case .caf:
            UTType(filenameExtension: "caf") ?? .audio
        case .au:
            UTType(filenameExtension: "au") ?? .audio
        case .flac:
            UTType(filenameExtension: "flac") ?? .audio
        }
    }

    static func from(url: URL) -> AudioFileFormat? {
        AudioFileFormat(rawValue: url.pathExtension.lowercased())
    }
}
