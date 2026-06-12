import Foundation

enum PlayerWallet {

    private static let balanceKey = "gamesk.hangarCredits"

    static var balance: Int {
        max(0, UserDefaults.standard.integer(forKey: balanceKey))
    }

    @discardableResult
    static func addCredits(_ amount: Int) -> Int {
        let earned = max(0, amount)
        guard earned > 0 else { return balance }
        let updated = balance + earned
        UserDefaults.standard.set(updated, forKey: balanceKey)
        return updated
    }

    @discardableResult
    static func spendCredits(_ amount: Int) -> Bool {
        let cost = max(0, amount)
        guard cost > 0, cost <= balance else { return false }
        UserDefaults.standard.set(balance - cost, forKey: balanceKey)
        return true
    }
}
