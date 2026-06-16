import Foundation
import UIKit

final class GameAssetLoader {

    static let shared = GameAssetLoader()

    private(set) var isReady = false
    private var isLoading = false
    private var readyHandlers: [() -> Void] = []
    private let lock = NSLock()

    var onProgress: ((CGFloat) -> Void)? {
        didSet {
            guard let onProgress else { return }
            lock.lock()
            let current = isReady ? CGFloat(1) : CGFloat(0)
            lock.unlock()
            if current > 0 {
                DispatchQueue.main.async { onProgress(current) }
            }
        }
    }

    private init() {}

    func beginPreloadingIfNeeded() {
        lock.lock()
        guard !isReady, !isLoading else {
            lock.unlock()
            return
        }
        isLoading = true
        lock.unlock()

        DispatchQueue.global(qos: .userInitiated).async {
            self.reportProgress(0.22)
            let starsImage = WorldBuilder3D.buildStarsTextureImage()

            self.reportProgress(0.48)
            Plane3DFactory.prepareFlightPlane()

            self.reportProgress(0.74)
            AsteroidFactory.prepareTemplate()
            FuelPickupFactory.prepareTemplate()
            AmmunitionPickupFactory.prepareTemplate()

            self.reportProgress(0.9)

            DispatchQueue.main.async {
                WorldBuilder3D.installStarsTexture(starsImage)
                AmmunitionPickupFactory.prepareHUDIcon()
                AsteroidFactory.prepareHUDIcon()
                FuelPickupFactory.prepareHUDIcon()
                self.reportProgress(1)
                self.finishLoading()
            }
        }
    }

    func whenReady(_ handler: @escaping () -> Void) {
        lock.lock()
        if isReady {
            lock.unlock()
            DispatchQueue.main.async(execute: handler)
            return
        }
        readyHandlers.append(handler)
        lock.unlock()
        beginPreloadingIfNeeded()
    }

    private func finishLoading() {
        lock.lock()
        isReady = true
        isLoading = false
        let handlers = readyHandlers
        readyHandlers = []
        lock.unlock()
        handlers.forEach { $0() }
    }

    private func reportProgress(_ value: CGFloat) {
        let clamped = max(0, min(1, value))
        DispatchQueue.main.async {
            self.onProgress?(clamped)
        }
    }
}
