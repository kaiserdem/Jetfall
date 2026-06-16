import UIKit

final class MissionFuelBadge: UIView {

    private let contentStack = UIStackView()
    private let iconView = UIImageView()
    private let valueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        update(remaining: 0, total: 1)
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

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 6
        contentStack.isUserInteractionEnabled = false

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.image = UIImage(systemName: "fuelpump.fill")
        iconView.tintColor = GameStyle.gaugeAmber
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .bold)
        valueLabel.textColor = GameStyle.textPrimary
        valueLabel.textAlignment = .left
        applyHUDShadow(to: valueLabel)

        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(valueLabel)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 32),

            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.widthAnchor.constraint(equalToConstant: 26),
            iconView.heightAnchor.constraint(equalToConstant: 26)
        ])
    }

    func update(remaining: TimeInterval, total: TimeInterval, afterburnerActive: Bool = false) {
        let safeTotal = max(total, 0.01)
        let fraction = max(0, min(1, remaining / safeTotal))
        valueLabel.text = "\(Int(round(fraction * 100)))%"
        valueLabel.textColor = fraction <= 0.2
            ? GameStyle.gaugeLowRed
            : GameStyle.textPrimary
        iconView.tintColor = afterburnerActive
            ? GameStyle.gaugeAmber
            : GameStyle.gaugeAmber.withAlphaComponent(0.9)
        accessibilityLabel = "Fuel \(valueLabel.text ?? "")"
    }

    func flashPickupRefill(duration: TimeInterval = FuelPickupConfig.refillBannerDuration) {
        let originalColor = valueLabel.textColor
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
            self.valueLabel.textColor = GameStyle.gaugeAmber
        }

        UIView.animate(
            withDuration: 0.28,
            delay: duration - 0.28,
            options: [.curveEaseIn]
        ) {
            self.valueLabel.textColor = originalColor
        }
    }

    private func applyHUDShadow(to label: UILabel) {
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOpacity = 0.55
        label.layer.shadowRadius = 3
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
    }
}
