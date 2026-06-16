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
    private var fuelPickupSpawnTimer: TimeInterval = 0
    private var nextFuelPickupSpawnDelay: TimeInterval = 0
    private var ammoPickupSpawnTimer: TimeInterval = 0
    private var nextAmmoPickupSpawnDelay: TimeInterval = 0
    private var ammoSpawnCooldownRemaining: TimeInterval = 0
    private var fireTimer: TimeInterval = 0
    private var currentBankAngle: Float = 0
    private var currentPitchAngle: Float = 0
    private var propellerAngle: Float = 0
    private lazy var cometEffects = CometEffectController(parent: scene.rootNode)

    private var currentLevel = 1
    private var levelConfig = LevelConfigFactory.config(for: 1)
    private var killsThisLevel = 0
    private var fuelRemaining: TimeInterval = 0
    private var ammoRemaining = 0
    private var ammoCapacity = 0

    private let hasPropeller: Bool
    private let moveSpeed: Float = 14
    private let asteroidSpawnInterval: TimeInterval = 0.9
    private let maxBankAngle: Float = .pi / 6
    private let maxPitchAngle: Float = .pi / 12
    private let bankSmoothing: Float = 10
    private let propellerSpeed: Float = 24
    private let bulletRange: Float = 400
    private let bulletSpeed: Float = 320
    private let asteroidHitRadius: Float = 1.1
    private let bulletHitRadius: Float = 0.22
    private var activeBullets: [ActiveBullet] = []
    private var asteroidHitsRemaining: [ObjectIdentifier: Int] = [:]
    private let planeCruiseMultiplier: Float

    var onAmmoChange: ((Int, Int) -> Void)?
    var onAmmoPickupCollected: ((Int) -> Void)?
    var onLevelProgress: ((Int, Int, Int) -> Void)?
    var onFuelChange: ((TimeInterval, TimeInterval, Bool) -> Void)?
    var onFuelPickupCollected: (() -> Void)?
    var onLevelComplete: ((Int, Bool, MissionScoreResult) -> Void)?
    var onGameOver: ((Int, Bool) -> Void)?
    var onVictory: ((MissionScoreResult) -> Void)?

    var currentLevelNumber: Int {
        currentLevel
    }

    var missionKillPoints: Int {
        missionScoreTracker.killPoints
    }

    func refreshHUD() {
        onAmmoChange?(ammoRemaining, ammoCapacity)
        onFuelChange?(fuelRemaining, levelConfig.fuelDuration, isBoosting)
        notifyLevelProgress()
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
            | PhysicsCategory.fuelPickup
            | PhysicsCategory.ammoPickup
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
        fuelPickupSpawnTimer = 0
        scheduleNextFuelPickupSpawn(initial: true)
        ammoPickupSpawnTimer = 0
        scheduleNextAmmoPickupSpawn(initial: true)
        ammoSpawnCooldownRemaining = TimeInterval.random(
            in: AmmunitionPickupConfig.initialSpawnCooldownRange
        )
        AmmunitionPickupFactory.prepareTemplate()
        activeDirections = []
        currentBankAngle = 0
        currentPitchAngle = 0

        playerRoot.isHidden = false
        playerRoot.position = SCNVector3(0, 0, 0)
        bankNode.eulerAngles = SCNVector3Zero

        fuelRemaining = levelConfig.fuelDuration
        ammoCapacity = levelConfig.startingAmmo
        ammoRemaining = ammoCapacity
        missionScoreTracker = MissionScoreTracker(level: currentLevel)
        onAmmoChange?(ammoRemaining, ammoCapacity)
        onFuelChange?(fuelRemaining, levelConfig.fuelDuration, false)

        clearEnemies()
        clearFuelPickups()
        clearAmmoPickups()
        clearBullets()
        asteroidHitsRemaining.removeAll()
        cometEffects.reset()
        spawnInitialAsteroids()
        notifyLevelProgress()
    }

    private func clearFuelPickups() {
        worldNode.childNodes
            .filter { $0.name == "fuelPickup" }
            .forEach { $0.removeFromParentNode() }
    }

    private func clearAmmoPickups() {
        worldNode.childNodes
            .filter { $0.name == "ammoPickup" }
            .forEach { $0.removeFromParentNode() }
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

    private func aimDirection() -> SCNVector3 {
        let forward = cameraNode.convertVector(SCNVector3(0, 0, -1), to: nil)
        let length = sqrt(forward.x * forward.x + forward.y * forward.y + forward.z * forward.z)
        guard length > 0.0001 else { return SCNVector3(0, 0, 1) }
        return SCNVector3(forward.x / length, forward.y / length, forward.z / length)
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
        updateBullets(delta: delta)
        scrollWorld(delta: delta)
        checkFuelPickupCollection()
        checkAmmoPickupCollection()
        updateFuel(delta: delta)
        cometEffects.update(delta: delta, anchor: playerRoot.position)

        asteroidSpawnTimer += TimeInterval(delta)
        fireTimer += TimeInterval(delta)

        if asteroidSpawnTimer >= asteroidSpawnInterval {
            asteroidSpawnTimer = 0
            spawnAsteroid()
        }
        updateFuelPickupSpawning(delta: delta)
        updateAmmoPickupSpawning(delta: delta)
        ammoSpawnCooldownRemaining = max(0, ammoSpawnCooldownRemaining - TimeInterval(delta))
        if isFiring, fireTimer >= 0.22, ammoRemaining > 0 {
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
        onFuelChange?(max(0, fuelRemaining), levelConfig.fuelDuration, isBoosting)

        if fuelRemaining <= 0 {
            triggerGameOver(outOfFuel: true)
        }
    }

    private func scrollWorld(delta: Float) {
        let offset = forwardScroll(delta: delta)
        for node in worldNode.childNodes {
            node.position.z -= offset
            if node.position.z < -15 {
                if node.name == "fuelPickup" {
                    scheduleMissedFuelPickupRetry()
                }
                if node.name == "ammoPickup" {
                    scheduleMissedAmmoPickupRetry()
                }
                if node.name == "enemy" {
                    unregisterAsteroidHits(node)
                }
                node.removeFromParentNode()
            }
        }
    }

    private func scheduleMissedFuelPickupRetry() {
        fuelPickupSpawnTimer = 0
        nextFuelPickupSpawnDelay = TimeInterval.random(in: 22...36)
    }

    private func scheduleMissedAmmoPickupRetry() {
        ammoPickupSpawnTimer = 0
        nextAmmoPickupSpawnDelay = TimeInterval.random(in: ammoSpawnDelayRange(initial: false))
    }

    private var isLowOnAmmo: Bool {
        ammoRemaining < AmmunitionPickupConfig.lowAmmoThreshold
    }

    private func ammoSpawnDelayRange(initial: Bool) -> ClosedRange<TimeInterval> {
        if isLowOnAmmo {
            return AmmunitionPickupConfig.lowAmmoSpawnDelayRange
        }
        if initial {
            return AmmunitionPickupConfig.initialSpawnCooldownRange
        }
        return AmmunitionPickupConfig.backgroundSpawnDelayRange
    }

    private func canSpawnAmmoPickup(ignoringCooldown: Bool = false) -> Bool {
        guard activeAmmoPickupCount < AmmunitionPickupConfig.maxOnScreen else { return false }
        if isLowOnAmmo { return true }
        if !ignoringCooldown, ammoSpawnCooldownRemaining > 0 { return false }
        return true
    }

    private func noteAmmoPickupSpawned() {
        ammoSpawnCooldownRemaining = TimeInterval.random(
            in: AmmunitionPickupConfig.spawnCooldownRange
        )
    }

    private func prioritizeAmmoPickupIfNeeded() {
        guard isLowOnAmmo, !isGameOver, !isLevelComplete else { return }
        guard activeAmmoPickupCount == 0 else { return }

        ammoPickupSpawnTimer = 0
        nextAmmoPickupSpawnDelay = TimeInterval.random(
            in: AmmunitionPickupConfig.lowAmmoSpawnDelayRange
        )
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

        let hitRadius: CGFloat = CGFloat(asteroidHitRadius)
        let shape = SCNPhysicsShape(geometry: SCNSphere(radius: hitRadius))
        let body = SCNPhysicsBody(type: .kinematic, shape: shape)
        body.categoryBitMask = PhysicsCategory.enemy
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.none
        asteroid.physicsBody = body

        asteroid.runAction(AsteroidFactory.makeTumbleAction())

        worldNode.addChildNode(asteroid)
        registerAsteroidHits(asteroid)
        spawnAmmoPickup(alongside: asteroid)
    }

    private func registerAsteroidHits(_ asteroid: SCNNode) {
        asteroidHitsRemaining[ObjectIdentifier(asteroid)] = levelConfig.hitsPerAsteroid
    }

    private func unregisterAsteroidHits(_ asteroid: SCNNode) {
        asteroidHitsRemaining.removeValue(forKey: ObjectIdentifier(asteroid))
    }

    private var activeAmmoPickupCount: Int {
        worldNode.childNodes.filter { $0.name == "ammoPickup" }.count
    }

    private func spawnAmmoPickup(alongside asteroid: SCNNode) {
        guard canSpawnAmmoPickup() else { return }
        guard Double.random(in: 0...1) <= AmmunitionPickupConfig.asteroidPairedSpawnChance else {
            return
        }

        let position = AmmunitionPickupFactory.positionAlongside(asteroidPosition: asteroid.position)
        spawnAmmoPickup(at: position)
    }

    private func spawnAmmoPickupAhead() {
        let position = AmmunitionPickupFactory.spawnPosition(near: playerRoot.position)
        spawnAmmoPickup(at: position)
    }

    private func spawnAmmoPickup(at position: SCNVector3) {
        guard !isGameOver, !isLevelComplete else { return }
        guard canSpawnAmmoPickup() else { return }
        guard let pickup = AmmunitionPickupFactory.makePickup() else {
            #if DEBUG
            print("[Game3DController] Failed to spawn ammo pickup — Ammunition.usdz not loaded")
            #endif
            return
        }

        pickup.position = position

        let hitRadius = CGFloat(AmmunitionPickupConfig.collectionRadius)
        let shape = SCNPhysicsShape(geometry: SCNSphere(radius: hitRadius))
        let body = SCNPhysicsBody(type: .kinematic, shape: shape)
        body.categoryBitMask = PhysicsCategory.ammoPickup
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.none
        pickup.physicsBody = body

        worldNode.addChildNode(pickup)
        noteAmmoPickupSpawned()

        #if DEBUG
        print(
            "[Game3DController] Ammo pickup spawned at",
            pickup.position,
            "active:",
            activeAmmoPickupCount
        )
        #endif
    }

    // MARK: - Fuel pickups

    private func scheduleNextFuelPickupSpawn(initial: Bool) {
        if initial {
            nextFuelPickupSpawnDelay = TimeInterval.random(
                in: FuelPickupConfig.initialSpawnDelayRange
            )
        } else {
            nextFuelPickupSpawnDelay = TimeInterval.random(
                in: FuelPickupConfig.minSpawnInterval...FuelPickupConfig.maxSpawnInterval
            )
        }
    }

    private func updateFuelPickupSpawning(delta: Float) {
        let hasPickup = worldNode.childNodes.contains { $0.name == "fuelPickup" }
        guard !hasPickup else { return }

        fuelPickupSpawnTimer += TimeInterval(delta)
        guard fuelPickupSpawnTimer >= nextFuelPickupSpawnDelay else { return }

        fuelPickupSpawnTimer = 0
        scheduleNextFuelPickupSpawn(initial: false)
        spawnFuelPickup()
    }

    private func spawnFuelPickup() {
        guard !isGameOver, !isLevelComplete else { return }
        guard let pickup = FuelPickupFactory.makePickup() else {
            #if DEBUG
            print("[Game3DController] Failed to spawn fuel pickup — gas.usdz not loaded")
            #endif
            return
        }

        pickup.position = FuelPickupFactory.spawnPosition(near: playerRoot.position)

        let hitRadius = CGFloat(FuelPickupConfig.collectionRadius)
        let shape = SCNPhysicsShape(geometry: SCNSphere(radius: hitRadius))
        let body = SCNPhysicsBody(type: .kinematic, shape: shape)
        body.categoryBitMask = PhysicsCategory.fuelPickup
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.none
        pickup.physicsBody = body

        worldNode.addChildNode(pickup)

        #if DEBUG
        print(
            "[Game3DController] Fuel pickup spawned at",
            pickup.position,
            "player:",
            playerRoot.position
        )
        #endif
    }

    private func checkFuelPickupCollection() {
        let playerCenter = playerRoot.presentation.worldPosition
        let radius = FuelPickupConfig.collectionRadius

        for node in worldNode.childNodes where node.name == "fuelPickup" {
            let pickupCenter = node.presentation.worldPosition
            if distance(playerCenter, pickupCenter) <= radius {
                collectFuelPickup(node)
                break
            }
        }
    }

    private func collectFuelPickup(_ pickup: SCNNode) {
        guard pickup.name == "fuelPickup", pickup.parent != nil else { return }

        let worldPosition = pickup.presentation.worldPosition
        pickup.removeFromParentNode()
        addFuelRefill()
        addFuelCollectionBurst(at: worldPosition)
    }

    private func addFuelRefill() {
        let bonus = levelConfig.fuelDuration * FuelPickupConfig.refillFraction
        fuelRemaining = min(levelConfig.fuelDuration, fuelRemaining + bonus)
        onFuelChange?(fuelRemaining, levelConfig.fuelDuration, isBoosting)
        onFuelPickupCollected?()
    }

    private func addFuelCollectionBurst(at position: SCNVector3) {
        let burst = SCNNode(geometry: SCNSphere(radius: 0.2))
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.35, green: 0.95, blue: 0.55, alpha: 1)
        material.emission.contents = UIColor(red: 0.2, green: 0.8, blue: 0.45, alpha: 1)
        burst.geometry?.materials = [material]
        burst.position = position
        worldNode.addChildNode(burst)

        let grow = SCNAction.scale(to: 2.2, duration: 0.16)
        let fade = SCNAction.fadeOut(duration: 0.16)
        burst.runAction(SCNAction.sequence([SCNAction.group([grow, fade]), .removeFromParentNode()]))
    }

    // MARK: - Ammunition pickups

    private func scheduleNextAmmoPickupSpawn(initial: Bool) {
        nextAmmoPickupSpawnDelay = TimeInterval.random(in: ammoSpawnDelayRange(initial: initial))
    }

    private func updateAmmoPickupSpawning(delta: Float) {
        guard activeAmmoPickupCount < AmmunitionPickupConfig.maxOnScreen else {
            ammoPickupSpawnTimer = 0
            return
        }

        guard canSpawnAmmoPickup(ignoringCooldown: ammoRemaining == 0) else { return }

        ammoPickupSpawnTimer += TimeInterval(delta)
        guard ammoPickupSpawnTimer >= nextAmmoPickupSpawnDelay else { return }

        ammoPickupSpawnTimer = 0
        scheduleNextAmmoPickupSpawn(initial: false)
        spawnAmmoPickupAhead()
    }

    private func checkAmmoPickupCollection() {
        let playerCenter = playerRoot.presentation.worldPosition
        let radius = AmmunitionPickupConfig.collectionRadius

        for node in worldNode.childNodes where node.name == "ammoPickup" {
            let pickupCenter = node.presentation.worldPosition
            if distance(playerCenter, pickupCenter) <= radius {
                collectAmmoPickup(node)
                break
            }
        }
    }

    private func collectAmmoPickup(_ pickup: SCNNode) {
        guard pickup.name == "ammoPickup", pickup.parent != nil else { return }

        let worldPosition = pickup.presentation.worldPosition
        pickup.removeFromParentNode()
        addAmmoRefill()
        addAmmoCollectionBurst(at: worldPosition)
    }

    private func addAmmoRefill() {
        let bonus = max(1, Int((Double(ammoCapacity) * AmmunitionPickupConfig.refillFraction).rounded()))
        let previous = ammoRemaining
        ammoRemaining = min(ammoCapacity, ammoRemaining + bonus)
        let added = ammoRemaining - previous
        onAmmoChange?(ammoRemaining, ammoCapacity)
        if added > 0 {
            onAmmoPickupCollected?(added)
        }
    }

    private func addAmmoCollectionBurst(at position: SCNVector3) {
        let burst = SCNNode(geometry: SCNSphere(radius: 0.2))
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.95, green: 0.75, blue: 0.25, alpha: 1)
        material.emission.contents = UIColor(red: 0.85, green: 0.6, blue: 0.15, alpha: 1)
        burst.geometry?.materials = [material]
        burst.position = position
        worldNode.addChildNode(burst)

        let grow = SCNAction.scale(to: 2.2, duration: 0.16)
        let fade = SCNAction.fadeOut(duration: 0.16)
        burst.runAction(SCNAction.sequence([SCNAction.group([grow, fade]), .removeFromParentNode()]))
    }

    private func fireBullet() {
        guard ammoRemaining > 0 else { return }

        ammoRemaining -= 1
        onAmmoChange?(ammoRemaining, ammoCapacity)
        prioritizeAmmoPickupIfNeeded()

        let bullet = SCNNode(geometry: SCNSphere(radius: CGFloat(bulletHitRadius)))
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 1, green: 0.92, blue: 0.2, alpha: 1)
        material.emission.contents = UIColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 1)
        bullet.geometry?.materials = [material]
        bullet.name = "bullet"

        let direction = aimDirection()
        let muzzle = playerRoot.presentation.worldPosition
        let spawnOffset: Float = 2.4
        bullet.position = SCNVector3(
            muzzle.x + direction.x * spawnOffset,
            muzzle.y + direction.y * spawnOffset,
            muzzle.z + direction.z * spawnOffset
        )
        scene.rootNode.addChildNode(bullet)

        let worldPosition = bullet.presentation.worldPosition
        activeBullets.append(
            ActiveBullet(
                node: bullet,
                direction: direction,
                traveled: 0,
                previousWorldPosition: worldPosition
            )
        )
    }

    private func updateBullets(delta: Float) {
        guard !activeBullets.isEmpty else { return }

        let step = bulletSpeed * delta
        let hitRadius = asteroidHitRadius + bulletHitRadius
        var remainingBullets: [ActiveBullet] = []

        for var bullet in activeBullets {
            let startPosition = bullet.node.presentation.worldPosition
            bullet.node.position.x += bullet.direction.x * step
            bullet.node.position.y += bullet.direction.y * step
            bullet.node.position.z += bullet.direction.z * step
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
        let id = ObjectIdentifier(enemy)
        var hitsLeft = asteroidHitsRemaining[id] ?? levelConfig.hitsPerAsteroid
        hitsLeft -= 1

        if hitsLeft > 0 {
            asteroidHitsRemaining[id] = hitsLeft
            addHitSpark(at: enemy.presentation.worldPosition)
            return
        }

        unregisterAsteroidHits(enemy)
        addExplosion(at: enemy.presentation.worldPosition)
        enemy.removeFromParentNode()
        missionScoreTracker.recordKill()
        registerKill()
    }

    private func addHitSpark(at position: SCNVector3) {
        let spark = SCNNode(geometry: SCNSphere(radius: 0.15))
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 1, green: 0.75, blue: 0.2, alpha: 1)
        material.emission.contents = UIColor.orange
        spark.geometry?.materials = [material]
        spark.position = position
        worldNode.addChildNode(spark)

        let grow = SCNAction.scale(to: 1.6, duration: 0.1)
        let fade = SCNAction.fadeOut(duration: 0.1)
        spark.runAction(SCNAction.sequence([SCNAction.group([grow, fade]), .removeFromParentNode()]))
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

        if maskA == PhysicsCategory.player && maskB == PhysicsCategory.fuelPickup {
            collectFuelPickup(contact.nodeB)
            return
        }
        if maskB == PhysicsCategory.player && maskA == PhysicsCategory.fuelPickup {
            collectFuelPickup(contact.nodeA)
            return
        }

        if maskA == PhysicsCategory.player && maskB == PhysicsCategory.ammoPickup {
            collectAmmoPickup(contact.nodeB)
            return
        }
        if maskB == PhysicsCategory.player && maskA == PhysicsCategory.ammoPickup {
            collectAmmoPickup(contact.nodeA)
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
    let direction: SCNVector3
    var traveled: Float
    var previousWorldPosition: SCNVector3
}
