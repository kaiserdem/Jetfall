import Foundation

enum FuelPickupConfig {
    static let refillFraction = 0.30
    static let refillBannerDuration: TimeInterval = 2
    static let minSpawnInterval: TimeInterval = 48
    static let maxSpawnInterval: TimeInterval = 72
    static let initialSpawnDelayRange: ClosedRange<TimeInterval> = 35...50
    static let collectionRadius: Float = 2.6
}
