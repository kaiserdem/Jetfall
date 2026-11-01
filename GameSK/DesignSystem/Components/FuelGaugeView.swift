import UIKit

final class FuelGaugeView: UIView {

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let trackView = UIView()
    private let fillView = UIView()
    private var fillWidthConstraint: NSLayoutConstraint?
    private var fillFraction: CGFloat = 1
    private var isAfterburnerActive = false
    private var refillFlashTimer: Timer?
    private var refillFlashTicks = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        GameStyle.stylePanel(self, cornerRadius: 10)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "FUEL"
        GameStyle.styleHUDLabel(titleLabel, size: 13, weight: .heavy)

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.textAlignment = .right
        GameStyle.styleHUDLabel(valueLabel, size: 13, weight: .bold)

        trackView.translatesAutoresizingMaskIntoConstraints = false
        trackView.backgroundColor = GameStyle.cockpitBlack
        trackView.layer.cornerRadius = 5
        trackView.layer.borderWidth = 1
        trackView.layer.borderColor = GameStyle.borderSteel.cgColor
        trackView.clipsToBounds = true

        fillView.translatesAutoresizingMaskIntoConstraints = false
        fillView.backgroundColor = GameStyle.gaugeAmber
        fillView.layer.cornerRadius = 4

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(trackView)
        trackView.addSubview(fillView)

        fillWidthConstraint = fillView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            valueLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            trackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            trackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            trackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            trackView.heightAnchor.constraint(equalToConstant: 12),
            trackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            fillView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor, constant: 1),
            fillView.topAnchor.constraint(equalTo: trackView.topAnchor, constant: 1),
            fillView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor, constant: -1),
            fillWidthConstraint!
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let maxWidth = max(0, trackView.bounds.width - 2)
        fillWidthConstraint?.constant = maxWidth * fillFraction
    }

    func update(remaining: TimeInterval, total: TimeInterval, afterburnerActive: Bool = false) {
        let safeTotal = max(total, 0.01)
        let fraction = max(0, min(1, remaining / safeTotal))
        fillFraction = CGFloat(fraction)
        valueLabel.text = "\(Int(round(fraction * 100)))%"
        fillView.backgroundColor = fraction <= 0.2 ? GameStyle.gaugeLowRed : GameStyle.gaugeAmber
        setAfterburnerHighlight(afterburnerActive)
        setNeedsLayout()
    }

    func flashPickupRefill(duration: TimeInterval = FuelPickupConfig.refillBannerDuration) {
        refillFlashTimer?.invalidate()
        refillFlashTicks = 0
        applyRefillFlashHighlight(true)

        refillFlashTimer = Timer.scheduledTimer(withTimeInterval: 0.22, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            self.refillFlashTicks += 1
            let isOn = self.refillFlashTicks % 2 == 0
            self.applyRefillFlashHighlight(isOn)

            if TimeInterval(self.refillFlashTicks) * 0.22 >= duration {
                timer.invalidate()
                self.refillFlashTimer = nil
                self.applyRefillFlashHighlight(false)
            }
        }
    }

    private func applyRefillFlashHighlight(_ active: Bool) {
        if active {
            layer.borderWidth = 2
            layer.borderColor = GameStyle.gaugeAmber.cgColor
            trackView.layer.borderWidth = 2
            trackView.layer.borderColor = GameStyle.gaugeAmber.withAlphaComponent(0.85).cgColor
            fillView.backgroundColor = GameStyle.gaugeAmber
            titleLabel.textColor = GameStyle.gaugeAmber
        } else if isAfterburnerActive {
            setAfterburnerHighlight(true)
        } else {
            layer.borderWidth = 1
            layer.borderColor = GameStyle.borderSteel.cgColor
            trackView.layer.borderWidth = 1
            trackView.layer.borderColor = GameStyle.borderSteel.cgColor
            fillView.backgroundColor = fillFraction <= 0.2 ? GameStyle.gaugeLowRed : GameStyle.gaugeAmber
            GameStyle.styleHUDLabel(titleLabel, size: 13, weight: .heavy)
            titleLabel.text = "FUEL"
        }
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            refillFlashTimer?.invalidate()
            refillFlashTimer = nil
        }
    }

    private func setAfterburnerHighlight(_ active: Bool) {
        guard active != isAfterburnerActive else { return }
        isAfterburnerActive = active

        if active {
            layer.borderColor = GameStyle.gaugeAmber.withAlphaComponent(0.38).cgColor
            layer.shadowOpacity = 0
            titleLabel.textColor = GameStyle.textPrimary
            trackView.layer.borderColor = GameStyle.gaugeAmber.withAlphaComponent(0.28).cgColor
            trackView.layer.borderWidth = 1
        } else {
            layer.borderColor = GameStyle.borderSteel.cgColor
            layer.shadowOpacity = 0
            GameStyle.styleHUDLabel(titleLabel, size: 13, weight: .heavy)
            titleLabel.text = "FUEL"
            trackView.layer.borderColor = GameStyle.borderSteel.cgColor
            trackView.layer.borderWidth = 1
        }
    }
}
