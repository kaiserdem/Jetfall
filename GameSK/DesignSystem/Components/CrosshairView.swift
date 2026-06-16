import UIKit

final class CrosshairView: UIView {

    private let outerRing = CAShapeLayer()
    private let innerDot = CAShapeLayer()
    private let north = CAShapeLayer()
    private let south = CAShapeLayer()
    private let east = CAShapeLayer()
    private let west = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 34, height: 34)
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        backgroundColor = .clear
        layer.addSublayer(outerRing)
        layer.addSublayer(north)
        layer.addSublayer(south)
        layer.addSublayer(east)
        layer.addSublayer(west)
        layer.addSublayer(innerDot)
        styleLayers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let ringRadius: CGFloat = min(bounds.width, bounds.height) * 0.34
        let gap: CGFloat = 4.5
        let tickLength: CGFloat = 5

        outerRing.path = UIBezierPath(
            arcCenter: center,
            radius: ringRadius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        ).cgPath
        outerRing.frame = bounds

        innerDot.path = UIBezierPath(
            arcCenter: center,
            radius: 1.6,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        ).cgPath
        innerDot.frame = bounds

        north.path = tickPath(
            from: CGPoint(x: center.x, y: center.y - ringRadius - gap - tickLength),
            to: CGPoint(x: center.x, y: center.y - ringRadius - gap)
        )
        south.path = tickPath(
            from: CGPoint(x: center.x, y: center.y + ringRadius + gap),
            to: CGPoint(x: center.x, y: center.y + ringRadius + gap + tickLength)
        )
        east.path = tickPath(
            from: CGPoint(x: center.x + ringRadius + gap, y: center.y),
            to: CGPoint(x: center.x + ringRadius + gap + tickLength, y: center.y)
        )
        west.path = tickPath(
            from: CGPoint(x: center.x - ringRadius - gap - tickLength, y: center.y),
            to: CGPoint(x: center.x - ringRadius - gap, y: center.y)
        )

        [north, south, east, west].forEach { $0.frame = bounds }
    }

    private func styleLayers() {
        let strokeColor = GameStyle.gaugeAmber.withAlphaComponent(0.92).cgColor

        outerRing.fillColor = UIColor.clear.cgColor
        outerRing.strokeColor = strokeColor
        outerRing.lineWidth = 1.5

        innerDot.fillColor = GameStyle.gaugeAmber.cgColor
        innerDot.strokeColor = UIColor.clear.cgColor

        [north, south, east, west].forEach { layer in
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = strokeColor
            layer.lineWidth = 1.5
            layer.lineCap = .round
        }

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.45
        layer.shadowRadius = 2
        layer.shadowOffset = .zero
    }

    private func tickPath(from start: CGPoint, to end: CGPoint) -> CGPath {
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        return path.cgPath
    }
}
