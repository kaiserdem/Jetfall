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

    /// Planes after the starter reuse the same mesh and appear blurred in the shop.
    var showsPrototypeBlur: Bool {
        id > 1
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
        ShopPlane(id: 2, name: "Sparrow II", callSign: "INTERCEPTOR", requiredCompletedLevels: 10, creditCost: 2_500),
        ShopPlane(id: 3, name: "Thunderbolt", callSign: "STRIKE", requiredCompletedLevels: 20, creditCost: 5_000),
        ShopPlane(id: 4, name: "Corsair", callSign: "PATROL", requiredCompletedLevels: 30, creditCost: 7_500),
        ShopPlane(id: 5, name: "Phantom Wing", callSign: "STEALTH", requiredCompletedLevels: 40, creditCost: 10_000),
        ShopPlane(id: 6, name: "Viper Strike", callSign: "ASSAULT", requiredCompletedLevels: 50, creditCost: 12_500),
        ShopPlane(id: 7, name: "Atlas Heavy", callSign: "BOMBER", requiredCompletedLevels: 60, creditCost: 15_000),
        ShopPlane(id: 8, name: "Eclipse Jet", callSign: "RECON", requiredCompletedLevels: 70, creditCost: 17_500),
        ShopPlane(id: 9, name: "Nova Cruiser", callSign: "ELITE", requiredCompletedLevels: 80, creditCost: 20_000),
        ShopPlane(id: 10, name: "Apex Ace", callSign: "LEGEND", requiredCompletedLevels: 90, creditCost: 22_500)
    ]

    static func plane(for id: Int) -> ShopPlane? {
        all.first { $0.id == id }
    }
}
