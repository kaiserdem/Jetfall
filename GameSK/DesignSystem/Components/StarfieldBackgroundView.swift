import QuartzCore
import SceneKit
import UIKit

final class StarfieldBackgroundView: UIView {

    private let scnView = SCNView()
    private let scene = SCNScene()
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var offsetX: Float = 0
    private var offsetY: Float = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        scnView.translatesAutoresizingMaskIntoConstraints = false
        scnView.backgroundColor = WorldBuilder3D.spaceColor
        scnView.scene = scene
        scnView.isPlaying = true
        scnView.antialiasingMode = .none
        scnView.isUserInteractionEnabled = false
        WorldBuilder3D.applyStarBackground(to: scene)
        addSubview(scnView)
        NSLayoutConstraint.activate([
            scnView.topAnchor.constraint(equalTo: topAnchor),
            scnView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scnView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scnView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopAnimating()
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
        offsetX += delta * 0.0035
        offsetY += delta * 0.0028
        scene.background.contentsTransform = SCNMatrix4MakeTranslation(offsetX, offsetY, 0)
    }
}
