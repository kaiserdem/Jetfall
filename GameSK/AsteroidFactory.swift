import SceneKit
import UIKit

enum AsteroidFactory {

    private static var template: SCNNode?

    static func makeAsteroid() -> SCNNode? {
        if template == nil {
            template = loadTemplate()
        }
        guard let template else { return nil }

        let asteroid = template.clone()
        asteroid.name = "enemy"
        return asteroid
    }

    static func randomSpawnPosition() -> SCNVector3 {
        SCNVector3(
            Float.random(in: -11...11),
            Float.random(in: -3...7),
            Float.random(in: 55...80)
        )
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
        print("[AsteroidFactory] Asteroid.usdz завантажено")
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
