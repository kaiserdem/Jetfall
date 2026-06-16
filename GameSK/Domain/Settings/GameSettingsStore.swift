import Foundation

extension Notification.Name {
    static let gameSettingsDidChange = Notification.Name("gamesk.settingsDidChange")
}

enum GameSettingsStore {

    private static let planeSizeKey = "gamesk.planeSizeMultiplier"
    private static let crosshairKey = "gamesk.crosshairEnabled"
    private static let soundKey = "gamesk.soundEnabled"

    static let planeSizeRange: ClosedRange<Float> = 0.45...1.1
    static let defaultPlaneSizeMultiplier: Float = 0.9

    static var planeSizeMultiplier: Float {
        get {
            guard UserDefaults.standard.object(forKey: planeSizeKey) != nil else {
                return defaultPlaneSizeMultiplier
            }
            let stored = Float(UserDefaults.standard.double(forKey: planeSizeKey))
            return clampPlaneSize(stored)
        }
        set {
            UserDefaults.standard.set(Double(clampPlaneSize(newValue)), forKey: planeSizeKey)
            postChange()
        }
    }

    static var isCrosshairEnabled: Bool {
        get {
            guard UserDefaults.standard.object(forKey: crosshairKey) != nil else {
                return true
            }
            return UserDefaults.standard.bool(forKey: crosshairKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: crosshairKey)
            postChange()
        }
    }

    static var isSoundEnabled: Bool {
        get {
            guard UserDefaults.standard.object(forKey: soundKey) != nil else {
                return true
            }
            return UserDefaults.standard.bool(forKey: soundKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: soundKey)
            postChange()
        }
    }

    static func planeSizePercentText(for multiplier: Float) -> String {
        "\(Int((multiplier * 100).rounded()))%"
    }

    private static func clampPlaneSize(_ value: Float) -> Float {
        min(planeSizeRange.upperBound, max(planeSizeRange.lowerBound, value))
    }

    private static func postChange() {
        NotificationCenter.default.post(name: .gameSettingsDidChange, object: nil)
    }
}
