import Foundation

enum AmmunitionPickupConfig {
    static let refillFraction = 0.30
    static let pickupBannerDuration: TimeInterval = 2
    static let lowAmmoThreshold = 5
    static let maxOnScreen = 3
    static let asteroidPairedSpawnChance = 0.42
    static let spawnCooldownRange: ClosedRange<TimeInterval> = 18...28
    static let initialSpawnCooldownRange: ClosedRange<TimeInterval> = 24...36
    static let backgroundSpawnDelayRange: ClosedRange<TimeInterval> = 34...48
    static let lowAmmoSpawnDelayRange: ClosedRange<TimeInterval> = 6...10
    static let missedRetryRange: ClosedRange<TimeInterval> = 14...22
    static let collectionRadius: Float = 2.6
}
