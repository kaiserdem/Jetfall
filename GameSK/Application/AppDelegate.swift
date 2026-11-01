import UIKit

/// TEMP — remove before App Store submit.
/// Gives enough credits + sector unlock to buy Sparrow II (plane 2).
private enum TempHangarBoost {
    static let isEnabled = false
    static let credits = 5_000
    static let unlockedLevel = 11
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        applyTemporaryHangarBoostIfNeeded()
        GameAssetLoader.shared.beginPreloadingIfNeeded()
        GameAudioService.shared.prepare()
        return true
    }

    private func applyTemporaryHangarBoostIfNeeded() {
        guard TempHangarBoost.isEnabled else { return }

        if PlayerWallet.balance < TempHangarBoost.credits {
            UserDefaults.standard.set(TempHangarBoost.credits, forKey: "gamesk.hangarCredits")
        }
        if LevelProgressStore.highestUnlockedLevel < TempHangarBoost.unlockedLevel {
            LevelProgressStore.highestUnlockedLevel = TempHangarBoost.unlockedLevel
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

