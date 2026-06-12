import UIKit

final class GameHUDView: UIView {

    private let levelLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 22)
        label.textColor = .white
        label.text = "Level 1"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = UIColor(white: 1, alpha: 0.9)
        label.text = "Destroyed: 0 / 3"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = UIColor(white: 1, alpha: 0.85)
        label.text = "Score: 0"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let overlayLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 36)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let actionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    enum OverlayAction {
        case nextLevel
        case retryLevel
        case restartCampaign
    }

    private(set) var overlayAction: OverlayAction?

    var onOverlayTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        addSubview(levelLabel)
        addSubview(progressLabel)
        addSubview(scoreLabel)
        addSubview(overlayLabel)
        addSubview(actionLabel)

        NSLayoutConstraint.activate([
            levelLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
            levelLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            progressLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 4),
            progressLabel.leadingAnchor.constraint(equalTo: levelLabel.leadingAnchor),
            scoreLabel.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 4),
            scoreLabel.leadingAnchor.constraint(equalTo: levelLabel.leadingAnchor),
            overlayLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            overlayLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 10),
            overlayLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            overlayLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24),
            actionLabel.topAnchor.constraint(equalTo: overlayLabel.bottomAnchor, constant: 12),
            actionLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateLevelProgress(level: Int, destroyed: Int, required: Int) {
        levelLabel.text = "Level \(level)"
        progressLabel.text = "Destroyed: \(destroyed) / \(required)"
    }

    func updateScore(_ score: Int) {
        scoreLabel.text = "Score: \(score)"
    }

    func showLevelComplete(level: Int, hasNextLevel: Bool) {
        overlayAction = .nextLevel
        overlayLabel.text = "Level \(level) Complete!"
        actionLabel.text = hasNextLevel ? "Tap for next level" : "Tap to finish"
        showOverlay(true)
    }

    func showGameOver(level: Int) {
        overlayAction = .retryLevel
        overlayLabel.text = "Game Over"
        actionLabel.text = "Tap to retry level \(level)"
        showOverlay(true)
    }

    func showVictory() {
        overlayAction = .restartCampaign
        overlayLabel.text = "All 100 Levels Complete!"
        actionLabel.text = "Tap to play again"
        showOverlay(true)
    }

    func hideOverlay() {
        overlayAction = nil
        showOverlay(false)
    }

    private func showOverlay(_ show: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.overlayLabel.alpha = show ? 1 : 0
            self.actionLabel.alpha = show ? 1 : 0
        }
    }

    @objc private func handleTap() {
        guard overlayLabel.alpha > 0.5 else { return }
        onOverlayTapped?()
    }
}
