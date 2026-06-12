import QuartzCore
import SceneKit
import UIKit

enum StarfieldBackgroundStyle {
    case menu
    case missions
    case hangarShop

    var spaceColor: UIColor {
        switch self {
        case .menu:
            return UIColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 1)
        case .missions:
            return UIColor(red: 0.06, green: 0.04, blue: 0.10, alpha: 1)
        case .hangarShop:
            return UIColor(red: 0.03, green: 0.08, blue: 0.13, alpha: 1)
        }
    }

    var starCount: Int {
        switch self {
        case .menu: return 1_050
        case .missions: return 1_650
        case .hangarShop: return 2_100
        }
    }

    var minStarRadius: CGFloat {
        switch self {
        case .menu: return 1.1
        case .missions: return 0.8
        case .hangarShop: return 0.55
        }
    }

    var maxStarRadius: CGFloat {
        switch self {
        case .menu: return 3.4
        case .missions: return 2.1
        case .hangarShop: return 1.7
        }
    }

    var textureSeed: UInt64 {
        switch self {
        case .menu: return 42
        case .missions: return 77
        case .hangarShop: return 129
        }
    }

    var driftSpeed: (x: Float, y: Float) {
        switch self {
        case .menu: return (0.0021, 0.0017)
        case .missions: return (0.0035, 0.0028)
        case .hangarShop: return (0.0046, 0.0034)
        }
    }

    var warmStarBias: Int {
        switch self {
        case .menu: return 82
        case .missions: return 68
        case .hangarShop: return 38
        }
    }

    var gradientColors: [UIColor] {
        switch self {
        case .menu:
            return [
                UIColor(red: 0.95, green: 0.72, blue: 0.18, alpha: 0.10),
                UIColor.clear,
                UIColor(red: 0.82, green: 0.14, blue: 0.12, alpha: 0.08)
            ]
        case .missions:
            return [
                UIColor(red: 0.92, green: 0.22, blue: 0.16, alpha: 0.12),
                UIColor.clear,
                UIColor(red: 0.10, green: 0.16, blue: 0.28, alpha: 0.18)
            ]
        case .hangarShop:
            return [
                UIColor(red: 0.18, green: 0.42, blue: 0.72, alpha: 0.14),
                UIColor.clear,
                UIColor(red: 0.10, green: 0.22, blue: 0.36, alpha: 0.20)
            ]
        }
    }
}

final class StarfieldBackgroundView: UIView {

    private let style: StarfieldBackgroundStyle
    private let scnView = SCNView()
    private let scene = SCNScene()
    private let gradientOverlay = UIView()
    private let gradientLayer = CAGradientLayer()
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var offsetX: Float = 0
    private var offsetY: Float = 0

    private static var textureCache: [StarfieldBackgroundStyle: UIImage] = [:]

    init(style: StarfieldBackgroundStyle = .missions) {
        self.style = style
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        self.style = .missions
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = gradientOverlay.bounds
    }

    deinit {
        stopAnimating()
    }

    private func setup() {
        scnView.translatesAutoresizingMaskIntoConstraints = false
        scnView.backgroundColor = style.spaceColor
        scnView.scene = scene
        scnView.isPlaying = true
        scnView.antialiasingMode = .none
        scnView.isUserInteractionEnabled = false

        scene.background.contents = Self.texture(for: style)
        scene.background.wrapS = .repeat
        scene.background.wrapT = .repeat

        gradientOverlay.translatesAutoresizingMaskIntoConstraints = false
        gradientOverlay.isUserInteractionEnabled = false
        gradientLayer.colors = style.gradientColors.map(\.cgColor)
        gradientLayer.locations = [0, 0.52, 1]
        gradientLayer.startPoint = CGPoint(x: 0.1, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.9, y: 1)
        gradientOverlay.layer.addSublayer(gradientLayer)

        addSubview(scnView)
        addSubview(gradientOverlay)

        NSLayoutConstraint.activate([
            scnView.topAnchor.constraint(equalTo: topAnchor),
            scnView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scnView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scnView.bottomAnchor.constraint(equalTo: bottomAnchor),

            gradientOverlay.topAnchor.constraint(equalTo: topAnchor),
            gradientOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientOverlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func startAnimating() {
        guard displayLink == nil else { return }
        lastTimestamp = 0
        let link = CADisplayLink(target: self, selector: #selector(step))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stopAnimating() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = 0
    }

    @objc private func step(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }

        let delta = Float(link.timestamp - lastTimestamp)
        lastTimestamp = link.timestamp
        offsetX += delta * style.driftSpeed.x
        offsetY += delta * style.driftSpeed.y
        scene.background.contentsTransform = SCNMatrix4MakeTranslation(offsetX, offsetY, 0)
    }

    private static func texture(for style: StarfieldBackgroundStyle) -> UIImage {
        if let cached = textureCache[style] {
            return cached
        }

        let image = drawStarsImage(for: style)
        textureCache[style] = image
        return image
    }

    private static func drawStarsImage(for style: StarfieldBackgroundStyle) -> UIImage {
        let size = 1024
        var rng = StarfieldSeededRNG(seed: style.textureSeed)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
        return renderer.image { ctx in
            let context = ctx.cgContext
            style.spaceColor.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))

            if style == .menu {
                drawMenuStars(in: context, canvasSize: CGFloat(size), rng: &rng)
            } else {
                for _ in 0..<style.starCount {
                    drawStar(
                        in: context,
                        x: CGFloat.random(in: 0...CGFloat(size), using: &rng),
                        y: CGFloat.random(in: 0...CGFloat(size), using: &rng),
                        radius: CGFloat.random(in: style.minStarRadius...style.maxStarRadius, using: &rng),
                        color: starColor(for: style, using: &rng),
                        canvasSize: CGFloat(size)
                    )
                }
            }
        }
    }

    private static func drawMenuStars(
        in context: CGContext,
        canvasSize: CGFloat,
        rng: inout StarfieldSeededRNG
    ) {
        for _ in 0..<880 {
            drawStar(
                in: context,
                x: CGFloat.random(in: 0...canvasSize, using: &rng),
                y: CGFloat.random(in: 0...canvasSize, using: &rng),
                radius: CGFloat.random(in: 0.65...1.5, using: &rng),
                color: menuStarColor(accent: false, using: &rng),
                canvasSize: canvasSize
            )
        }

        for _ in 0..<110 {
            drawStar(
                in: context,
                x: CGFloat.random(in: 0...canvasSize, using: &rng),
                y: CGFloat.random(in: 0...canvasSize, using: &rng),
                radius: CGFloat.random(in: 1.8...2.8, using: &rng),
                color: menuStarColor(accent: false, using: &rng),
                canvasSize: canvasSize
            )
        }

        for _ in 0..<34 {
            let radius = CGFloat.random(in: 3.4...5.8, using: &rng)
            let color = menuStarColor(accent: true, using: &rng)
            let x = CGFloat.random(in: 0...canvasSize, using: &rng)
            let y = CGFloat.random(in: 0...canvasSize, using: &rng)
            drawStarGlow(
                in: context,
                x: x,
                y: y,
                radius: radius,
                color: color,
                canvasSize: canvasSize
            )
            drawStar(
                in: context,
                x: x,
                y: y,
                radius: radius,
                color: color,
                canvasSize: canvasSize
            )
        }
    }

    private static func drawStarGlow(
        in context: CGContext,
        x: CGFloat,
        y: CGFloat,
        radius: CGFloat,
        color: UIColor,
        canvasSize: CGFloat
    ) {
        let glowRadius = radius * 2.1
        let glowColor = color.withAlphaComponent(0.22)
        drawStar(
            in: context,
            x: x,
            y: y,
            radius: glowRadius,
            color: glowColor,
            canvasSize: canvasSize
        )
    }

    private static func menuStarColor(accent: Bool, using rng: inout StarfieldSeededRNG) -> UIColor {
        let roll = Int.random(in: 0..<100, using: &rng)

        if accent {
            switch roll {
            case 0..<28:
                return UIColor(red: 0.95, green: 0.72, blue: 0.18, alpha: 1)
            case 28..<48:
                return UIColor(red: 0.92, green: 0.28, blue: 0.20, alpha: 1)
            case 48..<68:
                return UIColor(red: 0.55, green: 0.82, blue: 1.0, alpha: 1)
            case 68..<84:
                return UIColor(red: 0.45, green: 0.90, blue: 0.72, alpha: 1)
            default:
                return UIColor(red: 0.88, green: 0.88, blue: 1.0, alpha: 1)
            }
        }

        switch roll {
        case 0..<42:
            return UIColor(white: CGFloat.random(in: 0.82...1, using: &rng), alpha: 1)
        case 42..<62:
            return UIColor(
                red: CGFloat.random(in: 0.92...1, using: &rng),
                green: CGFloat.random(in: 0.74...0.9, using: &rng),
                blue: CGFloat.random(in: 0.35...0.58, using: &rng),
                alpha: 1
            )
        case 62..<78:
            return UIColor(
                red: CGFloat.random(in: 0.62...0.82, using: &rng),
                green: CGFloat.random(in: 0.78...0.95, using: &rng),
                blue: 1,
                alpha: 1
            )
        case 78..<90:
            return UIColor(
                red: 1,
                green: CGFloat.random(in: 0.62...0.78, using: &rng),
                blue: CGFloat.random(in: 0.55...0.72, using: &rng),
                alpha: 1
            )
        default:
            return UIColor(
                red: CGFloat.random(in: 0.55...0.75, using: &rng),
                green: CGFloat.random(in: 0.88...1, using: &rng),
                blue: CGFloat.random(in: 0.82...0.98, using: &rng),
                alpha: 1
            )
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

    private static func starColor(for style: StarfieldBackgroundStyle, using rng: inout StarfieldSeededRNG) -> UIColor {
        let roll = Int.random(in: 0..<100, using: &rng)

        switch style {
        case .menu:
            if roll < style.warmStarBias {
                return UIColor(
                    red: CGFloat.random(in: 0.92...1, using: &rng),
                    green: CGFloat.random(in: 0.78...0.95, using: &rng),
                    blue: CGFloat.random(in: 0.45...0.72, using: &rng),
                    alpha: 1
                )
            }
            let value = CGFloat.random(in: 0.82...1, using: &rng)
            return UIColor(white: value, alpha: 1)

        case .missions:
            if roll < 28 {
                return UIColor(
                    red: 1,
                    green: CGFloat.random(in: 0.72...0.9, using: &rng),
                    blue: CGFloat.random(in: 0.55...0.75, using: &rng),
                    alpha: 1
                )
            }
            if roll < style.warmStarBias {
                let value = CGFloat.random(in: 0.85...1, using: &rng)
                return UIColor(white: value, alpha: 1)
            }
            return UIColor(
                red: CGFloat.random(in: 0.7...0.9, using: &rng),
                green: CGFloat.random(in: 0.85...1, using: &rng),
                blue: 1,
                alpha: 1
            )

        case .hangarShop:
            if roll < style.warmStarBias {
                let value = CGFloat.random(in: 0.78...0.96, using: &rng)
                return UIColor(white: value, alpha: 1)
            }
            return UIColor(
                red: CGFloat.random(in: 0.55...0.82, using: &rng),
                green: CGFloat.random(in: 0.78...0.98, using: &rng),
                blue: 1,
                alpha: 1
            )
        }
    }
}

private struct StarfieldSeededRNG: RandomNumberGenerator {
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
