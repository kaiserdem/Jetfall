import UIKit

final class SettingsViewController: UIViewController {

    private var starfieldView: StarfieldBackgroundView?
    private let contentStack = UIStackView()
    private let topBar = UIView()
    private let backButton = AviatorNavButton(style: .labeled(title: "Back"))
    private let titleLabel = UILabel()
    private let optionsStack = UIStackView()

    private let planeSizeRow = SettingsSliderRowView(
        title: "Plane Size",
        subtitle: "Changes apply immediately and on mission restart.",
        minimum: GameSettingsStore.planeSizeRange.lowerBound,
        maximum: GameSettingsStore.planeSizeRange.upperBound
    )
    private let crosshairRow = SettingsToggleRowView(
        title: "Crosshair",
        subtitle: "Show an aim reticle in the center of the game screen."
    )
    private let soundRow = SettingsToggleRowView(
        title: "Sound",
        subtitle: "Play weapon fire audio during combat."
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GameStyle.cockpitBlack
        setupLayout()
        loadSettings()
        bindControls()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showStarfieldIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        starfieldView?.stopAnimating()
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    private func setupLayout() {
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 14

        topBar.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleHUDLabel(titleLabel, size: 24, weight: .heavy)
        titleLabel.text = "SETTINGS"
        titleLabel.textAlignment = .center

        optionsStack.translatesAutoresizingMaskIntoConstraints = false
        optionsStack.axis = .vertical
        optionsStack.spacing = 12
        optionsStack.addArrangedSubview(planeSizeRow)
        optionsStack.addArrangedSubview(crosshairRow)
        optionsStack.addArrangedSubview(soundRow)

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        topBar.addSubview(backButton)
        topBar.addSubview(titleLabel)

        contentStack.addArrangedSubview(topBar)
        contentStack.addArrangedSubview(optionsStack)
        view.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            topBar.heightAnchor.constraint(equalToConstant: 40),

            backButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: topBar.trailingAnchor, constant: -8)
        ])
    }

    private func loadSettings() {
        planeSizeRow.configure(value: GameSettingsStore.planeSizeMultiplier)
        crosshairRow.configure(isOn: GameSettingsStore.isCrosshairEnabled)
        soundRow.configure(isOn: GameSettingsStore.isSoundEnabled)
    }

    private func bindControls() {
        planeSizeRow.onValueChanged = { value in
            GameSettingsStore.planeSizeMultiplier = value
        }
        crosshairRow.onValueChanged = { isOn in
            GameSettingsStore.isCrosshairEnabled = isOn
        }
        soundRow.onValueChanged = { isOn in
            GameSettingsStore.isSoundEnabled = isOn
        }
    }

    private func showStarfieldIfNeeded() {
        guard starfieldView == nil else {
            starfieldView?.startAnimating()
            return
        }

        let starfield = StarfieldBackgroundView(style: .menu)
        starfield.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(starfield, at: 0)
        NSLayoutConstraint.activate([
            starfield.topAnchor.constraint(equalTo: view.topAnchor),
            starfield.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            starfield.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            starfield.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        starfieldView = starfield
        starfield.startAnimating()
    }

    @objc private func backTapped() {
        dismiss(animated: true)
    }
}
