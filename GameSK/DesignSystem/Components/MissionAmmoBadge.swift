import UIKit

final class MissionAmmoBadge: UIView {

    private let contentStack = UIStackView()
    private let iconView = UIImageView()
    private let valueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        update(remaining: 0, capacity: 0)
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
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        applyAmmunitionIcon()

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .bold)
        valueLabel.textColor = GameStyle.textPrimary
        valueLabel.textAlignment = .left
        applyHUDShadow(to: valueLabel)

        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(valueLabel)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 40),

            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.widthAnchor.constraint(equalToConstant: 34),
            iconView.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    func update(remaining: Int, capacity: Int) {
        let safeRemaining = max(0, remaining)
        let safeCapacity = max(0, capacity)
        valueLabel.text = "\(safeRemaining)/\(safeCapacity)"
        valueLabel.textColor = safeRemaining <= max(1, safeCapacity / 5)
            ? GameStyle.gaugeLowRed
            : GameStyle.textPrimary
        accessibilityLabel = "Ammunition \(safeRemaining) of \(safeCapacity)"
    }

    func refreshAmmunitionIcon() {
        applyAmmunitionIcon()
    }

    private func applyAmmunitionIcon() {
        iconView.image = UIImage(systemName: "scope")
        iconView.tintColor = GameStyle.gaugeAmber
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)

        AmmunitionPickupFactory.prepareHUDIcon { [weak self] image in
            guard let self, let image else { return }
            self.iconView.image = image
            self.iconView.tintColor = nil
        }
    }

    private func applyHUDShadow(to label: UILabel) {
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOpacity = 0.55
        label.layer.shadowRadius = 3
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
    }
}
