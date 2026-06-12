import UIKit

final class LevelMissionCell: UICollectionViewCell {

    static let reuseID = "LevelMissionCell"

    private let cardView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let accentStripe = UIView()
    private let glowView = UIView()
    private let missionTag = UILabel()
    private let numberLabel = UILabel()
    private let statusBadge = UILabel()
    private let lockedInfoStack = UIStackView()
    private let unlockCaptionLabel = UILabel()
    private let unlockRequirementLabel = UILabel()
    private let objectivesCaptionLabel = UILabel()
    private let targetsChip = MissionStatChipView(symbol: "scope", title: "TARGETS")
    private let fuelChip = MissionStatChipView(symbol: "fuelpump.fill", title: "FUEL")
    private var lockedInfoCollapsedHeight: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = cardView.bounds
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.cardView.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.96, y: 0.96)
                    : .identity
            }
        }
    }

    private func setup() {
        contentView.backgroundColor = .clear

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.layer.cornerRadius = 20
        cardView.layer.masksToBounds = false
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.35
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)

        gradientLayer.cornerRadius = 20
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        cardView.layer.insertSublayer(gradientLayer, at: 0)

        glowView.translatesAutoresizingMaskIntoConstraints = false
        glowView.layer.cornerRadius = 22
        glowView.isUserInteractionEnabled = false
        glowView.isHidden = true

        accentStripe.translatesAutoresizingMaskIntoConstraints = false
        accentStripe.layer.cornerRadius = 2

        missionTag.translatesAutoresizingMaskIntoConstraints = false
        missionTag.font = .systemFont(ofSize: 12, weight: .heavy)
        missionTag.textColor = GameStyle.gaugeAmber
        missionTag.text = "MISSION"

        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.font = .systemFont(ofSize: 52, weight: .black)
        numberLabel.textColor = GameStyle.textPrimary

        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        statusBadge.font = .systemFont(ofSize: 9, weight: .bold)
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 8
        statusBadge.layer.masksToBounds = true

        unlockCaptionLabel.translatesAutoresizingMaskIntoConstraints = false
        unlockCaptionLabel.font = .systemFont(ofSize: 9, weight: .heavy)
        unlockCaptionLabel.textColor = GameStyle.textSecondary
        unlockCaptionLabel.text = "UNLOCK REQUIREMENT"

        unlockRequirementLabel.translatesAutoresizingMaskIntoConstraints = false
        unlockRequirementLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        unlockRequirementLabel.textColor = GameStyle.textPrimary
        unlockRequirementLabel.numberOfLines = 2

        objectivesCaptionLabel.translatesAutoresizingMaskIntoConstraints = false
        objectivesCaptionLabel.font = .systemFont(ofSize: 9, weight: .heavy)
        objectivesCaptionLabel.textColor = GameStyle.gaugeAmber
        objectivesCaptionLabel.text = "SECTOR OBJECTIVES"

        lockedInfoStack.translatesAutoresizingMaskIntoConstraints = false
        lockedInfoStack.axis = .vertical
        lockedInfoStack.alignment = .leading
        lockedInfoStack.spacing = 4
        lockedInfoStack.addArrangedSubview(unlockCaptionLabel)
        lockedInfoStack.addArrangedSubview(unlockRequirementLabel)
        lockedInfoStack.addArrangedSubview(objectivesCaptionLabel)

        targetsChip.translatesAutoresizingMaskIntoConstraints = false
        fuelChip.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.insertSubview(glowView, at: 0)
        cardView.addSubview(accentStripe)
        cardView.addSubview(missionTag)
        cardView.addSubview(numberLabel)
        cardView.addSubview(statusBadge)
        cardView.addSubview(lockedInfoStack)
        cardView.addSubview(targetsChip)
        cardView.addSubview(fuelChip)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            glowView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: -3),
            glowView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: -3),
            glowView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: 3),
            glowView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 3),

            accentStripe.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            accentStripe.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            accentStripe.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
            accentStripe.widthAnchor.constraint(equalToConstant: 4),

            missionTag.leadingAnchor.constraint(equalTo: accentStripe.trailingAnchor, constant: 10),
            missionTag.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),

            numberLabel.leadingAnchor.constraint(equalTo: missionTag.leadingAnchor),
            numberLabel.topAnchor.constraint(equalTo: missionTag.bottomAnchor, constant: -2),

            statusBadge.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            statusBadge.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            statusBadge.heightAnchor.constraint(equalToConstant: 18),
            statusBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 52),

            lockedInfoStack.leadingAnchor.constraint(equalTo: missionTag.leadingAnchor),
            lockedInfoStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            lockedInfoStack.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 4),

            targetsChip.topAnchor.constraint(greaterThanOrEqualTo: lockedInfoStack.bottomAnchor, constant: 8),
            targetsChip.leadingAnchor.constraint(equalTo: missionTag.leadingAnchor),
            targetsChip.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            targetsChip.bottomAnchor.constraint(equalTo: fuelChip.topAnchor, constant: -6),

            fuelChip.leadingAnchor.constraint(equalTo: missionTag.leadingAnchor),
            fuelChip.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            fuelChip.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)
        ])

        lockedInfoCollapsedHeight = lockedInfoStack.heightAnchor.constraint(equalToConstant: 0)
    }

    func configure(level: Int, isUnlocked: Bool, asteroids: Int, fuelSeconds: Int) {
        numberLabel.text = String(format: "%02d", level)
        targetsChip.setValue("\(asteroids)")
        let fuelPercent = Int(round(Double(fuelSeconds) / 120.0 * 100))
        fuelChip.setValue("\(fuelPercent)%")

        let highest = LevelProgressStore.highestUnlockedLevel
        let isCompleted = isUnlocked && level < highest
        let isCurrent = isUnlocked && level == highest

        lockedInfoStack.isHidden = isUnlocked
        lockedInfoCollapsedHeight?.isActive = isUnlocked

        targetsChip.setMuted(!isUnlocked)
        fuelChip.setMuted(!isUnlocked)

        cardView.layer.borderWidth = 1.5

        if !isUnlocked {
            applyLockedStyle(level: level, asteroids: asteroids, fuelPercent: fuelPercent)
            return
        }

        cardView.alpha = 1
        numberLabel.textColor = GameStyle.textPrimary

        if isCurrent {
            applyCurrentStyle()
        } else if isCompleted {
            applyCompletedStyle()
        } else {
            applyOpenStyle()
        }
    }

    private func applyLockedStyle(level: Int, asteroids: Int, fuelPercent: Int) {
        let previousMission = max(1, level - 1)
        unlockRequirementLabel.text = "Complete Mission \(String(format: "%02d", previousMission))"
        if level == 1 {
            unlockRequirementLabel.text = "Available from the start"
            unlockCaptionLabel.isHidden = true
        }

        statusBadge.isHidden = false
        statusBadge.text = "  LOCKED  "
        statusBadge.textColor = GameStyle.textSecondary
        statusBadge.backgroundColor = GameStyle.cockpitBlack.withAlphaComponent(0.65)

        numberLabel.textColor = GameStyle.textSecondary.withAlphaComponent(0.85)
        missionTag.textColor = GameStyle.textSecondary

        gradientLayer.colors = [
            GameStyle.cockpitBlack.cgColor,
            GameStyle.panelBlueDark.cgColor
        ]
        cardView.layer.borderColor = GameStyle.borderSteel.withAlphaComponent(0.45).cgColor
        accentStripe.backgroundColor = GameStyle.borderSteel.withAlphaComponent(0.55)
        glowView.isHidden = true
        cardView.alpha = 0.94
    }

    private func applyCurrentStyle() {
        missionTag.textColor = GameStyle.gaugeAmber
        statusBadge.isHidden = false
        statusBadge.text = "  READY  "
        statusBadge.textColor = GameStyle.textPrimary
        statusBadge.backgroundColor = GameStyle.accentRed

        gradientLayer.colors = [
            UIColor(red: 0.18, green: 0.08, blue: 0.10, alpha: 1).cgColor,
            GameStyle.panelBlue.cgColor
        ]
        accentStripe.backgroundColor = GameStyle.accentRedBright
        cardView.layer.borderColor = GameStyle.accentRedBright.withAlphaComponent(0.85).cgColor
        glowView.backgroundColor = GameStyle.accentRed.withAlphaComponent(0.35)
        glowView.isHidden = false
    }

    private func applyCompletedStyle() {
        missionTag.textColor = GameStyle.gaugeAmber
        statusBadge.isHidden = false
        statusBadge.text = "  CLEAR  "
        statusBadge.textColor = GameStyle.cockpitBlack
        statusBadge.backgroundColor = UIColor(red: 0.35, green: 0.85, blue: 0.62, alpha: 1)

        gradientLayer.colors = [
            UIColor(red: 0.06, green: 0.14, blue: 0.12, alpha: 1).cgColor,
            GameStyle.panelBlue.cgColor
        ]
        accentStripe.backgroundColor = UIColor(red: 0.25, green: 0.72, blue: 0.55, alpha: 1)
        cardView.layer.borderColor = UIColor(red: 0.25, green: 0.72, blue: 0.55, alpha: 0.5).cgColor
        glowView.isHidden = true
    }

    private func applyOpenStyle() {
        missionTag.textColor = GameStyle.gaugeAmber
        statusBadge.isHidden = false
        statusBadge.text = "  OPEN  "
        statusBadge.textColor = GameStyle.textPrimary
        statusBadge.backgroundColor = GameStyle.panelBlueDark

        gradientLayer.colors = [
            GameStyle.deepNavy.cgColor,
            GameStyle.panelBlue.cgColor
        ]
        accentStripe.backgroundColor = GameStyle.gaugeAmber
        cardView.layer.borderColor = GameStyle.borderHighlight.cgColor
        glowView.isHidden = true
    }

    func applyCarouselPresentation(scale: CGFloat, alpha: CGFloat) {
        contentView.alpha = alpha
    }
}

private final class MissionStatChipView: UIView {

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    init(symbol: String, title: String) {
        super.init(frame: .zero)
        backgroundColor = GameStyle.cockpitBlack.withAlphaComponent(0.35)
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = GameStyle.borderSteel.withAlphaComponent(0.35).cgColor

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: symbol)
        iconView.tintColor = GameStyle.gaugeAmber
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 8, weight: .heavy)
        titleLabel.textColor = GameStyle.textSecondary

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        valueLabel.textColor = GameStyle.textPrimary
        valueLabel.textAlignment = .right

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(valueLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 34),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 14),
            iconView.heightAnchor.constraint(equalToConstant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setValue(_ value: String) {
        valueLabel.text = value
    }

    func setMuted(_ muted: Bool) {
        alpha = muted ? 0.82 : 1
        valueLabel.textColor = muted ? GameStyle.textSecondary : GameStyle.textPrimary
        iconView.tintColor = muted ? GameStyle.textSecondary : GameStyle.gaugeAmber
    }
}
