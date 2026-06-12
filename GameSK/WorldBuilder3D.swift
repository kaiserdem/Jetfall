import SceneKit
import UIKit

enum WorldBuilder3D {

    private static let skyColor = UIColor(red: 0.45, green: 0.72, blue: 0.95, alpha: 1)

    static func configureEnvironment(for scene: SCNScene) {
        scene.background.contents = skyColor
        scene.fogColor = skyColor
        scene.fogStartDistance = 35
        scene.fogEndDistance = 110
        scene.fogDensityExponent = 1.2
    }
}
