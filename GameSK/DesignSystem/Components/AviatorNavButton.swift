import UIKit

final class AviatorNavButton: UIControl {

    enum Style {
        case compact(symbol: String)
        case labeled(symbol: String, title: String)
    }

    private let backgroundPanel = UIView()
    private let accentStripe = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let contentStack = UIStackView()

    private let style: Style
    private var widthConstraint: NSLayoutConstraint?

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        setup()
        apply(style)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet { updateHighlight(animated: true) }
    }

    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.42
            isUserInteractionEnabled = isEnabled
        }
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = true
        accessibilityTraits = .button

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
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = GameStyle.textPrimary
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 13, weight: .heavy)
        titleLabel.textColor = GameStyle.textPrimary
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 6
        contentStack.isUserInteractionEnabled = false
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(titleLabel)

        addSubview(backgroundPanel)
        backgroundPanel.addSubview(accentStripe)
        backgroundPanel.addSubview(contentStack)

        widthConstraint = widthAnchor.constraint(greaterThanOrEqualToConstant: 44)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 40),
            widthConstraint!,

            backgroundPanel.topAnchor.constraint(equalTo: topAnchor),
            backgroundPanel.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundPanel.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundPanel.bottomAnchor.constraint(equalTo: bottomAnchor),

            accentStripe.leadingAnchor.constraint(equalTo: backgroundPanel.leadingAnchor, constant: 8),
            accentStripe.topAnchor.constraint(equalTo: backgroundPanel.topAnchor, constant: 8),
            accentStripe.bottomAnchor.constraint(equalTo: backgroundPanel.bottomAnchor, constant: -8),
            accentStripe.widthAnchor.constraint(equalToConstant: 3),

            contentStack.leadingAnchor.constraint(equalTo: accentStripe.trailingAnchor, constant: 8),
            contentStack.trailingAnchor.constraint(equalTo: backgroundPanel.trailingAnchor, constant: -10),
            contentStack.centerYAnchor.constraint(equalTo: backgroundPanel.centerYAnchor),

            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18)
        ])

    }

    private func apply(_ style: Style) {
        switch style {
        case let .compact(symbol):
            iconView.image = UIImage(systemName: symbol)
            titleLabel.isHidden = true
            accessibilityLabel = "Menu"
            widthConstraint?.constant = 44

        case let .labeled(symbol, title):
            iconView.image = UIImage(systemName: symbol)
            titleLabel.text = title.uppercased()
            titleLabel.isHidden = false
            accessibilityLabel = title
            widthConstraint?.constant = 44
        }
    }

    private func updateHighlight(animated: Bool) {
        let updates = {
            if self.isHighlighted {
                self.backgroundPanel.backgroundColor = GameStyle.accentRedDim.withAlphaComponent(0.95)
                self.backgroundPanel.layer.borderColor = GameStyle.accentRedBright.cgColor
                self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            } else {
                self.backgroundPanel.backgroundColor = GameStyle.panelBlueDark.withAlphaComponent(0.94)
                self.backgroundPanel.layer.borderColor = GameStyle.borderSteel.cgColor
                self.transform = .identity
            }
        }

        if animated {
            UIView.animate(withDuration: 0.12, animations: updates)
        } else {
            updates()
        }
    }

}
