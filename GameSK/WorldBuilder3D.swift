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

    static func makeCloud(at position: SCNVector3) -> SCNNode {
        let cloud = SCNNode()
        cloud.name = "cloud"

        let puffCount = Int.random(in: 3...5)
        for index in 0..<puffCount {
            let radius = CGFloat.random(in: 1.2...2.4)
            let plane = SCNPlane(width: radius * 2.2, height: radius * 1.4)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(white: 1, alpha: CGFloat.random(in: 0.55...0.8))
            material.isDoubleSided = true
            material.writesToDepthBuffer = false
            plane.materials = [material]

            let puff = SCNNode(geometry: plane)
            puff.position = SCNVector3(
                Float.random(in: -2.5...2.5),
                Float.random(in: -0.8...1.6),
                Float.random(in: -1.2...1.2)
            )
            puff.eulerAngles.y = Float.random(in: 0...(Float.pi * 2))

            let billboard = SCNBillboardConstraint()
            billboard.freeAxes = .Y
            puff.constraints = [billboard]
            cloud.addChildNode(puff)
        }

        cloud.position = position
        return cloud
    }

    static func randomCloudPosition(aheadOf playerZ: Float = 0) -> SCNVector3 {
        SCNVector3(
            Float.random(in: -14...14),
            Float.random(in: -4...10),
            playerZ + Float.random(in: 45...95)
        )
    }
}
