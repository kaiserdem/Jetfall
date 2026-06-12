import UIKit

final class GameHUDView: UIView {

    private let topBarGuide = UILayoutGuide()
    private let statsPanel = UIView()
    private let levelLabel = UILabel()
    private let progressLabel = UILabel()
    private let scoreLabel = UILabel()
    private let fuelGauge = FuelGaugeView()
    let pauseButton = AviatorNavButton(style: .labeled(symbol: "pause.fill", title: "Pause"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        setupStatsPanel()
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

        addLayoutGuide(topBarGuide)

        addSubview(pauseButton)

        addSubview(statsPanel)
        statsPanel.addSubview(levelLabel)
        statsPanel.addSubview(progressLabel)
        statsPanel.addSubview(scoreLabel)
        addSubview(fuelGauge)

        let statsCenterX = statsPanel.centerXAnchor.constraint(equalTo: centerXAnchor)
        statsCenterX.priority = .defaultHigh

        NSLayoutConstraint.activate([
            topBarGuide.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            topBarGuide.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            topBarGuide.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            pauseButton.leadingAnchor.constraint(equalTo: topBarGuide.leadingAnchor),
            pauseButton.topAnchor.constraint(equalTo: topBarGuide.topAnchor),

            fuelGauge.trailingAnchor.constraint(equalTo: topBarGuide.trailingAnchor),
            fuelGauge.centerYAnchor.constraint(equalTo: pauseButton.centerYAnchor),
            fuelGauge.widthAnchor.constraint(equalToConstant: 148),

            statsPanel.centerYAnchor.constraint(equalTo: pauseButton.centerYAnchor),
            statsCenterX,
            statsPanel.leadingAnchor.constraint(
                greaterThanOrEqualTo: pauseButton.trailingAnchor,
                constant: 12
            ),
            statsPanel.trailingAnchor.constraint(
                lessThanOrEqualTo: fuelGauge.leadingAnchor,
                constant: -12
            ),
            statsPanel.widthAnchor.constraint(equalToConstant: 168),

            levelLabel.topAnchor.constraint(equalTo: statsPanel.topAnchor, constant: 10),
            levelLabel.leadingAnchor.constraint(equalTo: statsPanel.leadingAnchor, constant: 12),
            progressLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 4),
            progressLabel.leadingAnchor.constraint(equalTo: levelLabel.leadingAnchor),
            scoreLabel.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 2),
            scoreLabel.leadingAnchor.constraint(equalTo: levelLabel.leadingAnchor),
            scoreLabel.bottomAnchor.constraint(equalTo: statsPanel.bottomAnchor, constant: -10),

            topBarGuide.bottomAnchor.constraint(equalTo: pauseButton.bottomAnchor)
        ])
    }

    func setPauseEnabled(_ enabled: Bool) {
        pauseButton.isEnabled = enabled
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

}
