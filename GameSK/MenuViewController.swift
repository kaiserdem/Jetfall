import UIKit

final class MenuViewController: UIViewController {

    private var starfieldView: StarfieldBackgroundView?
    private let titleLabel = UILabel()
    private let playButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WorldBuilder3D.spaceColor
        setupTitle()
        setupPlayButton()
        setupActivityIndicator()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        GameAssetLoader.shared.beginPreloadingIfNeeded()
        GameAssetLoader.shared.whenReady { [weak self] in
            self?.showStarfieldIfNeeded()
            self?.updatePlayButtonState()
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
        titleLabel.text = "GameSK"
        titleLabel.font = .boldSystemFont(ofSize: 44)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOpacity = 0.45
        titleLabel.layer.shadowRadius = 6
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -72)
        ])
    }

    private func setupPlayButton() {
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setTitle("Play", for: .normal)
        playButton.titleLabel?.font = .boldSystemFont(ofSize: 22)
        playButton.tintColor = .white
        playButton.backgroundColor = UIColor(red: 0.85, green: 0.2, blue: 0.15, alpha: 0.75)
        playButton.layer.cornerRadius = 28
        playButton.layer.borderColor = UIColor(white: 1, alpha: 0.55).cgColor
        playButton.layer.borderWidth = 2
        playButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 44, bottom: 14, right: 44)
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        view.addSubview(playButton)
        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 36)
        ])
    }

    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: playButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: playButton.centerYAnchor)
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

    private func updatePlayButtonState() {
        playButton.isEnabled = true
        activityIndicator.stopAnimating()
        playButton.setTitle("Play", for: .normal)
    }

    @objc private func playTapped() {
        playButton.isEnabled = false
        playButton.setTitle("", for: .normal)
        activityIndicator.startAnimating()

        GameAssetLoader.shared.whenReady { [weak self] in
            self?.presentGame()
        }
    }

    private func presentGame() {
        guard let gameViewController = storyboard?.instantiateViewController(
            withIdentifier: "GameViewController"
        ) as? GameViewController else {
            updatePlayButtonState()
            return
        }

        gameViewController.modalPresentationStyle = .fullScreen
        gameViewController.modalTransitionStyle = .crossDissolve
        present(gameViewController, animated: true) { [weak self] in
            self?.updatePlayButtonState()
        }
    }
}
