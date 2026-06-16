import Metal
import SceneKit
import UIKit

enum AmmunitionPickupFactory {

    private static var template: SCNNode?
    private static var cachedHUDIcon: UIImage?

    private static let resourceName = "Ammunition"
    private static let targetSpan: Float = 2.4

    static func prepareTemplate() {
        guard template == nil else { return }

        if let loaded = loadTemplate(named: resourceName) {
            template = loaded
        } else {
            #if DEBUG
            print("[AmmunitionPickupFactory] Failed to load \(resourceName).usdz")
            #endif
        }
    }

    static func makePickup() -> SCNNode? {
        prepareTemplate()
        guard let template else { return nil }

        let pickup = template.clone()
        pickup.name = "ammoPickup"
        pickup.renderingOrder = 5
        isolateMaterials(in: pickup)
        pickup.runAction(makeFloatAction())
        return pickup
    }

    static func spawnPosition(near playerPosition: SCNVector3) -> SCNVector3 {
        AsteroidFactory.spawnPosition(
            near: playerPosition,
            preferredDistance: Float.random(in: 220...340),
            avoiding: []
        )
    }

    static func positionAlongside(asteroidPosition: SCNVector3) -> SCNVector3 {
        SCNVector3(
            asteroidPosition.x + Float.random(in: -16...16),
            asteroidPosition.y + Float.random(in: -10...10),
            asteroidPosition.z + Float.random(in: -6...22)
        )
    }

    static var isTemplateReady: Bool {
        prepareTemplate()
        return template != nil
    }

    static func hudIconImage() -> UIImage? {
        if let cachedHUDIcon {
            return cachedHUDIcon
        }
        prepareTemplate()
        guard let template else { return nil }
        guard let image = renderHUDIcon(from: template) else { return nil }
        cachedHUDIcon = image
        return image
    }

    static func prepareHUDIcon(completion: ((UIImage?) -> Void)? = nil) {
        func run() {
            completion?(hudIconImage())
        }
        if Thread.isMainThread {
            run()
        } else {
            DispatchQueue.main.async(execute: run)
        }
    }

    private static func renderHUDIcon(from template: SCNNode) -> UIImage? {
        let scene = SCNScene()
        let model = template.clone()
        isolateMaterials(in: model)
        model.eulerAngles = SCNVector3(-0.18, 0.72, 0.1)
        scene.rootNode.addChildNode(model)

        let span = targetSpan
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.fieldOfView = 40
        camera.zNear = 0.01
        camera.zFar = 30
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, span * 0.1, span * 2.35)
        cameraNode.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(cameraNode)

        Plane3DFactory.addLights(to: scene.rootNode)

        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        let renderer = SCNRenderer(device: device, options: nil)
        renderer.scene = scene
        renderer.pointOfView = cameraNode

        let size = CGSize(width: 72, height: 72)
        return renderer.snapshot(atTime: 0, with: size, antialiasingMode: .multisampling4X)
    }

    private static func isolateMaterials(in node: SCNNode) {
        if let geometry = node.geometry {
            let uniqueGeometry = geometry.copy() as? SCNGeometry ?? geometry
            uniqueGeometry.materials = geometry.materials.map { material in
                let copy = material.copy() as? SCNMaterial ?? material
                copy.isDoubleSided = true
                return copy
            }
            node.geometry = uniqueGeometry
        }
        node.childNodes.forEach { isolateMaterials(in: $0) }
    }

    private static func makeFloatAction() -> SCNAction {
        let spin = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 6.5)
        let bobUp = SCNAction.moveBy(x: 0, y: 0.08, z: 0, duration: 1.1)
        bobUp.timingMode = .easeInEaseOut
        let bob = SCNAction.repeatForever(.sequence([bobUp, bobUp.reversed()]))
        return .group([.repeatForever(spin), bob])
    }

    private static func loadTemplate(named resourceName: String) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "usdz"),
              let scene = try? SCNScene(url: url, options: [.convertToYUp: true]) else {
            return nil
        }

        let source = findModelNode(in: scene)
        source.removeFromParentNode()
        source.transform = SCNMatrix4Identity
        styleMaterials(in: source)

        let wrapper = SCNNode()
        wrapper.addChildNode(source)
        centerNode(source)
        normalizeScale(of: wrapper, targetSpan: targetSpan)

        #if DEBUG
        print("[AmmunitionPickupFactory] \(resourceName).usdz loaded")
        #endif

        return wrapper
    }

    private static func styleMaterials(in node: SCNNode) {
        if let geometry = node.geometry {
            geometry.materials = geometry.materials.map { material in
                let copy = material.copy() as? SCNMaterial ?? material
                copy.isDoubleSided = true
                copy.fillMode = .fill
                copy.lightingModel = .physicallyBased
                return copy
            }
        }
        node.childNodes.forEach { styleMaterials(in: $0) }
    }

    private static func findModelNode(in scene: SCNScene) -> SCNNode {
        let preferredNames = ["Meshes", "Sketchfab_model", "GLTF_SceneRootNode"]
        for name in preferredNames {
            if let node = scene.rootNode.childNode(withName: name, recursively: true) {
                if let geometryNode = deepestGeometryNode(from: node) {
                    return commonGeometryAncestor(for: geometryNode)
                }
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
        return node.childNodes.map { measuredSpan(of: $0) }.max() ?? 0
    }
}
