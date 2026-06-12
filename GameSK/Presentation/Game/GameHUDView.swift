import UIKit

final class GameHUDView: UIView {

    private let hudStack = UIStackView()
    private let topRow = UIView()
    private let topTrailingSpacer = UIView()

    private let levelTitleLabel = UILabel()
    private let statsRow = UIStackView()
    private let statsPanel = UIView()
    private let progressLabel = UILabel()
    private let scoreLabel = UILabel()
    private let fuelGauge = FuelGaugeView()

    let pauseButton = AviatorNavButton(style: .labeled(symbol: "pause.fill", title: "Pause"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        setupHUD()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupHUD() {
        hudStack.translatesAutoresizingMaskIntoConstraints = false
        hudStack.axis = .vertical
        hudStack.alignment = .fill
        hudStack.distribution = .fill
        hudStack.spacing = 10

        topRow.translatesAutoresizingMaskIntoConstraints = false
        topTrailingSpacer.translatesAutoresizingMaskIntoConstraints = false
        topTrailingSpacer.isUserInteractionEnabled = false

        levelTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleHUDLabel(levelTitleLabel, size: 20, weight: .heavy)
        levelTitleLabel.text = "Level 1"
        levelTitleLabel.textAlignment = .center

        statsRow.axis = .horizontal
        statsRow.alignment = .fill
        statsRow.distribution = .fillEqually
        statsRow.spacing = 10

        statsPanel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.stylePanel(statsPanel, cornerRadius: 12)

        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleSubtitleLabel(progressLabel, size: 15)
        progressLabel.text = "Destroyed: 0 / 10"

        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleSubtitleLabel(scoreLabel, size: 15)
        scoreLabel.text = "Score: 0"

        fuelGauge.translatesAutoresizingMaskIntoConstraints = false

        topRow.addSubview(pauseButton)
        topRow.addSubview(levelTitleLabel)
        topRow.addSubview(topTrailingSpacer)

        statsPanel.addSubview(progressLabel)
        statsPanel.addSubview(scoreLabel)

        statsRow.addArrangedSubview(statsPanel)
        statsRow.addArrangedSubview(fuelGauge)

        hudStack.addArrangedSubview(topRow)
        hudStack.addArrangedSubview(statsRow)
        addSubview(hudStack)

        NSLayoutConstraint.activate([
            hudStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            hudStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            hudStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            topRow.heightAnchor.constraint(equalToConstant: 40),

            pauseButton.leadingAnchor.constraint(equalTo: topRow.leadingAnchor),
            pauseButton.centerYAnchor.constraint(equalTo: topRow.centerYAnchor),

            topTrailingSpacer.trailingAnchor.constraint(equalTo: topRow.trailingAnchor),
            topTrailingSpacer.centerYAnchor.constraint(equalTo: topRow.centerYAnchor),
            topTrailingSpacer.widthAnchor.constraint(equalTo: pauseButton.widthAnchor),
            topTrailingSpacer.heightAnchor.constraint(equalTo: pauseButton.heightAnchor),

            levelTitleLabel.centerXAnchor.constraint(equalTo: topRow.centerXAnchor),
            levelTitleLabel.centerYAnchor.constraint(equalTo: topRow.centerYAnchor),
            levelTitleLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: pauseButton.trailingAnchor,
                constant: 8
            ),
            levelTitleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: topTrailingSpacer.leadingAnchor,
                constant: -8
            ),

            progressLabel.topAnchor.constraint(equalTo: statsPanel.topAnchor, constant: 10),
            progressLabel.leadingAnchor.constraint(equalTo: statsPanel.leadingAnchor, constant: 12),
            progressLabel.trailingAnchor.constraint(equalTo: statsPanel.trailingAnchor, constant: -12),

            scoreLabel.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 4),
            scoreLabel.leadingAnchor.constraint(equalTo: progressLabel.leadingAnchor),
            scoreLabel.trailingAnchor.constraint(equalTo: progressLabel.trailingAnchor),
            scoreLabel.bottomAnchor.constraint(equalTo: statsPanel.bottomAnchor, constant: -10),

            statsRow.heightAnchor.constraint(equalToConstant: 58)
        ])
    }

    func setPauseEnabled(_ enabled: Bool) {
        pauseButton.isEnabled = enabled
    }

    func updateLevelProgress(level: Int, destroyed: Int, required: Int) {
        levelTitleLabel.text = "Level \(level)"
        progressLabel.text = "Destroyed: \(destroyed) / \(required)"
    }

    func updateScore(_ score: Int) {
        scoreLabel.text = "Score: \(score)"
    }

    func updateFuel(remaining: TimeInterval, total: TimeInterval) {
        fuelGauge.update(remaining: remaining, total: total)
    }
}
