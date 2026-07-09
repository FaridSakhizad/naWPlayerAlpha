import Foundation

enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case stopped
    case failed
}

enum PlaybackFailureReason: Equatable {
    case audioSessionUnavailable
    case missingStore
    case missingFile
    case emptyFile
    case unsupportedOrDamagedFile

    var message: String {
        switch self {
        case .audioSessionUnavailable:
            "Audio playback is temporarily unavailable."
        case .missingStore:
            "Playback is not ready yet. Please try again."
        case .missingFile:
            "The audio file is missing from the app sandbox."
        case .emptyFile:
            "The audio file has no playable samples."
        case .unsupportedOrDamagedFile:
            "Could not play this track. The file may be unsupported, damaged, or unavailable."
        }
    }
}

enum PlaybackError: LocalizedError {
    case missingFile
    case emptyFile
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .missingFile:
            "The audio file is missing from the app sandbox."
        case .emptyFile:
            "The audio file has no playable samples."
        case .unsupportedFormat:
            "The audio file format is unsupported."
        }
    }
}

struct PlaybackFailureMapper {
    static func reason(for error: Error) -> PlaybackFailureReason {
        if let playbackError = error as? PlaybackError {
            switch playbackError {
            case .missingFile:
                return .missingFile
            case .emptyFile:
                return .emptyFile
            case .unsupportedFormat:
                return .unsupportedOrDamagedFile
            }
        }
        if let codecError = error as? AudioCodecError {
            switch codecError {
            case .emptyFile:
                return .emptyFile
            case .unsupportedExtension, .noCodec, .invalidFormat:
                return .unsupportedOrDamagedFile
            }
        }
        if let engineError = error as? AudioEngineServiceError {
            switch engineError {
            case .emptyFile:
                return .emptyFile
            }
        }
        return .unsupportedOrDamagedFile
    }
}
