import UIKit

struct MenuDashboardSnapshot {
    let nextSectorText: String
    let bestRunText: String
    let creditsText: String
    let aircraftText: String

    static func current() -> MenuDashboardSnapshot {
        let sector = LevelProgressStore.highestUnlockedLevel
        let total = LevelConfigFactory.totalLevels
        let sectorLabel = String(format: "%02d", sector)

        let nextSectorText: String
        if sector >= total {
            nextSectorText = "Sector \(sectorLabel) · Complete"
        } else {
            nextSectorText = "Sector \(sectorLabel) · Ready"
        }

        let bestRunText: String
        if let careerBest = MissionScoreStore.careerBest() {
            let levelLabel = String(format: "%02d", careerBest.level)
            bestRunText = "\(careerBest.score) · Sector \(levelLabel)"
        } else {
            bestRunText = "— · Fly your first mission"
        }

        let credits = max(0, PlayerWallet.balance)
        let creditsText = "\(credits.formatted()) CR"

        let planeName = ShopPlaneCatalog.plane(for: PlayerPlaneStore.selectedPlaneID)?.name ?? "Scout Mk.I"
        let aircraftText = planeName

        return MenuDashboardSnapshot(
            nextSectorText: nextSectorText,
            bestRunText: bestRunText,
            creditsText: creditsText,
            aircraftText: aircraftText
        )
    }
}

final class MenuDashboardPanel: UIView {

    private let panel = UIView()
    private let headerLabel = UILabel()
    private let rowsStack = UIStackView()
    private let nextSectorRow = MenuDashboardRow(caption: "NEXT SECTOR")
    private let bestRunRow = MenuDashboardRow(caption: "BEST RUN")
    private let creditsRow = MenuDashboardRow(caption: "CREDITS")
    private let aircraftRow = MenuDashboardRow(caption: "AIRCRAFT")

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
        GameStyle.stylePanel(panel, cornerRadius: 14)
        panel.backgroundColor = GameStyle.panelBlueDark.withAlphaComponent(0.9)

        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = "PILOT STATUS"
        headerLabel.font = .systemFont(ofSize: 11, weight: .heavy)
        headerLabel.textColor = GameStyle.gaugeAmber

        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        rowsStack.axis = .vertical
        rowsStack.spacing = 10
        rowsStack.addArrangedSubview(nextSectorRow)
        rowsStack.addArrangedSubview(bestRunRow)
        rowsStack.addArrangedSubview(creditsRow)
        rowsStack.addArrangedSubview(aircraftRow)

        addSubview(panel)
        panel.addSubview(headerLabel)
        panel.addSubview(rowsStack)

        NSLayoutConstraint.activate([
            panel.topAnchor.constraint(equalTo: topAnchor),
            panel.leadingAnchor.constraint(equalTo: leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: trailingAnchor),
            panel.bottomAnchor.constraint(equalTo: bottomAnchor),

            headerLabel.topAnchor.constraint(equalTo: panel.topAnchor, constant: 14),
            headerLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 14),

            rowsStack.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 12),
            rowsStack.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 14),
            rowsStack.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -14),
            rowsStack.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -14)
        ])
    }

    func update(with snapshot: MenuDashboardSnapshot) {
        nextSectorRow.setValue(snapshot.nextSectorText)
        bestRunRow.setValue(snapshot.bestRunText)
        creditsRow.setValue(snapshot.creditsText)
        aircraftRow.setValue(snapshot.aircraftText)
    }
}

private final class MenuDashboardRow: UIView {

    private let captionLabel = UILabel()
    private let valueLabel = UILabel()

    init(caption: String) {
        super.init(frame: .zero)
        captionLabel.text = caption
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = GameStyle.cockpitBlack.withAlphaComponent(0.35)
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = GameStyle.borderSteel.withAlphaComponent(0.35).cgColor

        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        captionLabel.font = .systemFont(ofSize: 9, weight: .heavy)
        captionLabel.textColor = GameStyle.textSecondary

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        valueLabel.textColor = GameStyle.textPrimary
        valueLabel.textAlignment = .right
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.8

        addSubview(captionLabel)
        addSubview(valueLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 36),

            captionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            captionLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            captionLabel.trailingAnchor.constraint(lessThanOrEqualTo: valueLabel.leadingAnchor, constant: -8),

            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            valueLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.62)
        ])
    }

    func setValue(_ text: String) {
        valueLabel.text = text
    }
}
