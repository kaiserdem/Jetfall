import SceneKit
import UIKit

enum WorldBuilder3D {

    static let spaceColor = UIColor(red: 0.02, green: 0.04, blue: 0.14, alpha: 1)

    private static var starsImage: UIImage?
    private static var starOffsetX: Float = 0
    private static var starOffsetY: Float = 0
    private static var lastPlayerX: Float = 0
    private static var lastPlayerY: Float = 0
    private static var tracksPlayer = false

    static func resetStarMotion() {
        starOffsetX = 0
        starOffsetY = 0
        lastPlayerX = 0
        lastPlayerY = 0
        tracksPlayer = false
    }

    static func configureEnvironment(for scene: SCNScene) {
        scene.background.contents = starsTexture()
        scene.background.wrapS = .repeat
        scene.background.wrapT = .repeat
        scene.fogColor = spaceColor
        scene.fogStartDistance = 80
        scene.fogEndDistance = 200
        scene.fogDensityExponent = 0.9
    }

    static func updateStars(
        for scene: SCNScene,
        playerPosition: SCNVector3,
        delta: Float
    ) {
        if !tracksPlayer {
            lastPlayerX = playerPosition.x
            lastPlayerY = playerPosition.y
            tracksPlayer = true
        }

        let playerDeltaX = playerPosition.x - lastPlayerX
        let playerDeltaY = playerPosition.y - lastPlayerY
        lastPlayerX = playerPosition.x
        lastPlayerY = playerPosition.y

        starOffsetX += -playerDeltaX * 0.007
        starOffsetY += -playerDeltaY * 0.007
        starOffsetX += delta * 0.0035
        starOffsetY += delta * 0.0028

        scene.background.contentsTransform = SCNMatrix4MakeTranslation(starOffsetX, starOffsetY, 0)
    }

    private static func starsTexture() -> UIImage {
        if let starsImage {
            return starsImage
        }

        let image = drawStarsImage()
        starsImage = image
        return image
    }

    private static func drawStarsImage() -> UIImage {
        let size = 1024
        var rng = SeededRNG(seed: 77)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
        return renderer.image { ctx in
            let context = ctx.cgContext
            spaceColor.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))

            for _ in 0..<1800 {
                drawStar(
                    in: context,
                    x: CGFloat.random(in: 0...CGFloat(size), using: &rng),
                    y: CGFloat.random(in: 0...CGFloat(size), using: &rng),
                    radius: CGFloat.random(in: 0.8...2.2, using: &rng),
                    color: starColor(using: &rng),
                    canvasSize: CGFloat(size)
                )
            }
        }
    }

    private static func drawStar(
        in context: CGContext,
        x: CGFloat,
        y: CGFloat,
        radius: CGFloat,
        color: UIColor,
        canvasSize: CGFloat
    ) {
        let rect = CGRect(x: x - radius / 2, y: y - radius / 2, width: radius, height: radius)
        color.setFill()
        context.fillEllipse(in: rect)

        if x < radius {
            context.fillEllipse(in: rect.offsetBy(dx: canvasSize, dy: 0))
        }
        if y < radius {
            context.fillEllipse(in: rect.offsetBy(dx: 0, dy: canvasSize))
        }
        if x < radius, y < radius {
            context.fillEllipse(in: rect.offsetBy(dx: canvasSize, dy: canvasSize))
        }
        if x > canvasSize - radius {
            context.fillEllipse(in: rect.offsetBy(dx: -canvasSize, dy: 0))
        }
        if y > canvasSize - radius {
            context.fillEllipse(in: rect.offsetBy(dx: 0, dy: -canvasSize))
        }
        if x > canvasSize - radius, y > canvasSize - radius {
            context.fillEllipse(in: rect.offsetBy(dx: -canvasSize, dy: -canvasSize))
        }
    }

    private static func starColor(using rng: inout SeededRNG) -> UIColor {
        switch Int.random(in: 0..<100, using: &rng) {
        case 0..<55:
            let v = CGFloat.random(in: 0.85...1, using: &rng)
            return UIColor(white: v, alpha: 1)
        case 55..<75:
            return UIColor(
                red: CGFloat.random(in: 0.7...0.9, using: &rng),
                green: CGFloat.random(in: 0.85...1, using: &rng),
                blue: 1,
                alpha: 1
            )
        case 75..<90:
            return UIColor(
                red: 1,
                green: CGFloat.random(in: 0.9...1, using: &rng),
                blue: CGFloat.random(in: 0.65...0.85, using: &rng),
                alpha: 1
            )
        default:
            return UIColor(
                red: 1,
                green: CGFloat.random(in: 0.75...0.9, using: &rng),
                blue: CGFloat.random(in: 0.75...0.9, using: &rng),
                alpha: 1
            )
        }
    }
}

private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
