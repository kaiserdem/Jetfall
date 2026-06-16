import Metal
import SceneKit
import UIKit

enum AsteroidFactory {

    private static var template: SCNNode?
    private static var cachedHUDIcon: UIImage?

    private static let resourceName = "asteroid1"
    private static let targetSpan: Float = 2.4

    /// World-space hit radius that roughly matches the visible rock mesh.
    static func collisionRadius(for node: SCNNode) -> Float {
        let (bboxMin, bboxMax) = node.boundingBox
        let span = Swift.max(
            bboxMax.x - bboxMin.x,
            bboxMax.y - bboxMin.y,
            bboxMax.z - bboxMin.z
        )
        return max(1.25, span * 0.58)
    }

    static func prepareTemplate() {
        guard template == nil else { return }

        if let loaded = loadTemplate(named: resourceName) {
            template = loaded
        } else {
            #if DEBUG
            print("[AsteroidFactory] Failed to load \(resourceName).usdz")
            #endif
        }
    }

    static func makeAsteroid() -> SCNNode? {
        prepareTemplate()
        guard let template else { return nil }

        let asteroid = template.clone()
        asteroid.name = "enemy"
        let tint = spawnTint()
        applyTint(to: asteroid, color: tint)
        attachCosmicDust(to: asteroid)
        return asteroid
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

    private static let hudIconTint = UIColor(
        hue: 0.08,
        saturation: 0.24,
        brightness: 0.74,
        alpha: 1
    )

    private static func renderHUDIcon(from template: SCNNode) -> UIImage? {
        let scene = SCNScene()
        let model = template.clone()
        applyTint(to: model, color: hudIconTint)
        model.eulerAngles = SCNVector3(0.22, 0.92, 0.12)
        scene.rootNode.addChildNode(model)

        let span = targetSpan
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.fieldOfView = 42
        camera.zNear = 0.01
        camera.zFar = 30
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, span * 0.08, span * 2.45)
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

    private static func spawnTint() -> UIColor {
        varyTint(randomRockTint(), amount: 0.03)
    }

    private static func randomRockTint() -> UIColor {
        if Bool.random() {
            return UIColor(
                hue: CGFloat.random(in: 0.52...0.66),
                saturation: CGFloat.random(in: 0.10...0.28),
                brightness: CGFloat.random(in: 0.60...0.82),
                alpha: 1
            )
        }

        return UIColor(
            hue: CGFloat.random(in: 0.03...0.13),
            saturation: CGFloat.random(in: 0.14...0.36),
            brightness: CGFloat.random(in: 0.58...0.86),
            alpha: 1
        )
    }

    private static func varyTint(_ color: UIColor, amount: CGFloat) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        func jitter(_ channel: CGFloat) -> CGFloat {
            min(1, max(0, channel + CGFloat.random(in: -amount...amount)))
        }

        return UIColor(red: jitter(red), green: jitter(green), blue: jitter(blue), alpha: alpha)
    }

    private static func applyTint(to node: SCNNode, color: UIColor) {
        if let geometry = node.geometry {
            let uniqueGeometry = geometry.copy() as? SCNGeometry ?? geometry
            uniqueGeometry.materials = geometry.materials.map { material in
                let copy = material.copy() as? SCNMaterial ?? material
                copy.multiply.contents = color
                return copy
            }
            node.geometry = uniqueGeometry
        }
        node.childNodes.forEach { applyTint(to: $0, color: color) }
    }

    // MARK: - Cosmic dust

    private static var dustParticleTemplate: SCNParticleSystem?
    private static let dustSpeckImage = makeSoftSpeckImage()
    private static let dustColor = UIColor(white: 0.8, alpha: 0.24)

    private static func attachCosmicDust(to asteroid: SCNNode) {
        let dustRoot = SCNNode()
        dustRoot.name = "cosmicDust"
        dustRoot.renderingOrder = 4
        dustRoot.eulerAngles = SCNVector3(
            Float.random(in: 0...(Float.pi * 2)),
            Float.random(in: 0...(Float.pi * 2)),
            Float.random(in: 0...(Float.pi * 2))
        )
        dustRoot.scale = SCNVector3(
            Float.random(in: 0.9...1.3),
            Float.random(in: 0.65...1.0),
            Float.random(in: 0.85...1.35)
        )

        let mainEmitter = SCNNode()
        mainEmitter.position = randomDustOffset(magnitude: 0.42)
        mainEmitter.addParticleSystem(makeDustParticleSystem(birthRate: CGFloat.random(in: 6...9)))
        dustRoot.addChildNode(mainEmitter)

        if Bool.random() {
            let secondaryEmitter = SCNNode()
            secondaryEmitter.position = randomDustOffset(magnitude: 0.55)
            secondaryEmitter.eulerAngles = SCNVector3(
                Float.random(in: -0.6...0.6),
                Float.random(in: -0.6...0.6),
                Float.random(in: -0.6...0.6)
            )
            let secondary = makeDustParticleSystem(birthRate: CGFloat.random(in: 2...4))
            secondary.particleSize *= 0.85
            secondaryEmitter.addParticleSystem(secondary)
            dustRoot.addChildNode(secondaryEmitter)
        }

        asteroid.addChildNode(dustRoot)
    }

    private static func randomDustOffset(magnitude: Float) -> SCNVector3 {
        SCNVector3(
            Float.random(in: -magnitude...magnitude),
            Float.random(in: -magnitude * 0.7...magnitude * 0.7),
            Float.random(in: -magnitude...magnitude)
        )
    }

    private static func makeDustParticleSystem(birthRate: CGFloat) -> SCNParticleSystem {
        let particles = (dustParticleTemplate?.copy() as? SCNParticleSystem) ?? buildDustParticleTemplate()
        particles.birthRate = birthRate
        particles.particleColor = dustColor
        particles.emittingDirection = SCNVector3(
            Float.random(in: -0.4...0.4),
            Float.random(in: -0.4...0.4),
            Float.random(in: -0.4...0.4)
        )
        return particles
    }

    private static func buildDustParticleTemplate() -> SCNParticleSystem {
        let particles = SCNParticleSystem()
        particles.birthRate = 8
        particles.birthLocation = .surface
        particles.particleLifeSpan = 1.35
        particles.particleLifeSpanVariation = 0.55
        particles.particleSize = 0.028
        particles.particleSizeVariation = 0.014
        particles.particleVelocity = 0.09
        particles.particleVelocityVariation = 0.07
        particles.spreadingAngle = 42
        particles.emitterShape = SCNSphere(radius: 1.18)
        particles.particleImage = dustSpeckImage
        particles.particleColor = dustColor
        particles.blendMode = .additive
        particles.isLocal = true
        particles.warmupDuration = 0.6
        particles.orientationMode = .billboardScreenAligned
        particles.stretchFactor = 0
        dustParticleTemplate = particles
        return particles.copy() as? SCNParticleSystem ?? particles
    }

    private static func makeSoftSpeckImage() -> UIImage {
        let length = 10
        let size = CGSize(width: length, height: length)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = size.width / 2
            let colors = [
                UIColor.white.cgColor,
                UIColor.white.withAlphaComponent(0).cgColor
            ] as CFArray
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 1]
            )!
            context.cgContext.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: radius,
                options: []
            )
        }
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
