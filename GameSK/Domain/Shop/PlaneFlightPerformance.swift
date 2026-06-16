import Foundation

enum PlaneFlightPerformance {
    /// Nominal in-sector cruise for a standard interceptor (~280 km/s).
    static let referenceCruiseKmPerSec: Float = 280

    /// Afterburner doubles forward cruise velocity.
    static let afterburnerSpeedMultiplier: Float = 2.0

    /// Afterburner raises fuel consumption by 60%.
    static let afterburnerFuelMultiplier: Float = 1.60

    static func cruiseVelocityKmPerSec(planeMultiplier: Float) -> Int {
        Int((referenceCruiseKmPerSec * planeMultiplier).rounded())
    }

    static func afterburnerVelocityKmPerSec(planeMultiplier: Float) -> Int {
        let cruise = referenceCruiseKmPerSec * planeMultiplier
        return Int((cruise * afterburnerSpeedMultiplier).rounded())
    }
}
