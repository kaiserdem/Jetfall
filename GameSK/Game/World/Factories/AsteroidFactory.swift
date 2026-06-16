import SceneKit
import UIKit

enum AsteroidFactory {

    private static var templates: [String: SCNNode] = [:]

    private static let asteroidResourceNames = ["asteroid1", "asteroid2"]
    private static let targetSpan: Float = 2.4

    static func prepareTemplate() {
        for resourceName in asteroidResourceNames where templates[resourceName] == nil {
            if let template = loadTemplate(named: resourceName) {
                templates[resourceName] = template
            } else {
                #if DEBUG
                print("[AsteroidFactory] Failed to load \(resourceName).usdz")
                #endif
            }
        }
    }

    static func makeAsteroid() -> SCNNode? {
        prepareTemplate()

        let availableNames = asteroidResourceNames.filter { templates[$0] != nil }
        guard let resourceName = availableNames.randomElement(),
              let template = templates[resourceName] else {
            return nil
        }

        let asteroid = template.clone()
        asteroid.name = "enemy"
        return asteroid
    }

    static func makeTumbleAction() -> SCNAction {
        func signedAngle(_ range: ClosedRange<CGFloat>) -> CGFloat {
            let magnitude = CGFloat.random(in: range)
            return Bool.random() ? magnitude : -magnitude
        }

        let duration = Double.random(in: 3.0...7.0)
        let tumble = SCNAction.rotateBy(
            x: signedAngle(0.35...1.1),
            y: signedAngle(0.45...1.3),
            z: signedAngle(0.25...1.0),
            duration: duration
        )
        return .repeatForever(tumble)
    }

    private static let minSpawnDistance: Float = 200
    private static let maxSpawnDistance: Float = 450
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
        [230, 270, 310, 350, 390, 430]
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

    private static func loadTemplate(named resourceName: String) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "usdz"),
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
        normalizeScale(of: wrapper, targetSpan: targetSpan)

        #if DEBUG
        print("[AsteroidFactory] \(resourceName).usdz loaded")
        #endif

        return wrapper
    }

    private static func findModelNode(in scene: SCNScene) -> SCNNode {
        let preferredNames = ["Meshes", "Sketchfab_model", "GLTF_SceneRootNode"]
        for name in preferredNames {
            if let node = scene.rootNode.childNode(withName: name, recursively: true) {
                return node
            }
        }
        if let geometryNode = deepestGeometryNode(from: scene.rootNode) {
            return commonGeometryAncestor(for: geometryNode)
        }
        return scene.rootNode
    }

    private static func commonGeometryAncestor(for geometryNode: SCNNode) -> SCNNode {
        var candidate = geometryNode.parent ?? geometryNode
        while let parent = candidate.parent {
            let geometryChildren = parent.childNodes.filter { $0.geometry != nil || hasGeometry(in: $0) }
            if geometryChildren.count > 1 {
                return parent
            }
            candidate = parent
        }
        return candidate
    }

    private static func hasGeometry(in node: SCNNode) -> Bool {
        if node.geometry != nil { return true }
        return node.childNodes.contains { hasGeometry(in: $0) }
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
        let span = measuredSpan(of: node)
        guard span > 0.0001 else { return }
        let factor = targetSpan / span
        node.scale = SCNVector3(factor, factor, factor)
    }

    private static func measuredSpan(of node: SCNNode) -> Float {
        let (bboxMin, bboxMax) = node.boundingBox
        let direct = Swift.max(
            bboxMax.x - bboxMin.x,
            bboxMax.y - bboxMin.y,
            bboxMax.z - bboxMin.z
        )
        if direct > 0.0001 {
            return direct
        }
        let childSpans = node.childNodes.map { measuredSpan(of: $0) }
        return childSpans.max() ?? 0
    }

    private static func fixMaterials(in node: SCNNode) {
        if let geometry = node.geometry {
            geometry.materials = geometry.materials.map { material in
                let copy = material.copy() as? SCNMaterial ?? material
                copy.isDoubleSided = true
                copy.fillMode = .fill
                copy.lightingModel = .physicallyBased
                copy.transparencyMode = .default
                if copy.diffuse.contents == nil {
                    copy.diffuse.contents = UIColor(white: 0.55, alpha: 1)
                }
                return copy
            }
        }
        node.childNodes.forEach { fixMaterials(in: $0) }
    }
}
