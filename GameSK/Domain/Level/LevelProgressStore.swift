import Foundation

enum LevelProgressStore {

    private static let unlockedLevelKey = "gamesk.highestUnlockedLevel"

    static var highestUnlockedLevel: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: unlockedLevelKey)
            return max(1, stored == 0 ? 1 : stored)
        }
        set {
            UserDefaults.standard.set(max(1, min(LevelConfigFactory.totalLevels, newValue)), forKey: unlockedLevelKey)
        }
    }

    static func isUnlocked(_ level: Int) -> Bool {
        level >= 1 && level <= highestUnlockedLevel
    }

    static func unlockNext(after completedLevel: Int) {
        let next = completedLevel + 1
        guard next <= LevelConfigFactory.totalLevels else { return }
        if next > highestUnlockedLevel {
            highestUnlockedLevel = next
        }
    }

    static func resetProgress() {
        highestUnlockedLevel = 1
    }
}
