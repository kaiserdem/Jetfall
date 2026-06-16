import UIKit

final class HangarShopViewController: UIViewController {

    private enum CarouselMetrics {
        static let cardWidthFraction: CGFloat = 0.78
        static let interGroupSpacing: CGFloat = 14
        static let horizontalInset: CGFloat = 12
        static let maxAlphaReduction: CGFloat = 0.26
        static let maxScaleReduction: CGFloat = 0.09
        static let distanceFactor: CGFloat = 0.48
    }

    private enum LayoutMetrics {
        static let horizontalInset: CGFloat = 16
        static let stackSpacing: CGFloat = 12
        static let topInset: CGFloat = 10
        static let bottomInset: CGFloat = 12
    }

    private var starfieldView: StarfieldBackgroundView?
    private let contentStack = UIStackView()
    private let topBar = UIView()
    private let headerPanel = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let progressLabel = UILabel()
    private let progressTrack = UIView()
    private let progressFill = UIView()
    private var progressFillWidth: NSLayoutConstraint?
    private let backButton = AviatorNavButton(style: .labeled(symbol: "chevron.left", title: "Back"))
    private let creditsBadge = HangarCreditsBadge()
    private var collectionView: UICollectionView!

    private let pagerBar = MissionPagerBar()
    private let footerPanel = UIView()
    private let planeHintLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    private let planes = ShopPlaneCatalog.all
    private var focusedPlaneID = 1
    private var didPerformInitialScroll = false
    private var carouselScrollOffset: CGPoint = .zero
    private var carouselContainerWidth: CGFloat = 0
    private var pagerNavigationTarget: Int?
    private var pagerNavigationUnlockWorkItem: DispatchWorkItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GameStyle.cockpitBlack
        configureHeaderPanel()
        configureFooterPanel()
        configureCollectionView()
        configurePagerBar()
        setupContentStack()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        GameAssetLoader.shared.beginPreloadingIfNeeded()
        GameAssetLoader.shared.whenReady { [weak self] in
            self?.showStarfieldIfNeeded()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFleetProgress()
        updateCreditsBadge()
        didPerformInitialScroll = false
        updateFocusedPlane()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didPerformInitialScroll, collectionView.bounds.width > 0 else { return }
        didPerformInitialScroll = true
        scrollToPlane(focusedPlaneID, animated: false)
        updateFocusedPlane(focusedPlaneID)
        applyCarouselTransforms()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        starfieldView?.stopAnimating()
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    private func configureHeaderPanel() {
        headerPanel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.stylePanel(headerPanel, cornerRadius: 14)
        headerPanel.backgroundColor = GameStyle.panelBlueDark.withAlphaComponent(0.88)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "HANGAR SHOP"
        titleLabel.font = .systemFont(ofSize: 28, weight: .heavy)
        titleLabel.textColor = GameStyle.textPrimary
        titleLabel.textAlignment = .center

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Swipe or use aircraft controls below"
        GameStyle.styleSubtitleLabel(subtitleLabel, size: 14)
        subtitleLabel.textAlignment = .center

        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleHUDLabel(progressLabel, size: 12, weight: .bold)
        progressLabel.textColor = GameStyle.gaugeAmber

        progressTrack.translatesAutoresizingMaskIntoConstraints = false
        progressTrack.backgroundColor = GameStyle.cockpitBlack
        progressTrack.layer.cornerRadius = 4
        progressTrack.layer.borderWidth = 1
        progressTrack.layer.borderColor = GameStyle.borderSteel.cgColor

        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressFill.backgroundColor = GameStyle.accentRed
        progressFill.layer.cornerRadius = 3

        headerPanel.addSubview(titleLabel)
        headerPanel.addSubview(subtitleLabel)
        headerPanel.addSubview(progressLabel)
        headerPanel.addSubview(progressTrack)
        progressTrack.addSubview(progressFill)

        progressFillWidth = progressFill.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: headerPanel.topAnchor, constant: 14),
            titleLabel.centerXAnchor.constraint(equalTo: headerPanel.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerPanel.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: headerPanel.trailingAnchor, constant: -16),

            progressLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            progressLabel.leadingAnchor.constraint(equalTo: headerPanel.leadingAnchor, constant: 16),

            progressTrack.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 6),
            progressTrack.leadingAnchor.constraint(equalTo: headerPanel.leadingAnchor, constant: 16),
            progressTrack.trailingAnchor.constraint(equalTo: headerPanel.trailingAnchor, constant: -16),
            progressTrack.heightAnchor.constraint(equalToConstant: 8),
            progressTrack.bottomAnchor.constraint(equalTo: headerPanel.bottomAnchor, constant: -14),

            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor, constant: 1),
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor, constant: 1),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor, constant: -1),
            progressFillWidth!
        ])
    }

    private func configureFooterPanel() {
        footerPanel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.stylePanel(footerPanel, cornerRadius: 14)
        footerPanel.backgroundColor = GameStyle.panelBlueDark.withAlphaComponent(0.88)

        planeHintLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleSubtitleLabel(planeHintLabel, size: 14)
        planeHintLabel.textAlignment = .center
        planeHintLabel.numberOfLines = 2
        planeHintLabel.lineBreakMode = .byWordWrapping

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.applyMissionLaunchButton(actionButton, title: "Equip", style: .active)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        footerPanel.addSubview(planeHintLabel)
        footerPanel.addSubview(actionButton)

        NSLayoutConstraint.activate([
            planeHintLabel.topAnchor.constraint(equalTo: footerPanel.topAnchor, constant: 14),
            planeHintLabel.leadingAnchor.constraint(equalTo: footerPanel.leadingAnchor, constant: 16),
            planeHintLabel.trailingAnchor.constraint(equalTo: footerPanel.trailingAnchor, constant: -16),

            actionButton.topAnchor.constraint(equalTo: planeHintLabel.bottomAnchor, constant: 16),
            actionButton.leadingAnchor.constraint(equalTo: footerPanel.leadingAnchor, constant: 16),
            actionButton.trailingAnchor.constraint(equalTo: footerPanel.trailingAnchor, constant: -16),
            actionButton.heightAnchor.constraint(equalToConstant: GameStyle.missionLaunchButtonHeight),
            actionButton.bottomAnchor.constraint(equalTo: footerPanel.bottomAnchor, constant: -14)
        ])
    }

    private func configurePagerBar() {
        pagerBar.onPrevious = { [weak self] in
            self?.stepFocusedPlane(by: -1)
        }
        pagerBar.onNext = { [weak self] in
            self?.stepFocusedPlane(by: 1)
        }
    }

    private func configureCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCarouselLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.clipsToBounds = false
        collectionView.register(ShopPlaneCell.self, forCellWithReuseIdentifier: ShopPlaneCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.setContentHuggingPriority(.defaultLow, for: .vertical)
        collectionView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    private func setupContentStack() {
        topBar.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        topBar.addSubview(backButton)
        topBar.addSubview(creditsBadge)

        NSLayoutConstraint.activate([
            topBar.heightAnchor.constraint(equalToConstant: 40),

            backButton.topAnchor.constraint(equalTo: topBar.topAnchor),
            backButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor),
            backButton.bottomAnchor.constraint(equalTo: topBar.bottomAnchor),

            creditsBadge.topAnchor.constraint(equalTo: topBar.topAnchor),
            creditsBadge.trailingAnchor.constraint(equalTo: topBar.trailingAnchor),
            creditsBadge.bottomAnchor.constraint(equalTo: topBar.bottomAnchor),
            creditsBadge.leadingAnchor.constraint(
                greaterThanOrEqualTo: backButton.trailingAnchor,
                constant: 8
            ),
            creditsBadge.widthAnchor.constraint(
                lessThanOrEqualTo: topBar.widthAnchor,
                multiplier: 0.42
            )
        ])

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.distribution = .fill
        contentStack.spacing = LayoutMetrics.stackSpacing
        contentStack.addArrangedSubview(topBar)
        contentStack.addArrangedSubview(headerPanel)
        contentStack.addArrangedSubview(collectionView)
        contentStack.addArrangedSubview(pagerBar)
        contentStack.addArrangedSubview(footerPanel)

        view.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: LayoutMetrics.topInset),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: LayoutMetrics.horizontalInset),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -LayoutMetrics.horizontalInset),
            contentStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -LayoutMetrics.bottomInset)
        ])
    }

    private func makeCarouselLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let cardHeight = min(358, environment.container.effectiveContentSize.height * 0.86)

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(cardHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(CarouselMetrics.cardWidthFraction),
                heightDimension: .absolute(cardHeight)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .groupPagingCentered
            section.interGroupSpacing = CarouselMetrics.interGroupSpacing
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 12,
                leading: CarouselMetrics.horizontalInset,
                bottom: 12,
                trailing: CarouselMetrics.horizontalInset
            )
            section.visibleItemsInvalidationHandler = { [weak self] visibleItems, scrollOffset, environment in
                guard let self else { return }

                let containerWidth = environment.container.effectiveContentSize.width
                self.carouselScrollOffset = scrollOffset
                self.carouselContainerWidth = containerWidth

                for item in visibleItems where item.representedElementCategory == .cell {
                    self.applyCarouselMetrics(
                        to: item,
                        scrollOffset: scrollOffset,
                        containerWidth: containerWidth
                    )
                }

                if let planeID = self.focusedPlaneID(
                    in: visibleItems,
                    scrollOffset: scrollOffset,
                    containerWidth: containerWidth
                ) {
                    self.reportFocusedPlane(planeID)
                }
            }
            return section
        }
    }

    private func updateCreditsBadge() {
        creditsBadge.update(balance: PlayerWallet.balance)
    }

    private func updateFleetProgress() {
        let owned = PlayerPlaneStore.ownedCount
        let total = ShopPlaneCatalog.totalPlanes
        progressLabel.text = "FLEET UNLOCKED  \(owned) / \(total)"

        view.layoutIfNeeded()
        let maxWidth = max(0, progressTrack.bounds.width - 2)
        let fraction = CGFloat(owned) / CGFloat(total)
        progressFillWidth?.constant = maxWidth * fraction
    }

    private func scrollToPlane(_ planeID: Int, animated: Bool) {
        let index = max(0, min(planes.count - 1, planeID - 1))
        collectionView.scrollToItem(
            at: IndexPath(item: index, section: 0),
            at: .centeredHorizontally,
            animated: animated
        )
    }

    private func planeActionHint(
        isOwned: Bool,
        isEquipped: Bool,
        levelsMet: Bool,
        canAfford: Bool
    ) -> String {
        if isEquipped {
            return "Currently equipped for missions"
        }
        if isOwned {
            return "Ready to equip for your next mission"
        }
        if !levelsMet {
            return "Complete more sectors to unlock purchase"
        }
        if !canAfford {
            return "Earn more hangar credits from missions"
        }
        return "Purchase and equip this aircraft"
    }

    private func reportFocusedPlane(_ planeID: Int) {
        if let target = pagerNavigationTarget {
            guard planeID == target else { return }
            clearPagerNavigationLock()
            return
        }

        guard planeID != focusedPlaneID else { return }
        updateFocusedPlane(planeID)
    }

    private func beginPagerNavigation(to planeID: Int) {
        pagerNavigationTarget = planeID
        schedulePagerNavigationUnlock()

        scrollToPlane(planeID, animated: true)
        updateFocusedPlane(planeID)
        applyCarouselTransforms()
    }

    private func schedulePagerNavigationUnlock() {
        pagerNavigationUnlockWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.pagerNavigationTarget = nil
        }
        pagerNavigationUnlockWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    private func clearPagerNavigationLock() {
        pagerNavigationTarget = nil
        pagerNavigationUnlockWorkItem?.cancel()
        pagerNavigationUnlockWorkItem = nil
    }

    private func updateFocusedPlane(_ planeID: Int? = nil) {
        if let planeID {
            focusedPlaneID = planeID
        } else {
            focusedPlaneID = planeAtCarouselCenter()
        }

        guard let plane = ShopPlaneCatalog.plane(for: focusedPlaneID) else { return }

        let isOwned = PlayerPlaneStore.isOwned(plane.id)
        let isEquipped = PlayerPlaneStore.isEquipped(plane.id)
        let levelsMet = plane.isLevelRequirementMet()
        let canAfford = plane.canAfford()

        planeHintLabel.text = planeActionHint(
            isOwned: isOwned,
            isEquipped: isEquipped,
            levelsMet: levelsMet,
            canAfford: canAfford
        )

        if isEquipped {
            GameStyle.applyMissionLaunchButton(actionButton, title: "Equipped", style: .locked)
            actionButton.isEnabled = false
            actionButton.alpha = 0.45
        } else if isOwned {
            GameStyle.applyMissionLaunchButton(actionButton, title: "Equip Aircraft", style: .active)
            actionButton.isEnabled = true
            actionButton.alpha = 1
        } else if !levelsMet {
            GameStyle.applyMissionLaunchButton(actionButton, title: "Locked", style: .locked)
            actionButton.isEnabled = false
            actionButton.alpha = 0.45
        } else if !canAfford {
            GameStyle.applyMissionLaunchButton(actionButton, title: "Insufficient Credits", style: .locked)
            actionButton.isEnabled = false
            actionButton.alpha = 0.45
        } else {
            GameStyle.applyMissionLaunchButton(
                actionButton,
                title: "Buy · \(plane.creditCost.formatted())",
                style: .active
            )
            actionButton.isEnabled = true
            actionButton.alpha = 1
        }

        pagerBar.update(level: focusedPlaneID, total: planes.count)
    }

    private func focusedPlaneID(
        in visibleItems: [NSCollectionLayoutVisibleItem],
        scrollOffset: CGPoint,
        containerWidth: CGFloat
    ) -> Int? {
        let centerX = scrollOffset.x + containerWidth / 2
        guard let centeredItem = visibleItems
            .filter({ $0.representedElementCategory == .cell })
            .min(by: { lhs, rhs in
                abs(lhs.frame.midX - centerX) < abs(rhs.frame.midX - centerX)
            }) else {
            return nil
        }

        let index = centeredItem.indexPath.item
        guard planes.indices.contains(index) else { return nil }
        return planes[index].id
    }

    private func stepFocusedPlane(by delta: Int) {
        let nextID = max(1, min(planes.count, focusedPlaneID + delta))
        guard nextID != focusedPlaneID else { return }
        beginPagerNavigation(to: nextID)
    }

    private func planeAtCarouselCenter() -> Int {
        let containerWidth = carouselContainerWidth > 0
            ? carouselContainerWidth
            : collectionView.bounds.width
        let centerX = carouselScrollOffset.x + containerWidth / 2

        let visible = collectionView.indexPathsForVisibleItems
        guard let closestPath = visible.min(by: { lhs, rhs in
            let lhsCenter = collectionView.layoutAttributesForItem(at: lhs)?.frame.midX ?? 0
            let rhsCenter = collectionView.layoutAttributesForItem(at: rhs)?.frame.midX ?? 0
            return abs(lhsCenter - centerX) < abs(rhsCenter - centerX)
        }) else {
            return focusedPlaneID
        }
        return planes[closestPath.item].id
    }

    private func applyCarouselTransforms() {
        let scrollOffset = collectionView.contentOffset
        let containerWidth = collectionView.bounds.width
        guard containerWidth > 0 else { return }

        for cell in collectionView.visibleCells {
            guard let planeCell = cell as? ShopPlaneCell else { continue }
            let metrics = carouselMetrics(
                forMidX: cell.center.x,
                scrollOffset: scrollOffset,
                containerWidth: containerWidth
            )
            planeCell.applyCarouselPresentation(scale: metrics.scale, alpha: metrics.alpha)
        }
    }

    private func applyCarouselMetrics(
        to item: NSCollectionLayoutVisibleItem,
        scrollOffset: CGPoint,
        containerWidth: CGFloat
    ) {
        let metrics = carouselMetrics(
            forMidX: item.frame.midX,
            scrollOffset: scrollOffset,
            containerWidth: containerWidth
        )
        item.transform = CGAffineTransform(scaleX: metrics.scale, y: metrics.scale)
        item.alpha = metrics.alpha
        item.zIndex = metrics.zIndex
    }

    private func carouselMetrics(
        forMidX midX: CGFloat,
        scrollOffset: CGPoint,
        containerWidth: CGFloat
    ) -> (scale: CGFloat, alpha: CGFloat, zIndex: Int) {
        let centerX = scrollOffset.x + containerWidth / 2
        let maxDistance = containerWidth * CarouselMetrics.distanceFactor
        let progress = min(1, abs(midX - centerX) / maxDistance)
        let scale = 1 - progress * CarouselMetrics.maxScaleReduction
        let alpha = 1 - progress * CarouselMetrics.maxAlphaReduction
        let zIndex = Int((1 - progress) * 100)
        return (scale, alpha, zIndex)
    }

    private func showStarfieldIfNeeded() {
        guard starfieldView == nil else { return }

        let starfield = StarfieldBackgroundView(style: .hangarShop)
        starfield.translatesAutoresizingMaskIntoConstraints = false
        starfield.alpha = 0
        view.insertSubview(starfield, at: 0)
        NSLayoutConstraint.activate([
            starfield.topAnchor.constraint(equalTo: view.topAnchor),
            starfield.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            starfield.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            starfield.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        starfieldView = starfield
        starfield.startAnimating()

        UIView.animate(withDuration: 0.35) {
            starfield.alpha = 1
        }
    }

    @objc private func backTapped() {
        dismiss(animated: true)
    }

    @objc private func actionTapped() {
        guard let plane = ShopPlaneCatalog.plane(for: focusedPlaneID) else { return }

        if PlayerPlaneStore.isOwned(plane.id) {
            guard !PlayerPlaneStore.isEquipped(plane.id) else { return }
            PlayerPlaneStore.equip(planeID: plane.id)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            refreshAfterTransaction()
            return
        }

        switch PlayerPlaneStore.purchase(plane) {
        case .success:
            PlayerPlaneStore.equip(planeID: plane.id)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            refreshAfterTransaction()
        case .alreadyOwned:
            refreshAfterTransaction()
        case .levelsNotMet:
            presentPurchaseAlert(
                title: "Sectors Required",
                message: "Complete \(plane.requiredCompletedLevels) sectors before purchasing \(plane.name)."
            )
        case .insufficientCredits:
            presentPurchaseAlert(
                title: "Not Enough Credits",
                message: "You need \(plane.creditCost.formatted()) hangar credits. Finish missions to earn more."
            )
        }
    }

    private func refreshAfterTransaction() {
        updateFleetProgress()
        updateCreditsBadge()
        collectionView.reloadData()
        updateFocusedPlane()
        applyCarouselTransforms()
    }

    private func presentPurchaseAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension HangarShopViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        planes.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ShopPlaneCell.reuseID,
            for: indexPath
        ) as? ShopPlaneCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: planes[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        beginPagerNavigation(to: planes[indexPath.item].id)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        clearPagerNavigationLock()
        updateFocusedPlane()
        applyCarouselTransforms()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        clearPagerNavigationLock()
        updateFocusedPlane()
        applyCarouselTransforms()
    }
}
