import Foundation

struct PlaybackQueue {
    private(set) var tracks: [AudioTrack] = []
    private(set) var currentIndex: Int?
    private var shuffledOrder: [Int] = []

    var currentTrack: AudioTrack? {
        guard let currentIndex, tracks.indices.contains(currentIndex) else { return nil }
        return tracks[currentIndex]
    }

    var isEmpty: Bool {
        tracks.isEmpty
    }

    mutating func setTracks(_ newTracks: [AudioTrack], startingAt index: Int?) {
        tracks = newTracks
        currentIndex = index.flatMap { newTracks.indices.contains($0) ? $0 : nil }
        shuffledOrder = []
    }

    mutating func setCurrentTrack(_ track: AudioTrack) {
        currentIndex = tracks.firstIndex(of: track)
    }

    mutating func nextIndex(shuffleEnabled: Bool, repeatMode: RepeatMode) -> Int? {
        guard !tracks.isEmpty else { return nil }
        if shuffleEnabled {
            return nextShuffleIndex()
        }
        if let currentIndex, currentIndex + 1 < tracks.count {
            return currentIndex + 1
        }
        if repeatMode == .all {
            return 0
        }
        return nil
    }

    mutating func previousIndex(repeatMode: RepeatMode) -> Int? {
        guard !tracks.isEmpty else { return nil }
        if let currentIndex, currentIndex > 0 {
            return currentIndex - 1
        }
        if repeatMode == .all {
            return tracks.count - 1
        }
        return currentIndex
    }

    mutating func moveItems(from source: IndexSet, to destination: Int, keeping currentTrack: AudioTrack?) {
        tracks.move(fromOffsets: source, toOffset: destination)
        if let currentTrack {
            currentIndex = tracks.firstIndex(of: currentTrack)
        }
        shuffledOrder = []
    }

    mutating func removeItems(at offsets: IndexSet) -> Bool {
        let activeTrack = currentTrack
        let removedCurrent = offsets.contains { index in
            guard tracks.indices.contains(index), let currentIndex else { return false }
            return index == currentIndex
        }
        tracks.remove(atOffsets: offsets)
        if removedCurrent {
            currentIndex = tracks.isEmpty ? nil : min(currentIndex ?? 0, tracks.count - 1)
        } else if let activeTrack {
            currentIndex = tracks.firstIndex(of: activeTrack)
        }
        shuffledOrder = []
        return removedCurrent
    }

    mutating func removeTracks(withIDs ids: Set<AudioTrack.ID>) -> Bool {
        guard !ids.isEmpty else { return false }
        let activeTrack = currentTrack
        let removedCurrent = activeTrack.map { ids.contains($0.id) } ?? false
        tracks.removeAll { ids.contains($0.id) }
        if removedCurrent {
            currentIndex = nil
        } else if let activeTrack {
            currentIndex = tracks.firstIndex(of: activeTrack)
        } else if tracks.isEmpty {
            currentIndex = nil
        } else {
            currentIndex = min(currentIndex ?? 0, tracks.count - 1)
        }
        shuffledOrder = []
        return removedCurrent
    }

    mutating func clear() {
        tracks.removeAll()
        currentIndex = nil
        shuffledOrder = []
    }

    private mutating func nextShuffleIndex() -> Int? {
        guard !tracks.isEmpty else { return nil }
        if shuffledOrder.isEmpty || shuffledOrder.count != tracks.count {
            shuffledOrder = Array(tracks.indices).shuffled()
        }
        if
            let currentIndex,
            let orderPosition = shuffledOrder.firstIndex(of: currentIndex),
            orderPosition + 1 < shuffledOrder.count
        {
            return shuffledOrder[orderPosition + 1]
        }
        shuffledOrder = Array(tracks.indices).shuffled()
        return shuffledOrder.first
    }
}
