import UIKit

protocol VirtualDPadDelegate: AnyObject {
    func dPad(_ dPad: VirtualDPadView, didUpdate directions: Set<MoveDirection>)
}

final class VirtualDPadView: UIView {

    enum HorizontalAlignment {
        case left
        case right
    }

    weak var delegate: VirtualDPadDelegate?

    var horizontalAlignment: HorizontalAlignment = .right

    private var activeDirections = Set<MoveDirection>()
    private var touchMap = [UITouch: MoveDirection]()
    private let buttonSize: CGFloat = 58
    private let spacing: CGFloat = 48

    private lazy var buttons: [MoveDirection: UIButton] = {
        var map = [MoveDirection: UIButton]()
        for direction in MoveDirection.allCases {
            let button = UIButton(type: .system)
            button.tag = directionTag(direction)
            button.setTitle(symbol(for: direction), for: .normal)
            button.titleLabel?.font = .boldSystemFont(ofSize: 22)
            GameStyle.styleControlButton(button, cornerRadius: buttonSize / 2)
            button.addTarget(self, action: #selector(buttonDown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(buttonUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
            map[direction] = button
            addSubview(button)
        }
        return map
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        _ = buttons
        isMultipleTouchEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = buttonSize + spacing * 0.5
        let centerX = horizontalAlignment == .right ? bounds.width - inset : inset
        let center = CGPoint(x: centerX, y: bounds.height - buttonSize - spacing * 0.5)
        let offsets: [MoveDirection: CGPoint] = [
            .up: CGPoint(x: 0, y: spacing),
            .down: CGPoint(x: 0, y: -spacing),
            .left: CGPoint(x: -spacing, y: 0),
            .right: CGPoint(x: spacing, y: 0)
        ]
        for (direction, button) in buttons {
            let offset = offsets[direction] ?? .zero
            button.frame = CGRect(
                x: center.x + offset.x - buttonSize / 2,
                y: center.y - offset.y - buttonSize / 2,
                width: buttonSize,
                height: buttonSize
            )
        }
    }

    func setPressed(_ pressed: Bool, for direction: MoveDirection) {
        guard let button = buttons[direction] else { return }
        if pressed {
            GameStyle.styleControlButtonPressed(button)
        } else {
            GameStyle.styleControlButtonReleased(button)
        }
        button.transform = pressed ? CGAffineTransform(scaleX: 0.92, y: 0.92) : .identity
    }

    func clearAll() {
        activeDirections.removeAll()
        touchMap.removeAll()
        MoveDirection.allCases.forEach { setPressed(false, for: $0) }
        delegate?.dPad(self, didUpdate: [])
    }

    @objc private func buttonDown(_ sender: UIButton) {
        guard let direction = direction(from: sender.tag) else { return }
        activeDirections.insert(direction)
        setPressed(true, for: direction)
        delegate?.dPad(self, didUpdate: activeDirections)
    }

    @objc private func buttonUp(_ sender: UIButton) {
        guard let direction = direction(from: sender.tag) else { return }
        activeDirections.remove(direction)
        setPressed(false, for: direction)
        delegate?.dPad(self, didUpdate: activeDirections)
    }

    private func symbol(for direction: MoveDirection) -> String {
        switch direction {
        case .up: return "▲"
        case .down: return "▼"
        case .left: return "◀"
        case .right: return "▶"
        }
    }

    private func directionTag(_ direction: MoveDirection) -> Int {
        switch direction {
        case .up: return 0
        case .down: return 1
        case .left: return 2
        case .right: return 3
        }
    }

    private func direction(from tag: Int) -> MoveDirection? {
        switch tag {
        case 0: return .up
        case 1: return .down
        case 2: return .left
        case 3: return .right
        default: return nil
        }
    }
}
