import UIKit

final class MenuViewController: ImmersiveViewController {

    private var starfieldView: StarfieldBackgroundView?
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let dashboardPanel = MenuDashboardPanel()
    private let aircraftPreview = MenuAircraftPreviewView()
    private let continueButton = UIButton(type: .system)
    private let shopButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let bootOverlay = BootLoadingOverlayView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GameStyle.cockpitBlack
        setupContentStack()
        setupButtons()
        setupActivityIndicator()
        setupBootOverlay()
        beginBootSequence()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshDashboard()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        starfieldView?.stopAnimating()
        aircraftPreview.stopAnimating()
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    private func setupContentStack() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill

        contentStack.addArrangedSubview(dashboardPanel)
        contentStack.addArrangedSubview(aircraftPreview)

        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    private func setupButtons() {
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.applyPrimaryButton(continueButton, title: "Continue Mission")
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        shopButton.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.applySecondaryButton(shopButton, title: "Hangar Shop")
        shopButton.addTarget(self, action: #selector(shopTapped), for: .touchUpInside)

        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.applySecondaryButton(settingsButton, title: "Settings")
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)

        contentStack.addArrangedSubview(continueButton)
        contentStack.addArrangedSubview(shopButton)
        contentStack.addArrangedSubview(settingsButton)

        contentStack.setCustomSpacing(20, after: aircraftPreview)
    }

    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = GameStyle.textPrimary
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: continueButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor)
        ])
    }

    private func setupBootOverlay() {
        bootOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bootOverlay)
        NSLayoutConstraint.activate([
            bootOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            bootOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bootOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bootOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func beginBootSequence() {
        contentStack.alpha = 0
        bootOverlay.alpha = 1
        bootOverlay.isHidden = false
        bootOverlay.startAnimating()

        GameAssetLoader.shared.onProgress = { [weak self] progress in
            self?.bootOverlay.updateProgress(progress)
        }

        GameAssetLoader.shared.whenReady { [weak self] in
            guard let self else { return }
            self.bootOverlay.complete { [weak self] in
                guard let self else { return }
                Plane3DFactory.prepareFlightPlane()
                self.showStarfieldIfNeeded()
                self.aircraftPreview.startAnimating()
                self.updateContinueButtonState()
                UIView.animate(withDuration: 0.3) {
                    self.contentStack.alpha = 1
                }
            }
        }
    }

    private func refreshDashboard() {
        dashboardPanel.update(with: .current())
        aircraftPreview.reloadSelectedPlane()
        aircraftPreview.startAnimating()
    }

    private func showStarfieldIfNeeded() {
        guard starfieldView == nil else { return }

        let starfield = StarfieldBackgroundView(style: .menu)
        starfield.translatesAutoresizingMaskIntoConstraints = false
        starfield.alpha = 0
        view.insertSubview(starfield, at: 0)
        NSLayoutConstraint.activate([
            starfield.topAnchor.constraint(equalTo: view.topAnchor),
            starfield.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            starfield.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            starfield.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        starfieldView = starfield
        starfield.startAnimating()

        UIView.animate(withDuration: 0.35) {
            starfield.alpha = 1
        }
    }

    private func updateContinueButtonState() {
        continueButton.isEnabled = true
        activityIndicator.stopAnimating()
        continueButton.setTitle("Continue Mission", for: .normal)
    }

    @objc private func shopTapped() {
        GameAssetLoader.shared.whenReady { [weak self] in
            self?.presentHangarShop()
        }
    }

    private func presentHangarShop() {
        let shop = HangarShopViewController()
        shop.modalPresentationStyle = .fullScreen
        shop.modalTransitionStyle = .crossDissolve
        present(shop, animated: true)
    }

    @objc private func settingsTapped() {
        presentSettings()
    }

    private func presentSettings() {
        let settings = SettingsViewController()
        settings.modalPresentationStyle = .fullScreen
        settings.modalTransitionStyle = .crossDissolve
        present(settings, animated: true)
    }

    @objc private func continueTapped() {
        continueButton.isEnabled = false
        continueButton.setTitle("", for: .normal)
        activityIndicator.startAnimating()

        GameAssetLoader.shared.whenReady { [weak self] in
            self?.presentLevelSelect()
        }
    }

    private func presentLevelSelect() {
        guard let levelSelect = storyboard?.instantiateViewController(
            withIdentifier: "LevelSelectViewController"
        ) else {
            updateContinueButtonState()
            return
        }

        levelSelect.modalPresentationStyle = .fullScreen
        levelSelect.modalTransitionStyle = .crossDissolve
        present(levelSelect, animated: true) { [weak self] in
            self?.updateContinueButtonState()
        }
    }
}
