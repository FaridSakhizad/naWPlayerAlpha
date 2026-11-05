import SwiftUI

struct SeekHoldButton<Label: View>: View {
    enum Direction {
        case backward
        case forward

        var step: TimeInterval {
            switch self {
            case .backward:
                -4
            case .forward:
                4
            }
        }
    }

    let direction: Direction
    let tapAction: () -> Void
    @ViewBuilder let label: () -> Label
    @EnvironmentObject private var player: AudioPlayerService
    @State private var holdTask: Task<Void, Never>?
    @State private var didStartHolding = false

    var body: some View {
        label()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        startPressIfNeeded()
                    }
                    .onEnded { _ in
                        finishPress()
                    }
            )
            .onDisappear {
                cancelHold()
            }
    }

    private func startPressIfNeeded() {
        guard holdTask == nil else { return }
        didStartHolding = false
        holdTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                didStartHolding = true
                seekOneStep()
            }

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 120_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    seekOneStep()
                }
            }
        }
    }

    private func finishPress() {
        let shouldRunTapAction = !didStartHolding
        cancelHold()
        if shouldRunTapAction {
            tapAction()
        }
    }

    private func cancelHold() {
        holdTask?.cancel()
        holdTask = nil
        didStartHolding = false
    }

    private func seekOneStep() {
        guard let duration = player.currentTrack?.duration, duration > 0 else { return }
        let target = min(max(player.elapsed + direction.step, 0), duration)
        player.seek(to: target)
    }
}
