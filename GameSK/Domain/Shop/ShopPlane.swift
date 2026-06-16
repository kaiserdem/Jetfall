import Foundation

struct ShopPlane: Equatable {
    let id: Int
    let name: String
    let callSign: String
    let requiredCompletedLevels: Int
    let creditCost: Int

    var requiredUnlockedLevel: Int {
        guard id > 1 else { return 1 }
        return (id - 1) * 10 + 1
    }

    /// Slots without a dedicated asset reuse plane1 and stay blurred in the hangar.
    var showsPrototypeBlur: Bool {
        id > 2
    }

    var modelResourceName: String {
        switch id {
        case 1: return "plane1"
        case 2: return "plane2"
        default: return "plane1"
        }
    }

    /// Applied to level cruise speed — starter is a bit slower, all others a bit faster.
    var cruiseSpeedMultiplier: Float {
        id == 1 ? 0.65 : 1.10
    }

    /// Display cruise velocity derived from the gameplay multiplier.
    var cruiseVelocityKmPerSec: Int {
        PlaneFlightPerformance.cruiseVelocityKmPerSec(planeMultiplier: cruiseSpeedMultiplier)
    }

    var afterburnerVelocityKmPerSec: Int {
        PlaneFlightPerformance.afterburnerVelocityKmPerSec(planeMultiplier: cruiseSpeedMultiplier)
    }

    func cruiseSpeedDetailText() -> String {
        let flightClass = id == 1 ? "patrol" : "intercept"
        return "Cruise velocity: \(cruiseVelocityKmPerSec) km/s · \(flightClass)"
    }

    func afterburnerDetailText() -> String {
        "Afterburner velocity: \(afterburnerVelocityKmPerSec) km/s"
    }

    func afterburnerFuelDetailText() -> String {
        let flow = PlaneFlightPerformance.afterburnerFuelFlowKgPerSec(planeMultiplier: cruiseSpeedMultiplier)
        let formatted = flow.formatted(.number.precision(.fractionLength(1)))
        return "Afterburner fuel flow: \(formatted) kg/s"
    }

    func aircraftSpecsText() -> String {
        "\(cruiseSpeedDetailText())\n\(afterburnerDetailText())\n\(afterburnerFuelDetailText())"
    }

    func isLevelRequirementMet() -> Bool {
        LevelProgressStore.highestUnlockedLevel >= requiredUnlockedLevel
    }

    func canAfford() -> Bool {
        PlayerWallet.balance >= creditCost
    }

    func unlockRequirementText() -> String {
        guard id > 1 else { return "Included with hangar" }
        return "Complete \(requiredCompletedLevels) sectors"
    }

    func priceText() -> String {
        guard creditCost > 0 else { return "Free" }
        return "\(creditCost.formatted()) credits"
    }
}

enum ShopPlaneCatalog {

    static let totalPlanes = 10

    static let all: [ShopPlane] = [
        ShopPlane(id: 1, name: "Scout Mk.I", callSign: "STARTER", requiredCompletedLevels: 0, creditCost: 0),
        ShopPlane(id: 2, name: "Sparrow II", callSign: "INTERCEPTOR", requiredCompletedLevels: 10, creditCost: 3_500),
        ShopPlane(id: 3, name: "Thunderbolt", callSign: "STRIKE", requiredCompletedLevels: 20, creditCost: 7_000),
        ShopPlane(id: 4, name: "Corsair", callSign: "PATROL", requiredCompletedLevels: 30, creditCost: 10_500),
        ShopPlane(id: 5, name: "Phantom Wing", callSign: "STEALTH", requiredCompletedLevels: 40, creditCost: 14_000),
        ShopPlane(id: 6, name: "Viper Strike", callSign: "ASSAULT", requiredCompletedLevels: 50, creditCost: 17_500),
        ShopPlane(id: 7, name: "Atlas Heavy", callSign: "BOMBER", requiredCompletedLevels: 60, creditCost: 21_000),
        ShopPlane(id: 8, name: "Eclipse Jet", callSign: "RECON", requiredCompletedLevels: 70, creditCost: 24_500),
        ShopPlane(id: 9, name: "Nova Cruiser", callSign: "ELITE", requiredCompletedLevels: 80, creditCost: 28_000),
        ShopPlane(id: 10, name: "Apex Ace", callSign: "LEGEND", requiredCompletedLevels: 90, creditCost: 31_500)
    ]

    static func plane(for id: Int) -> ShopPlane? {
        all.first { $0.id == id }
    }

    static func modelResourceName(for planeID: Int) -> String {
        plane(for: planeID)?.modelResourceName ?? "plane1"
    }

    static func cruiseSpeedMultiplier(for planeID: Int) -> Float {
        plane(for: planeID)?.cruiseSpeedMultiplier ?? 1
    }
}
