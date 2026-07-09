import Foundation

struct EQSettings {
    var isEnabled: Bool
    var preset: EQPreset
    var gains: [Float]
}

struct PlayerSettingsStore {
    private enum Key {
        static let equalizerEnabled = "equalizerEnabled"
        static let eqPreset = "eqPreset"
        static let eqGains = "eqGains"
        static let playerVolume = "playerVolume"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadEQSettings() -> EQSettings {
        let isEnabled = userDefaults.object(forKey: Key.equalizerEnabled) as? Bool ?? true
        let preset = userDefaults
            .string(forKey: Key.eqPreset)
            .flatMap(EQPreset.init(rawValue:)) ?? .flat
        let savedGains = userDefaults.array(forKey: Key.eqGains) as? [Float]
        let gains: [Float]
        if let savedGains, savedGains.count == EQPreset.bandFrequencies.count {
            gains = savedGains
        } else {
            gains = preset.gains
        }
        return EQSettings(isEnabled: isEnabled, preset: preset, gains: gains)
    }

    func saveEQEnabled(_ isEnabled: Bool) {
        userDefaults.set(isEnabled, forKey: Key.equalizerEnabled)
    }

    func saveEQPreset(_ preset: EQPreset, gains: [Float]) {
        userDefaults.set(preset.rawValue, forKey: Key.eqPreset)
        userDefaults.set(gains, forKey: Key.eqGains)
    }

    func loadVolume(default defaultVolume: Float = 1.0) -> Float {
        guard userDefaults.object(forKey: Key.playerVolume) != nil else {
            return defaultVolume
        }
        return min(max(userDefaults.float(forKey: Key.playerVolume), 0), 1)
    }

    func saveVolume(_ volume: Float) {
        userDefaults.set(min(max(volume, 0), 1), forKey: Key.playerVolume)
    }
}
