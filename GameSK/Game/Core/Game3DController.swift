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
    private var isBoosting = false
    private var missionScoreTracker = MissionScoreTracker(level: 1)
    private var lastMissionScoreResult: MissionScoreResult?
    private var isGameOver = false
    private var isLevelComplete = false
    private(set) var isPaused = false
    private var lastUpdateTime: TimeInterval = 0
    private var asteroidSpawnTimer: TimeInterval = 0
    private var fireTimer: TimeInterval = 0
    private var currentBankAngle: Float = 0
    private var currentPitchAngle: Float = 0
    private var propellerAngle: Float = 0
    private lazy var cometEffects = CometEffectController(parent: scene.rootNode)

    private var currentLevel = 1
    private var levelConfig = LevelConfigFactory.config(for: 1)
    private var killsThisLevel = 0
    private var fuelRemaining: TimeInterval = 0

    private let hasPropeller: Bool
    private let moveSpeed: Float = 14
    private let asteroidSpawnInterval: TimeInterval = 0.9
    private let maxBankAngle: Float = .pi / 6
    private let maxPitchAngle: Float = .pi / 12
    private let bankSmoothing: Float = 10
    private let propellerSpeed: Float = 24
    private let bulletRange: Float = 400
    private let bulletSpeed: Float = 320
    private let enemyHitRadius: Float = 2.1
    private let bulletHitRadius: Float = 0.35
    private var activeBullets: [ActiveBullet] = []
    private let planeCruiseMultiplier: Float

    var onScoreChange: ((Int) -> Void)?
    var onLevelProgress: ((Int, Int, Int) -> Void)?
    var onFuelChange: ((TimeInterval, TimeInterval) -> Void)?
    var onLevelComplete: ((Int, Bool, MissionScoreResult) -> Void)?
    var onGameOver: ((Int, Bool) -> Void)?
    var onVictory: ((MissionScoreResult) -> Void)?

    var currentLevelNumber: Int {
        currentLevel
    }

    var missionKillPoints: Int {
        missionScoreTracker.killPoints
    }

    init(scnView: SCNView, startingLevel: Int = 1) {
        self.scnView = scnView
        self.currentLevel = max(1, min(LevelConfigFactory.totalLevels, startingLevel))

        let assembly = Plane3DFactory.makeFlightPlane(for: PlayerPlaneStore.selectedPlaneID)
        bankNode = assembly.bankNode
        propellerNode = assembly.propellerNode
        hasPropeller = assembly.hasPropeller
        planeCruiseMultiplier = ShopPlaneCatalog.cruiseSpeedMultiplier(
            for: PlayerPlaneStore.selectedPlaneID
        )
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
            if let lastMissionScoreResult {
                onVictory?(lastMissionScoreResult)
            }
            return
        }

        beginLevel(currentLevel + 1)
    }

    func restartCurrentLevel() {
        beginLevel(currentLevel)
    }

    func restartCampaign() {
        beginLevel(1)
    }

    func pause() {
        guard !isPaused, !isGameOver, !isLevelComplete else { return }
        isPaused = true
        isFiring = false
        isBoosting = false
        fireTimer = 0
        activeDirections = []
        scene.isPaused = true
        scnView?.isPlaying = false
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        lastUpdateTime = 0
        scene.isPaused = false
        scnView?.isPlaying = true
    }

    private func beginLevel(_ level: Int) {
        currentLevel = max(1, min(LevelConfigFactory.totalLevels, level))
        levelConfig = LevelConfigFactory.config(for: currentLevel)
        killsThisLevel = 0
        isLevelComplete = false
        isPaused = false
        lastUpdateTime = 0
        isGameOver = false
        scene.isPaused = false
        scnView?.isPlaying = true
        isFiring = false
        isBoosting = false
        fireTimer = 0
        asteroidSpawnTimer = 0
        activeDirections = []
        currentBankAngle = 0
        currentPitchAngle = 0

        playerRoot.isHidden = false
        playerRoot.position = SCNVector3(0, 0, 0)
        bankNode.eulerAngles = SCNVector3Zero

        fuelRemaining = levelConfig.fuelDuration
        missionScoreTracker = MissionScoreTracker(level: currentLevel)
        onScoreChange?(0)
        onFuelChange?(fuelRemaining, levelConfig.fuelDuration)

        clearEnemies()
        clearBullets()
        cometEffects.reset()
        spawnInitialAsteroids()
        notifyLevelProgress()
    }

    private func clearEnemies() {
        worldNode.childNodes
            .filter { $0.name == "enemy" }
            .forEach { $0.removeFromParentNode() }
    }

    private func clearBullets() {
        activeBullets.forEach { $0.node.removeFromParentNode() }
        activeBullets.removeAll()
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
        isBoosting = false
        activeDirections = []

        let result = missionScoreTracker.finalize(
            fuelRemaining: fuelRemaining,
            fuelTotal: levelConfig.fuelDuration,
            level: currentLevel
        )
        lastMissionScoreResult = result
        onScoreChange?(result.total)

        let hasNextLevel = currentLevel < LevelConfigFactory.totalLevels
        onLevelComplete?(currentLevel, hasNextLevel, result)
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
            delta: delta,
            forwardRate: starfieldForwardRate()
        )
    }

    private func starfieldForwardRate() -> Float {
        let boost = isBoosting ? PlaneFlightPerformance.afterburnerSpeedMultiplier : 1
        let normalizedApproach = levelConfig.approachSpeed / 24
        return planeCruiseMultiplier * boost * normalizedApproach
    }

    private func forwardScroll(delta: Float) -> Float {
        levelConfig.approachSpeed * planeCruiseMultiplier * (
            isBoosting ? PlaneFlightPerformance.afterburnerSpeedMultiplier : 1
        ) * delta
    }

    // MARK: - Input

    func setDirections(_ directions: Set<MoveDirection>) {
        guard !isGameOver, !isLevelComplete, !isPaused else { return }
        activeDirections = directions
    }

    func setFiring(_ firing: Bool) {
        guard !isGameOver, !isLevelComplete, !isPaused else { return }
        isFiring = firing
        if !firing {
            fireTimer = 0
        }
    }

    func setBoosting(_ boosting: Bool) {
        guard !isGameOver, !isLevelComplete, !isPaused else { return }
        isBoosting = boosting
    }

    // MARK: - Loop

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = time
            return
        }
        let delta = min(Float(time - lastUpdateTime), 1.0 / 30.0)
        lastUpdateTime = time

        guard !isGameOver, !isLevelComplete, !isPaused else { return }

        updatePlayer(delta: delta)
        updateCamera(delta: delta)
        scrollWorld(delta: delta)
        updateBullets(delta: delta)
        updateFuel(delta: delta)
        cometEffects.update(delta: delta, anchor: playerRoot.position)

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
        var verticalInput: Float = 0

        if activeDirections.contains(.left) {
            dx += 1
            horizontalInput -= 1
        }
        if activeDirections.contains(.right) {
            dx -= 1
            horizontalInput += 1
        }
        if activeDirections.contains(.up) {
            dy += 1
            verticalInput += 1
        }
        if activeDirections.contains(.down) {
            dy -= 1
            verticalInput -= 1
        }

        if dx != 0, dy != 0 {
            let factor: Float = 0.707
            dx *= factor
            dy *= factor
        }

        let distance = moveSpeed * delta
        playerRoot.position.x += dx * distance
        playerRoot.position.y += dy * distance

        let blend = min(1, bankSmoothing * delta)
        let targetBank = horizontalInput * maxBankAngle
        currentBankAngle += (targetBank - currentBankAngle) * blend
        let targetPitch = -verticalInput * maxPitchAngle
        currentPitchAngle += (targetPitch - currentPitchAngle) * blend
        bankNode.eulerAngles = SCNVector3(currentPitchAngle, 0, currentBankAngle)

        if hasPropeller {
            propellerAngle += propellerSpeed * delta
            propellerNode.rotation = SCNVector4(1, 0, 0, propellerAngle)
        }
    }

    private func updateFuel(delta: Float) {
        let fuelRate: Float = isBoosting
            ? PlaneFlightPerformance.afterburnerFuelMultiplier
            : 1
        fuelRemaining -= TimeInterval(delta * fuelRate)
        onFuelChange?(max(0, fuelRemaining), levelConfig.fuelDuration)

        if fuelRemaining <= 0 {
            triggerGameOver(outOfFuel: true)
        }
    }

    private func scrollWorld(delta: Float) {
        let offset = forwardScroll(delta: delta)
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
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.none
        asteroid.physicsBody = body

        asteroid.runAction(AsteroidFactory.makeTumbleAction())

        worldNode.addChildNode(asteroid)
    }

    private func fireBullet() {
        let bullet = SCNNode(geometry: SCNSphere(radius: 0.22))
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 1, green: 0.92, blue: 0.2, alpha: 1)
        material.emission.contents = UIColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 1)
        bullet.geometry?.materials = [material]
        bullet.name = "bullet"

        let muzzle = playerRoot.presentation.worldPosition
        bullet.position = SCNVector3(muzzle.x, muzzle.y, muzzle.z + 2.4)
        scene.rootNode.addChildNode(bullet)

        let worldPosition = bullet.presentation.worldPosition
        activeBullets.append(
            ActiveBullet(
                node: bullet,
                traveled: 0,
                previousWorldPosition: worldPosition
            )
        )
    }

    private func updateBullets(delta: Float) {
        guard !activeBullets.isEmpty else { return }

        let step = bulletSpeed * delta
        let hitRadius = enemyHitRadius + bulletHitRadius
        var remainingBullets: [ActiveBullet] = []

        for var bullet in activeBullets {
            let startPosition = bullet.node.presentation.worldPosition
            bullet.node.position.z += step
            bullet.traveled += step

            let endPosition = bullet.node.presentation.worldPosition

            if bullet.traveled >= bulletRange {
                bullet.node.removeFromParentNode()
                continue
            }

            if let enemy = enemyHitByBullet(
                from: startPosition,
                to: endPosition,
                hitRadius: hitRadius
            ) {
                bullet.node.removeFromParentNode()
                handleBulletHit(enemy: enemy)
                continue
            }

            bullet.previousWorldPosition = endPosition
            remainingBullets.append(bullet)
        }

        activeBullets = remainingBullets
    }

    private func enemyHitByBullet(
        from start: SCNVector3,
        to end: SCNVector3,
        hitRadius: Float
    ) -> SCNNode? {
        for enemy in worldNode.childNodes where enemy.name == "enemy" {
            let center = enemy.presentation.worldPosition
            if segmentIntersectsSphere(
                segmentStart: start,
                segmentEnd: end,
                sphereCenter: center,
                radius: hitRadius
            ) {
                return enemy
            }
        }
        return nil
    }

    private func handleBulletHit(enemy: SCNNode) {
        addExplosion(at: enemy.presentation.worldPosition)
        enemy.removeFromParentNode()
        missionScoreTracker.recordKill()
        onScoreChange?(missionScoreTracker.displayedScore)
        registerKill()
    }

    private func segmentIntersectsSphere(
        segmentStart: SCNVector3,
        segmentEnd: SCNVector3,
        sphereCenter: SCNVector3,
        radius: Float
    ) -> Bool {
        let dx = segmentEnd.x - segmentStart.x
        let dy = segmentEnd.y - segmentStart.y
        let dz = segmentEnd.z - segmentStart.z
        let lengthSquared = dx * dx + dy * dy + dz * dz

        guard lengthSquared > 0.0001 else {
            return distance(segmentStart, sphereCenter) <= radius
        }

        var t = (
            (sphereCenter.x - segmentStart.x) * dx
                + (sphereCenter.y - segmentStart.y) * dy
                + (sphereCenter.z - segmentStart.z) * dz
        ) / lengthSquared
        t = max(0, min(1, t))

        let closest = SCNVector3(
            segmentStart.x + dx * t,
            segmentStart.y + dy * t,
            segmentStart.z + dz * t
        )
        return distance(closest, sphereCenter) <= radius
    }

    private func distance(_ a: SCNVector3, _ b: SCNVector3) -> Float {
        let dx = a.x - b.x
        let dy = a.y - b.y
        let dz = a.z - b.z
        return sqrt(dx * dx + dy * dy + dz * dz)
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
            triggerGameOver(outOfFuel: false)
            return
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

    private func triggerGameOver(outOfFuel: Bool) {
        guard !isGameOver else { return }
        isGameOver = true
        isFiring = false
        isBoosting = false
        activeDirections = []

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if !outOfFuel {
                self.addExplosion(at: self.playerRoot.worldPosition)
            }
            self.playerRoot.isHidden = true
            self.onGameOver?(self.currentLevel, outOfFuel)
        }
    }
}

private struct ActiveBullet {
    let node: SCNNode
    var traveled: Float
    var previousWorldPosition: SCNVector3
}
