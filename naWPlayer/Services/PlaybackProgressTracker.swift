import Foundation

struct PlaybackProgressTracker {
    private var trackStartDate: Date?
    private var seekOffset: TimeInterval = 0

    mutating func start(at offset: TimeInterval) {
        seekOffset = offset
        trackStartDate = Date()
    }

    mutating func pause(at elapsed: TimeInterval) {
        seekOffset = elapsed
        trackStartDate = nil
    }

    mutating func stop() {
        seekOffset = 0
        trackStartDate = nil
    }

    mutating func reset() {
        stop()
    }

    func elapsed(duration: TimeInterval?) -> TimeInterval? {
        guard let trackStartDate else { return nil }
        let elapsed = seekOffset + Date().timeIntervalSince(trackStartDate)
        guard let duration, duration > 0 else { return elapsed }
        return min(elapsed, duration)
    }
}
