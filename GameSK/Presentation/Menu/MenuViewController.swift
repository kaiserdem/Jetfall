import UIKit

final class MenuViewController: UIViewController {

    private var starfieldView: StarfieldBackgroundView?
    private let contentStack = UIStackView()
    private let dashboardPanel = MenuDashboardPanel()
    private let aircraftPreview = MenuAircraftPreviewView()
    private let continueButton = UIButton(type: .system)
    private let shopButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GameStyle.cockpitBlack
        setupContentStack()
        setupButtons()
        setupActivityIndicator()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshDashboard()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        GameAssetLoader.shared.beginPreloadingIfNeeded()
        GameAssetLoader.shared.whenReady { [weak self] in
            Plane3DFactory.prepareFlightPlane()
            self?.showStarfieldIfNeeded()
            self?.aircraftPreview.startAnimating()
            self?.updateContinueButtonState()
        }
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
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .fill

        contentStack.addArrangedSubview(dashboardPanel)
        contentStack.addArrangedSubview(aircraftPreview)

        view.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            contentStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupButtons() {
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.applyPrimaryButton(continueButton, title: "Continue Mission")
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        shopButton.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.applySecondaryButton(shopButton, title: "Hangar Shop")
        shopButton.addTarget(self, action: #selector(shopTapped), for: .touchUpInside)

        contentStack.addArrangedSubview(continueButton)
        contentStack.addArrangedSubview(shopButton)

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

    private func refreshDashboard() {
        dashboardPanel.update(with: .current())
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
