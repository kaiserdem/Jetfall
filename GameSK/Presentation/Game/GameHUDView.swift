import UIKit

final class GameHUDView: UIView {

    private let hudStack = UIStackView()
    private let topRow = UIView()

    private let levelTitleLabel = UILabel()
    private let statsRow = UIStackView()
    private let statsPanel = UIView()
    private let progressLabel = UILabel()
    private let scoreBadge = MissionScoreBadge()
    private let fuelGauge = FuelGaugeView()
    private let fuelPickupBanner = UILabel()

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

        fuelGauge.translatesAutoresizingMaskIntoConstraints = false

        fuelPickupBanner.translatesAutoresizingMaskIntoConstraints = false
        fuelPickupBanner.text = "+30%"
        fuelPickupBanner.textAlignment = .center
        fuelPickupBanner.alpha = 0
        fuelPickupBanner.isHidden = true
        GameStyle.styleHUDLabel(fuelPickupBanner, size: 28, weight: .heavy)
        fuelPickupBanner.textColor = GameStyle.gaugeAmber
        fuelPickupBanner.layer.shadowColor = UIColor.black.cgColor
        fuelPickupBanner.layer.shadowOpacity = 0.45
        fuelPickupBanner.layer.shadowRadius = 4
        fuelPickupBanner.layer.shadowOffset = CGSize(width: 0, height: 2)

        topRow.addSubview(pauseButton)
        topRow.addSubview(levelTitleLabel)
        topRow.addSubview(scoreBadge)

        statsPanel.addSubview(progressLabel)

        statsRow.addArrangedSubview(statsPanel)
        statsRow.addArrangedSubview(fuelGauge)

        hudStack.addArrangedSubview(topRow)
        hudStack.addArrangedSubview(statsRow)
        addSubview(fuelPickupBanner)
        addSubview(hudStack)

        NSLayoutConstraint.activate([
            hudStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            hudStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            hudStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            topRow.heightAnchor.constraint(equalToConstant: 40),

            pauseButton.leadingAnchor.constraint(equalTo: topRow.leadingAnchor),
            pauseButton.centerYAnchor.constraint(equalTo: topRow.centerYAnchor),

            scoreBadge.trailingAnchor.constraint(equalTo: topRow.trailingAnchor),
            scoreBadge.centerYAnchor.constraint(equalTo: topRow.centerYAnchor),

            levelTitleLabel.centerXAnchor.constraint(equalTo: topRow.centerXAnchor),
            levelTitleLabel.centerYAnchor.constraint(equalTo: topRow.centerYAnchor),
            levelTitleLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: pauseButton.trailingAnchor,
                constant: 8
            ),
            levelTitleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: scoreBadge.leadingAnchor,
                constant: -8
            ),

            progressLabel.topAnchor.constraint(equalTo: statsPanel.topAnchor, constant: 10),
            progressLabel.leadingAnchor.constraint(equalTo: statsPanel.leadingAnchor, constant: 12),
            progressLabel.trailingAnchor.constraint(equalTo: statsPanel.trailingAnchor, constant: -12),
            progressLabel.bottomAnchor.constraint(equalTo: statsPanel.bottomAnchor, constant: -10),

            statsRow.heightAnchor.constraint(equalToConstant: 44),

            fuelPickupBanner.centerXAnchor.constraint(equalTo: fuelGauge.centerXAnchor),
            fuelPickupBanner.bottomAnchor.constraint(equalTo: fuelGauge.topAnchor, constant: -6)
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
        scoreBadge.update(score: score)
    }

    func updateFuel(remaining: TimeInterval, total: TimeInterval, afterburnerActive: Bool = false) {
        fuelGauge.update(remaining: remaining, total: total, afterburnerActive: afterburnerActive)
    }

    func showFuelPickupBonus(percent: Int = Int(FuelPickupConfig.refillFraction * 100)) {
        fuelPickupBanner.text = "+\(percent)%"
        fuelPickupBanner.isHidden = false
        fuelPickupBanner.alpha = 0
        fuelPickupBanner.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
            self.fuelPickupBanner.alpha = 1
            self.fuelPickupBanner.transform = .identity
        }

        fuelGauge.flashPickupRefill()

        UIView.animate(
            withDuration: 0.28,
            delay: FuelPickupConfig.refillBannerDuration - 0.28,
            options: [.curveEaseIn]
        ) {
            self.fuelPickupBanner.alpha = 0
        } completion: { _ in
            self.fuelPickupBanner.isHidden = true
        }
    }
}
