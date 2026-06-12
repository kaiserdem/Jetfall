import UIKit

final class GameHUDView: UIView {

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 24)
        label.textColor = .white
        label.text = "Рахунок: 0"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let gameOverLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 36)
        label.textColor = .white
        label.text = "Гра закінчена"
        label.textAlignment = .center
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let restartLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.text = "Торкніться, щоб грати знову"
        label.textAlignment = .center
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var onRestartTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        addSubview(scoreLabel)
        addSubview(gameOverLabel)
        addSubview(restartLabel)

        NSLayoutConstraint.activate([
            scoreLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
            scoreLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            gameOverLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            gameOverLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 20),
            restartLabel.topAnchor.constraint(equalTo: gameOverLabel.bottomAnchor, constant: 12),
            restartLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateScore(_ score: Int) {
        scoreLabel.text = "Рахунок: \(score)"
    }

    func showGameOver(_ show: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.gameOverLabel.alpha = show ? 1 : 0
            self.restartLabel.alpha = show ? 1 : 0
        }
    }

    @objc private func handleTap() {
        guard gameOverLabel.alpha > 0.5 else { return }
        onRestartTapped?()
    }
}
