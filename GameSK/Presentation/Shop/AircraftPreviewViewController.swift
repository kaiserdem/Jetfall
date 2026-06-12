import SceneKit
import UIKit

final class AircraftPreviewViewController: UIViewController {

    private let plane: ShopPlane

    private let dimView = UIView()
    private let panel = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let sceneContainer = UIView()
    private let sceneView = SCNView()
    private let blurOverlay = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let classifiedStack = UIStackView()
    private let lockIcon = UIImageView()
    private let classifiedLabel = UILabel()
    private let closeButton = AviatorNavButton(style: .labeled(symbol: "xmark", title: "Close"))

    init(plane: ShopPlane) {
        self.plane = plane
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GameStyle.cockpitBlack
        setupUI()
        configureScene()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sceneView.isPlaying = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        sceneView.isPlaying = false
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    private func setupUI() {
        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.backgroundColor = GameStyle.cockpitBlack.withAlphaComponent(0.55)

        panel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.stylePanel(panel, cornerRadius: 18)
        panel.backgroundColor = GameStyle.panelBlueDark.withAlphaComponent(0.96)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 24, weight: .heavy)
        titleLabel.textColor = GameStyle.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.text = plane.name

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleSubtitleLabel(subtitleLabel, size: 14)
        subtitleLabel.textAlignment = .center
        subtitleLabel.text = "\(plane.callSign) · \(plane.priceText())"

        sceneContainer.translatesAutoresizingMaskIntoConstraints = false
        sceneContainer.backgroundColor = GameStyle.cockpitBlack.withAlphaComponent(0.5)
        sceneContainer.layer.cornerRadius = 16
        sceneContainer.layer.borderWidth = 1.5
        sceneContainer.layer.borderColor = GameStyle.borderSteel.cgColor
        sceneContainer.clipsToBounds = true

        sceneView.translatesAutoresizingMaskIntoConstraints = false

        blurOverlay.translatesAutoresizingMaskIntoConstraints = false
        blurOverlay.isUserInteractionEnabled = false

        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        lockIcon.image = UIImage(systemName: "lock.fill")
        lockIcon.tintColor = GameStyle.textPrimary
        lockIcon.contentMode = .scaleAspectFit

        classifiedLabel.text = "CLASSIFIED PROTOTYPE"
        classifiedLabel.font = .systemFont(ofSize: 12, weight: .heavy)
        classifiedLabel.textColor = GameStyle.textPrimary
        classifiedLabel.textAlignment = .center

        classifiedStack.translatesAutoresizingMaskIntoConstraints = false
        classifiedStack.axis = .vertical
        classifiedStack.alignment = .center
        classifiedStack.spacing = 8
        classifiedStack.addArrangedSubview(lockIcon)
        classifiedStack.addArrangedSubview(classifiedLabel)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        view.addSubview(dimView)
        view.addSubview(panel)
        panel.addSubview(titleLabel)
        panel.addSubview(subtitleLabel)
        panel.addSubview(sceneContainer)
        sceneContainer.addSubview(sceneView)
        sceneContainer.addSubview(blurOverlay)
        sceneContainer.addSubview(classifiedStack)
        panel.addSubview(closeButton)

        let showClassified = plane.showsPrototypeBlur && !PlayerPlaneStore.isOwned(plane.id)
        blurOverlay.isHidden = !showClassified
        classifiedStack.isHidden = !showClassified

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            panel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: panel.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            sceneContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            sceneContainer.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            sceneContainer.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),
            sceneContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.42),

            sceneView.topAnchor.constraint(equalTo: sceneContainer.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: sceneContainer.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: sceneContainer.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: sceneContainer.bottomAnchor),

            blurOverlay.topAnchor.constraint(equalTo: sceneContainer.topAnchor),
            blurOverlay.leadingAnchor.constraint(equalTo: sceneContainer.leadingAnchor),
            blurOverlay.trailingAnchor.constraint(equalTo: sceneContainer.trailingAnchor),
            blurOverlay.bottomAnchor.constraint(equalTo: sceneContainer.bottomAnchor),

            classifiedStack.centerXAnchor.constraint(equalTo: sceneContainer.centerXAnchor),
            classifiedStack.centerYAnchor.constraint(equalTo: sceneContainer.centerYAnchor),
            lockIcon.widthAnchor.constraint(equalToConstant: 28),
            lockIcon.heightAnchor.constraint(equalToConstant: 28),

            closeButton.topAnchor.constraint(equalTo: sceneContainer.bottomAnchor, constant: 18),
            closeButton.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),
            closeButton.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -20)
        ])
    }

    private func configureScene() {
        GameAssetLoader.shared.whenReady { [weak self] in
            guard let self else { return }
            Plane3DFactory.prepareFlightPlane()
            let planeNode = AircraftPreviewSceneBuilder.attach(to: self.sceneView, style: .fullscreen)
            let rotate = SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 18)
            )
            planeNode.runAction(rotate)
            self.sceneView.isPlaying = true
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
