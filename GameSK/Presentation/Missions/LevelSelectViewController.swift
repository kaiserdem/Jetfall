import UIKit

final class LevelSelectViewController: UIViewController {

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
    private let backButton = AviatorNavButton(style: .labeled(title: "Menu"))
    private let creditsBadge = HangarCreditsBadge()
    private var collectionView: UICollectionView!

    private let pagerBar = MissionPagerBar()
    private let footerPanel = UIView()
    private let missionCounterLabel = UILabel()
    private let missionHintLabel = UILabel()
    private let launchButton = UIButton(type: .system)

    private let levels = Array(1...LevelConfigFactory.totalLevels)
    private var focusedLevel = 1
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
        updateProgress()
        updateCreditsBadge()
        collectionView.reloadData()
        didPerformInitialScroll = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didPerformInitialScroll, collectionView.bounds.width > 0 else { return }
        didPerformInitialScroll = true
        let target = LevelProgressStore.highestUnlockedLevel
        scrollToLevel(target, animated: false)
        updateFocusedLevel(target)
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
        titleLabel.text = "MISSIONS"
        titleLabel.font = .systemFont(ofSize: 28, weight: .heavy)
        titleLabel.textColor = GameStyle.textPrimary
        titleLabel.textAlignment = .center

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Swipe or use sector controls below"
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

        missionCounterLabel.translatesAutoresizingMaskIntoConstraints = false
        missionCounterLabel.font = .monospacedDigitSystemFont(ofSize: 22, weight: .heavy)
        missionCounterLabel.textColor = GameStyle.textPrimary
        missionCounterLabel.textAlignment = .center

        missionHintLabel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.styleSubtitleLabel(missionHintLabel, size: 14)
        missionHintLabel.textAlignment = .center
        missionHintLabel.numberOfLines = 2
        missionHintLabel.lineBreakMode = .byWordWrapping
        missionHintLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        missionHintLabel.setContentHuggingPriority(.required, for: .vertical)

        launchButton.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.applyMissionLaunchButton(launchButton, title: "Launch Mission", style: .active)
        launchButton.addTarget(self, action: #selector(launchFocusedLevel), for: .touchUpInside)

        footerPanel.addSubview(missionCounterLabel)
        footerPanel.addSubview(missionHintLabel)
        footerPanel.addSubview(launchButton)

        NSLayoutConstraint.activate([
            missionCounterLabel.topAnchor.constraint(equalTo: footerPanel.topAnchor, constant: 14),
            missionCounterLabel.leadingAnchor.constraint(equalTo: footerPanel.leadingAnchor, constant: 16),
            missionCounterLabel.trailingAnchor.constraint(equalTo: footerPanel.trailingAnchor, constant: -16),

            missionHintLabel.topAnchor.constraint(equalTo: missionCounterLabel.bottomAnchor, constant: 8),
            missionHintLabel.leadingAnchor.constraint(equalTo: missionCounterLabel.leadingAnchor),
            missionHintLabel.trailingAnchor.constraint(equalTo: missionCounterLabel.trailingAnchor),

            launchButton.topAnchor.constraint(equalTo: missionHintLabel.bottomAnchor, constant: 16),
            launchButton.leadingAnchor.constraint(equalTo: footerPanel.leadingAnchor, constant: 16),
            launchButton.trailingAnchor.constraint(equalTo: footerPanel.trailingAnchor, constant: -16),
            launchButton.heightAnchor.constraint(equalToConstant: GameStyle.missionLaunchButtonHeight),
            launchButton.bottomAnchor.constraint(equalTo: footerPanel.bottomAnchor, constant: -14)
        ])
    }

    private func configurePagerBar() {
        pagerBar.onPrevious = { [weak self] in
            self?.stepFocusedLevel(by: -1)
        }
        pagerBar.onNext = { [weak self] in
            self?.stepFocusedLevel(by: 1)
        }
    }

    private func configureCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCarouselLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.clipsToBounds = false
        collectionView.register(LevelMissionCell.self, forCellWithReuseIdentifier: LevelMissionCell.reuseID)
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
            let cardHeight = min(300, environment.container.effectiveContentSize.height * 0.82)

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

                if let level = self.focusedLevel(
                    in: visibleItems,
                    scrollOffset: scrollOffset,
                    containerWidth: containerWidth
                ) {
                    self.reportFocusedLevel(level)
                }
            }
            return section
        }
    }

    private func updateCreditsBadge() {
        creditsBadge.update(balance: PlayerWallet.balance)
    }

    private func updateProgress() {
        let unlocked = LevelProgressStore.highestUnlockedLevel
        let total = LevelConfigFactory.totalLevels
        progressLabel.text = "SECTORS UNLOCKED  \(unlocked) / \(total)"

        view.layoutIfNeeded()
        let maxWidth = max(0, progressTrack.bounds.width - 2)
        let fraction = CGFloat(unlocked) / CGFloat(total)
        progressFillWidth?.constant = maxWidth * fraction
    }

    private func scrollToLevel(_ level: Int, animated: Bool) {
        let index = max(0, min(levels.count - 1, level - 1))
        collectionView.scrollToItem(
            at: IndexPath(item: index, section: 0),
            at: .centeredHorizontally,
            animated: animated
        )
    }

    private func missionHint(stats: String, status: String) -> String {
        "\(stats)\n\(status)"
    }

    private func statusWithBestScore(_ status: String, bestScoreNote: String?) -> String {
        guard let bestScoreNote else { return status }
        return "\(status) · \(bestScoreNote)"
    }

    private func reportFocusedLevel(_ level: Int) {
        if let target = pagerNavigationTarget {
            guard level == target else { return }
            clearPagerNavigationLock()
            return
        }

        guard level != focusedLevel else { return }
        updateFocusedLevel(level)
    }

    private func beginPagerNavigation(to level: Int) {
        pagerNavigationTarget = level
        schedulePagerNavigationUnlock()

        scrollToLevel(level, animated: true)
        updateFocusedLevel(level)
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

    private func updateFocusedLevel(_ level: Int? = nil) {
        if let level {
            focusedLevel = level
        } else {
            focusedLevel = levelAtCarouselCenter()
        }

        let config = LevelConfigFactory.config(for: focusedLevel)
        let highest = LevelProgressStore.highestUnlockedLevel
        let isUnlocked = LevelProgressStore.isUnlocked(focusedLevel)
        let isCompleted = isUnlocked && focusedLevel < highest
        let isCurrent = isUnlocked && focusedLevel == highest
        let missionStats = "Targets: \(config.asteroidsToDestroy)"
        let bestScore = MissionScoreStore.bestScore(for: focusedLevel)
        let bestScoreNote = bestScore > 0 ? "Best score \(bestScore)" : nil

        missionCounterLabel.text = "MISSION"

        if !isUnlocked {
            missionHintLabel.text = missionHint(
                stats: missionStats,
                status: "Complete previous missions to unlock"
            )
            GameStyle.applyMissionLaunchButton(launchButton, title: "Locked", style: .locked)
            launchButton.isEnabled = false
            launchButton.alpha = 0.45
        } else if isCurrent {
            missionHintLabel.text = missionHint(
                stats: missionStats,
                status: statusWithBestScore("Ready for launch", bestScoreNote: bestScoreNote)
            )
            GameStyle.applyMissionLaunchButton(launchButton, title: "Launch Mission", style: .active)
            launchButton.isEnabled = true
            launchButton.alpha = 1
        } else if isCompleted {
            missionHintLabel.text = missionHint(
                stats: missionStats,
                status: statusWithBestScore("Sector cleared — replay anytime", bestScoreNote: bestScoreNote)
            )
            GameStyle.applyMissionLaunchButton(launchButton, title: "Replay Mission", style: .active)
            launchButton.isEnabled = true
            launchButton.alpha = 1
        } else {
            missionHintLabel.text = missionStats
            GameStyle.applyMissionLaunchButton(launchButton, title: "Launch Mission", style: .active)
            launchButton.isEnabled = true
            launchButton.alpha = 1
        }

        pagerBar.update(level: focusedLevel, total: levels.count)
    }

    private func focusedLevel(
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
        guard levels.indices.contains(index) else { return nil }
        return levels[index]
    }

    private func stepFocusedLevel(by delta: Int) {
        let nextLevel = max(1, min(levels.count, focusedLevel + delta))
        guard nextLevel != focusedLevel else { return }
        beginPagerNavigation(to: nextLevel)
    }

    private func levelAtCarouselCenter() -> Int {
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
            return focusedLevel
        }
        return levels[closestPath.item]
    }

    private func applyCarouselTransforms() {
        let scrollOffset = collectionView.contentOffset
        let containerWidth = collectionView.bounds.width
        guard containerWidth > 0 else { return }

        for cell in collectionView.visibleCells {
            guard let missionCell = cell as? LevelMissionCell else { continue }
            let metrics = carouselMetrics(
                forMidX: cell.center.x,
                scrollOffset: scrollOffset,
                containerWidth: containerWidth
            )
            missionCell.applyCarouselPresentation(scale: metrics.scale, alpha: metrics.alpha)
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

        let starfield = StarfieldBackgroundView(style: .missions)
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

    @objc private func launchFocusedLevel() {
        launchLevel(focusedLevel)
    }

    private func launchLevel(_ level: Int) {
        guard LevelProgressStore.isUnlocked(level) else { return }

        GameAssetLoader.shared.whenReady { [weak self] in
            guard let self,
                  let gameViewController = self.storyboard?.instantiateViewController(
                    withIdentifier: "GameViewController"
                  ) as? GameViewController else {
                return
            }

            gameViewController.startingLevel = level
            gameViewController.modalPresentationStyle = .fullScreen
            gameViewController.modalTransitionStyle = .crossDissolve
            self.present(gameViewController, animated: true)
        }
    }
}

extension LevelSelectViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        levels.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: LevelMissionCell.reuseID,
            for: indexPath
        ) as! LevelMissionCell
        let level = levels[indexPath.item]
        let config = LevelConfigFactory.config(for: level)
        cell.configure(
            level: level,
            isUnlocked: LevelProgressStore.isUnlocked(level),
            asteroids: config.asteroidsToDestroy
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let level = levels[indexPath.item]
        beginPagerNavigation(to: level)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        clearPagerNavigationLock()
        updateFocusedLevel()
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        clearPagerNavigationLock()
        updateFocusedLevel()
    }
}
