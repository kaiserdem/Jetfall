import UIKit

final class MissionPagerBar: UIView {

    var onPrevious: (() -> Void)?
    var onNext: (() -> Void)?

    private let panel = UIView()
    private let accentStripe = UIView()
    private let prevButton = AviatorNavButton(
        style: .compact(symbol: "chevron.left", accessibilityLabel: "Previous sector")
    )
    private let nextButton = AviatorNavButton(
        style: .compact(symbol: "chevron.right", accessibilityLabel: "Next sector")
    )
    private let indicatorStack = UIStackView()
    private let sectorCaption = UILabel()
    private let levelLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        panel.translatesAutoresizingMaskIntoConstraints = false
        panel.backgroundColor = GameStyle.panelBlueDark.withAlphaComponent(0.9)
        panel.layer.cornerRadius = 12
        panel.layer.borderWidth = 1.5
        panel.layer.borderColor = GameStyle.borderSteel.cgColor

        accentStripe.translatesAutoresizingMaskIntoConstraints = false
        accentStripe.backgroundColor = GameStyle.gaugeAmber
        accentStripe.layer.cornerRadius = 2

        sectorCaption.translatesAutoresizingMaskIntoConstraints = false
        sectorCaption.text = "SECTOR"
        sectorCaption.font = .systemFont(ofSize: 9, weight: .heavy)
        sectorCaption.textColor = GameStyle.textSecondary
        sectorCaption.textAlignment = .center

        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        levelLabel.font = .monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        levelLabel.textColor = GameStyle.gaugeAmber
        levelLabel.textAlignment = .center

        indicatorStack.translatesAutoresizingMaskIntoConstraints = false
        indicatorStack.axis = .vertical
        indicatorStack.alignment = .center
        indicatorStack.spacing = 1
        indicatorStack.addArrangedSubview(sectorCaption)
        indicatorStack.addArrangedSubview(levelLabel)

        prevButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        addSubview(panel)
        panel.addSubview(accentStripe)
        panel.addSubview(prevButton)
        panel.addSubview(indicatorStack)
        panel.addSubview(nextButton)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 52),

            panel.topAnchor.constraint(equalTo: topAnchor),
            panel.leadingAnchor.constraint(equalTo: leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: trailingAnchor),
            panel.bottomAnchor.constraint(equalTo: bottomAnchor),

            accentStripe.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 10),
            accentStripe.topAnchor.constraint(equalTo: panel.topAnchor, constant: 10),
            accentStripe.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -10),
            accentStripe.widthAnchor.constraint(equalToConstant: 3),

            prevButton.leadingAnchor.constraint(equalTo: accentStripe.trailingAnchor, constant: 10),
            prevButton.centerYAnchor.constraint(equalTo: panel.centerYAnchor),
            prevButton.widthAnchor.constraint(equalToConstant: 44),

            nextButton.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -12),
            nextButton.centerYAnchor.constraint(equalTo: panel.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 44),

            indicatorStack.centerXAnchor.constraint(equalTo: panel.centerXAnchor),
            indicatorStack.centerYAnchor.constraint(equalTo: panel.centerYAnchor),
            indicatorStack.leadingAnchor.constraint(
                greaterThanOrEqualTo: prevButton.trailingAnchor,
                constant: 12
            ),
            indicatorStack.trailingAnchor.constraint(
                lessThanOrEqualTo: nextButton.leadingAnchor,
                constant: -12
            )
        ])
    }

    func update(level: Int, total: Int) {
        levelLabel.text = "\(String(format: "%02d", level)) / \(total)"
        prevButton.isEnabled = level > 1
        nextButton.isEnabled = level < total
    }

    @objc private func previousTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onPrevious?()
    }

    @objc private func nextTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onNext?()
    }
}
