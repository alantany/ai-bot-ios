import Foundation
import AVFoundation

@MainActor
final class SpeechViewModel: NSObject, ViewModelProtocol {
    // MARK: - State
    struct State {
        var isPlaying = false
    }
    
    // MARK: - Singleton
    static let shared = SpeechViewModel()
    
    // MARK: - Properties
    @Published private(set) var state = State()
    @Published var isLoading = false
    @Published var error: Error?
    
    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    private var playbackFinishedContinuation: AsyncStream<Void>.Continuation?
    
    // MARK: - Public Properties
    var playbackFinished: AsyncStream<Void> {
        AsyncStream { continuation in
            playbackFinishedContinuation = continuation
        }
    }
    
    // MARK: - Initialization
    private override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    // MARK: - Private Methods
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Public Methods
    func updateText(_ text: String) async {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        currentUtterance = utterance
    }
    
    func play() async {
        guard let utterance = currentUtterance else { return }
        state.isPlaying = true
        synthesizer.speak(utterance)
    }
    
    func pause() async {
        state.isPlaying = false
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
        }
    }
    
    func stop() async {
        state.isPlaying = false
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            state.isPlaying = false
            playbackFinishedContinuation?.yield()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            state.isPlaying = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            state.isPlaying = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            state.isPlaying = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            state.isPlaying = true
        }
    }
}

// MARK: - Preview Helper
extension SpeechViewModel {
    static var preview: SpeechViewModel {
        shared
    }
} 