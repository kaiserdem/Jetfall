import SceneKit
import UIKit

class GameViewController: UIViewController, VirtualDPadDelegate {

    private var scnView: SCNView!
    private var gameController: Game3DController!
    private let hudView = GameHUDView()
    private let dPadView = VirtualDPadView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
        setupHUD()
        setupDPad()
        startGame()
    }

    private func setupSceneView() {
        scnView = SCNView(frame: view.bounds)
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scnView)
    }

    private func setupHUD() {
        hudView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hudView)
        NSLayoutConstraint.activate([
            hudView.topAnchor.constraint(equalTo: view.topAnchor),
            hudView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hudView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hudView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupDPad() {
        dPadView.translatesAutoresizingMaskIntoConstraints = false
        dPadView.delegate = self
        view.addSubview(dPadView)
        NSLayoutConstraint.activate([
            dPadView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dPadView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            dPadView.widthAnchor.constraint(equalToConstant: 220),
            dPadView.heightAnchor.constraint(equalToConstant: 220)
        ])
    }

    private func startGame() {
        gameController = Game3DController(scnView: scnView)

        gameController.onScoreChange = { [weak self] score in
            DispatchQueue.main.async {
                self?.hudView.updateScore(score)
            }
        }

        gameController.onGameOver = { [weak self] in
            DispatchQueue.main.async {
                self?.hudView.showGameOver(true)
                self?.dPadView.clearAll()
            }
        }

        hudView.onRestartTapped = { [weak self] in
            self?.restartGame()
        }

        hudView.updateScore(0)
        hudView.showGameOver(false)
    }

    private func restartGame() {
        scnView.delegate = nil
        scnView.scene = nil
        startGame()
    }

    // MARK: - VirtualDPadDelegate

    func dPad(_ dPad: VirtualDPadView, didUpdate directions: Set<MoveDirection>) {
        gameController.setDirections(directions)
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
