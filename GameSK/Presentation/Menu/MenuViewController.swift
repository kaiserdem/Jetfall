import UIKit

final class MenuViewController: UIViewController {

    private var starfieldView: StarfieldBackgroundView?
    private let titleLabel = UILabel()
    private let missionsButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GameStyle.cockpitBlack
        setupTitle()
        setupMissionsButton()
        setupActivityIndicator()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        GameAssetLoader.shared.beginPreloadingIfNeeded()
        GameAssetLoader.shared.whenReady { [weak self] in
            self?.showStarfieldIfNeeded()
            self?.updateMissionsButtonState()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        starfieldView?.stopAnimating()
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    private func setupTitle() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleTitleLabel(titleLabel, text: "GameSK")
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -72)
        ])
    }

    private func setupMissionsButton() {
        missionsButton.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.applyPrimaryButton(missionsButton, title: "Missions")
        missionsButton.addTarget(self, action: #selector(missionsTapped), for: .touchUpInside)
        view.addSubview(missionsButton)
        NSLayoutConstraint.activate([
            missionsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            missionsButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 36)
        ])
    }

    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = GameStyle.textPrimary
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: missionsButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: missionsButton.centerYAnchor)
        ])
    }

    private func showStarfieldIfNeeded() {
        guard starfieldView == nil else { return }

        let starfield = StarfieldBackgroundView()
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

    private func updateMissionsButtonState() {
        missionsButton.isEnabled = true
        activityIndicator.stopAnimating()
        missionsButton.setTitle("Missions", for: .normal)
    }

    @objc private func missionsTapped() {
        missionsButton.isEnabled = false
        missionsButton.setTitle("", for: .normal)
        activityIndicator.startAnimating()

        GameAssetLoader.shared.whenReady { [weak self] in
            self?.presentLevelSelect()
        }
    }

    private func presentLevelSelect() {
        guard let levelSelect = storyboard?.instantiateViewController(
            withIdentifier: "LevelSelectViewController"
        ) else {
            updateMissionsButtonState()
            return
        }

        levelSelect.modalPresentationStyle = .fullScreen
        levelSelect.modalTransitionStyle = .crossDissolve
        present(levelSelect, animated: true) { [weak self] in
            self?.updateMissionsButtonState()
        }
    }
}
