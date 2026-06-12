import Foundation

struct ScoreCalculator {

    let level: Int

    var levelMultiplier: Double {
        1.0 + Double(max(1, level) - 1) * 0.02
    }

    var pointsPerKill: Int {
        Int(round(100.0 * levelMultiplier))
    }

    func fuelBonus(killPoints: Int, fuelRemaining: TimeInterval, fuelTotal: TimeInterval) -> Int {
        guard fuelTotal > 0, killPoints > 0 else { return 0 }
        let fraction = max(0, min(1, fuelRemaining / fuelTotal))
        return Int(round(Double(killPoints) * fraction * 0.5))
    }
}
