import UIKit

final class MissionResultView: UIView {

    enum Result {
        case levelComplete(level: Int, result: MissionScoreResult, hasNextLevel: Bool)
        case gameOver(level: Int, killPoints: Int, outOfFuel: Bool)
        case campaignVictory(result: MissionScoreResult)
    }

    var onPrimaryAction: (() -> Void)?
    var onSecondaryAction: (() -> Void)?

    private(set) var isPresented = false

    private let dimView = UIView()
    private let panel = UIView()
    private let accentStripe = UIView()
    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let scoreChip = UIView()
    private let scoreTitleLabel = UILabel()
    private let scoreValueLabel = UILabel()
    private let primaryButton = UIButton(type: .system)
    private let secondaryButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        isHidden = true
        alpha = 0
        isUserInteractionEnabled = true

        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.backgroundColor = GameStyle.cockpitBlack.withAlphaComponent(0.72)

        panel.translatesAutoresizingMaskIntoConstraints = false
        panel.backgroundColor = GameStyle.panelBlueDark.withAlphaComponent(0.97)
        panel.layer.cornerRadius = 18
        panel.layer.borderWidth = 2
        panel.layer.borderColor = GameStyle.borderHighlight.cgColor
        panel.layer.shadowColor = UIColor.black.cgColor
        panel.layer.shadowOpacity = 0.45
        panel.layer.shadowRadius = 16
        panel.layer.shadowOffset = CGSize(width: 0, height: 8)

        accentStripe.translatesAutoresizingMaskIntoConstraints = false
        accentStripe.layer.cornerRadius = 2

        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.layer.cornerRadius = 34
        iconContainer.layer.borderWidth = 1.5

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 26, weight: .heavy)
        titleLabel.textColor = GameStyle.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleSubtitleLabel(subtitleLabel, size: 16)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        scoreChip.translatesAutoresizingMaskIntoConstraints = false
        scoreChip.backgroundColor = GameStyle.cockpitBlack.withAlphaComponent(0.45)
        scoreChip.layer.cornerRadius = 10
        scoreChip.layer.borderWidth = 1
        scoreChip.layer.borderColor = GameStyle.borderSteel.withAlphaComponent(0.45).cgColor

        scoreTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreTitleLabel.text = "SCORE"
        scoreTitleLabel.font = .systemFont(ofSize: 10, weight: .heavy)
        scoreTitleLabel.textColor = GameStyle.textSecondary

        scoreValueLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreValueLabel.font = .monospacedDigitSystemFont(ofSize: 22, weight: .bold)
        scoreValueLabel.textColor = GameStyle.gaugeAmber
        scoreValueLabel.textAlignment = .center

        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)

        secondaryButton.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.applySecondaryButton(secondaryButton, title: "Missions")
        secondaryButton.addTarget(self, action: #selector(secondaryTapped), for: .touchUpInside)

        addSubview(dimView)
        addSubview(panel)
        panel.addSubview(accentStripe)
        panel.addSubview(iconContainer)
        iconContainer.addSubview(iconView)
        panel.addSubview(titleLabel)
        panel.addSubview(subtitleLabel)
        panel.addSubview(scoreChip)
        scoreChip.addSubview(scoreTitleLabel)
        scoreChip.addSubview(scoreValueLabel)
        panel.addSubview(primaryButton)
        panel.addSubview(secondaryButton)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            panel.centerXAnchor.constraint(equalTo: centerXAnchor),
            panel.centerYAnchor.constraint(equalTo: centerYAnchor),
            panel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 28),
            panel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -28),

            accentStripe.topAnchor.constraint(equalTo: panel.topAnchor, constant: 16),
            accentStripe.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 12),
            accentStripe.bottomAnchor.constraint(equalTo: scoreChip.bottomAnchor, constant: 8),
            accentStripe.widthAnchor.constraint(equalToConstant: 4),

            iconContainer.topAnchor.constraint(equalTo: panel.topAnchor, constant: 22),
            iconContainer.centerXAnchor.constraint(equalTo: panel.centerXAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 68),
            iconContainer.heightAnchor.constraint(equalToConstant: 68),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 34),
            iconView.heightAnchor.constraint(equalToConstant: 34),

            titleLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            scoreChip.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            scoreChip.centerXAnchor.constraint(equalTo: panel.centerXAnchor),
            scoreChip.widthAnchor.constraint(greaterThanOrEqualToConstant: 132),

            scoreTitleLabel.topAnchor.constraint(equalTo: scoreChip.topAnchor, constant: 8),
            scoreTitleLabel.centerXAnchor.constraint(equalTo: scoreChip.centerXAnchor),

            scoreValueLabel.topAnchor.constraint(equalTo: scoreTitleLabel.bottomAnchor, constant: 2),
            scoreValueLabel.leadingAnchor.constraint(equalTo: scoreChip.leadingAnchor, constant: 16),
            scoreValueLabel.trailingAnchor.constraint(equalTo: scoreChip.trailingAnchor, constant: -16),
            scoreValueLabel.bottomAnchor.constraint(equalTo: scoreChip.bottomAnchor, constant: -8),

            primaryButton.topAnchor.constraint(equalTo: scoreChip.bottomAnchor, constant: 20),
            primaryButton.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 28),
            primaryButton.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -28),

            secondaryButton.topAnchor.constraint(equalTo: primaryButton.bottomAnchor, constant: 10),
            secondaryButton.leadingAnchor.constraint(equalTo: primaryButton.leadingAnchor),
            secondaryButton.trailingAnchor.constraint(equalTo: primaryButton.trailingAnchor),
            secondaryButton.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -22)
        ])
    }

    func present(_ result: Result, animated: Bool = true) {
        configure(for: result)
        isPresented = true
        isHidden = false

        guard animated else {
            alpha = 1
            panel.transform = .identity
            return
        }

        alpha = 0
        panel.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: 0.4
        ) {
            self.alpha = 1
            self.panel.transform = .identity
        }
    }

    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        isPresented = false

        guard animated else {
            alpha = 0
            isHidden = true
            completion?()
            return
        }

        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
            self.panel.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }, completion: { _ in
            self.isHidden = true
            self.panel.transform = .identity
            completion?()
        })
    }

    private func configure(for result: Result) {
        scoreTitleLabel.text = "SCORE"

        switch result {
        case let .levelComplete(level, result, hasNextLevel):
            applySuccessTheme()
            iconView.image = UIImage(systemName: "checkmark.seal.fill")
            titleLabel.text = "MISSION COMPLETE"
            subtitleLabel.text = levelCompleteSubtitle(level: level, result: result)
            scoreValueLabel.text = "\(result.total)"
            if hasNextLevel {
                GameStyle.applyPrimaryButton(primaryButton, title: "Next Mission")
                secondaryButton.isHidden = false
            } else {
                GameStyle.applyPrimaryButton(primaryButton, title: "Return to Missions")
                secondaryButton.isHidden = true
            }

        case let .gameOver(level, killPoints, outOfFuel):
            applyFailureTheme()
            iconView.image = UIImage(
                systemName: outOfFuel ? "fuelpump.fill" : "exclamationmark.triangle.fill"
            )
            titleLabel.text = outOfFuel ? "OUT OF FUEL" : "MISSION FAILED"
            subtitleLabel.text = outOfFuel
                ? "Tank empty in sector \(String(format: "%02d", level))"
                : "Hull destroyed in sector \(String(format: "%02d", level))"
            scoreValueLabel.text = "\(killPoints)"
            scoreTitleLabel.text = killPoints > 0 ? "KILLS SCORE" : "SCORE"
            GameStyle.applyPrimaryButton(primaryButton, title: "Try Again")
            secondaryButton.isHidden = false

        case let .campaignVictory(result):
            applyVictoryTheme()
            iconView.image = UIImage(systemName: "trophy.fill")
            titleLabel.text = "ALL MISSIONS\nCOMPLETE!"
            subtitleLabel.text = "You conquered all 100 sectors"
            scoreValueLabel.text = "\(result.total)"
            GameStyle.applyPrimaryButton(primaryButton, title: "Return to Missions")
            secondaryButton.isHidden = true
        }
    }

    private func levelCompleteSubtitle(level: Int, result: MissionScoreResult) -> String {
        var lines = [
            "Sector \(String(format: "%02d", level)) cleared",
            "Kills \(result.killPoints) · Fuel +\(result.fuelBonus)",
            "+\(result.total) hangar credits"
        ]
        if result.isNewBest {
            lines.append("New best score!")
        } else if result.bestScore > 0 {
            lines.append("Best \(result.bestScore)")
        }
        return lines.joined(separator: "\n")
    }

    private func applySuccessTheme() {
        accentStripe.backgroundColor = UIColor(red: 0.35, green: 0.85, blue: 0.62, alpha: 1)
        iconContainer.backgroundColor = UIColor(red: 0.10, green: 0.22, blue: 0.18, alpha: 1)
        iconContainer.layer.borderColor = UIColor(red: 0.35, green: 0.85, blue: 0.62, alpha: 0.65).cgColor
        iconView.tintColor = UIColor(red: 0.35, green: 0.85, blue: 0.62, alpha: 1)
        panel.layer.borderColor = UIColor(red: 0.35, green: 0.85, blue: 0.62, alpha: 0.45).cgColor
    }

    private func applyFailureTheme() {
        accentStripe.backgroundColor = GameStyle.accentRedBright
        iconContainer.backgroundColor = UIColor(red: 0.22, green: 0.08, blue: 0.08, alpha: 1)
        iconContainer.layer.borderColor = GameStyle.accentRedBright.withAlphaComponent(0.65).cgColor
        iconView.tintColor = GameStyle.gaugeAmber
        panel.layer.borderColor = GameStyle.accentRedBright.withAlphaComponent(0.45).cgColor
    }

    private func applyVictoryTheme() {
        accentStripe.backgroundColor = GameStyle.gaugeAmber
        iconContainer.backgroundColor = UIColor(red: 0.20, green: 0.14, blue: 0.04, alpha: 1)
        iconContainer.layer.borderColor = GameStyle.gaugeAmber.withAlphaComponent(0.7).cgColor
        iconView.tintColor = GameStyle.gaugeAmber
        panel.layer.borderColor = GameStyle.gaugeAmber.withAlphaComponent(0.5).cgColor
    }

    @objc private func primaryTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onPrimaryAction?()
    }

    @objc private func secondaryTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onSecondaryAction?()
    }
}
