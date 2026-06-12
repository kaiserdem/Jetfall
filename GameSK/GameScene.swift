import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    private enum MoveDirection: CaseIterable {
        case up, down, left, right

        var symbol: String {
            switch self {
            case .up: return "▲"
            case .down: return "▼"
            case .left: return "◀"
            case .right: return "▶"
            }
        }
    }

    private var player: SKSpriteNode!
    private var scoreLabel: SKLabelNode!
    private var gameOverLabel: SKLabelNode!
    private var restartLabel: SKLabelNode!
    private var controlsLayer: SKNode!

    private var controlButtons: [MoveDirection: SKNode] = [:]
    private var touchDirections: [UITouch: MoveDirection] = [:]

    private var score = 0
    private var isGameOver = false
    private var lastUpdateTime: TimeInterval = 0
    private var enemySpawnTimer: TimeInterval = 0
    private var fireTimer: TimeInterval = 0

    private let playerCategory = PhysicsCategory.player
    private let bulletCategory = PhysicsCategory.playerBullet
    private let enemyCategory = PhysicsCategory.enemy
    private let moveSpeed: CGFloat = 260
    private let minBankWidthFactor: CGFloat = 0.68
    private let bankLengthStretch: CGFloat = 0.06
    private let bankSmoothing: CGFloat = 10

    private var playerBaseScale: CGFloat = 1
    private var backgroundLayers: [SKNode] = []

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.45, green: 0.72, blue: 0.95, alpha: 1)
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        setupBackground()
        setupPlayer()
        setupControls()
        setupHUD()
    }

    // MARK: - Setup

    private func setupBackground() {
        for index in 0..<3 {
            let layer = SKNode()
            layer.zPosition = CGFloat(-10 + index)
            addChild(layer)
            backgroundLayers.append(layer)

            let cloudCount = 4 + index * 2
            let speed = 40.0 + Double(index) * 25.0

            for _ in 0..<cloudCount {
                let cloud = makeCloud(scale: 0.6 + CGFloat(index) * 0.25)
                cloud.position = CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                )
                cloud.userData = ["speed": speed]
                layer.addChild(cloud)
            }
        }
    }

    private func makeCloud(scale: CGFloat) -> SKNode {
        let cloud = SKNode()
        let base = CGFloat.random(in: 28...48) * scale

        let positions: [CGPoint] = [
            .zero,
            CGPoint(x: base * 0.6, y: base * 0.1),
            CGPoint(x: -base * 0.55, y: base * 0.05),
            CGPoint(x: base * 0.15, y: base * 0.35)
        ]

        for position in positions {
            let puff = SKShapeNode(circleOfRadius: base * 0.45)
            puff.fillColor = SKColor(white: 1, alpha: 0.75)
            puff.strokeColor = .clear
            puff.position = position
            cloud.addChild(puff)
        }

        return cloud
    }

    private func setupPlayer() {
        let texture = SKTexture(imageNamed: "plane1")
        let sprite = SKSpriteNode(texture: texture)

        let targetHeight: CGFloat = 96
        let scale = targetHeight / sprite.size.height
        playerBaseScale = scale
        sprite.setScale(scale)

        player = sprite
        player.position = CGPoint(x: size.width / 2, y: size.height * 0.22)
        player.zPosition = 10

        let bodySize = CGSize(
            width: sprite.size.width * scale * 0.55,
            height: sprite.size.height * scale * 0.75
        )
        let body = SKPhysicsBody(rectangleOf: bodySize)
        body.categoryBitMask = playerCategory
        body.contactTestBitMask = enemyCategory
        body.collisionBitMask = PhysicsCategory.none
        body.allowsRotation = false
        body.isDynamic = false
        player.physicsBody = body

        addChild(player)
    }

    private func setupControls() {
        controlsLayer = SKNode()
        controlsLayer.zPosition = 150
        addChild(controlsLayer)

        let buttonSize: CGFloat = 58
        let spacing: CGFloat = 64
        let margin: CGFloat = 28
        let center = CGPoint(x: margin + spacing, y: margin + spacing)

        let offsets: [MoveDirection: CGPoint] = [
            .up: CGPoint(x: 0, y: spacing),
            .down: CGPoint(x: 0, y: -spacing),
            .left: CGPoint(x: -spacing, y: 0),
            .right: CGPoint(x: spacing, y: 0)
        ]

        for direction in MoveDirection.allCases {
            let button = makeControlButton(direction: direction, size: buttonSize)
            button.position = CGPoint(
                x: center.x + offsets[direction]!.x,
                y: center.y + offsets[direction]!.y
            )
            controlsLayer.addChild(button)
            controlButtons[direction] = button
        }
    }

    private func makeControlButton(direction: MoveDirection, size: CGFloat) -> SKNode {
        let container = SKNode()
        container.name = "control_\(direction)"

        let background = SKShapeNode(circleOfRadius: size / 2)
        background.fillColor = SKColor(white: 0, alpha: 0.35)
        background.strokeColor = SKColor(white: 1, alpha: 0.5)
        background.lineWidth = 2
        background.name = "background"
        container.addChild(background)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = direction.symbol
        label.fontSize = 22
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.fontColor = .white
        label.name = "label"
        container.addChild(label)

        return container
    }

    private func setupHUD() {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 24
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 20, y: size.height - 50)
        scoreLabel.zPosition = 100
        scoreLabel.text = "Рахунок: 0"
        addChild(scoreLabel)

        gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel.fontSize = 40
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 30)
        gameOverLabel.zPosition = 100
        gameOverLabel.alpha = 0
        gameOverLabel.text = "Гра закінчена"
        addChild(gameOverLabel)

        restartLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        restartLabel.fontSize = 22
        restartLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        restartLabel.zPosition = 100
        restartLabel.alpha = 0
        restartLabel.text = "Торкніться, щоб грати знову"
        addChild(restartLabel)
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }

        let delta = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        scrollBackground(delta: delta)

        guard !isGameOver else { return }

        updatePlayerMovement(delta: delta)

        enemySpawnTimer += delta
        fireTimer += delta

        if enemySpawnTimer >= 1.2 {
            enemySpawnTimer = 0
            spawnEnemy()
        }

        if fireTimer >= 0.25 {
            fireTimer = 0
            fireBullet()
        }
    }

    private func updatePlayerMovement(delta: TimeInterval) {
        let active = Set(touchDirections.values)

        var dx: CGFloat = 0
        var dy: CGFloat = 0
        var horizontalInput: CGFloat = 0

        if active.contains(.left) {
            dx -= 1
            horizontalInput -= 1
        }
        if active.contains(.right) {
            dx += 1
            horizontalInput += 1
        }
        if active.contains(.up) { dy += 1 }
        if active.contains(.down) { dy -= 1 }

        if dx != 0, dy != 0 {
            let factor: CGFloat = 0.707
            dx *= factor
            dy *= factor
        }

        if dx != 0 || dy != 0 {
            let distance = moveSpeed * CGFloat(delta)
            let marginX = player.size.width * player.xScale * 0.5 + 8
            let marginY = player.size.height * player.yScale * 0.5 + 8

            player.position.x = min(max(player.position.x + dx * distance, marginX), size.width - marginX)
            player.position.y = min(max(player.position.y + dy * distance, marginY), size.height - marginY)
        }

        updatePlayerBank(delta: delta, horizontalInput: horizontalInput)
    }

    private func updatePlayerBank(delta: TimeInterval, horizontalInput: CGFloat) {
        // Крен з виду зверху: крила нахиляються по осі фюзеляжа — проєкція стає вужчою.
        let bankAmount = min(1, abs(horizontalInput))
        let widthFactor = 1 - bankAmount * (1 - minBankWidthFactor)
        let lengthFactor = 1 + bankAmount * bankLengthStretch

        let targetXScale = playerBaseScale * widthFactor
        let targetYScale = playerBaseScale * lengthFactor

        let blend = min(1, bankSmoothing * CGFloat(delta))
        player.xScale += (targetXScale - player.xScale) * blend
        player.yScale += (targetYScale - player.yScale) * blend
        player.zRotation = 0
    }

    private func scrollBackground(delta: TimeInterval) {
        for layer in backgroundLayers {
            for case let cloud as SKNode in layer.children {
                let speed = cloud.userData?["speed"] as? Double ?? 50
                cloud.position.y -= CGFloat(speed * delta)

                if cloud.position.y < -80 {
                    cloud.position.y = size.height + 80
                    cloud.position.x = CGFloat.random(in: 0...size.width)
                }
            }
        }
    }

    // MARK: - Spawning

    private func spawnEnemy() {
        let enemy = makeEnemyNode()
        let margin: CGFloat = 40
        enemy.position = CGPoint(
            x: CGFloat.random(in: margin...(size.width - margin)),
            y: size.height + 40
        )
        enemy.zPosition = 5
        addChild(enemy)

        let duration = TimeInterval.random(in: 2.8...4.2)
        let move = SKAction.moveTo(y: -60, duration: duration)
        let remove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([move, remove]))
    }

    private func makeEnemyNode() -> SKNode {
        let enemy = SKNode()

        let body = SKShapeNode(rectOf: CGSize(width: 36, height: 36), cornerRadius: 6)
        body.fillColor = SKColor(red: 0.9, green: 0.25, blue: 0.2, alpha: 1)
        body.strokeColor = SKColor(red: 0.6, green: 0.1, blue: 0.1, alpha: 1)
        body.lineWidth = 2
        enemy.addChild(body)

        let wing = SKShapeNode(rectOf: CGSize(width: 48, height: 10), cornerRadius: 2)
        wing.fillColor = SKColor(red: 0.75, green: 0.15, blue: 0.15, alpha: 1)
        wing.strokeColor = .clear
        wing.position = CGPoint(x: 0, y: -2)
        enemy.addChild(wing)

        let physics = SKPhysicsBody(rectangleOf: CGSize(width: 36, height: 36))
        physics.categoryBitMask = enemyCategory
        physics.contactTestBitMask = playerCategory | bulletCategory
        physics.collisionBitMask = PhysicsCategory.none
        physics.allowsRotation = false
        physics.isDynamic = false
        enemy.physicsBody = physics

        return enemy
    }

    private func fireBullet() {
        let bullet = SKShapeNode(circleOfRadius: 5)
        bullet.fillColor = SKColor(red: 1, green: 0.9, blue: 0.2, alpha: 1)
        bullet.strokeColor = .clear
        bullet.position = CGPoint(
            x: player.position.x,
            y: player.position.y + player.size.height * player.yScale * 0.45
        )
        bullet.zPosition = 8

        let physics = SKPhysicsBody(circleOfRadius: 5)
        physics.categoryBitMask = bulletCategory
        physics.contactTestBitMask = enemyCategory
        physics.collisionBitMask = PhysicsCategory.none
        physics.allowsRotation = false
        physics.isDynamic = false
        bullet.physicsBody = physics

        addChild(bullet)

        let move = SKAction.moveBy(x: 0, y: size.height, duration: 1.2)
        let remove = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([move, remove]))
    }

    // MARK: - Collisions

    func didBegin(_ contact: SKPhysicsContact) {
        let bodies = [contact.bodyA, contact.bodyB]

        if bodies.contains(where: { $0.categoryBitMask == playerCategory }),
           bodies.contains(where: { $0.categoryBitMask == enemyCategory }) {
            triggerGameOver()
            return
        }

        guard let bulletBody = bodies.first(where: { $0.categoryBitMask == bulletCategory }),
              let enemyBody = bodies.first(where: { $0.categoryBitMask == enemyCategory }),
              let bullet = bulletBody.node,
              let enemy = enemyBody.node else {
            return
        }

        addExplosion(at: enemy.position)
        bullet.removeFromParent()
        enemy.removeFromParent()
        score += 10
        scoreLabel.text = "Рахунок: \(score)"
    }

    private func addExplosion(at position: CGPoint) {
        let burst = SKShapeNode(circleOfRadius: 8)
        burst.fillColor = SKColor(red: 1, green: 0.6, blue: 0.1, alpha: 0.9)
        burst.strokeColor = .clear
        burst.position = position
        burst.zPosition = 20
        addChild(burst)

        let grow = SKAction.scale(to: 2.5, duration: 0.15)
        let fade = SKAction.fadeOut(withDuration: 0.15)
        let remove = SKAction.removeFromParent()
        burst.run(SKAction.sequence([SKAction.group([grow, fade]), remove]))
    }

    private func triggerGameOver() {
        guard !isGameOver else { return }
        isGameOver = true
        touchDirections.removeAll()
        updateAllButtons(pressed: false)

        addExplosion(at: player.position)
        player.removeFromParent()

        gameOverLabel.run(SKAction.fadeIn(withDuration: 0.3))
        restartLabel.run(SKAction.fadeIn(withDuration: 0.3))
    }

    private func restartGame() {
        let scene = GameScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            restartGame()
            return
        }

        for touch in touches {
            let location = touch.location(in: controlsLayer)
            if let direction = direction(at: location) {
                touchDirections[touch] = direction
                setButtonPressed(direction, pressed: true)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }

        for touch in touches {
            let location = touch.location(in: controlsLayer)

            if let previous = touchDirections[touch] {
                setButtonPressed(previous, pressed: false)
                touchDirections.removeValue(forKey: touch)
            }

            if let direction = direction(at: location) {
                touchDirections[touch] = direction
                setButtonPressed(direction, pressed: true)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let direction = touchDirections.removeValue(forKey: touch) {
                setButtonPressed(direction, pressed: false)
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func direction(at point: CGPoint) -> MoveDirection? {
        for (direction, button) in controlButtons where button.contains(point) {
            return direction
        }
        return nil
    }

    private func setButtonPressed(_ direction: MoveDirection, pressed: Bool) {
        guard let button = controlButtons[direction],
              let background = button.childNode(withName: "background") as? SKShapeNode else {
            return
        }

        background.fillColor = pressed
            ? SKColor(red: 0.85, green: 0.2, blue: 0.15, alpha: 0.65)
            : SKColor(white: 0, alpha: 0.35)
        button.setScale(pressed ? 0.92 : 1.0)
    }

    private func updateAllButtons(pressed: Bool) {
        for direction in MoveDirection.allCases {
            setButtonPressed(direction, pressed: pressed)
        }
    }
}
