import SceneKit
import UIKit

enum Plane3DFactory {

    struct PlaneAssembly {
        let rootNode: SCNNode
        let bankNode: SCNNode
        let propellerNode: SCNNode
        let hasPropeller: Bool
    }

    private static var flightPlaneTemplates: [String: PlaneAssembly] = [:]

    /// Normalized model span for fighters (plane2 baseline).
    private static let modelTargetSpan: Float = 3.8

    /// In-game flight scale relative to the normalized span.
    private static let gameplayScaleFactor: Float = 0.9

    /// Scout Mk.I (plane1) is ~15% smaller than other fighters.
    private static let plane1ScaleFactor: Float = 0.85

    /// UI previews use a larger display scale than gameplay.
    static let shopPreviewScale: Float = 3.15
    static let menuPreviewScale: Float = 2.7

    private static func targetSpan(for resourceName: String) -> Float {
        let baseSpan = resourceName == "plane1" ? modelTargetSpan * plane1ScaleFactor : modelTargetSpan
        return baseSpan * gameplayScaleFactor
    }

    /// Plane for forward flight — nose points along +Z.
    static func makeFlightPlane(for planeID: Int) -> PlaneAssembly {
        makeFlightPlane(forResource: ShopPlaneCatalog.modelResourceName(for: planeID))
    }

    static func makeFlightPlane(forResource resourceName: String) -> PlaneAssembly {
        if let template = flightPlaneTemplates[resourceName] {
            return cloneAssembly(template)
        }
        if let scene = loadUSDZ(named: resourceName) {
            return buildFromUSDZ(scene, resourceName: resourceName, targetSpan: targetSpan(for: resourceName))
        }
        if resourceName != "plane1" {
            return makeFlightPlane(forResource: "plane1")
        }
        return buildProcedural(targetSpan: targetSpan(for: "plane1"))
    }

    static func prepareFlightPlane() {
        for resourceName in ["plane1", "plane2"] {
            if let scene = loadUSDZ(named: resourceName) {
                flightPlaneTemplates[resourceName] = buildFromUSDZ(
                    scene,
                    resourceName: resourceName,
                    targetSpan: targetSpan(for: resourceName)
                )
            }
        }
    }

    private static func cloneAssembly(_ template: PlaneAssembly) -> PlaneAssembly {
        let rootNode = template.rootNode.clone()
        guard let bankNode = rootNode.childNode(withName: "player", recursively: false) else {
            return PlaneAssembly(
                rootNode: rootNode,
                bankNode: bankNodeFallback(in: rootNode),
                propellerNode: bankNodeFallback(in: rootNode),
                hasPropeller: template.hasPropeller
            )
        }
        let propellerNode = bankNode.childNode(withName: "propeller", recursively: true) ?? bankNode
        return PlaneAssembly(
            rootNode: rootNode,
            bankNode: bankNode,
            propellerNode: propellerNode,
            hasPropeller: template.hasPropeller
        )
    }

    private static func bankNodeFallback(in rootNode: SCNNode) -> SCNNode {
        rootNode.childNode(withName: "player", recursively: true) ?? rootNode
    }

    // MARK: - USDZ

    private static func loadUSDZ(named name: String) -> SCNScene? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "usdz") else {
            return nil
        }
        return try? SCNScene(url: url, options: [.convertToYUp: true])
    }

    private static func buildFromUSDZ(
        _ scene: SCNScene,
        resourceName: String,
        targetSpan: Float
    ) -> PlaneAssembly {
        let sourceModel = findModelNode(in: scene, resourceName: resourceName)

        let rootNode = SCNNode()
        let bankNode = SCNNode()
        bankNode.name = "player"

        sourceModel.removeFromParentNode()
        sourceModel.transform = SCNMatrix4Identity
        fixMaterials(in: sourceModel)

        orientForFlight(sourceModel, resourceName: resourceName)
        centerNode(sourceModel)
        applyUniformScale(to: sourceModel, targetSpan: targetSpan)

        bankNode.addChildNode(sourceModel)
        rootNode.addChildNode(bankNode)

        alignContentToWrapperCenter(bankNode, in: rootNode)

        let propellerNode = sourceModel.childNode(withName: "propeller", recursively: true)
        let hasPropeller = propellerNode != nil

        #if DEBUG
        print("[Plane3DFactory] USDZ for flight: \(sourceModel.name ?? "model")")
        #endif

        return PlaneAssembly(
            rootNode: rootNode,
            bankNode: bankNode,
            propellerNode: propellerNode ?? bankNode,
            hasPropeller: hasPropeller
        )
    }

    // MARK: - Procedural

    private static func buildProcedural(targetSpan: Float) -> PlaneAssembly {
        let red = material(color: UIColor(red: 0.82, green: 0.14, blue: 0.12, alpha: 1))
        let darkRed = material(color: UIColor(red: 0.55, green: 0.08, blue: 0.08, alpha: 1))
        let black = material(color: UIColor(white: 0.08, alpha: 1))
        let metal = material(color: UIColor(white: 0.55, alpha: 1))

        let bankNode = SCNNode()
        bankNode.name = "player"

        let fuselage = SCNNode(geometry: SCNBox(width: 0.32, height: 0.14, length: 1.15, chamferRadius: 0.04))
        fuselage.geometry?.materials = [red, red, darkRed, darkRed, red, red]
        bankNode.addChildNode(fuselage)

        let wings = SCNNode(geometry: SCNBox(width: 1.55, height: 0.05, length: 0.38, chamferRadius: 0.02))
        wings.geometry?.materials = Array(repeating: black, count: 6)
        wings.position = SCNVector3(0, 0, 0.04)
        bankNode.addChildNode(wings)

        let tailWing = SCNNode(geometry: SCNBox(width: 0.55, height: 0.04, length: 0.22, chamferRadius: 0.02))
        tailWing.geometry?.materials = Array(repeating: black, count: 6)
        tailWing.position = SCNVector3(0, 0, -0.48)
        bankNode.addChildNode(tailWing)

        let tailFin = SCNNode(geometry: SCNBox(width: 0.06, height: 0.22, length: 0.2, chamferRadius: 0.02))
        tailFin.geometry?.materials = Array(repeating: red, count: 6)
        tailFin.position = SCNVector3(0, 0.1, -0.5)
        bankNode.addChildNode(tailFin)

        let cockpit = SCNNode(geometry: SCNSphere(radius: 0.1))
        cockpit.geometry?.materials = [metal]
        cockpit.position = SCNVector3(0, 0.08, 0.22)
        bankNode.addChildNode(cockpit)

        let propellerNode = SCNNode(geometry: SCNBox(width: 0.95, height: 0.025, length: 0.07, chamferRadius: 0))
        propellerNode.geometry?.materials = Array(repeating: black, count: 6)
        propellerNode.name = "propeller"
        propellerNode.position = SCNVector3(0, 0, 0.62)
        bankNode.addChildNode(propellerNode)

        let rootNode = SCNNode()
        rootNode.addChildNode(bankNode)
        normalizeScale(of: rootNode, targetSpan: targetSpan)

        return PlaneAssembly(
            rootNode: rootNode,
            bankNode: bankNode,
            propellerNode: propellerNode,
            hasPropeller: true
        )
    }

    // MARK: - Helpers

    private static func findModelNode(in scene: SCNScene, resourceName: String) -> SCNNode {
        if let node = scene.rootNode.childNode(withName: resourceName, recursively: true) {
            return node
        }
        let preferredNames = ["Sketchfab_model", "Su35_2", "GLTF_SceneRootNode", "Meshes", "scene"]
        for name in preferredNames {
            if let node = scene.rootNode.childNode(withName: name, recursively: true) {
                return node
            }
        }
        return deepestGeometryNode(from: scene.rootNode) ?? scene.rootNode
    }

    private static func deepestGeometryNode(from node: SCNNode) -> SCNNode? {
        if node.geometry != nil, node.childNodes.isEmpty {
            return node
        }
        for child in node.childNodes {
            if let found = deepestGeometryNode(from: child) {
                return found.parent ?? found
            }
        }
        return node.childNodes.isEmpty ? nil : node.childNodes[0]
    }

    private static func orientForFlight(_ node: SCNNode, resourceName: String) {
        _ = resourceName
        // Y-up (Sketchfab) → nose along +Z, belly down (not flipped).
        node.eulerAngles = SCNVector3(-Float.pi / 2, Float.pi, Float.pi)
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

    private static func applyUniformScale(to node: SCNNode, targetSpan: Float) {
        let span = measuredSpan(of: node)
        guard span > 0.0001 else { return }
        let factor = targetSpan / span
        node.scale = SCNVector3(factor, factor, factor)
    }

    private static func normalizeScale(of node: SCNNode, targetSpan: Float) {
        applyUniformScale(to: node, targetSpan: targetSpan)
    }

    private static func alignContentToWrapperCenter(_ content: SCNNode, in wrapper: SCNNode) {
        let (bboxMin, bboxMax) = wrapper.boundingBox
        let center = SCNVector3(
            (bboxMin.x + bboxMax.x) * 0.5,
            (bboxMin.y + bboxMax.y) * 0.5,
            (bboxMin.z + bboxMax.z) * 0.5
        )
        content.position.x -= center.x
        content.position.y -= center.y
        content.position.z -= center.z
    }

    private static func fixMaterials(in node: SCNNode) {
        if let geometry = node.geometry {
            geometry.materials = geometry.materials.map { material in
                let copy = material.copy() as? SCNMaterial ?? material
                copy.isDoubleSided = true
                if copy.diffuse.contents == nil {
                    copy.diffuse.contents = UIColor(white: 0.75, alpha: 1)
                }
                copy.lightingModel = .physicallyBased
                return copy
            }
        }
        node.childNodes.forEach { fixMaterials(in: $0) }
    }

    static func addLights(to root: SCNNode) {
        let sun = SCNLight()
        sun.type = .directional
        sun.intensity = 1200
        sun.castsShadow = true
        let sunNode = SCNNode()
        sunNode.light = sun
        sunNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        root.addChildNode(sunNode)

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 700
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        root.addChildNode(ambientNode)
    }

    private static func material(color: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.lightingModel = .physicallyBased
        material.metalness.contents = 0.15
        material.roughness.contents = 0.55
        return material
    }
}
