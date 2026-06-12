import SceneKit
import UIKit

final class MenuAircraftPreviewView: UIView {

    private let container = UIView()
    private let sceneView = SCNView()
    private var didConfigureScene = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = GameStyle.cockpitBlack.withAlphaComponent(0.45)
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 1.5
        container.layer.borderColor = GameStyle.borderSteel.withAlphaComponent(0.45).cgColor
        container.clipsToBounds = true

        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false
        sceneView.antialiasingMode = .multisampling2X

        addSubview(container)
        container.addSubview(sceneView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 208),

            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),

            sceneView.topAnchor.constraint(equalTo: container.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    func startAnimating() {
        configureSceneIfNeeded()
        sceneView.isPlaying = true
    }

    func stopAnimating() {
        sceneView.isPlaying = false
    }

    private func configureSceneIfNeeded() {
        guard !didConfigureScene else { return }
        didConfigureScene = true

        let scene = SCNScene()
        sceneView.scene = scene

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 48
        cameraNode.position = SCNVector3(0, 1.35, 11.5)
        cameraNode.look(at: SCNVector3(0, 0.25, 0))
        scene.rootNode.addChildNode(cameraNode)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 440
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 700
        key.eulerAngles = SCNVector3(-0.55, 0.75, 0)
        scene.rootNode.addChildNode(key)

        let assembly = Plane3DFactory.makeFlightPlane()
        let planeNode = assembly.rootNode
        planeNode.scale = SCNVector3(0.36, 0.36, 0.36)
        planeNode.position = SCNVector3(0, 0.2, 0)
        planeNode.eulerAngles = SCNVector3(-0.1, .pi * 0.92, 0)
        scene.rootNode.addChildNode(planeNode)

        let rotate = SCNAction.repeatForever(
            SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 16)
        )
        planeNode.runAction(rotate)
    }
}
