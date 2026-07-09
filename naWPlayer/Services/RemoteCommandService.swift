import Foundation
import MediaPlayer

final class RemoteCommandService {
    private var targets: [(command: MPRemoteCommand, target: Any)] = []

    func configure(
        play: @MainActor @escaping () -> Void,
        pause: @MainActor @escaping () -> Void,
        next: @MainActor @escaping () -> Void,
        previous: @MainActor @escaping () -> Void,
        seek: @MainActor @escaping (TimeInterval) -> Void
    ) {
        removeTargets()

        let center = MPRemoteCommandCenter.shared()
        register(center.playCommand) { _ in
            Task { @MainActor in play() }
            return .success
        }
        register(center.pauseCommand) { _ in
            Task { @MainActor in pause() }
            return .success
        }
        register(center.nextTrackCommand) { _ in
            Task { @MainActor in next() }
            return .success
        }
        register(center.previousTrackCommand) { _ in
            Task { @MainActor in previous() }
            return .success
        }
        center.changePlaybackPositionCommand.isEnabled = true
        register(center.changePlaybackPositionCommand) { event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            Task { @MainActor in seek(event.positionTime) }
            return .success
        }
    }

    func removeTargets() {
        for target in targets {
            target.command.removeTarget(target.target)
        }
        targets.removeAll()
    }

    private func register(
        _ command: MPRemoteCommand,
        handler: @escaping (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    ) {
        let target = command.addTarget(handler: handler)
        targets.append((command, target))
    }
}
