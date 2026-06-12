import Foundation

enum MissionScoreStore {

    private static let keyPrefix = "gamesk.missionBestScore."

    struct SaveOutcome {
        let bestScore: Int
        let isNewBest: Bool
    }

    static func bestScore(for level: Int) -> Int {
        UserDefaults.standard.integer(forKey: key(for: level))
    }

    @discardableResult
    static func saveScoreIfBest(_ score: Int, for level: Int) -> SaveOutcome {
        let safeScore = max(0, score)
        let previousBest = bestScore(for: level)
        guard safeScore > previousBest else {
            return SaveOutcome(bestScore: previousBest, isNewBest: false)
        }
        UserDefaults.standard.set(safeScore, forKey: key(for: level))
        return SaveOutcome(bestScore: safeScore, isNewBest: true)
    }

    static func careerBest() -> (score: Int, level: Int)? {
        var topScore = 0
        var topLevel = 0

        for level in 1...LevelProgressStore.highestUnlockedLevel {
            let score = bestScore(for: level)
            if score > topScore {
                topScore = score
                topLevel = level
            }
        }

        guard topScore > 0 else { return nil }
        return (topScore, topLevel)
    }

    static func resetAll() {
        for level in 1...LevelConfigFactory.totalLevels {
            UserDefaults.standard.removeObject(forKey: key(for: level))
        }
    }

    private static func key(for level: Int) -> String {
        "\(keyPrefix)\(level)"
    }
}
