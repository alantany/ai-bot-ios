import Foundation
import AVFoundation
import Combine

@MainActor
final class SpeechViewModel: ViewModelProtocol {
    // MARK: - State
    struct State {
        var text: String
        var isPlaying: Bool = false
        var progress: Double = 0
        var rate: Float = 1.0
        var volume: Float = 1.0
        var pitch: Float = 1.0
    }
    
    // MARK: - Properties
    @Published private(set) var state: State
    @Published var isLoading = false
    @Published var error: Error?
    
    private let networkService: NetworkService
    private let storageService: StorageService
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(text: String,
         networkService: NetworkService = .shared,
         storageService: StorageService = .shared) {
        self.state = State(text: text)
        self.networkService = networkService
        self.storageService = storageService
        setupAudioSession()
    }
    
    deinit {
        // 在deinit中只进行非actor隔离的清理
        cleanupNonIsolated()
        
        // 对于需要在主线程执行的清理，使用Task
        Task { @MainActor in
            await cleanupIsolated()
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Public Methods
    func play() async {
        guard !state.isPlaying else { return }
        
        // 检查缓存
        let cacheKey = "speech_\(state.text.hashValue)"
        
        do {
            var audioData: Data
            
            // 尝试从缓存加载
            if let cachedData = try? await storageService.getCachedData(forKey: cacheKey) {
                audioData = cachedData
            } else {
                // 从服务器获取
                startLoading()
                let endpoint = Endpoint.textToSpeech(text: state.text)
                audioData = try await networkService.requestData(endpoint)
                
                // 缓存音频数据
                try await storageService.cacheData(audioData, forKey: cacheKey)
                stopLoading()
            }
            
            // 创建音频播放器
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.enableRate = true
            audioPlayer?.rate = state.rate
            audioPlayer?.volume = state.volume
            
            // 开始播放
            guard audioPlayer?.prepareToPlay() == true,
                  audioPlayer?.play() == true else {
                throw SpeechError.playbackFailed
            }
            
            state.isPlaying = true
            startProgressTracking()
            
        } catch {
            handleError(error)
            cleanup()
        }
    }
    
    func pause() {
        guard state.isPlaying else { return }
        audioPlayer?.pause()
        state.isPlaying = false
        stopProgressTracking()
    }
    
    func resume() {
        guard !state.isPlaying,
              audioPlayer?.play() == true else { return }
        state.isPlaying = true
        startProgressTracking()
    }
    
    func stop() {
        guard state.isPlaying else { return }
        cleanup()
    }
    
    func seek(to progress: Double) {
        guard let player = audioPlayer else { return }
        let time = TimeInterval(progress * player.duration)
        player.currentTime = time
        state.progress = progress
    }
    
    func setRate(_ rate: Float) {
        state.rate = rate
        audioPlayer?.rate = rate
    }
    
    func setVolume(_ volume: Float) {
        state.volume = volume
        audioPlayer?.volume = volume
    }
    
    // MARK: - Private Methods
    private func startProgressTracking() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func stopProgressTracking() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func updateProgress() {
        guard let player = audioPlayer else { return }
        state.progress = player.currentTime / player.duration
        
        if player.currentTime >= player.duration {
            cleanup()
        }
    }
    
    private func cleanup() {
        cleanupNonIsolated()
        cleanupIsolated()
    }
    
    // 非actor隔离的清理工作
    private nonisolated func cleanupNonIsolated() {
        progressTimer?.invalidate()
        progressTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // actor隔离的清理工作
    private func cleanupIsolated() {
        state.isPlaying = false
        state.progress = 0
    }
}

// MARK: - Speech Errors
enum SpeechError: LocalizedError {
    case playbackFailed
    
    var errorDescription: String? {
        switch self {
        case .playbackFailed:
            return "音频播放失败"
        }
    }
}

// MARK: - Preview Helper
extension SpeechViewModel {
    static var preview: SpeechViewModel {
        SpeechViewModel(text: "这是一段用于预览的测试文本。")
    }
} 