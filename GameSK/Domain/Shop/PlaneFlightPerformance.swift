import Foundation

enum PlaneFlightPerformance {
    /// Nominal in-sector cruise for a standard interceptor (~280 km/s).
    static let referenceCruiseKmPerSec: Float = 280

    /// Afterburner doubles forward cruise velocity.
    static let afterburnerSpeedMultiplier: Float = 2.0

    /// Afterburner raises fuel consumption by 40%.
    static let afterburnerFuelMultiplier: Float = 1.40

    static func cruiseFuelFlowKgPerSec(planeMultiplier: Float) -> Float {
        Float(cruiseVelocityKmPerSec(planeMultiplier: planeMultiplier)) * 0.14
    }

    static func afterburnerFuelFlowKgPerSec(planeMultiplier: Float) -> Float {
        cruiseFuelFlowKgPerSec(planeMultiplier: planeMultiplier) * afterburnerFuelMultiplier
    }

    static func cruiseVelocityKmPerSec(planeMultiplier: Float) -> Int {
        Int((referenceCruiseKmPerSec * planeMultiplier).rounded())
    }

    static func afterburnerVelocityKmPerSec(planeMultiplier: Float) -> Int {
        let cruise = referenceCruiseKmPerSec * planeMultiplier
        return Int((cruise * afterburnerSpeedMultiplier).rounded())
    }
}
