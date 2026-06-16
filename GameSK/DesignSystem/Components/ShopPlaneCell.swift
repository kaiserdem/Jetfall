import SceneKit
import UIKit

final class ShopPlaneCell: UICollectionViewCell {

    static let reuseID = "ShopPlaneCell"

    private let shadowWrapper = UIView()
    private let cardView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let accentStripe = UIView()
    private let glowView = UIView()
    private let aircraftTag = UILabel()
    private let nameLabel = UILabel()
    private let cruiseLabel = UILabel()
    private let priceLabel = UILabel()
    private let statusBadge = UILabel()
    private let previewContainer = UIView()
    private let sceneView = SCNView()
    private let blurOverlay = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let classifiedLabel = UILabel()
    private let lockIcon = UIImageView()
    private let requirementsStack = UIStackView()
    private let unlockCaptionLabel = UILabel()
    private let unlockRequirementLabel = UILabel()
    private var lockedInfoCollapsedHeight: NSLayoutConstraint?
    private var didConfigureScene = false
    private var previewPlaneNode: SCNNode?
    private var configuredPlaneID: Int?
    private var displayedPlane: ShopPlane?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        sceneView.isPlaying = false
        previewPlaneNode?.removeAllActions()
        previewPlaneNode?.removeFromParentNode()
        previewPlaneNode = nil
        configuredPlaneID = nil
        displayedPlane = nil
    }

    private func setup() {
        contentView.backgroundColor = .clear

        shadowWrapper.translatesAutoresizingMaskIntoConstraints = false
        shadowWrapper.backgroundColor = .clear
        shadowWrapper.layer.shadowColor = UIColor.black.cgColor
        shadowWrapper.layer.shadowOpacity = 0.35
        shadowWrapper.layer.shadowRadius = 8
        shadowWrapper.layer.shadowOffset = CGSize(width: 0, height: 4)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.layer.cornerRadius = 20
        cardView.layer.borderWidth = 1.5
        cardView.layer.masksToBounds = true

        gradientLayer.cornerRadius = 20
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        cardView.layer.insertSublayer(gradientLayer, at: 0)

        glowView.translatesAutoresizingMaskIntoConstraints = false
        glowView.layer.cornerRadius = 22
        glowView.isUserInteractionEnabled = false
        glowView.isHidden = true

        accentStripe.translatesAutoresizingMaskIntoConstraints = false
        accentStripe.layer.cornerRadius = 2

        aircraftTag.translatesAutoresizingMaskIntoConstraints = false
        aircraftTag.font = .systemFont(ofSize: 11, weight: .heavy)
        aircraftTag.textColor = GameStyle.gaugeAmber
        aircraftTag.text = "AIRCRAFT"

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 20, weight: .black)
        nameLabel.textColor = GameStyle.textPrimary
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.82

        cruiseLabel.translatesAutoresizingMaskIntoConstraints = false
        cruiseLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        cruiseLabel.textColor = GameStyle.textSecondary
        cruiseLabel.numberOfLines = 3

        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .bold)
        priceLabel.textColor = GameStyle.gaugeAmber

        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        statusBadge.font = .systemFont(ofSize: 9, weight: .bold)
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 8
        statusBadge.layer.masksToBounds = true
        statusBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusBadge.setContentHuggingPriority(.required, for: .horizontal)

        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.backgroundColor = GameStyle.cockpitBlack.withAlphaComponent(0.45)
        previewContainer.layer.cornerRadius = 12
        previewContainer.layer.borderWidth = 1
        previewContainer.layer.borderColor = GameStyle.borderSteel.withAlphaComponent(0.4).cgColor
        previewContainer.clipsToBounds = true

        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false
        sceneView.antialiasingMode = .multisampling2X
        sceneView.rendersContinuously = true

        blurOverlay.translatesAutoresizingMaskIntoConstraints = false
        blurOverlay.isHidden = true
        blurOverlay.isUserInteractionEnabled = false

        classifiedLabel.translatesAutoresizingMaskIntoConstraints = false
        classifiedLabel.text = "CLASSIFIED"
        classifiedLabel.font = .systemFont(ofSize: 11, weight: .heavy)
        classifiedLabel.textColor = GameStyle.textPrimary.withAlphaComponent(0.85)
        classifiedLabel.textAlignment = .center
        classifiedLabel.isHidden = true

        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        lockIcon.image = UIImage(systemName: "lock.fill")
        lockIcon.tintColor = GameStyle.textPrimary.withAlphaComponent(0.9)
        lockIcon.contentMode = .scaleAspectFit
        lockIcon.isHidden = true

        unlockCaptionLabel.translatesAutoresizingMaskIntoConstraints = false
        unlockCaptionLabel.font = .systemFont(ofSize: 9, weight: .heavy)
        unlockCaptionLabel.textColor = GameStyle.textSecondary
        unlockCaptionLabel.text = "UNLOCK REQUIREMENT"

        unlockRequirementLabel.translatesAutoresizingMaskIntoConstraints = false
        unlockRequirementLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        unlockRequirementLabel.textColor = GameStyle.textPrimary
        unlockRequirementLabel.numberOfLines = 2

        requirementsStack.translatesAutoresizingMaskIntoConstraints = false
        requirementsStack.axis = .vertical
        requirementsStack.spacing = 3
        requirementsStack.alignment = .leading
        requirementsStack.addArrangedSubview(unlockCaptionLabel)
        requirementsStack.addArrangedSubview(unlockRequirementLabel)

        previewContainer.addSubview(sceneView)
        previewContainer.addSubview(blurOverlay)
        previewContainer.addSubview(lockIcon)
        previewContainer.addSubview(classifiedLabel)

        shadowWrapper.insertSubview(glowView, at: 0)
        cardView.addSubview(accentStripe)
        cardView.addSubview(aircraftTag)
        cardView.addSubview(statusBadge)
        cardView.addSubview(nameLabel)
        cardView.addSubview(cruiseLabel)
        cardView.addSubview(priceLabel)
        cardView.addSubview(previewContainer)
        cardView.addSubview(requirementsStack)
        shadowWrapper.addSubview(cardView)
        contentView.addSubview(shadowWrapper)

        lockedInfoCollapsedHeight = requirementsStack.heightAnchor.constraint(equalToConstant: 0)
        lockedInfoCollapsedHeight?.isActive = true

        NSLayoutConstraint.activate([
            shadowWrapper.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            shadowWrapper.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shadowWrapper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shadowWrapper.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            cardView.topAnchor.constraint(equalTo: shadowWrapper.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: shadowWrapper.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: shadowWrapper.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: shadowWrapper.bottomAnchor),

            glowView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: -3),
            glowView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: -3),
            glowView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: 3),
            glowView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 3),

            accentStripe.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            accentStripe.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            accentStripe.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            accentStripe.widthAnchor.constraint(equalToConstant: 3),

            aircraftTag.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            aircraftTag.leadingAnchor.constraint(equalTo: accentStripe.trailingAnchor, constant: 10),

            statusBadge.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            statusBadge.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            statusBadge.heightAnchor.constraint(equalToConstant: 18),
            statusBadge.leadingAnchor.constraint(greaterThanOrEqualTo: aircraftTag.trailingAnchor, constant: 8),

            nameLabel.topAnchor.constraint(equalTo: aircraftTag.bottomAnchor, constant: 2),
            nameLabel.leadingAnchor.constraint(equalTo: aircraftTag.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            cruiseLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            cruiseLabel.leadingAnchor.constraint(equalTo: aircraftTag.leadingAnchor),
            cruiseLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            priceLabel.topAnchor.constraint(equalTo: cruiseLabel.bottomAnchor, constant: 4),
            priceLabel.leadingAnchor.constraint(equalTo: aircraftTag.leadingAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            previewContainer.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 10),
            previewContainer.leadingAnchor.constraint(equalTo: accentStripe.trailingAnchor, constant: 10),
            previewContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            previewContainer.heightAnchor.constraint(equalToConstant: 112),

            sceneView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),

            blurOverlay.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            blurOverlay.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            blurOverlay.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            blurOverlay.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),

            lockIcon.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            lockIcon.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor, constant: -8),
            lockIcon.widthAnchor.constraint(equalToConstant: 20),
            lockIcon.heightAnchor.constraint(equalToConstant: 20),

            classifiedLabel.topAnchor.constraint(equalTo: lockIcon.bottomAnchor, constant: 4),
            classifiedLabel.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),

            requirementsStack.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 8),
            requirementsStack.leadingAnchor.constraint(equalTo: aircraftTag.leadingAnchor),
            requirementsStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            requirementsStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = cardView.bounds

        guard displayedPlane != nil else { return }
        sceneView.isPlaying = true
    }

    func configure(with plane: ShopPlane) {
        displayedPlane = plane
        configureSceneIfNeeded()
        setPreviewPlane(for: plane)
        sceneView.isPlaying = true

        nameLabel.text = plane.name
        aircraftTag.text = plane.callSign
        cruiseLabel.text = plane.aircraftSpecsText()
        priceLabel.text = formattedPrice(for: plane)

        let isOwned = PlayerPlaneStore.isOwned(plane.id)
        let isEquipped = PlayerPlaneStore.isEquipped(plane.id)
        let levelsMet = plane.isLevelRequirementMet()
        let showBlur = plane.showsPrototypeBlur

        blurOverlay.isHidden = !showBlur
        classifiedLabel.isHidden = !showBlur
        lockIcon.isHidden = !showBlur || isOwned

        if isEquipped {
            applyEquippedStyle()
        } else if isOwned {
            applyOwnedStyle()
        } else if !levelsMet {
            applyLockedStyle(plane: plane)
        } else {
            applyAvailableStyle(plane: plane)
        }
    }

    func applyCarouselPresentation(scale: CGFloat, alpha: CGFloat) {
        contentView.alpha = alpha
    }

    private func formattedPrice(for plane: ShopPlane) -> String {
        if plane.creditCost == 0 {
            return "FREE"
        }
        if PlayerPlaneStore.isOwned(plane.id) {
            return "OWNED · \(plane.creditCost.formatted()) CR"
        }
        return "\(plane.creditCost.formatted()) CR"
    }

    private func configureSceneIfNeeded() {
        guard !didConfigureScene else { return }
        didConfigureScene = true

        let scene = SCNScene()
        sceneView.scene = scene

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 48
        cameraNode.position = SCNVector3(0, 1.4, 10.5)
        cameraNode.look(at: SCNVector3(0, 0.35, 0))
        scene.rootNode.addChildNode(cameraNode)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 420
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 700
        key.eulerAngles = SCNVector3(-0.55, 0.75, 0)
        scene.rootNode.addChildNode(key)
    }

    private func setPreviewPlane(for plane: ShopPlane) {
        guard let scene = sceneView.scene else { return }

        let isAttached = previewPlaneNode?.parent != nil
        if configuredPlaneID == plane.id, isAttached {
            return
        }

        configuredPlaneID = plane.id
        previewPlaneNode?.removeAllActions()
        previewPlaneNode?.removeFromParentNode()

        let assembly = Plane3DFactory.makeFlightPlane(forResource: plane.modelResourceName)
        let planeNode = assembly.rootNode
        planeNode.scale = SCNVector3(
            Plane3DFactory.shopPreviewScale,
            Plane3DFactory.shopPreviewScale,
            Plane3DFactory.shopPreviewScale
        )
        planeNode.position = SCNVector3(0, 0.3, 0)
        planeNode.eulerAngles = SCNVector3(-0.1, .pi * 0.92, 0)
        scene.rootNode.addChildNode(planeNode)

        let rotate = SCNAction.repeatForever(
            SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 14)
        )
        planeNode.runAction(rotate)
        previewPlaneNode = planeNode
    }

    private func applyEquippedStyle() {
        lockedInfoCollapsedHeight?.isActive = true
        requirementsStack.isHidden = true
        priceLabel.textColor = GameStyle.textPrimary
        cruiseLabel.textColor = GameStyle.textSecondary

        statusBadge.isHidden = false
        statusBadge.text = "  EQUIPPED  "
        statusBadge.textColor = GameStyle.textPrimary
        statusBadge.backgroundColor = GameStyle.accentRed

        gradientLayer.colors = [
            UIColor(red: 0.18, green: 0.08, blue: 0.10, alpha: 1).cgColor,
            GameStyle.panelBlue.cgColor
        ]
        accentStripe.backgroundColor = GameStyle.accentRedBright
        cardView.layer.borderColor = GameStyle.accentRedBright.withAlphaComponent(0.85).cgColor
        glowView.backgroundColor = GameStyle.accentRed.withAlphaComponent(0.35)
        glowView.isHidden = false
        nameLabel.textColor = GameStyle.textPrimary
    }

    private func applyOwnedStyle() {
        lockedInfoCollapsedHeight?.isActive = true
        requirementsStack.isHidden = true
        priceLabel.textColor = GameStyle.gaugeAmber
        cruiseLabel.textColor = GameStyle.textSecondary

        statusBadge.isHidden = false
        statusBadge.text = "  OWNED  "
        statusBadge.textColor = GameStyle.cockpitBlack
        statusBadge.backgroundColor = UIColor(red: 0.35, green: 0.85, blue: 0.62, alpha: 1)

        gradientLayer.colors = [
            UIColor(red: 0.06, green: 0.14, blue: 0.12, alpha: 1).cgColor,
            GameStyle.panelBlue.cgColor
        ]
        accentStripe.backgroundColor = UIColor(red: 0.25, green: 0.72, blue: 0.55, alpha: 1)
        cardView.layer.borderColor = UIColor(red: 0.25, green: 0.72, blue: 0.55, alpha: 0.5).cgColor
        glowView.isHidden = true
        nameLabel.textColor = GameStyle.textPrimary
    }

    private func applyLockedStyle(plane: ShopPlane) {
        lockedInfoCollapsedHeight?.isActive = false
        requirementsStack.isHidden = false
        unlockRequirementLabel.text = plane.unlockRequirementText()
        priceLabel.textColor = GameStyle.textSecondary
        cruiseLabel.textColor = GameStyle.textSecondary.withAlphaComponent(0.85)

        statusBadge.isHidden = false
        statusBadge.text = "  LOCKED  "
        statusBadge.textColor = GameStyle.textSecondary
        statusBadge.backgroundColor = GameStyle.cockpitBlack.withAlphaComponent(0.65)

        gradientLayer.colors = [
            GameStyle.cockpitBlack.cgColor,
            GameStyle.panelBlueDark.cgColor
        ]
        accentStripe.backgroundColor = GameStyle.borderSteel.withAlphaComponent(0.55)
        cardView.layer.borderColor = GameStyle.borderSteel.withAlphaComponent(0.45).cgColor
        glowView.isHidden = true
        nameLabel.textColor = GameStyle.textSecondary.withAlphaComponent(0.85)
    }

    private func applyAvailableStyle(plane: ShopPlane) {
        lockedInfoCollapsedHeight?.isActive = false
        requirementsStack.isHidden = false
        unlockRequirementLabel.text = plane.unlockRequirementText()
        priceLabel.textColor = GameStyle.gaugeAmber
        cruiseLabel.textColor = GameStyle.textSecondary

        statusBadge.isHidden = false
        statusBadge.text = "  AVAILABLE  "
        statusBadge.textColor = GameStyle.textPrimary
        statusBadge.backgroundColor = GameStyle.panelBlueDark

        gradientLayer.colors = [
            GameStyle.deepNavy.cgColor,
            GameStyle.panelBlue.cgColor
        ]
        accentStripe.backgroundColor = GameStyle.gaugeAmber
        cardView.layer.borderColor = GameStyle.borderHighlight.cgColor
        glowView.isHidden = true
        nameLabel.textColor = GameStyle.textPrimary
    }
}
