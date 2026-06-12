import Foundation
import UIKit

final class GameAssetLoader {

    static let shared = GameAssetLoader()

    private(set) var isReady = false
    private var isLoading = false
    private var readyHandlers: [() -> Void] = []
    private let lock = NSLock()

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
            let starsImage = WorldBuilder3D.buildStarsTextureImage()
            Plane3DFactory.prepareFlightPlane()
            AsteroidFactory.prepareTemplate()

            DispatchQueue.main.async {
                WorldBuilder3D.installStarsTexture(starsImage)
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
}
