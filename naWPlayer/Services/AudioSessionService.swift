import AVFoundation
import Combine
import Foundation

enum AudioSessionInterruption {
    case began
    case ended(shouldResume: Bool)
    case unknown
}

enum AudioRouteChange {
    case oldDeviceUnavailable
}

final class AudioSessionService {
    private var observers: [AnyCancellable] = []

    func configure(
        onInterruption: @MainActor @escaping (AudioSessionInterruption) -> Void,
        onRouteChange: @MainActor @escaping (AudioRouteChange) -> Void
    ) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
        configureObservers(onInterruption: onInterruption, onRouteChange: onRouteChange)
    }

    func activate() throws {
        try AVAudioSession.sharedInstance().setActive(true)
    }

    func tearDown() {
        observers.removeAll()
    }

    private func configureObservers(
        onInterruption: @MainActor @escaping (AudioSessionInterruption) -> Void,
        onRouteChange: @MainActor @escaping (AudioRouteChange) -> Void
    ) {
        let center = NotificationCenter.default
        observers = [
            center.publisher(for: AVAudioSession.interruptionNotification)
                .sink { notification in
                    let event = Self.interruption(from: notification)
                    Task { @MainActor in onInterruption(event) }
                },
            center.publisher(for: AVAudioSession.routeChangeNotification)
                .sink { notification in
                    guard let event = Self.routeChange(from: notification) else { return }
                    Task { @MainActor in onRouteChange(event) }
                }
        ]
    }

    private static func interruption(from notification: Notification) -> AudioSessionInterruption {
        guard
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawType)
        else {
            return .unknown
        }

        switch type {
        case .began:
            return .began
        case .ended:
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            let shouldResume = rawOptions.map {
                AVAudioSession.InterruptionOptions(rawValue: $0).contains(.shouldResume)
            } ?? false
            return .ended(shouldResume: shouldResume)
        @unknown default:
            return .unknown
        }
    }

    private static func routeChange(from notification: Notification) -> AudioRouteChange? {
        guard
            let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason)
        else {
            return nil
        }

        return reason == .oldDeviceUnavailable ? .oldDeviceUnavailable : nil
    }
}
