import UIKit

final class LevelSelectViewController: UIViewController {

    private var starfieldView: StarfieldBackgroundView?
    private let headerPanel = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let progressLabel = UILabel()
    private let progressTrack = UIView()
    private let progressFill = UIView()
    private var progressFillWidth: NSLayoutConstraint?
    private let backButton = UIButton(type: .system)
    private var collectionView: UICollectionView!

    private let levels = Array(1...LevelConfigFactory.totalLevels)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = GameStyle.cockpitBlack
        setupHeader()
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
        subtitleLabel.text = "Clear sectors to unlock deep space routes"
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

    private func setupBackButton() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.left")
        config.title = " Hangar"
        config.imagePadding = 4
        config.baseForegroundColor = GameStyle.textPrimary
        backButton.configuration = config
        backButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            backButton.centerYAnchor.constraint(equalTo: headerPanel.topAnchor, constant: 22)
        ])
    }

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        collectionView.register(LevelMissionCell.self, forCellWithReuseIdentifier: LevelMissionCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: headerPanel.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let columns: CGFloat = 3
            let spacing: CGFloat = 14
            let inset: CGFloat = 18
            let totalWidth = environment.container.effectiveContentSize.width
            let cellWidth = floor((totalWidth - inset * 2 - spacing * (columns - 1)) / columns)
            let cellHeight: CGFloat = 132

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(cellWidth),
                heightDimension: .absolute(cellHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(cellHeight)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .fixed(spacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset)
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
        guard LevelProgressStore.isUnlocked(level) else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        launchLevel(level)
    }
}
