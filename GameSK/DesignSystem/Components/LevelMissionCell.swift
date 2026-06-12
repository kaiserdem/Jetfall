import UIKit

final class LevelMissionCell: UICollectionViewCell {

    static let reuseID = "LevelMissionCell"

    private let cardView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let accentStripe = UIView()
    private let glowLayer = CALayer()
    private let missionTag = UILabel()
    private let numberLabel = UILabel()
    private let statusBadge = UILabel()
    private let targetsChip = MissionStatChipView(symbol: "scope", title: "TARGETS")
    private let fuelChip = MissionStatChipView(symbol: "fuelpump.fill", title: "FUEL")
    private let lockIcon = UIImageView()
    private let lockOverlay = UIView()

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
        glowLayer.frame = cardView.bounds.insetBy(dx: -2, dy: -2)
        glowLayer.cornerRadius = cardView.layer.cornerRadius + 2
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
        cardView.layer.cornerRadius = 16
        cardView.layer.masksToBounds = false
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.35
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)

        gradientLayer.cornerRadius = 16
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        cardView.layer.insertSublayer(gradientLayer, at: 0)

        glowLayer.cornerRadius = 18
        glowLayer.opacity = 0
        contentView.layer.insertSublayer(glowLayer, below: cardView.layer)

        accentStripe.translatesAutoresizingMaskIntoConstraints = false
        accentStripe.layer.cornerRadius = 2

        missionTag.translatesAutoresizingMaskIntoConstraints = false
        missionTag.font = .systemFont(ofSize: 10, weight: .heavy)
        missionTag.textColor = GameStyle.gaugeAmber
        missionTag.text = "MISSION"

        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.font = .systemFont(ofSize: 34, weight: .black)
        numberLabel.textColor = GameStyle.textPrimary

        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        statusBadge.font = .systemFont(ofSize: 9, weight: .bold)
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 8
        statusBadge.layer.masksToBounds = true

        targetsChip.translatesAutoresizingMaskIntoConstraints = false
        fuelChip.translatesAutoresizingMaskIntoConstraints = false

        lockOverlay.translatesAutoresizingMaskIntoConstraints = false
        lockOverlay.backgroundColor = GameStyle.cockpitBlack.withAlphaComponent(0.55)
        lockOverlay.layer.cornerRadius = 16
        lockOverlay.isHidden = true

        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        lockIcon.image = UIImage(systemName: "lock.fill")
        lockIcon.tintColor = GameStyle.textSecondary
        lockIcon.contentMode = .scaleAspectFit
        lockIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)

        contentView.addSubview(cardView)
        cardView.addSubview(accentStripe)
        cardView.addSubview(missionTag)
        cardView.addSubview(numberLabel)
        cardView.addSubview(statusBadge)
        cardView.addSubview(targetsChip)
        cardView.addSubview(fuelChip)
        cardView.addSubview(lockOverlay)
        lockOverlay.addSubview(lockIcon)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

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

            targetsChip.leadingAnchor.constraint(equalTo: missionTag.leadingAnchor),
            targetsChip.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            targetsChip.bottomAnchor.constraint(equalTo: fuelChip.topAnchor, constant: -6),

            fuelChip.leadingAnchor.constraint(equalTo: missionTag.leadingAnchor),
            fuelChip.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            fuelChip.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),

            lockOverlay.topAnchor.constraint(equalTo: cardView.topAnchor),
            lockOverlay.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            lockOverlay.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            lockOverlay.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            lockIcon.centerXAnchor.constraint(equalTo: lockOverlay.centerXAnchor),
            lockIcon.centerYAnchor.constraint(equalTo: lockOverlay.centerYAnchor),
            lockIcon.widthAnchor.constraint(equalToConstant: 28),
            lockIcon.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    func configure(level: Int, isUnlocked: Bool, asteroids: Int, fuelSeconds: Int) {
        numberLabel.text = String(format: "%02d", level)
        targetsChip.setValue("\(asteroids)")
        fuelChip.setValue("\(fuelSeconds)s")

        let highest = LevelProgressStore.highestUnlockedLevel
        let isCompleted = isUnlocked && level < highest
        let isCurrent = isUnlocked && level == highest

        lockOverlay.isHidden = isUnlocked
        targetsChip.isHidden = !isUnlocked
        fuelChip.isHidden = !isUnlocked
        missionTag.isHidden = !isUnlocked
        numberLabel.isHidden = !isUnlocked
        statusBadge.isHidden = !isUnlocked

        cardView.layer.borderWidth = 1.5

        if !isUnlocked {
            gradientLayer.colors = [
                GameStyle.cockpitBlack.cgColor,
                GameStyle.panelBlueDark.cgColor
            ]
            cardView.layer.borderColor = GameStyle.borderSteel.withAlphaComponent(0.35).cgColor
            accentStripe.backgroundColor = GameStyle.borderSteel.withAlphaComponent(0.4)
            glowLayer.backgroundColor = UIColor.clear.cgColor
            glowLayer.opacity = 0
            cardView.alpha = 0.72
            return
        }

        cardView.alpha = 1

        if isCurrent {
            gradientLayer.colors = [
                UIColor(red: 0.18, green: 0.08, blue: 0.10, alpha: 1).cgColor,
                GameStyle.panelBlue.cgColor
            ]
            accentStripe.backgroundColor = GameStyle.accentRedBright
            cardView.layer.borderColor = GameStyle.accentRedBright.withAlphaComponent(0.85).cgColor
            glowLayer.backgroundColor = GameStyle.accentRed.withAlphaComponent(0.35).cgColor
            glowLayer.opacity = 1
            statusBadge.text = "  READY  "
            statusBadge.textColor = GameStyle.textPrimary
            statusBadge.backgroundColor = GameStyle.accentRed
        } else if isCompleted {
            gradientLayer.colors = [
                UIColor(red: 0.06, green: 0.14, blue: 0.12, alpha: 1).cgColor,
                GameStyle.panelBlue.cgColor
            ]
            accentStripe.backgroundColor = UIColor(red: 0.25, green: 0.72, blue: 0.55, alpha: 1)
            cardView.layer.borderColor = UIColor(red: 0.25, green: 0.72, blue: 0.55, alpha: 0.5).cgColor
            glowLayer.opacity = 0
            statusBadge.text = "  CLEAR  "
            statusBadge.textColor = GameStyle.cockpitBlack
            statusBadge.backgroundColor = UIColor(red: 0.35, green: 0.85, blue: 0.62, alpha: 1)
        } else {
            gradientLayer.colors = [
                GameStyle.deepNavy.cgColor,
                GameStyle.panelBlue.cgColor
            ]
            accentStripe.backgroundColor = GameStyle.gaugeAmber
            cardView.layer.borderColor = GameStyle.borderHighlight.cgColor
            glowLayer.opacity = 0
            statusBadge.text = "  OPEN  "
            statusBadge.textColor = GameStyle.textPrimary
            statusBadge.backgroundColor = GameStyle.panelBlueDark
        }
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
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .bold)
        valueLabel.textColor = GameStyle.textPrimary
        valueLabel.textAlignment = .right

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(valueLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 30),
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
}
