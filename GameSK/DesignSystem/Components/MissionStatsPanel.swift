import UIKit

final class MissionStatsPanel: UIView {

    let ammoBadge = MissionAmmoBadge()
    let fuelBadge = MissionFuelBadge()
    let targetsBadge = MissionTargetsBadge()

    private let backgroundPanel = UIView()
    private let accentStripe = UIView()
    private let statsRow = UIStackView()

    private static let panelHeight: CGFloat = 40

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false

        backgroundPanel.translatesAutoresizingMaskIntoConstraints = false
        backgroundPanel.isUserInteractionEnabled = false
        backgroundPanel.backgroundColor = GameStyle.panelBlueDark.withAlphaComponent(0.88)
        backgroundPanel.layer.cornerRadius = 11
        backgroundPanel.layer.borderWidth = 1.5
        backgroundPanel.layer.borderColor = GameStyle.borderSteel.cgColor
        backgroundPanel.layer.shadowColor = UIColor.black.cgColor
        backgroundPanel.layer.shadowOpacity = 0.28
        backgroundPanel.layer.shadowRadius = 6
        backgroundPanel.layer.shadowOffset = CGSize(width: 0, height: 3)

        accentStripe.translatesAutoresizingMaskIntoConstraints = false
        accentStripe.backgroundColor = GameStyle.gaugeAmber
        accentStripe.layer.cornerRadius = 1.5

        statsRow.translatesAutoresizingMaskIntoConstraints = false
        statsRow.axis = .horizontal
        statsRow.alignment = .center
        statsRow.distribution = .equalSpacing
        statsRow.spacing = 12
        statsRow.addArrangedSubview(ammoBadge)
        statsRow.addArrangedSubview(fuelBadge)
        statsRow.addArrangedSubview(targetsBadge)

        addSubview(backgroundPanel)
        backgroundPanel.addSubview(accentStripe)
        backgroundPanel.addSubview(statsRow)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Self.panelHeight),

            backgroundPanel.topAnchor.constraint(equalTo: topAnchor),
            backgroundPanel.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundPanel.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundPanel.bottomAnchor.constraint(equalTo: bottomAnchor),

            accentStripe.leadingAnchor.constraint(equalTo: backgroundPanel.leadingAnchor, constant: 8),
            accentStripe.topAnchor.constraint(equalTo: backgroundPanel.topAnchor, constant: 8),
            accentStripe.bottomAnchor.constraint(equalTo: backgroundPanel.bottomAnchor, constant: -8),
            accentStripe.widthAnchor.constraint(equalToConstant: 3),

            statsRow.leadingAnchor.constraint(equalTo: accentStripe.trailingAnchor, constant: 10),
            statsRow.trailingAnchor.constraint(equalTo: backgroundPanel.trailingAnchor, constant: -12),
            statsRow.centerYAnchor.constraint(equalTo: backgroundPanel.centerYAnchor)
        ])
    }
}
