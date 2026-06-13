import SceneKit
import UIKit

/// Background comets with short fading trails.
final class CometEffectController {

    private let container = SCNNode()
    private var activeComets: [ActiveComet] = []
    private var fadingTrails: [TrailSegment] = []
    private var spawnTimer: TimeInterval = 0
    private var nextSpawnDelay: TimeInterval = 2

    private let maxActiveComets = 4

    init(parent: SCNNode) {
        container.name = "cometEffects"
        parent.addChildNode(container)
        scheduleNextSpawn(initial: true)
    }

    func reset() {
        activeComets.forEach { $0.removeHeadOnly() }
        activeComets.removeAll()
        fadingTrails.forEach { $0.node.removeFromParentNode() }
        fadingTrails.removeAll()
        spawnTimer = 0
        scheduleNextSpawn(initial: true)
    }

    func update(delta: Float, anchor: SCNVector3) {
        let step = max(0, min(delta, 1.0 / 30.0))

        fadingTrails = TrailSegment.advanceSegments(fadingTrails, delta: step)

        activeComets.removeAll { comet in
            comet.advance(delta: step, anchor: anchor)
            if comet.shouldRemove(relativeTo: anchor) {
                fadingTrails.append(contentsOf: comet.retireTrail())
                comet.removeHeadOnly()
                return true
            }
            return false
        }

        guard activeComets.count < maxActiveComets else { return }

        spawnTimer += TimeInterval(step)
        guard spawnTimer >= nextSpawnDelay else { return }

        spawnTimer = 0
        let comet = ActiveComet.spawn(relativeTo: anchor)
        comet.attach(to: container)
        activeComets.append(comet)
        scheduleNextSpawn(initial: false)
    }

    private func scheduleNextSpawn(initial: Bool) {
        if initial {
            nextSpawnDelay = TimeInterval.random(in: 0.8...2.0)
        } else if activeComets.count >= maxActiveComets - 1 {
            nextSpawnDelay = TimeInterval.random(in: 4.0...7.0)
        } else {
            nextSpawnDelay = TimeInterval.random(in: 1.5...4.0)
        }
    }
}

// MARK: - Active Comet

private final class ActiveComet {

    private let head = SCNNode()
    private var velocity = SCNVector3Zero
    private var trailTimer: Float = 0
    private var trailSegments: [TrailSegment] = []

    private let speed: Float = 64
    private let depth: Float = 72
    private let trailSpacing: Float = 0.03
    private let trailLifetime: Float = 1.6
    private let boundsX: Float = 42
    private let boundsY: Float = 26

    static func spawn(relativeTo anchor: SCNVector3) -> ActiveComet {
        let comet = ActiveComet()

        let startSide = Int.random(in: 0...3)
        var start = SCNVector3(anchor.x, anchor.y, anchor.z + comet.depth)

        switch startSide {
        case 0:
            start.x = anchor.x - comet.boundsX
            start.y = anchor.y + Float.random(in: -comet.boundsY * 0.65...comet.boundsY)
        case 1:
            start.x = anchor.x + comet.boundsX
            start.y = anchor.y + Float.random(in: -comet.boundsY * 0.65...comet.boundsY)
        case 2:
            start.x = anchor.x + Float.random(in: -comet.boundsX...comet.boundsX)
            start.y = anchor.y + comet.boundsY
        default:
            start.x = anchor.x + Float.random(in: -comet.boundsX...comet.boundsX)
            start.y = anchor.y - comet.boundsY
        }

        var target = SCNVector3(
            anchor.x + Float.random(in: -comet.boundsX * 0.75...comet.boundsX * 0.75),
            anchor.y + Float.random(in: -comet.boundsY * 0.75...comet.boundsY * 0.75),
            anchor.z + comet.depth
        )

        if startSide == 0 { target.x += comet.boundsX * 1.6 }
        if startSide == 1 { target.x -= comet.boundsX * 1.6 }
        if startSide == 2 { target.y -= comet.boundsY * 1.4 }
        if startSide == 3 { target.y += comet.boundsY * 1.4 }

        let direction = Self.normalize(SCNVector3(
            target.x - start.x,
            target.y - start.y,
            target.z - start.z
        ))
        comet.velocity = SCNVector3(
            direction.x * comet.speed,
            direction.y * comet.speed,
            direction.z * comet.speed
        )
        comet.head.position = start
        comet.configureHead()
        return comet
    }

    func attach(to parent: SCNNode) {
        parent.addChildNode(head)
    }

    func removeHeadOnly() {
        head.removeFromParentNode()
    }

    func retireTrail() -> [TrailSegment] {
        let segments = trailSegments
        trailSegments = []
        return segments
    }

    func advance(delta: Float, anchor: SCNVector3) {
        head.position.x += velocity.x * delta
        head.position.y += velocity.y * delta
        head.position.z = anchor.z + depth

        trailTimer += delta
        while trailTimer >= trailSpacing {
            trailTimer -= trailSpacing
            addTrailDot(at: head.position)
        }

        trailSegments = TrailSegment.advanceSegments(trailSegments, delta: delta)
    }

    func shouldRemove(relativeTo anchor: SCNVector3) -> Bool {
        let dx = abs(head.position.x - anchor.x)
        let dy = abs(head.position.y - anchor.y)
        return dx > boundsX * 1.35 || dy > boundsY * 1.35
    }

    private func configureHead() {
        let core = SCNSphere(radius: 0.18)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(white: 0.98, alpha: 1)
        material.emission.contents = UIColor(red: 0.72, green: 0.86, blue: 1.0, alpha: 1)
        material.lightingModel = .constant
        core.materials = [material]

        head.geometry = core
        head.name = "cometHead"

        let glow = SCNNode(geometry: SCNSphere(radius: 0.38))
        let glowMaterial = SCNMaterial()
        glowMaterial.diffuse.contents = UIColor(red: 0.45, green: 0.72, blue: 1.0, alpha: 0.22)
        glowMaterial.emission.contents = UIColor(red: 0.35, green: 0.58, blue: 0.95, alpha: 0.35)
        glowMaterial.lightingModel = .constant
        glowMaterial.transparency = 0.35
        glow.geometry?.materials = [glowMaterial]
        head.addChildNode(glow)

        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .all
        head.constraints = [billboard]
    }

    private func addTrailDot(at position: SCNVector3) {
        let radius = CGFloat.random(in: 0.06...0.13)
        let dot = SCNNode(geometry: SCNSphere(radius: radius))
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.78, green: 0.88, blue: 1.0, alpha: 0.85)
        material.emission.contents = UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 0.7)
        material.lightingModel = .constant
        material.transparency = 0.85
        dot.geometry?.materials = [material]
        dot.position = position
        dot.name = "cometTrail"

        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .all
        dot.constraints = [billboard]

        head.parent?.addChildNode(dot)
        trailSegments.append(
            TrailSegment(
                node: dot,
                age: 0,
                maxAge: trailLifetime
            )
        )
    }

    private static func normalize(_ vector: SCNVector3) -> SCNVector3 {
        let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        guard length > 0.0001 else { return SCNVector3(1, 0, 0) }
        return SCNVector3(vector.x / length, vector.y / length, vector.z / length)
    }
}

// MARK: - Trail

private struct TrailSegment {
    let node: SCNNode
    var age: Float
    let maxAge: Float

    static func advanceSegments(_ segments: [TrailSegment], delta: Float) -> [TrailSegment] {
        segments.compactMap { segment in
            advance(segment, delta: delta)
        }
    }

    private static func advance(_ segment: TrailSegment, delta: Float) -> TrailSegment? {
        var segment = segment
        segment.age += delta
        let life = 1 - (segment.age / segment.maxAge)

        guard life > 0 else {
            segment.node.removeFromParentNode()
            return nil
        }

        applyAppearance(to: &segment, life: life)
        return segment
    }

    private static func applyAppearance(to segment: inout TrailSegment, life: Float) {
        let eased = life * life
        segment.node.opacity = CGFloat(eased * 0.92)
        let scale = 0.4 + (0.6 * eased)
        segment.node.scale = SCNVector3(scale, scale, scale)
    }
}
