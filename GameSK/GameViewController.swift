import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let view = self.view as? SKView else { return }

        let scene = GameScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        view.presentScene(scene)

        view.ignoresSiblingOrder = true
        view.showsFPS = true
        view.showsNodeCount = true
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        guard let view = self.view as? SKView,
              let scene = view.scene as? GameScene else { return }

        scene.size = view.bounds.size
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        }
        return .all
    }

    override var prefersStatusBarHidden: Bool {
        true
    }
}
