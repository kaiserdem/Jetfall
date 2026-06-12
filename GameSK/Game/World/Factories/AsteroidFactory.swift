import SceneKit
import UIKit

enum AsteroidFactory {

    private static var template: SCNNode?

    static func prepareTemplate() {
        if template == nil {
            template = loadTemplate()
        }
    }

    static func makeAsteroid() -> SCNNode? {
        prepareTemplate()
        guard let template else { return nil }

        let asteroid = template.clone()
        asteroid.name = "enemy"
        return asteroid
    }

    private static let minSpawnDistance: Float = 150
    private static let maxSpawnDistance: Float = 340
    private static let cameraVerticalFOV: Float = 58 * .pi / 180
    private static let screenAspect: Float = 9.0 / 19.5

    static func spawnPosition(
        near playerPosition: SCNVector3,
        preferredDistance: Float? = nil,
        avoiding otherAsteroids: [SCNNode] = []
    ) -> SCNVector3 {
        for _ in 0..<16 {
            let distance = preferredDistance ?? Float.random(in: minSpawnDistance...maxSpawnDistance)
            let spread = visibleSpread(at: distance)
            let candidate = SCNVector3(
                playerPosition.x + Float.random(in: -spread.x...spread.x),
                playerPosition.y + Float.random(in: -spread.y...spread.y),
                playerPosition.z + distance
            )

            if isSeparated(from: otherAsteroids, candidate: candidate, spread: spread) {
                return candidate
            }
        }

        let fallbackDistance = preferredDistance ?? Float.random(in: minSpawnDistance...maxSpawnDistance)
        let spread = visibleSpread(at: fallbackDistance)
        return SCNVector3(
            playerPosition.x + Float.random(in: -spread.x...spread.x),
            playerPosition.y + Float.random(in: -spread.y...spread.y),
            playerPosition.z + fallbackDistance
        )
    }

    private static func visibleSpread(at distance: Float) -> (x: Float, y: Float) {
        let horizontalFOV = 2 * atan(tan(cameraVerticalFOV / 2) * screenAspect)
        let halfWidth = distance * tan(horizontalFOV / 2)
        let halfHeight = distance * tan(cameraVerticalFOV / 2)
        return (x: halfWidth * 0.92, y: halfHeight * 0.45)
    }

    static func initialSpawnDistances() -> [Float] {
        [170, 200, 230, 260, 290, 320]
    }

    private static func isSeparated(
        from asteroids: [SCNNode],
        candidate: SCNVector3,
        spread: (x: Float, y: Float)
    ) -> Bool {
        let minHorizontalSeparation = max(10, spread.x * 0.22)
        let minDepthSeparation: Float = 45

        for asteroid in asteroids {
            let delta = SCNVector3(
                candidate.x - asteroid.position.x,
                candidate.y - asteroid.position.y,
                candidate.z - asteroid.position.z
            )
            let horizontalDistance = hypot(delta.x, delta.y)
            let depthDistance = abs(delta.z)
            if horizontalDistance < minHorizontalSeparation, depthDistance < minDepthSeparation {
                return false
            }
        }
        return true
    }

    private static func loadTemplate() -> SCNNode? {
        guard let url = Bundle.main.url(forResource: "Asteroid", withExtension: "usdz"),
              let scene = try? SCNScene(url: url, options: [.convertToYUp: true]) else {
            return nil
        }

        let source = findModelNode(in: scene)
        source.removeFromParentNode()
        source.transform = SCNMatrix4Identity
        fixMaterials(in: source)

        let wrapper = SCNNode()
        wrapper.addChildNode(source)
        centerNode(source)
        normalizeScale(of: wrapper, targetSpan: 2.4)

        #if DEBUG
        print("[AsteroidFactory] Asteroid.usdz loaded")
        #endif

        return wrapper
    }

    private static func findModelNode(in scene: SCNScene) -> SCNNode {
        if let geometryNode = deepestGeometryNode(from: scene.rootNode) {
            return geometryNode.parent ?? geometryNode
        }
        return scene.rootNode
    }

    private static func deepestGeometryNode(from node: SCNNode) -> SCNNode? {
        if node.geometry != nil, node.childNodes.isEmpty {
            return node
        }
        for child in node.childNodes {
            if let found = deepestGeometryNode(from: child) {
                return found
            }
        }
        return nil
    }

    private static func centerNode(_ node: SCNNode) {
        let (min, max) = node.boundingBox
        let center = SCNVector3(
            (min.x + max.x) * 0.5,
            (min.y + max.y) * 0.5,
            (min.z + max.z) * 0.5
        )
        node.position = SCNVector3(-center.x, -center.y, -center.z)
    }

    private static func normalizeScale(of node: SCNNode, targetSpan: Float) {
        let (bboxMin, bboxMax) = node.boundingBox
        let span = Swift.max(
            bboxMax.x - bboxMin.x,
            bboxMax.y - bboxMin.y,
            bboxMax.z - bboxMin.z
        )
        guard span > 0 else { return }
        let factor = targetSpan / span
        node.scale = SCNVector3(factor, factor, factor)
    }

    private static func fixMaterials(in node: SCNNode) {
        if let geometry = node.geometry {
            geometry.materials = geometry.materials.map { material in
                let copy = material.copy() as? SCNMaterial ?? material
                copy.isDoubleSided = true
                if copy.diffuse.contents == nil {
                    copy.diffuse.contents = UIColor(white: 0.55, alpha: 1)
                }
                copy.lightingModel = .physicallyBased
                return copy
            }
        }
        node.childNodes.forEach { fixMaterials(in: $0) }
    }
}
