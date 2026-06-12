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
    private var isFiring = false
    private var score = 0
    private var isGameOver = false
    private var isLevelComplete = false
    private var lastUpdateTime: TimeInterval = 0
    private var asteroidSpawnTimer: TimeInterval = 0
    private var fireTimer: TimeInterval = 0
    private var currentBankAngle: Float = 0
    private var propellerAngle: Float = 0

    private var currentLevel = 1
    private var levelConfig = LevelConfigFactory.config(for: 1)
    private var killsThisLevel = 0

    private let hasPropeller: Bool
    private let moveSpeed: Float = 14
    private let asteroidSpawnInterval: TimeInterval = 0.9
    private let maxBankAngle: Float = .pi / 6
    private let bankSmoothing: Float = 10
    private let propellerSpeed: Float = 24

    var onScoreChange: ((Int) -> Void)?
    var onLevelProgress: ((Int, Int, Int) -> Void)?
    var onLevelComplete: ((Int, Bool) -> Void)?
    var onGameOver: ((Int) -> Void)?
    var onVictory: (() -> Void)?

    init(scnView: SCNView, startingLevel: Int = 1) {
        self.scnView = scnView
        self.currentLevel = max(1, min(LevelConfigFactory.totalLevels, startingLevel))

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
        scnView.backgroundColor = WorldBuilder3D.spaceColor

        beginLevel(currentLevel)
    }

    // MARK: - Setup

    private func setupScene() {
        WorldBuilder3D.resetStarMotion()
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
    }

    private func setupCamera() {
        let camera = SCNCamera()
        camera.fieldOfView = 58
        camera.zNear = 0.1
        camera.zFar = 420
        cameraNode.camera = camera
        cameraNode.name = "chaseCamera"
        scene.rootNode.addChildNode(cameraNode)
        updateCamera(delta: 0)
    }

    // MARK: - Levels

    func advanceToNextLevel() {
        guard isLevelComplete else { return }

        if currentLevel >= LevelConfigFactory.totalLevels {
            onVictory?()
            return
        }

        beginLevel(currentLevel + 1)
    }

    func restartCurrentLevel() {
        beginLevel(currentLevel)
    }

    func restartCampaign() {
        score = 0
        onScoreChange?(score)
        beginLevel(1)
    }

    private func beginLevel(_ level: Int) {
        currentLevel = max(1, min(LevelConfigFactory.totalLevels, level))
        levelConfig = LevelConfigFactory.config(for: currentLevel)
        killsThisLevel = 0
        isLevelComplete = false
        lastUpdateTime = 0
        isGameOver = false
        isFiring = false
        fireTimer = 0
        asteroidSpawnTimer = 0
        activeDirections = []
        currentBankAngle = 0

        playerRoot.isHidden = false
        playerRoot.position = SCNVector3(0, 0, 0)
        bankNode.rotation = SCNVector4Zero

        clearEnemies()
        spawnInitialAsteroids()
        notifyLevelProgress()
    }

    private func clearEnemies() {
        worldNode.childNodes
            .filter { $0.name == "enemy" || $0.name == "bullet" }
            .forEach { $0.removeFromParentNode() }
    }

    private func spawnInitialAsteroids() {
        for distance in AsteroidFactory.initialSpawnDistances() {
            spawnAsteroid(preferredDistance: distance)
        }
    }

    private func notifyLevelProgress() {
        onLevelProgress?(currentLevel, killsThisLevel, levelConfig.asteroidsToDestroy)
    }

    private func completeLevel() {
        guard !isLevelComplete else { return }
        isLevelComplete = true
        isFiring = false
        activeDirections = []
        let hasNextLevel = currentLevel < LevelConfigFactory.totalLevels
        onLevelComplete?(currentLevel, hasNextLevel)
    }

    // MARK: - Camera

    private func updateCamera(delta: Float) {
        let px = playerRoot.position.x
        let py = playerRoot.position.y
        let pz = playerRoot.position.z

        cameraNode.position = SCNVector3(px, py + 2.8, pz - 10)
        cameraNode.look(
            at: SCNVector3(px, py + 0.35, pz + 24),
            up: SCNVector3(0, 1, 0),
            localFront: SCNVector3(0, 0, -1)
        )

        WorldBuilder3D.updateStars(
            for: scene,
            playerPosition: playerRoot.position,
            delta: delta
        )
    }

    // MARK: - Input

    func setDirections(_ directions: Set<MoveDirection>) {
        guard !isGameOver, !isLevelComplete else { return }
        activeDirections = directions
    }

    func setFiring(_ firing: Bool) {
        guard !isGameOver, !isLevelComplete else { return }
        isFiring = firing
        if !firing {
            fireTimer = 0
        }
    }

    // MARK: - Loop

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = time
            return
        }
        let delta = min(Float(time - lastUpdateTime), 1.0 / 30.0)
        lastUpdateTime = time

        guard !isGameOver, !isLevelComplete else { return }

        updatePlayer(delta: delta)
        updateCamera(delta: delta)
        scrollWorld(delta: delta)

        asteroidSpawnTimer += TimeInterval(delta)
        fireTimer += TimeInterval(delta)

        if asteroidSpawnTimer >= asteroidSpawnInterval {
            asteroidSpawnTimer = 0
            spawnAsteroid()
        }
        if isFiring, fireTimer >= 0.22 {
            fireTimer = 0
            fireBullet()
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
        playerRoot.position.x += dx * distance
        playerRoot.position.y += dy * distance

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
        let offset = levelConfig.approachSpeed * delta
        for node in worldNode.childNodes {
            node.position.z -= offset
            if node.position.z < -15 {
                node.removeFromParentNode()
            }
        }
    }

    // MARK: - Spawning

    private func spawnAsteroid(preferredDistance: Float? = nil) {
        guard !isGameOver, !isLevelComplete else { return }
        guard let asteroid = AsteroidFactory.makeAsteroid() else { return }

        let existingAsteroids = worldNode.childNodes.filter { $0.name == "enemy" }
        asteroid.position = AsteroidFactory.spawnPosition(
            near: playerRoot.position,
            preferredDistance: preferredDistance,
            avoiding: existingAsteroids
        )
        asteroid.eulerAngles = SCNVector3(
            Float.random(in: 0...(Float.pi * 2)),
            Float.random(in: 0...(Float.pi * 2)),
            Float.random(in: 0...(Float.pi * 2))
        )

        let hitRadius: CGFloat = 1.1
        let shape = SCNPhysicsShape(geometry: SCNSphere(radius: hitRadius))
        let body = SCNPhysicsBody(type: .kinematic, shape: shape)
        body.categoryBitMask = PhysicsCategory.enemy
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.playerBullet
        body.collisionBitMask = PhysicsCategory.none
        asteroid.physicsBody = body

        let tumble = SCNAction.rotateBy(
            x: CGFloat.random(in: 0.4...1.2),
            y: CGFloat.random(in: 0.6...1.4),
            z: CGFloat.random(in: 0.3...0.9),
            duration: Double.random(in: 2.5...4.5)
        )
        asteroid.runAction(.repeatForever(tumble))

        worldNode.addChildNode(asteroid)
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
            self.registerKill()
        }
    }

    private func registerKill() {
        killsThisLevel += 1
        notifyLevelProgress()

        if killsThisLevel >= levelConfig.asteroidsToDestroy {
            completeLevel()
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
        isFiring = false
        activeDirections = []

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.addExplosion(at: self.playerRoot.worldPosition)
            self.playerRoot.isHidden = true
            self.onGameOver?(self.currentLevel)
        }
    }
}
