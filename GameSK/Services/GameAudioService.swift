import AVFoundation
import AudioToolbox

final class GameAudioService {

    static let shared = GameAudioService()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var shootBuffer: AVAudioPCMBuffer?
    private var isPrepared = false

    private init() {}

    func prepare() {
        guard !isPrepared else { return }
        isPrepared = true

        configureAudioSession()
        buildShootBuffer()

        guard let shootBuffer else { return }

        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: shootBuffer.format)
        engine.mainMixerNode.outputVolume = 1
        try? engine.start()
    }

    func playShoot() {
        guard GameSettingsStore.isSoundEnabled else { return }

        if shootBuffer == nil {
            prepare()
        }

        guard let shootBuffer else {
            AudioServicesPlaySystemSound(1104)
            return
        }

        if !engine.isRunning {
            try? engine.start()
        }

        playerNode.stop()
        playerNode.scheduleBuffer(shootBuffer, at: nil, options: [], completionHandler: nil)
        playerNode.play()
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func buildShootBuffer() {
        let sampleRate = 44_100.0
        let duration = 0.11
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else {
            return
        }

        buffer.frameLength = frameCount

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let envelope = exp(-time * 28)
            let tone = sin(2 * .pi * 880 * time) * 0.42
            let noise = Double.random(in: -0.45...0.45) * 0.35
            samples[frame] = Float(envelope * (tone + noise))
        }

        shootBuffer = buffer
    }
}
