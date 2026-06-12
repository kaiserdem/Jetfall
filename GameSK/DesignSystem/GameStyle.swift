import UIKit

enum GameStyle {

    static let cockpitBlack = UIColor(red: 0.04, green: 0.05, blue: 0.07, alpha: 1)
    static let deepNavy = UIColor(red: 0.06, green: 0.10, blue: 0.20, alpha: 1)
    static let panelBlue = UIColor(red: 0.10, green: 0.16, blue: 0.28, alpha: 0.94)
    static let panelBlueDark = UIColor(red: 0.07, green: 0.11, blue: 0.20, alpha: 0.96)
    static let accentRed = UIColor(red: 0.82, green: 0.14, blue: 0.12, alpha: 1)
    static let accentRedBright = UIColor(red: 0.92, green: 0.22, blue: 0.16, alpha: 1)
    static let accentRedDim = UIColor(red: 0.55, green: 0.10, blue: 0.10, alpha: 0.75)
    static let gaugeAmber = UIColor(red: 0.95, green: 0.72, blue: 0.18, alpha: 1)
    static let gaugeLowRed = UIColor(red: 0.90, green: 0.18, blue: 0.12, alpha: 1)
    static let textPrimary = UIColor(white: 0.95, alpha: 1)
    static let textSecondary = UIColor(white: 0.72, alpha: 1)
    static let borderSteel = UIColor(white: 0.55, alpha: 0.42)
    static let borderHighlight = UIColor(white: 0.82, alpha: 0.55)

    static func styleTitleLabel(_ label: UILabel, text: String, size: CGFloat = 40) {
        label.text = text
        label.font = .systemFont(ofSize: size, weight: .heavy)
        label.textColor = textPrimary
        label.textAlignment = .center
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOpacity = 0.5
        label.layer.shadowRadius = 5
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    static func styleHUDLabel(_ label: UILabel, size: CGFloat = 18, weight: UIFont.Weight = .semibold) {
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = textPrimary
    }

    static func styleSubtitleLabel(_ label: UILabel, size: CGFloat = 15) {
        label.font = .systemFont(ofSize: size, weight: .medium)
        label.textColor = textSecondary
    }

    static func applyPrimaryButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.tintColor = textPrimary
        button.backgroundColor = accentRedDim
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 2
        button.layer.borderColor = borderHighlight.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 28, bottom: 14, right: 28)
    }

    static func applySecondaryButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.tintColor = textPrimary
        button.backgroundColor = panelBlue
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1.5
        button.layer.borderColor = borderSteel.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 22, bottom: 12, right: 22)
    }

    static func styleControlButton(_ button: UIButton, cornerRadius: CGFloat) {
        button.tintColor = textPrimary
        button.backgroundColor = panelBlueDark
        button.layer.cornerRadius = cornerRadius
        button.layer.borderWidth = 2
        button.layer.borderColor = borderSteel.cgColor
    }

    static func styleControlButtonPressed(_ button: UIButton) {
        button.backgroundColor = accentRedDim
        button.layer.borderColor = accentRedBright.cgColor
    }

    static func styleControlButtonReleased(_ button: UIButton) {
        button.backgroundColor = panelBlueDark
        button.layer.borderColor = borderSteel.cgColor
    }

    static func stylePanel(_ view: UIView, cornerRadius: CGFloat = 10) {
        view.backgroundColor = panelBlueDark
        view.layer.cornerRadius = cornerRadius
        view.layer.borderWidth = 1.5
        view.layer.borderColor = borderSteel.cgColor
    }

    static func styleOverlayPanel(_ view: UIView) {
        view.backgroundColor = cockpitBlack.withAlphaComponent(0.72)
        view.layer.cornerRadius = 14
        view.layer.borderWidth = 2
        view.layer.borderColor = borderHighlight.cgColor
    }
}
