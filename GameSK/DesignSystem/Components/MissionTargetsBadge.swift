import UIKit

final class MissionTargetsBadge: UIView {

    private let contentStack = UIStackView()
    private let iconView = UIImageView()
    private let valueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        update(destroyed: 0, required: 0)
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
        applyAsteroidIcon()

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

            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    func update(destroyed: Int, required: Int) {
        let safeDestroyed = max(0, destroyed)
        let safeRequired = max(0, required)
        valueLabel.text = "\(safeDestroyed)/\(safeRequired)"
        accessibilityLabel = "Destroyed \(safeDestroyed) of \(safeRequired)"
    }

    func refreshAsteroidIcon() {
        applyAsteroidIcon()
    }

    private func applyAsteroidIcon() {
        iconView.image = UIImage(systemName: "circle.hexagongrid.fill")
        iconView.tintColor = GameStyle.textSecondary
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)

        AsteroidFactory.prepareHUDIcon { [weak self] image in
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
