import Foundation

final class MissionScoreTracker {

    private let calculator: ScoreCalculator
    private(set) var killPoints = 0

    init(level: Int) {
        calculator = ScoreCalculator(level: level)
    }

    var displayedScore: Int {
        killPoints
    }

    @discardableResult
    func recordKill() -> Int {
        let points = calculator.pointsPerKill
        killPoints += points
        return points
    }

    func finalize(fuelRemaining: TimeInterval, fuelTotal: TimeInterval, level: Int) -> MissionScoreResult {
        let bonus = calculator.fuelBonus(
            killPoints: killPoints,
            fuelRemaining: fuelRemaining,
            fuelTotal: fuelTotal
        )
        let saveOutcome = MissionScoreStore.saveScoreIfBest(
            killPoints + bonus,
            for: level
        )
        return MissionScoreResult(
            killPoints: killPoints,
            fuelBonus: bonus,
            bestScore: saveOutcome.bestScore,
            isNewBest: saveOutcome.isNewBest
        )
    }
}
