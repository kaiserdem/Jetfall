import UIKit

final class MissionScoreBadge: UIView {

    private let backgroundPanel = UIView()
    private let accentStripe = UIView()
    private let iconView = UIImageView()
    private let valueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        update(score: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = true
        accessibilityTraits = .updatesFrequently
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .horizontal)

        backgroundPanel.translatesAutoresizingMaskIntoConstraints = false
        backgroundPanel.isUserInteractionEnabled = false
        backgroundPanel.backgroundColor = GameStyle.panelBlueDark.withAlphaComponent(0.94)
        backgroundPanel.layer.cornerRadius = 11
        backgroundPanel.layer.borderWidth = 1.5
        backgroundPanel.layer.borderColor = GameStyle.borderSteel.cgColor
        backgroundPanel.layer.shadowColor = UIColor.black.cgColor
        backgroundPanel.layer.shadowOpacity = 0.28
        backgroundPanel.layer.shadowRadius = 6
        backgroundPanel.layer.shadowOffset = CGSize(width: 0, height: 3)

        accentStripe.translatesAutoresizingMaskIntoConstraints = false
        accentStripe.backgroundColor = GameStyle.accentRedBright
        accentStripe.layer.cornerRadius = 1.5

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: "star.fill")
        iconView.tintColor = GameStyle.gaugeAmber
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        valueLabel.textColor = GameStyle.textPrimary
        valueLabel.textAlignment = .right
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.75
        valueLabel.lineBreakMode = .byClipping
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        addSubview(backgroundPanel)
        backgroundPanel.addSubview(accentStripe)
        backgroundPanel.addSubview(iconView)
        backgroundPanel.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 40),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 72),
            widthAnchor.constraint(lessThanOrEqualToConstant: 120),

            backgroundPanel.topAnchor.constraint(equalTo: topAnchor),
            backgroundPanel.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundPanel.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundPanel.bottomAnchor.constraint(equalTo: bottomAnchor),

            accentStripe.leadingAnchor.constraint(equalTo: backgroundPanel.leadingAnchor, constant: 8),
            accentStripe.topAnchor.constraint(equalTo: backgroundPanel.topAnchor, constant: 8),
            accentStripe.bottomAnchor.constraint(equalTo: backgroundPanel.bottomAnchor, constant: -8),
            accentStripe.widthAnchor.constraint(equalToConstant: 3),

            iconView.leadingAnchor.constraint(equalTo: accentStripe.trailingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: backgroundPanel.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),

            valueLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            valueLabel.trailingAnchor.constraint(equalTo: backgroundPanel.trailingAnchor, constant: -10),
            valueLabel.centerYAnchor.constraint(equalTo: backgroundPanel.centerYAnchor)
        ])
    }

    func update(score: Int) {
        let safeScore = max(0, score)
        valueLabel.text = Self.format(safeScore)
        accessibilityLabel = "Score \(safeScore)"
    }

    private static func format(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
