import SceneKit
import UIKit

enum AircraftPreviewSceneBuilder {

    enum Style {
        case thumbnail
        case fullscreen
    }

    @discardableResult
    static func attach(to sceneView: SCNView, style: Style) -> SCNNode {
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = style == .fullscreen
        sceneView.antialiasingMode = style == .fullscreen ? .multisampling4X : .multisampling2X

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = style == .fullscreen ? 42 : 48
        cameraNode.position = SCNVector3(0, style == .fullscreen ? 1.4 : 1.6, style == .fullscreen ? 4.0 : 5.4)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = style == .fullscreen ? 500 : 420
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = style == .fullscreen ? 900 : 650
        key.eulerAngles = SCNVector3(-0.6, 0.8, 0)
        scene.rootNode.addChildNode(key)

        let assembly = Plane3DFactory.makeFlightPlane()
        let planeNode = assembly.rootNode
        let planeScale: Float = style == .fullscreen ? 1.28 : 1.18
        planeNode.scale = SCNVector3(planeScale, planeScale, planeScale)
        planeNode.eulerAngles = SCNVector3(-0.1, .pi * 0.92, 0)
        scene.rootNode.addChildNode(planeNode)

        if style == .thumbnail {
            let rotate = SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 14)
            )
            planeNode.runAction(rotate)
        }

        return planeNode
    }
}
