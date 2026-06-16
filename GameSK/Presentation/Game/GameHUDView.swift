import UIKit

final class GameHUDView: UIView {

    private let hudStack = UIStackView()
    private let topRow = UIView()

    private let levelTitleLabel = UILabel()
    private let statsPanel = MissionStatsPanel()
    private let fuelPickupBanner = UILabel()
    private let ammoPickupBanner = UILabel()
    private let crosshairView = CrosshairView()

    let pauseButton = AviatorNavButton(style: .labeled(title: "Menu"))

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

        ammoPickupBanner.translatesAutoresizingMaskIntoConstraints = false
        ammoPickupBanner.text = "+0"
        ammoPickupBanner.textAlignment = .center
        ammoPickupBanner.alpha = 0
        ammoPickupBanner.isHidden = true
        GameStyle.styleHUDLabel(ammoPickupBanner, size: 28, weight: .heavy)
        ammoPickupBanner.textColor = GameStyle.gaugeAmber
        ammoPickupBanner.layer.shadowColor = UIColor.black.cgColor
        ammoPickupBanner.layer.shadowOpacity = 0.45
        ammoPickupBanner.layer.shadowRadius = 4
        ammoPickupBanner.layer.shadowOffset = CGSize(width: 0, height: 2)

        topRow.addSubview(pauseButton)
        topRow.addSubview(levelTitleLabel)

        hudStack.addArrangedSubview(topRow)
        hudStack.addArrangedSubview(statsPanel)
        addSubview(fuelPickupBanner)
        addSubview(ammoPickupBanner)
        addSubview(crosshairView)
        addSubview(hudStack)
        bringSubviewToFront(crosshairView)

        updateCrosshairVisibility()

        NSLayoutConstraint.activate([
            hudStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            hudStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            hudStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            topRow.heightAnchor.constraint(equalToConstant: 40),

            pauseButton.leadingAnchor.constraint(equalTo: topRow.leadingAnchor),
            pauseButton.centerYAnchor.constraint(equalTo: topRow.centerYAnchor),

            levelTitleLabel.centerXAnchor.constraint(equalTo: topRow.centerXAnchor),
            levelTitleLabel.centerYAnchor.constraint(equalTo: topRow.centerYAnchor),
            levelTitleLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: pauseButton.trailingAnchor,
                constant: 8
            ),
            levelTitleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: topRow.trailingAnchor,
                constant: -8
            ),

            ammoPickupBanner.centerXAnchor.constraint(equalTo: statsPanel.ammoBadge.centerXAnchor),
            ammoPickupBanner.bottomAnchor.constraint(equalTo: statsPanel.topAnchor, constant: -6),

            fuelPickupBanner.centerXAnchor.constraint(equalTo: centerXAnchor),
            fuelPickupBanner.centerYAnchor.constraint(
                equalTo: safeAreaLayoutGuide.centerYAnchor,
                constant: -52
            ),

            crosshairView.centerXAnchor.constraint(equalTo: centerXAnchor),
            crosshairView.centerYAnchor.constraint(equalTo: centerYAnchor),
            crosshairView.widthAnchor.constraint(equalToConstant: 40),
            crosshairView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    func updateCrosshairVisibility() {
        crosshairView.isHidden = !GameSettingsStore.isCrosshairEnabled
    }

    func setPauseEnabled(_ enabled: Bool) {
        pauseButton.isEnabled = enabled
    }

    func updateLevelProgress(level: Int, destroyed: Int, required: Int) {
        levelTitleLabel.text = "Level \(level)"
        statsPanel.targetsBadge.update(destroyed: destroyed, required: required)
    }

    func refreshAsteroidIcon() {
        statsPanel.targetsBadge.refreshAsteroidIcon()
    }

    func refreshFuelIcon() {
        statsPanel.fuelBadge.refreshFuelIcon()
    }

    func updateAmmo(remaining: Int, capacity: Int) {
        statsPanel.ammoBadge.update(remaining: remaining, capacity: capacity)
    }

    func refreshAmmunitionIcon() {
        statsPanel.ammoBadge.refreshAmmunitionIcon()
    }

    func showAmmoPickupBonus(added: Int) {
        ammoPickupBanner.text = "+\(added)"
        ammoPickupBanner.isHidden = false
        ammoPickupBanner.alpha = 0
        ammoPickupBanner.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
            self.ammoPickupBanner.alpha = 1
            self.ammoPickupBanner.transform = .identity
        }

        UIView.animate(
            withDuration: 0.28,
            delay: AmmunitionPickupConfig.pickupBannerDuration - 0.28,
            options: [.curveEaseIn]
        ) {
            self.ammoPickupBanner.alpha = 0
        } completion: { _ in
            self.ammoPickupBanner.isHidden = true
        }
    }

    func updateFuel(remaining: TimeInterval, total: TimeInterval, afterburnerActive: Bool = false) {
        statsPanel.fuelBadge.update(remaining: remaining, total: total, afterburnerActive: afterburnerActive)
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

        statsPanel.fuelBadge.flashPickupRefill()

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
