import SceneKit
import UIKit

class GameViewController: ImmersiveViewController, VirtualDPadDelegate, FireButtonDelegate, BoostButtonDelegate {

    var startingLevel = 1

    private var scnView: SCNView!
    private var gameController: Game3DController!
    private let hudView = GameHUDView()
    private let pauseMenuView = PauseMenuView()
    private let missionResultView = MissionResultView()
    private let dPadView = VirtualDPadView()
    private let fireButtonView = FireButtonView()
    private let boostButtonView = BoostButtonView()
    private var isPauseMenuVisible = false
    private var currentScore = 0
    private var lastMissionResult: MissionResultView.Result?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GameStyle.cockpitBlack
        setupSceneView()
        setupHUD()
        setupPauseMenu()
        setupMissionResult()
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

        hudView.pauseButton.addTarget(self, action: #selector(pauseTapped), for: .touchUpInside)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .gameSettingsDidChange,
            object: nil
        )
    }

    isolated deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hudView.updateCrosshairVisibility()
    }

    @objc private func settingsDidChange() {
        hudView.updateCrosshairVisibility()
        gameController?.applyPlaneSizeFromSettings()
    }

    private func setupMissionResult() {
        missionResultView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(missionResultView)
        NSLayoutConstraint.activate([
            missionResultView.topAnchor.constraint(equalTo: view.topAnchor),
            missionResultView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            missionResultView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            missionResultView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        missionResultView.onPrimaryAction = { [weak self] in
            self?.handleMissionResultPrimary()
        }
        missionResultView.onSecondaryAction = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    private func setupPauseMenu() {
        pauseMenuView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pauseMenuView)
        NSLayoutConstraint.activate([
            pauseMenuView.topAnchor.constraint(equalTo: view.topAnchor),
            pauseMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pauseMenuView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pauseMenuView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        pauseMenuView.onContinue = { [weak self] in
            self?.resumeFromPause()
        }
        pauseMenuView.onRestart = { [weak self] in
            self?.restartFromPause()
        }
        pauseMenuView.onExit = { [weak self] in
            self?.dismiss(animated: true)
        }
        pauseMenuView.onShop = { [weak self] in
            self?.presentHangarShop()
        }
        pauseMenuView.onSettings = { [weak self] in
            self?.presentSettings()
        }
    }

    private func setupControls() {
        dPadView.translatesAutoresizingMaskIntoConstraints = false
        dPadView.horizontalAlignment = .right
        dPadView.delegate = self
        view.addSubview(dPadView)

        fireButtonView.translatesAutoresizingMaskIntoConstraints = false
        fireButtonView.delegate = self
        view.addSubview(fireButtonView)

        boostButtonView.translatesAutoresizingMaskIntoConstraints = false
        boostButtonView.delegate = self
        view.addSubview(boostButtonView)

        let sideInset: CGFloat = 20
        // Distance above the safe-area bottom. Smaller values move controls closer to the screen edge.
        let controlsBottomPadding: CGFloat = -12

        NSLayoutConstraint.activate([
            dPadView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sideInset),
            dPadView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -controlsBottomPadding),
            dPadView.widthAnchor.constraint(equalToConstant: 190),
            dPadView.heightAnchor.constraint(equalToConstant: 190),

            fireButtonView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sideInset),
            fireButtonView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -controlsBottomPadding),
            fireButtonView.widthAnchor.constraint(equalToConstant: 88),
            fireButtonView.heightAnchor.constraint(equalToConstant: 88),

            boostButtonView.leadingAnchor.constraint(equalTo: fireButtonView.trailingAnchor, constant: 10),
            boostButtonView.bottomAnchor.constraint(equalTo: fireButtonView.bottomAnchor),
            boostButtonView.widthAnchor.constraint(equalToConstant: 88),
            boostButtonView.heightAnchor.constraint(equalToConstant: 88)
        ])
    }

    private func startGame() {
        gameController = Game3DController(scnView: scnView, startingLevel: startingLevel)

        gameController.onAmmoChange = { [weak self] remaining, capacity in
            DispatchQueue.main.async {
                self?.hudView.updateAmmo(remaining: remaining, capacity: capacity)
            }
        }

        gameController.onAmmoPickupCollected = { [weak self] added in
            DispatchQueue.main.async {
                self?.hudView.showAmmoPickupBonus(added: added)
            }
        }

        gameController.onLevelProgress = { [weak self] level, destroyed, required in
            DispatchQueue.main.async {
                self?.hudView.updateLevelProgress(level: level, destroyed: destroyed, required: required)
            }
        }

        gameController.onFuelChange = { [weak self] remaining, total, afterburnerActive in
            DispatchQueue.main.async {
                self?.hudView.updateFuel(
                    remaining: remaining,
                    total: total,
                    afterburnerActive: afterburnerActive
                )
            }
        }

        gameController.onFuelPickupCollected = { [weak self] in
            DispatchQueue.main.async {
                self?.hudView.showFuelPickupBonus()
            }
        }

        gameController.onLevelComplete = { [weak self] level, hasNextLevel, result in
            DispatchQueue.main.async {
                guard let self else { return }
                LevelProgressStore.unlockNext(after: level)
                PlayerWallet.addCredits(result.total)
                self.currentScore = result.total
                self.presentMissionResult(
                    .levelComplete(
                        level: level,
                        result: result,
                        hasNextLevel: hasNextLevel
                    )
                )
            }
        }

        gameController.onGameOver = { [weak self] level, outOfFuel in
            DispatchQueue.main.async {
                guard let self else { return }
                let killPoints = self.gameController.missionKillPoints
                self.currentScore = killPoints
                self.presentMissionResult(
                    .gameOver(
                        level: level,
                        killPoints: killPoints,
                        outOfFuel: outOfFuel
                    )
                )
            }
        }

        gameController.onVictory = { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.currentScore = result.total
                self.presentMissionResult(.campaignVictory(result: result))
            }
        }

        currentScore = 0
        hudView.setPauseEnabled(true)
        gameController.refreshHUD()
        GameAssetLoader.shared.whenReady { [weak self] in
            self?.hudView.refreshAmmunitionIcon()
            self?.hudView.refreshAsteroidIcon()
            self?.hudView.refreshFuelIcon()
        }
        isPauseMenuVisible = false
        pauseMenuView.hide(animated: false)
        missionResultView.dismiss(animated: false)
    }

    @objc private func pauseTapped() {
        guard !isPauseMenuVisible, !missionResultView.isPresented else { return }
        presentPause()
    }

    private func presentPause() {
        dPadView.clearAll()
        fireButtonView.clear()
        boostButtonView.clear()
        gameController.pause()
        setControlsEnabled(false)
        isPauseMenuVisible = true
        pauseMenuView.show()
    }

    private func resumeFromPause() {
        pauseMenuView.hide { [weak self] in
            guard let self else { return }
            self.isPauseMenuVisible = false
            self.gameController.resume()
            self.setControlsEnabled(true)
        }
    }

    private func restartFromPause() {
        dPadView.clearAll()
        fireButtonView.clear()
        boostButtonView.clear()
        pauseMenuView.hide { [weak self] in
            guard let self else { return }
            self.isPauseMenuVisible = false
            self.gameController.restartCurrentLevel()
            self.setControlsEnabled(true)
        }
    }

    private func setControlsEnabled(_ enabled: Bool) {
        dPadView.isUserInteractionEnabled = enabled
        fireButtonView.isUserInteractionEnabled = enabled
        boostButtonView.isUserInteractionEnabled = enabled
        dPadView.alpha = enabled ? 1 : 0.45
        fireButtonView.alpha = enabled ? 1 : 0.45
        boostButtonView.alpha = enabled ? 1 : 0.45
    }

    private func presentHangarShop() {
        let shop = HangarShopViewController()
        shop.modalPresentationStyle = .fullScreen
        shop.modalTransitionStyle = .crossDissolve
        present(shop, animated: true)
    }

    private func presentSettings() {
        let settings = SettingsViewController()
        settings.modalPresentationStyle = .fullScreen
        settings.modalTransitionStyle = .crossDissolve
        present(settings, animated: true)
    }

    private func presentMissionResult(_ result: MissionResultView.Result) {
        lastMissionResult = result
        dPadView.clearAll()
        fireButtonView.clear()
        boostButtonView.clear()
        setControlsEnabled(false)
        hudView.setPauseEnabled(false)
        missionResultView.present(result)
    }

    private func handleMissionResultPrimary() {
        guard let result = lastMissionResult else { return }

        missionResultView.dismiss { [weak self] in
            guard let self else { return }
            self.lastMissionResult = nil

            switch result {
            case let .levelComplete(_, _, hasNextLevel):
                if hasNextLevel {
                    self.hudView.setPauseEnabled(true)
                    self.setControlsEnabled(true)
                    self.gameController.advanceToNextLevel()
                    self.startingLevel = self.gameController.currentLevelNumber
                } else {
                    self.dismiss(animated: true)
                }
            case .gameOver:
                self.hudView.setPauseEnabled(true)
                self.setControlsEnabled(true)
                self.gameController.restartCurrentLevel()
            case .campaignVictory:
                self.dismiss(animated: true)
            }
        }
    }

    // MARK: - VirtualDPadDelegate

    func dPad(_ dPad: VirtualDPadView, didUpdate directions: Set<MoveDirection>) {
        gameController.setDirections(directions)
    }

    func fireButton(_ button: FireButtonView, didChangePressed isPressed: Bool) {
        gameController.setFiring(isPressed)
    }

    func boostButton(_ button: BoostButtonView, didChangePressed isPressed: Bool) {
        gameController.setBoosting(isPressed)
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
