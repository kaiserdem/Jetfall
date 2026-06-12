import Foundation

struct LevelConfig {
    let number: Int
    let asteroidsToDestroy: Int
    let approachSpeed: Float
    let fuelDuration: TimeInterval
}

enum LevelConfigFactory {

    static let totalLevels = 100

    static func config(for level: Int) -> LevelConfig {
        let number = max(1, min(totalLevels, level))
        let progress = Float(number - 1) / Float(totalLevels - 1)

        let asteroidsToDestroy = 10 + Int(round(progress * 20))
        let approachSpeed = 24 + progress * 24
        let fuelDuration = TimeInterval(120 - Double(progress) * 50)

        return LevelConfig(
            number: number,
            asteroidsToDestroy: asteroidsToDestroy,
            approachSpeed: approachSpeed,
            fuelDuration: fuelDuration
        )
    }
}
