import UIKit

protocol BoostButtonDelegate: AnyObject {
    func boostButton(_ button: BoostButtonView, didChangePressed isPressed: Bool)
}

final class BoostButtonView: UIView {

    weak var delegate: BoostButtonDelegate?

    private let button = UIButton(type: .system)
    private let buttonSize: CGFloat = 72

    override init(frame: CGRect) {
        super.init(frame: frame)
        button.setTitle("BOOST", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 10, weight: .heavy)
        GameStyle.styleControlButton(button, cornerRadius: buttonSize / 2)
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
        delegate?.boostButton(self, didChangePressed: false)
    }

    private func setPressed(_ pressed: Bool) {
        if pressed {
            GameStyle.styleControlButtonPressed(button)
            button.backgroundColor = GameStyle.gaugeAmber.withAlphaComponent(0.35)
        } else {
            GameStyle.styleControlButtonReleased(button)
            button.backgroundColor = nil
        }
        button.transform = pressed ? CGAffineTransform(scaleX: 0.92, y: 0.92) : .identity
    }

    @objc private func buttonDown() {
        setPressed(true)
        delegate?.boostButton(self, didChangePressed: true)
    }

    @objc private func buttonUp() {
        setPressed(false)
        delegate?.boostButton(self, didChangePressed: false)
    }
}
