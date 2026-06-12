import UIKit

final class MenuViewController: UIViewController {

    private let starfieldView = StarfieldBackgroundView()
    private let titleLabel = UILabel()
    private let playButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupStarfield()
        setupTitle()
        setupPlayButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        starfieldView.startAnimating()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        starfieldView.stopAnimating()
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    private func setupStarfield() {
        starfieldView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(starfieldView)
        NSLayoutConstraint.activate([
            starfieldView.topAnchor.constraint(equalTo: view.topAnchor),
            starfieldView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            starfieldView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            starfieldView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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

    @objc private func playTapped() {
        guard let gameViewController = storyboard?.instantiateViewController(
            withIdentifier: "GameViewController"
        ) as? GameViewController else {
            return
        }

        gameViewController.modalPresentationStyle = .fullScreen
        gameViewController.modalTransitionStyle = .crossDissolve
        present(gameViewController, animated: true)
    }
}
