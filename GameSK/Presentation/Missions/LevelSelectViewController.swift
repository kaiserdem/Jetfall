import UIKit

final class LevelSelectViewController: UIViewController {

    private enum CarouselMetrics {
        static let cardWidthFraction: CGFloat = 0.72
        static let interGroupSpacing: CGFloat = 14
        static let horizontalInset: CGFloat = 12
        static let maxAlphaReduction: CGFloat = 0.26
        static let maxScaleReduction: CGFloat = 0.09
        static let distanceFactor: CGFloat = 0.48
    }

    private var starfieldView: StarfieldBackgroundView?
    private let headerPanel = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let progressLabel = UILabel()
    private let progressTrack = UIView()
    private let progressFill = UIView()
    private var progressFillWidth: NSLayoutConstraint?
    private let backButton = AviatorNavButton(style: .labeled(symbol: "chevron.left", title: "Hangar"))
    private var collectionView: UICollectionView!

    private let footerPanel = UIView()
    private let missionCounterLabel = UILabel()
    private let missionHintLabel = UILabel()
    private let launchButton = UIButton(type: .system)

    private let levels = Array(1...LevelConfigFactory.totalLevels)
    private var focusedLevel = 1
    private var didPerformInitialScroll = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GameStyle.cockpitBlack
        setupHeader()
        setupFooter()
        setupCollectionView()
        setupBackButton()
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

    private func setupHeader() {
        headerPanel.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.stylePanel(headerPanel, cornerRadius: 14)
        headerPanel.backgroundColor = GameStyle.panelBlueDark.withAlphaComponent(0.88)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "MISSIONS"
        titleLabel.font = .systemFont(ofSize: 28, weight: .heavy)
        titleLabel.textColor = GameStyle.textPrimary
        titleLabel.textAlignment = .center

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Swipe to browse sectors"
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

        view.addSubview(headerPanel)
        headerPanel.addSubview(titleLabel)
        headerPanel.addSubview(subtitleLabel)
        headerPanel.addSubview(progressLabel)
        headerPanel.addSubview(progressTrack)
        progressTrack.addSubview(progressFill)

        progressFillWidth = progressFill.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            headerPanel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

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

    private func setupFooter() {
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

        launchButton.translatesAutoresizingMaskIntoConstraints = false
        GameStyle.applyPrimaryButton(launchButton, title: "Launch Mission")
        launchButton.addTarget(self, action: #selector(launchFocusedLevel), for: .touchUpInside)

        view.addSubview(footerPanel)
        footerPanel.addSubview(missionCounterLabel)
        footerPanel.addSubview(missionHintLabel)
        footerPanel.addSubview(launchButton)

        NSLayoutConstraint.activate([
            footerPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            footerPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            footerPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            missionCounterLabel.topAnchor.constraint(equalTo: footerPanel.topAnchor, constant: 14),
            missionCounterLabel.leadingAnchor.constraint(equalTo: footerPanel.leadingAnchor, constant: 16),
            missionCounterLabel.trailingAnchor.constraint(equalTo: footerPanel.trailingAnchor, constant: -16),

            missionHintLabel.topAnchor.constraint(equalTo: missionCounterLabel.bottomAnchor, constant: 4),
            missionHintLabel.leadingAnchor.constraint(equalTo: missionCounterLabel.leadingAnchor),
            missionHintLabel.trailingAnchor.constraint(equalTo: missionCounterLabel.trailingAnchor),

            launchButton.topAnchor.constraint(equalTo: missionHintLabel.bottomAnchor, constant: 14),
            launchButton.leadingAnchor.constraint(equalTo: footerPanel.leadingAnchor, constant: 16),
            launchButton.trailingAnchor.constraint(equalTo: footerPanel.trailingAnchor, constant: -16),
            launchButton.bottomAnchor.constraint(equalTo: footerPanel.bottomAnchor, constant: -14)
        ])
    }

    private func setupBackButton() {
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: headerPanel.topAnchor, constant: 22)
        ])
        view.bringSubviewToFront(backButton)
    }

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCarouselLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.clipsToBounds = false
        collectionView.register(LevelMissionCell.self, forCellWithReuseIdentifier: LevelMissionCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: headerPanel.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: footerPanel.topAnchor, constant: -12)
        ])
    }

    private func makeCarouselLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let cardHeight = min(260, environment.container.effectiveContentSize.height * 0.72)

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
                let containerWidth = environment.container.effectiveContentSize.width
                for item in visibleItems where item.representedElementCategory == .cell {
                    self?.applyCarouselMetrics(
                        to: item,
                        scrollOffset: scrollOffset,
                        containerWidth: containerWidth
                    )
                }
            }
            return section
        }
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

    private func updateFocusedLevel(_ level: Int? = nil) {
        if let level {
            focusedLevel = level
        } else {
            focusedLevel = levelAtCarouselCenter()
        }

        missionCounterLabel.text = "MISSION \(String(format: "%02d", focusedLevel)) / \(levels.count)"

        let isUnlocked = LevelProgressStore.isUnlocked(focusedLevel)
        launchButton.isEnabled = isUnlocked
        launchButton.alpha = isUnlocked ? 1 : 0.45

        if !isUnlocked {
            missionHintLabel.text = "Complete previous missions to unlock"
        } else if focusedLevel == LevelProgressStore.highestUnlockedLevel {
            missionHintLabel.text = "Ready for launch"
        } else if focusedLevel < LevelProgressStore.highestUnlockedLevel {
            missionHintLabel.text = "Sector cleared — replay anytime"
        } else {
            missionHintLabel.text = "Select a mission"
        }
    }

    private func levelAtCarouselCenter() -> Int {
        let center = CGPoint(
            x: collectionView.contentOffset.x + collectionView.bounds.width / 2,
            y: collectionView.bounds.height / 2
        )
        if let indexPath = collectionView.indexPathForItem(at: center) {
            return levels[indexPath.item]
        }

        let visible = collectionView.indexPathsForVisibleItems.sorted { $0.item < $1.item }
        guard let closestPath = visible.min(by: { lhs, rhs in
            let lhsCenter = collectionView.layoutAttributesForItem(at: lhs)?.center.x ?? 0
            let rhsCenter = collectionView.layoutAttributesForItem(at: rhs)?.center.x ?? 0
            let centerX = collectionView.contentOffset.x + collectionView.bounds.width / 2
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

        let starfield = StarfieldBackgroundView()
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
            asteroids: config.asteroidsToDestroy,
            fuelSeconds: Int(config.fuelDuration)
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let level = levels[indexPath.item]
        scrollToLevel(level, animated: true)
        updateFocusedLevel(level)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        applyCarouselTransforms()
        updateFocusedLevel()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateFocusedLevel()
        applyCarouselTransforms()
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        updateFocusedLevel()
        applyCarouselTransforms()
    }
}
