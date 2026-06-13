import UIKit

final class BootLoadingOverlayView: UIView {

    private let starfield = StarfieldBackgroundView(style: .menu)
    private let reticle = BootReticleView()
    private let progressView = BootProgressView()

    private var displayLink: CADisplayLink?
    private var displayedProgress: CGFloat = 0
    private var reportedTarget: CGFloat = 0
    private var timedRamp: CGFloat = 0
    private var isFinishing = false
    private var finishHandler: (() -> Void)?
    private var bootStartTime: CFTimeInterval = 0
    private let minimumBootDuration: TimeInterval = 2.2
    private let timedRampDuration: TimeInterval = 2.8

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopDisplayLink()
    }

    private func setup() {
        backgroundColor = GameStyle.cockpitBlack

        starfield.translatesAutoresizingMaskIntoConstraints = false
        reticle.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(starfield)
        addSubview(reticle)
        addSubview(progressView)

        NSLayoutConstraint.activate([
            starfield.topAnchor.constraint(equalTo: topAnchor),
            starfield.leadingAnchor.constraint(equalTo: leadingAnchor),
            starfield.trailingAnchor.constraint(equalTo: trailingAnchor),
            starfield.bottomAnchor.constraint(equalTo: bottomAnchor),

            reticle.centerXAnchor.constraint(equalTo: centerXAnchor),
            reticle.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -28),
            reticle.widthAnchor.constraint(equalToConstant: 108),
            reticle.heightAnchor.constraint(equalToConstant: 108),

            progressView.topAnchor.constraint(equalTo: reticle.bottomAnchor, constant: 28),
            progressView.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 220)
        ])
    }

    func startAnimating() {
        bootStartTime = CACurrentMediaTime()
        displayedProgress = 0
        reportedTarget = 0
        timedRamp = 0
        isFinishing = false
        finishHandler = nil
        progressView.setProgress(0, animated: false)
        progressView.setStatus("INITIALIZING SYSTEMS")
        starfield.startAnimating()
        startDisplayLink()
    }

    func stopAnimating() {
        stopDisplayLink()
        starfield.stopAnimating()
    }

    func updateProgress(_ progress: CGFloat) {
        reportedTarget = max(reportedTarget, max(0, min(1, progress)))
        if reportedTarget > 0 {
            progressView.setStatus("LOADING ASSETS")
        }
    }

    func complete(completion: (() -> Void)? = nil) {
        reportedTarget = 1
        isFinishing = true
        finishHandler = completion
        progressView.setStatus("READY")
    }

    private func startDisplayLink() {
        stopDisplayLink()
        let link = CADisplayLink(target: self, selector: #selector(tickProgress))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tickProgress() {
        let elapsed = CACurrentMediaTime() - bootStartTime
        let rampFraction = min(1, elapsed / timedRampDuration)
        timedRamp = CGFloat(rampFraction) * 0.88

        let effectiveTarget = min(1, max(reportedTarget, timedRamp))
        let delta = effectiveTarget - displayedProgress

        if abs(delta) < 0.0005 {
            displayedProgress = effectiveTarget
        } else {
            let step = max(0.0018, abs(delta) * 0.07)
            displayedProgress += delta > 0 ? min(step, delta) : max(-step, delta)
        }

        displayedProgress = max(0, min(1, displayedProgress))
        progressView.setProgress(displayedProgress, animated: false)

        guard isFinishing else { return }

        let minimumElapsed = elapsed >= minimumBootDuration
        guard displayedProgress >= 0.995, minimumElapsed else { return }

        displayedProgress = 1
        progressView.setProgress(1, animated: false)
        stopDisplayLink()

        UIView.animate(withDuration: 0.35, delay: 0.1, options: [.curveEaseInOut]) {
            self.alpha = 0
        } completion: { _ in
            self.stopAnimating()
            self.isHidden = true
            self.finishHandler?()
            self.finishHandler = nil
        }
    }
}

// MARK: - Reticle

private final class BootReticleView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        drawReticle()
    }

    private func drawReticle() {
        let bounds = self.bounds
        guard bounds.width > 0 else { return }

        let outerInset: CGFloat = 8
        let innerInset: CGFloat = 24
        let outerRect = bounds.insetBy(dx: outerInset, dy: outerInset)
        let innerRect = bounds.insetBy(dx: innerInset, dy: innerInset)

        addStroke(rect: outerRect, color: GameStyle.gaugeAmber.cgColor, width: 2)
        addStroke(rect: innerRect, color: GameStyle.borderSteel.cgColor, width: 1)

        let stripe = CALayer()
        stripe.backgroundColor = GameStyle.accentRedBright.cgColor
        stripe.frame = CGRect(x: 0, y: bounds.midY - 36, width: 3, height: 72)
        layer.addSublayer(stripe)

        let glow = CALayer()
        glow.backgroundColor = GameStyle.panelBlueDark.withAlphaComponent(0.96).cgColor
        glow.frame = CGRect(x: bounds.midX - 34, y: bounds.midY - 34, width: 68, height: 68)
        layer.insertSublayer(glow, at: 0)

        let crossV = CALayer()
        crossV.backgroundColor = GameStyle.accentRedBright.cgColor
        crossV.frame = CGRect(x: bounds.midX - 1, y: bounds.midY - 30, width: 2, height: 60)
        layer.addSublayer(crossV)

        let crossH = CALayer()
        crossH.backgroundColor = GameStyle.gaugeAmber.cgColor
        crossH.frame = CGRect(x: bounds.midX - 30, y: bounds.midY - 1, width: 60, height: 2)
        layer.addSublayer(crossH)

        let dot = CALayer()
        dot.backgroundColor = GameStyle.accentRedBright.cgColor
        dot.frame = CGRect(x: bounds.midX - 2, y: bounds.midY - 2, width: 4, height: 4)
        layer.addSublayer(dot)

        addCornerBrackets(in: bounds, length: 12, inset: 4)
    }

    private func addStroke(rect: CGRect, color: CGColor, width: CGFloat) {
        let shape = CAShapeLayer()
        shape.path = UIBezierPath(rect: rect).cgPath
        shape.strokeColor = color
        shape.fillColor = UIColor.clear.cgColor
        shape.lineWidth = width
        layer.addSublayer(shape)
    }

    private func addCornerBrackets(in bounds: CGRect, length: CGFloat, inset: CGFloat) {
        let color = GameStyle.borderSteel.cgColor
        let thickness: CGFloat = 2
        let corners: [(CGPoint, CGPoint)] = [
            (CGPoint(x: inset, y: inset), CGPoint(x: inset + length, y: inset)),
            (CGPoint(x: inset, y: inset), CGPoint(x: inset, y: inset + length)),
            (CGPoint(x: bounds.width - inset, y: inset), CGPoint(x: bounds.width - inset - length, y: inset)),
            (CGPoint(x: bounds.width - inset, y: inset), CGPoint(x: bounds.width - inset, y: inset + length)),
            (CGPoint(x: inset, y: bounds.height - inset), CGPoint(x: inset + length, y: bounds.height - inset)),
            (CGPoint(x: inset, y: bounds.height - inset), CGPoint(x: inset, y: bounds.height - inset - length)),
            (CGPoint(x: bounds.width - inset, y: bounds.height - inset), CGPoint(x: bounds.width - inset - length, y: bounds.height - inset)),
            (CGPoint(x: bounds.width - inset, y: bounds.height - inset), CGPoint(x: bounds.width - inset, y: bounds.height - inset - length))
        ]

        for (start, end) in corners {
            let line = CAShapeLayer()
            let path = UIBezierPath()
            path.move(to: start)
            path.addLine(to: end)
            line.path = path.cgPath
            line.strokeColor = color
            line.lineWidth = thickness
            layer.addSublayer(line)
        }
    }
}

// MARK: - Progress

private final class BootProgressView: UIView {

    private let statusLabel = UILabel()
    private let trackView = UIView()
    private let fillView = UIView()
    private var fillWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .systemFont(ofSize: 9, weight: .heavy)
        statusLabel.textColor = GameStyle.gaugeAmber
        statusLabel.textAlignment = .center

        trackView.translatesAutoresizingMaskIntoConstraints = false
        trackView.backgroundColor = GameStyle.cockpitBlack
        trackView.layer.cornerRadius = 4
        trackView.layer.borderWidth = 1
        trackView.layer.borderColor = GameStyle.borderSteel.cgColor
        trackView.clipsToBounds = true

        fillView.translatesAutoresizingMaskIntoConstraints = false
        fillView.backgroundColor = GameStyle.accentRedBright
        fillView.layer.cornerRadius = 3

        addSubview(statusLabel)
        addSubview(trackView)
        trackView.addSubview(fillView)

        fillWidthConstraint = fillView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: topAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            trackView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            trackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            trackView.heightAnchor.constraint(equalToConstant: 8),
            trackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            fillView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor, constant: 1),
            fillView.topAnchor.constraint(equalTo: trackView.topAnchor, constant: 1),
            fillView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor, constant: -1),
            fillWidthConstraint!
        ])
    }

    func setStatus(_ text: String) {
        statusLabel.text = text
    }

    func setProgress(_ progress: CGFloat, animated: Bool) {
        layoutIfNeeded()
        let trackWidth = max(trackView.bounds.width - 2, 0)
        fillWidthConstraint?.constant = trackWidth * progress
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut]) {
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }
    }
}
