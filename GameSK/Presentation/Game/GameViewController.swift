import SceneKit
import UIKit

class GameViewController: UIViewController, VirtualDPadDelegate, FireButtonDelegate {

    var startingLevel = 1

    private var scnView: SCNView!
    private var gameController: Game3DController!
    private let hudView = GameHUDView()
    private let dPadView = VirtualDPadView()
    private let fireButtonView = FireButtonView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GameStyle.cockpitBlack
        setupSceneView()
        setupHUD()
        setupControls()
        startGame()
    }

    private func setupSceneView() {
        scnView = SCNView(frame: view.bounds)
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(scnView, at: 0)
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

    private func setupControls() {
        dPadView.translatesAutoresizingMaskIntoConstraints = false
        dPadView.horizontalAlignment = .right
        dPadView.delegate = self
        view.addSubview(dPadView)

        fireButtonView.translatesAutoresizingMaskIntoConstraints = false
        fireButtonView.delegate = self
        view.addSubview(fireButtonView)

        NSLayoutConstraint.activate([
            dPadView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dPadView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            dPadView.widthAnchor.constraint(equalToConstant: 190),
            dPadView.heightAnchor.constraint(equalToConstant: 190),

            fireButtonView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            fireButtonView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            fireButtonView.widthAnchor.constraint(equalToConstant: 88),
            fireButtonView.heightAnchor.constraint(equalToConstant: 88)
        ])
    }

    private func startGame() {
        gameController = Game3DController(scnView: scnView, startingLevel: startingLevel)

        gameController.onScoreChange = { [weak self] score in
            DispatchQueue.main.async {
                self?.hudView.updateScore(score)
            }
        }

        gameController.onLevelProgress = { [weak self] level, destroyed, required in
            DispatchQueue.main.async {
                self?.hudView.updateLevelProgress(level: level, destroyed: destroyed, required: required)
            }
        }

        gameController.onFuelChange = { [weak self] remaining, total in
            DispatchQueue.main.async {
                self?.hudView.updateFuel(remaining: remaining, total: total)
            }
        }

        gameController.onLevelComplete = { [weak self] level, hasNextLevel in
            DispatchQueue.main.async {
                LevelProgressStore.unlockNext(after: level)
                self?.dPadView.clearAll()
                self?.fireButtonView.clear()
                self?.hudView.showLevelComplete(level: level, hasNextLevel: hasNextLevel)
            }
        }

        gameController.onGameOver = { [weak self] level, outOfFuel in
            DispatchQueue.main.async {
                self?.dPadView.clearAll()
                self?.fireButtonView.clear()
                self?.hudView.showGameOver(level: level, outOfFuel: outOfFuel)
            }
        }

        gameController.onVictory = { [weak self] in
            DispatchQueue.main.async {
                self?.dPadView.clearAll()
                self?.fireButtonView.clear()
                self?.hudView.showVictory()
            }
        }

        hudView.onOverlayTapped = { [weak self] in
            self?.handleOverlayTap()
        }

        hudView.hideOverlay()
        hudView.updateScore(0)
    }

    private func handleOverlayTap() {
        guard let action = hudView.overlayAction else { return }

        switch action {
        case .nextLevel:
            hudView.hideOverlay()
            gameController.advanceToNextLevel()
            startingLevel = gameController.currentLevelNumber
        case .retryLevel:
            hudView.hideOverlay()
            gameController.restartCurrentLevel()
        case .dismissToMissions:
            dismiss(animated: true)
        }
    }

    // MARK: - VirtualDPadDelegate

    func dPad(_ dPad: VirtualDPadView, didUpdate directions: Set<MoveDirection>) {
        gameController.setDirections(directions)
    }

    func fireButton(_ button: FireButtonView, didChangePressed isPressed: Bool) {
        gameController.setFiring(isPressed)
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
