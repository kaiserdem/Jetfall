import Foundation

struct MissionScoreResult: Equatable {
    let killPoints: Int
    let fuelBonus: Int
    let bestScore: Int
    let isNewBest: Bool

    var total: Int {
        killPoints + fuelBonus
    }
}
