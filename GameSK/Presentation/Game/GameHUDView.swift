import UIKit

final class GameHUDView: UIView {

    private let statsPanel = UIView()
    private let levelLabel = UILabel()
    private let progressLabel = UILabel()
    private let scoreLabel = UILabel()
    private let fuelGauge = FuelGaugeView()

    private let overlayPanel = UIView()
    private let overlayLabel = UILabel()
    private let actionLabel = UILabel()

    enum OverlayAction {
        case nextLevel
        case retryLevel
        case dismissToMissions
    }

    private(set) var overlayAction: OverlayAction?

    var onOverlayTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        setupStatsPanel()
        setupOverlay()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupStatsPanel() {
        statsPanel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.stylePanel(statsPanel, cornerRadius: 12)

        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleHUDLabel(levelLabel, size: 20, weight: .heavy)
        levelLabel.text = "Level 1"

        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleSubtitleLabel(progressLabel, size: 15)
        progressLabel.text = "Destroyed: 0 / 10"

        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleSubtitleLabel(scoreLabel, size: 15)
        scoreLabel.text = "Score: 0"

        fuelGauge.translatesAutoresizingMaskIntoConstraints = false

        addSubview(statsPanel)
        statsPanel.addSubview(levelLabel)
        statsPanel.addSubview(progressLabel)
        statsPanel.addSubview(scoreLabel)
        addSubview(fuelGauge)

        NSLayoutConstraint.activate([
            statsPanel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            statsPanel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            statsPanel.widthAnchor.constraint(equalToConstant: 168),
            levelLabel.topAnchor.constraint(equalTo: statsPanel.topAnchor, constant: 10),
            levelLabel.leadingAnchor.constraint(equalTo: statsPanel.leadingAnchor, constant: 12),
            progressLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 4),
            progressLabel.leadingAnchor.constraint(equalTo: levelLabel.leadingAnchor),
            scoreLabel.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 2),
            scoreLabel.leadingAnchor.constraint(equalTo: levelLabel.leadingAnchor),
            scoreLabel.bottomAnchor.constraint(equalTo: statsPanel.bottomAnchor, constant: -10),
            fuelGauge.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            fuelGauge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            fuelGauge.widthAnchor.constraint(equalToConstant: 148)
        ])
    }

    private func setupOverlay() {
        overlayPanel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleOverlayPanel(overlayPanel)
        overlayPanel.alpha = 0
        overlayPanel.isUserInteractionEnabled = false

        overlayLabel.translatesAutoresizingMaskIntoConstraints = false
        overlayLabel.font = .systemFont(ofSize: 30, weight: .heavy)
        overlayLabel.textColor = GameStyle.textPrimary
        overlayLabel.textAlignment = .center
        overlayLabel.numberOfLines = 0

        actionLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleSubtitleLabel(actionLabel, size: 18)
        actionLabel.textAlignment = .center

        addSubview(overlayPanel)
        overlayPanel.addSubview(overlayLabel)
        overlayPanel.addSubview(actionLabel)

        NSLayoutConstraint.activate([
            overlayPanel.centerXAnchor.constraint(equalTo: centerXAnchor),
            overlayPanel.centerYAnchor.constraint(equalTo: centerYAnchor),
            overlayPanel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            overlayPanel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24),
            overlayLabel.topAnchor.constraint(equalTo: overlayPanel.topAnchor, constant: 20),
            overlayLabel.leadingAnchor.constraint(equalTo: overlayPanel.leadingAnchor, constant: 20),
            overlayLabel.trailingAnchor.constraint(equalTo: overlayPanel.trailingAnchor, constant: -20),
            actionLabel.topAnchor.constraint(equalTo: overlayLabel.bottomAnchor, constant: 10),
            actionLabel.leadingAnchor.constraint(equalTo: overlayLabel.leadingAnchor),
            actionLabel.trailingAnchor.constraint(equalTo: overlayLabel.trailingAnchor),
            actionLabel.bottomAnchor.constraint(equalTo: overlayPanel.bottomAnchor, constant: -20)
        ])
    }

    func updateLevelProgress(level: Int, destroyed: Int, required: Int) {
        levelLabel.text = "Level \(level)"
        progressLabel.text = "Destroyed: \(destroyed) / \(required)"
    }

    func updateScore(_ score: Int) {
        scoreLabel.text = "Score: \(score)"
    }

    func updateFuel(remaining: TimeInterval, total: TimeInterval) {
        fuelGauge.update(remaining: remaining, total: total)
    }

    func showLevelComplete(level: Int, hasNextLevel: Bool) {
        overlayAction = hasNextLevel ? .nextLevel : .dismissToMissions
        overlayLabel.text = "Mission \(level)\nComplete!"
        actionLabel.text = hasNextLevel ? "Tap for next mission" : "Tap to return"
        showOverlay(true)
    }

    func showGameOver(level: Int, outOfFuel: Bool) {
        overlayAction = .retryLevel
        overlayLabel.text = outOfFuel ? "Out of Fuel" : "Game Over"
        actionLabel.text = "Tap to retry mission \(level)"
        showOverlay(true)
    }

    func showVictory() {
        overlayAction = .dismissToMissions
        overlayLabel.text = "All 100 Missions\nComplete!"
        actionLabel.text = "Tap to return"
        showOverlay(true)
    }

    func hideOverlay() {
        overlayAction = nil
        showOverlay(false)
    }

    private func showOverlay(_ show: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.overlayPanel.alpha = show ? 1 : 0
        }
    }

    @objc private func handleTap() {
        guard overlayPanel.alpha > 0.5 else { return }
        onOverlayTapped?()
    }
}
