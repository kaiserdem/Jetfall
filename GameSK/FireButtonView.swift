import UIKit

protocol FireButtonDelegate: AnyObject {
    func fireButton(_ button: FireButtonView, didChangePressed isPressed: Bool)
}

final class FireButtonView: UIView {

    weak var delegate: FireButtonDelegate?

    private let button = UIButton(type: .system)
    private let buttonSize: CGFloat = 72

    override init(frame: CGRect) {
        super.init(frame: frame)
        button.setTitle("●", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 28)
        button.tintColor = .white
        button.backgroundColor = UIColor(red: 0.85, green: 0.2, blue: 0.15, alpha: 0.55)
        button.layer.cornerRadius = buttonSize / 2
        button.layer.borderColor = UIColor(white: 1, alpha: 0.55).cgColor
        button.layer.borderWidth = 2
        button.addTarget(self, action: #selector(buttonDown), for: .touchDown)
        button.addTarget(self, action: #selector(buttonUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        addSubview(button)
        isMultipleTouchEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = CGRect(
            x: (bounds.width - buttonSize) / 2,
            y: bounds.height - buttonSize,
            width: buttonSize,
            height: buttonSize
        )
    }

    func clear() {
        setPressed(false)
        delegate?.fireButton(self, didChangePressed: false)
    }

    private func setPressed(_ pressed: Bool) {
        button.backgroundColor = pressed
            ? UIColor(red: 1, green: 0.35, blue: 0.2, alpha: 0.85)
            : UIColor(red: 0.85, green: 0.2, blue: 0.15, alpha: 0.55)
        button.transform = pressed ? CGAffineTransform(scaleX: 0.92, y: 0.92) : .identity
    }

    @objc private func buttonDown() {
        setPressed(true)
        delegate?.fireButton(self, didChangePressed: true)
    }

    @objc private func buttonUp() {
        setPressed(false)
        delegate?.fireButton(self, didChangePressed: false)
    }
}
