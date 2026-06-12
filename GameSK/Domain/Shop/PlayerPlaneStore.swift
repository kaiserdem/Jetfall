import Foundation

enum PlanePurchaseResult {
    case success
    case alreadyOwned
    case levelsNotMet
    case insufficientCredits
}

enum PlayerPlaneStore {

    private static let ownedKey = "gamesk.ownedPlaneIDs"
    private static let selectedKey = "gamesk.selectedPlaneID"

    static var ownedIDs: Set<Int> {
        get {
            if let stored = UserDefaults.standard.array(forKey: ownedKey) as? [Int], !stored.isEmpty {
                return Set(stored)
            }
            return [1]
        }
        set {
            UserDefaults.standard.set(Array(newValue).sorted(), forKey: ownedKey)
        }
    }

    static var selectedPlaneID: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: selectedKey)
            return stored == 0 ? 1 : stored
        }
        set {
            UserDefaults.standard.set(newValue, forKey: selectedKey)
        }
    }

    static var ownedCount: Int {
        ownedIDs.count
    }

    static func isOwned(_ planeID: Int) -> Bool {
        planeID == 1 || ownedIDs.contains(planeID)
    }

    static func isEquipped(_ planeID: Int) -> Bool {
        selectedPlaneID == planeID
    }

    @discardableResult
    static func purchase(_ plane: ShopPlane) -> PlanePurchaseResult {
        guard plane.id > 1 else { return .alreadyOwned }
        guard !isOwned(plane.id) else { return .alreadyOwned }
        guard plane.isLevelRequirementMet() else { return .levelsNotMet }
        guard plane.canAfford() else { return .insufficientCredits }
        guard PlayerWallet.spendCredits(plane.creditCost) else { return .insufficientCredits }

        var owned = ownedIDs
        owned.insert(plane.id)
        ownedIDs = owned
        return .success
    }

    @discardableResult
    static func equip(planeID: Int) -> Bool {
        guard isOwned(planeID) else { return false }
        selectedPlaneID = planeID
        return true
    }
}
