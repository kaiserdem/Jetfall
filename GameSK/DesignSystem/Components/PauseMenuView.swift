import UIKit

final class PauseMenuView: UIView {

    var onContinue: (() -> Void)?
    var onRestart: (() -> Void)?
    var onExit: (() -> Void)?
    var onShop: (() -> Void)?

    private let dimView = UIView()
    private let panel = UIView()
    private let titleLabel = UILabel()
    private let continueButton = UIButton(type: .system)
    private let restartButton = UIButton(type: .system)
    private let shopButton = UIButton(type: .system)
    private let exitButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        isHidden = true
        alpha = 0

        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.backgroundColor = GameStyle.cockpitBlack.withAlphaComponent(0.65)

        panel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleOverlayPanel(panel)
        panel.backgroundColor = GameStyle.panelBlueDark.withAlphaComponent(0.96)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "MENU"
        titleLabel.font = .systemFont(ofSize: 32, weight: .heavy)
        titleLabel.textColor = GameStyle.textPrimary
        titleLabel.textAlignment = .center

        continueButton.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.applyPrimaryButton(continueButton, title: "Continue")
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        restartButton.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.applySecondaryButton(restartButton, title: "Start Again")
        restartButton.addTarget(self, action: #selector(restartTapped), for: .touchUpInside)

        shopButton.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.applySecondaryButton(shopButton, title: "Shop")
        shopButton.addTarget(self, action: #selector(shopTapped), for: .touchUpInside)

        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.setTitle("Exit", for: .normal)
        exitButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        exitButton.tintColor = GameStyle.gaugeLowRed
        exitButton.backgroundColor = .clear
        exitButton.layer.cornerRadius = 10
        exitButton.layer.borderWidth = 1.5
        exitButton.layer.borderColor = GameStyle.gaugeLowRed.withAlphaComponent(0.6).cgColor
        exitButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 22, bottom: 12, right: 22)
        exitButton.addTarget(self, action: #selector(exitTapped), for: .touchUpInside)

        addSubview(dimView)
        addSubview(panel)
        panel.addSubview(titleLabel)
        panel.addSubview(continueButton)
        panel.addSubview(restartButton)
        panel.addSubview(shopButton)
        panel.addSubview(exitButton)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            panel.centerXAnchor.constraint(equalTo: centerXAnchor),
            panel.centerYAnchor.constraint(equalTo: centerYAnchor),
            panel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 36),
            panel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -36),

            titleLabel.topAnchor.constraint(equalTo: panel.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -20),

            continueButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            continueButton.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -20),

            restartButton.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 12),
            restartButton.leadingAnchor.constraint(equalTo: continueButton.leadingAnchor),
            restartButton.trailingAnchor.constraint(equalTo: continueButton.trailingAnchor),

            shopButton.topAnchor.constraint(equalTo: restartButton.bottomAnchor, constant: 12),
            shopButton.leadingAnchor.constraint(equalTo: continueButton.leadingAnchor),
            shopButton.trailingAnchor.constraint(equalTo: continueButton.trailingAnchor),

            exitButton.topAnchor.constraint(equalTo: shopButton.bottomAnchor, constant: 12),
            exitButton.leadingAnchor.constraint(equalTo: continueButton.leadingAnchor),
            exitButton.trailingAnchor.constraint(equalTo: continueButton.trailingAnchor),
            exitButton.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -24)
        ])
    }

    func show(animated: Bool = true) {
        isHidden = false
        guard animated else {
            alpha = 1
            return
        }
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }

    func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard animated else {
            alpha = 0
            isHidden = true
            completion?()
            return
        }
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.isHidden = true
            completion?()
        })
    }

    @objc private func continueTapped() {
        onContinue?()
    }

    @objc private func restartTapped() {
        onRestart?()
    }

    @objc private func shopTapped() {
        onShop?()
    }

    @objc private func exitTapped() {
        onExit?()
    }
}
