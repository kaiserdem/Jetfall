import UIKit

final class SettingsToggleRowView: UIView {

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let toggle = UISwitch()
    var onValueChanged: ((Bool) -> Void)?

    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        GameStyle.stylePanel(self, cornerRadius: 12)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleHUDLabel(titleLabel, size: 16, weight: .heavy)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleSubtitleLabel(subtitleLabel, size: 13)
        subtitleLabel.numberOfLines = 2

        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.onTintColor = GameStyle.accentRedBright
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)

        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(toggle)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 72),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -12),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),

            toggle.centerYAnchor.constraint(equalTo: centerYAnchor),
            toggle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14)
        ])
    }

    func configure(isOn: Bool) {
        toggle.isOn = isOn
    }

    @objc private func toggleChanged() {
        onValueChanged?(toggle.isOn)
    }
}

final class SettingsSliderRowView: UIView {

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let slider = UISlider()
    var onValueChanged: ((Float) -> Void)?

    init(title: String, subtitle: String, minimum: Float, maximum: Float) {
        super.init(frame: .zero)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        slider.minimumValue = minimum
        slider.maximumValue = maximum
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        GameStyle.stylePanel(self, cornerRadius: 12)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleHUDLabel(titleLabel, size: 16, weight: .heavy)

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .bold)
        valueLabel.textColor = GameStyle.gaugeAmber
        valueLabel.textAlignment = .right

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleSubtitleLabel(subtitleLabel, size: 13)
        subtitleLabel.numberOfLines = 2

        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = GameStyle.gaugeAmber
        slider.maximumTrackTintColor = GameStyle.borderSteel
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(subtitleLabel)
        addSubview(slider)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),

            valueLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            slider.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            slider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            slider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            slider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }

    func configure(value: Float) {
        slider.value = value
        updateValueLabel(value)
    }

    @objc private func sliderChanged() {
        let value = slider.value
        updateValueLabel(value)
        onValueChanged?(value)
    }

    private func updateValueLabel(_ value: Float) {
        valueLabel.text = GameSettingsStore.planeSizePercentText(for: value)
    }
}
