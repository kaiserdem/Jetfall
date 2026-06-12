import SceneKit
import UIKit

final class Game3DController: NSObject, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {

    let scene = SCNScene()
    private weak var scnView: SCNView?

    private let playerRoot = SCNNode()
    private let bankNode: SCNNode
    private let propellerNode: SCNNode
    private let cameraNode = SCNNode()
    private let worldNode = SCNNode()

    private var activeDirections = Set<MoveDirection>()
    private var score = 0
    private var isGameOver = false
    private var lastUpdateTime: TimeInterval = 0
    private var enemySpawnTimer: TimeInterval = 0
    private var fireTimer: TimeInterval = 0
    private var cloudSpawnTimer: TimeInterval = 0
    private var currentBankAngle: Float = 0
    private var propellerAngle: Float = 0

    private let hasPropeller: Bool
    private let moveSpeed: Float = 14
    private let worldScrollSpeed: Float = 28
    private let maxBankAngle: Float = .pi / 6
    private let bankSmoothing: Float = 10
    private let propellerSpeed: Float = 24

    var onScoreChange: ((Int) -> Void)?
    var onGameOver: (() -> Void)?

    init(scnView: SCNView) {
        self.scnView = scnView

        let assembly = Plane3DFactory.makeFlightPlane()
        bankNode = assembly.bankNode
        propellerNode = assembly.propellerNode
        hasPropeller = assembly.hasPropeller
        playerRoot.addChildNode(assembly.rootNode)

        super.init()

        setupScene()
        scnView.scene = scene
        scnView.pointOfView = cameraNode
        scnView.delegate = self
        scnView.isPlaying = true
        scnView.loops = true
        scnView.antialiasingMode = .multisampling4X
        scnView.backgroundColor = UIColor(red: 0.45, green: 0.72, blue: 0.95, alpha: 1)
    }

    // MARK: - Setup

    private func setupScene() {
        WorldBuilder3D.configureEnvironment(for: scene)
        scene.physicsWorld.gravity = SCNVector3Zero
        scene.physicsWorld.contactDelegate = self
        scene.rootNode.addChildNode(worldNode)

        playerRoot.position = SCNVector3(0, 0, 0)
        playerRoot.name = "playerRoot"
        scene.rootNode.addChildNode(playerRoot)

        let playerBox = SCNBox(width: 2.2, height: 0.8, length: 2.8, chamferRadius: 0)
        let shape = SCNPhysicsShape(geometry: playerBox)
        let body = SCNPhysicsBody(type: .kinematic, shape: shape)
        body.categoryBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.enemy
        body.collisionBitMask = PhysicsCategory.none
        playerRoot.physicsBody = body

        setupCamera()
        Plane3DFactory.addLights(to: scene.rootNode)

        for _ in 0..<10 {
            spawnCloud(at: WorldBuilder3D.randomCloudPosition())
        }
    }

    private func setupCamera() {
        let camera = SCNCamera()
        camera.fieldOfView = 58
        camera.zNear = 0.1
        camera.zFar = 200
        cameraNode.camera = camera
        cameraNode.name = "chaseCamera"
        scene.rootNode.addChildNode(cameraNode)
        updateCamera()
    }

    private func updateCamera() {
        let px = playerRoot.position.x
        let py = playerRoot.position.y
        let pz = playerRoot.position.z

        cameraNode.position = SCNVector3(px, py + 2.8, pz - 10)
        cameraNode.look(
            at: SCNVector3(px, py + 0.35, pz + 24),
            up: SCNVector3(0, 1, 0),
            localFront: SCNVector3(0, 0, -1)
        )
    }

    // MARK: - Input

    func setDirections(_ directions: Set<MoveDirection>) {
        guard !isGameOver else { return }
        activeDirections = directions
    }

    // MARK: - Loop

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = time
        }
        let delta = Float(time - lastUpdateTime)
        lastUpdateTime = time

        guard !isGameOver else { return }

        updatePlayer(delta: delta)
        updateCamera()
        scrollWorld(delta: delta)

        enemySpawnTimer += TimeInterval(delta)
        fireTimer += TimeInterval(delta)
        cloudSpawnTimer += TimeInterval(delta)

        if enemySpawnTimer >= 1.4 {
            enemySpawnTimer = 0
            spawnEnemy()
        }
        if fireTimer >= 0.22 {
            fireTimer = 0
            fireBullet()
        }
        if cloudSpawnTimer >= 0.9 {
            cloudSpawnTimer = 0
            spawnCloud(at: WorldBuilder3D.randomCloudPosition())
        }
    }

    private func updatePlayer(delta: Float) {
        var dx: Float = 0
        var dy: Float = 0
        var horizontalInput: Float = 0

        if activeDirections.contains(.left) {
            dx += 1
            horizontalInput -= 1
        }
        if activeDirections.contains(.right) {
            dx -= 1
            horizontalInput += 1
        }
        if activeDirections.contains(.up) { dy += 1 }
        if activeDirections.contains(.down) { dy -= 1 }

        if dx != 0, dy != 0 {
            let factor: Float = 0.707
            dx *= factor
            dy *= factor
        }

        let distance = moveSpeed * delta
        playerRoot.position.x = clamp(playerRoot.position.x + dx * distance, min: -12, max: 12)
        playerRoot.position.y = clamp(playerRoot.position.y + dy * distance, min: -5, max: 8)

        let targetBank = horizontalInput * maxBankAngle
        let blend = min(1, bankSmoothing * delta)
        currentBankAngle += (targetBank - currentBankAngle) * blend
        bankNode.rotation = SCNVector4(0, 0, 1, currentBankAngle)

        if hasPropeller {
            propellerAngle += propellerSpeed * delta
            propellerNode.rotation = SCNVector4(1, 0, 0, propellerAngle)
        }
    }

    private func scrollWorld(delta: Float) {
        let offset = worldScrollSpeed * delta
        for node in worldNode.childNodes {
            node.position.z -= offset
            if node.position.z < -15 {
                node.removeFromParentNode()
            }
        }
    }

    // MARK: - Spawning

    private func spawnCloud(at position: SCNVector3) {
        let cloud = WorldBuilder3D.makeCloud(at: position)
        worldNode.addChildNode(cloud)
    }

    private func spawnEnemy() {
        let enemy = AsteroidFactory.makeEnemyNode()
        enemy.position = SCNVector3(
            Float.random(in: -11...11),
            Float.random(in: -3...7),
            Float.random(in: 55...80)
        )
        enemy.eulerAngles = SCNVector3(
            Float.random(in: 0...(Float.pi * 2)),
            Float.random(in: 0...(Float.pi * 2)),
            Float.random(in: 0...(Float.pi * 2))
        )

        let hitRadius: CGFloat = 1.1
        let enemyShape = SCNPhysicsShape(geometry: SCNSphere(radius: hitRadius))
        let body = SCNPhysicsBody(type: .kinematic, shape: enemyShape)
        body.categoryBitMask = PhysicsCategory.enemy
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.playerBullet
        body.collisionBitMask = PhysicsCategory.none
        enemy.physicsBody = body

        let tumble = SCNAction.rotateBy(
            x: CGFloat.random(in: 0.4...1.2),
            y: CGFloat.random(in: 0.6...1.4),
            z: CGFloat.random(in: 0.3...0.9),
            duration: Double.random(in: 2.5...4.5)
        )
        enemy.runAction(.repeatForever(tumble))

        worldNode.addChildNode(enemy)
    }

    private func fireBullet() {
        let bullet = SCNNode(geometry: SCNSphere(radius: 0.18))
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 1, green: 0.92, blue: 0.2, alpha: 1)
        material.emission.contents = UIColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 1)
        bullet.geometry?.materials = [material]
        bullet.name = "bullet"
        bullet.position = SCNVector3(
            playerRoot.position.x,
            playerRoot.position.y,
            playerRoot.position.z + 2.2
        )

        let bulletSphere = SCNSphere(radius: 0.18)
        let bulletShape = SCNPhysicsShape(geometry: bulletSphere)
        let body = SCNPhysicsBody(type: .kinematic, shape: bulletShape)
        body.categoryBitMask = PhysicsCategory.playerBullet
        body.contactTestBitMask = PhysicsCategory.enemy
        body.collisionBitMask = PhysicsCategory.none
        bullet.physicsBody = body

        worldNode.addChildNode(bullet)

        let travel = SCNAction.move(by: SCNVector3(0, 0, 90), duration: 1.1)
        let remove = SCNAction.removeFromParentNode()
        bullet.runAction(SCNAction.sequence([travel, remove]))
    }

    // MARK: - Physics

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        guard let bodyA = contact.nodeA.physicsBody, let bodyB = contact.nodeB.physicsBody else {
            return
        }
        let maskA = bodyA.categoryBitMask
        let maskB = bodyB.categoryBitMask

        if (maskA == PhysicsCategory.player && maskB == PhysicsCategory.enemy)
            || (maskB == PhysicsCategory.player && maskA == PhysicsCategory.enemy) {
            triggerGameOver()
            return
        }

        let isBulletHit = (maskA == PhysicsCategory.playerBullet && maskB == PhysicsCategory.enemy)
            || (maskB == PhysicsCategory.playerBullet && maskA == PhysicsCategory.enemy)
        guard isBulletHit else { return }

        let bulletNode = maskA == PhysicsCategory.playerBullet ? contact.nodeA : contact.nodeB
        let enemyNode = maskA == PhysicsCategory.enemy ? contact.nodeA : contact.nodeB

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.addExplosion(at: enemyNode.worldPosition)
            bulletNode.removeFromParentNode()
            enemyNode.removeFromParentNode()
            self.score += 10
            self.onScoreChange?(self.score)
        }
    }

    private func addExplosion(at position: SCNVector3) {
        let burst = SCNNode(geometry: SCNSphere(radius: 0.3))
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 1, green: 0.55, blue: 0.1, alpha: 1)
        material.emission.contents = UIColor.orange
        burst.geometry?.materials = [material]
        burst.position = position
        worldNode.addChildNode(burst)

        let grow = SCNAction.scale(to: 2.8, duration: 0.18)
        let fade = SCNAction.fadeOut(duration: 0.18)
        let remove = SCNAction.removeFromParentNode()
        burst.runAction(SCNAction.sequence([SCNAction.group([grow, fade]), remove]))
    }

    private func triggerGameOver() {
        guard !isGameOver else { return }
        isGameOver = true

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.addExplosion(at: self.playerRoot.worldPosition)
            self.playerRoot.isHidden = true
            self.onGameOver?()
        }
    }

    private func clamp(_ value: Float, min: Float, max: Float) -> Float {
        Swift.max(min, Swift.min(max, value))
    }
}
