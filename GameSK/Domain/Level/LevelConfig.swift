import Foundation

struct LevelConfig {
    let number: Int
    let asteroidsToDestroy: Int
    let hitsPerAsteroid: Int
    let approachSpeed: Float
    let fuelDuration: TimeInterval

    var startingAmmo: Int {
        asteroidsToDestroy * hitsPerAsteroid
    }
}

enum LevelConfigFactory {

    static let totalLevels = 100

    static func config(for level: Int) -> LevelConfig {
        let number = max(1, min(totalLevels, level))
        let progress = Float(number - 1) / Float(totalLevels - 1)

        let asteroidsToDestroy = targetsCount(for: number)
        let hitsPerAsteroid = hitsPerAsteroid(for: number)
        let approachSpeed = 24 + progress * 24
        let fuelDuration = TimeInterval(120 - Double(progress) * 50)

        return LevelConfig(
            number: number,
            asteroidsToDestroy: asteroidsToDestroy,
            hitsPerAsteroid: hitsPerAsteroid,
            approachSpeed: approachSpeed,
            fuelDuration: fuelDuration
        )
    }

    /// Level 1 → 10 targets, level 2 → 12, then +2 per level through 9, steeper growth from 10.
    private static func targetsCount(for level: Int) -> Int {
        if level <= 1 { return 10 }
        if level == 2 { return 12 }
        if level <= 9 { return 10 + (level - 1) * 2 }
        return 26 + (level - 9) * 4
    }

    /// One shot per asteroid on levels 1–9; two shots from level 10 onward.
    private static func hitsPerAsteroid(for level: Int) -> Int {
        level >= 10 ? 2 : 1
    }
}
