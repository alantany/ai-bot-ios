import Foundation
import AVFoundation
import MicrosoftCognitiveServicesSpeech

@MainActor
final class SpeechViewModel: NSObject, ViewModelProtocol {
    // MARK: - State
    struct State {
        var isPlaying = false
        var isTransitioning = false
        var autoPlayEnabled = true  // 默认开启自动播放
    }
    
    // MARK: - Singleton
    static let shared = SpeechViewModel()
    
    // MARK: - Properties
    @Published private(set) var state = State()
    @Published var isLoading = false
    @Published var error: Error?
    
    // Azure Speech 配置
    private let speechConfig: SPXSpeechConfiguration?
    private var synthesizer: SPXSpeechSynthesizer?
    private var currentTask: Task<Void, Never>?
    
    // MARK: - Public Properties
    var playbackFinished: AsyncStream<Void> {
        AsyncStream { continuation in
            playbackFinishedContinuation = continuation
        }
    }
    
    private var playbackFinishedContinuation: AsyncStream<Void>.Continuation?
    private var synthesisCompleted = false
    
    // MARK: - Initialization
    private override init() {
        speechConfig = nil
        super.init()
        
        // 初始化 Azure Speech 配置
        do {
            let config = try SPXSpeechConfiguration(subscription: "5bdwA3BWQM17ZNYirv7n4QRfKAfLXOzFIbqqzagcojsYbmDNUNXhJQQJ99ALACYeBjFXJ3w3AAAYACOGhlDt", region: "eastus")
            // 设置语音
            config.speechSynthesisVoiceName = "zh-CN-XiaoxiaoNeural"
            
            // 初始化合成器
            synthesizer = try SPXSpeechSynthesizer(config)
            
            // 设置事件处理
            synthesizer?.addSynthesisCompletedEventHandler { [weak self] synthesizer, eventArgs in
                print("语音合成完成")
                Task { @MainActor in
                    self?.synthesisCompleted = true
                    self?.state.isPlaying = false
                    self?.isLoading = false
                    self?.playbackFinishedContinuation?.yield()
                }
            }
            
            synthesizer?.addSynthesisCanceledEventHandler { [weak self] synthesizer, eventArgs in
                print("语音合成取消：\(eventArgs)")
                Task { @MainActor in
                    self?.synthesisCompleted = true
                    self?.state.isPlaying = false
                    self?.isLoading = false
                }
            }
            
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Public Methods
    func setAutoPlay(enabled: Bool) {
        state.autoPlayEnabled = enabled
    }
    
    func updateText(_ text: String) async {
        guard !state.isTransitioning else { return }
        state.isTransitioning = true
        
        defer {
            state.isTransitioning = false
        }
        
        // 先停止当前播放
        await stop()
        
        // 如果自动播放开启，立即开始播放
        if state.autoPlayEnabled {
            await play(text)
        }
    }
    
    func play(_ text: String) async {
        guard !state.isTransitioning else { return }
        
        state.isTransitioning = true
        defer {
            state.isTransitioning = false
        }
        
        // 确保之前的播放已经停止
        await stop()
        
        print("========== 开始播放新闻 ==========")
        print("文本长度：\(text.count)")
        print("文本内容：\(text)")
        print("================================")
        
        // 使用 Azure 语音服务播放
        do {
            guard let synthesizer = synthesizer else {
                throw NSError(domain: "SpeechViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "语音合成器未初始化"])
            }
            
            state.isPlaying = true
            isLoading = true
            synthesisCompleted = false
            
            currentTask = Task {
                do {
                    let result = try synthesizer.speakText(text)
                    print("调用speakText返回：\(result)")
                    
                    // 等待合成完成
                    while !synthesisCompleted && !Task.isCancelled {
                        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    }
                    
                    if Task.isCancelled {
                        print("任务被取消")
                        return
                    }
                    
                } catch {
                    if !Task.isCancelled {
                        await MainActor.run {
                            self.error = error
                            state.isPlaying = false
                            isLoading = false
                            print("播放出错：\(error)")
                        }
                    }
                }
            }
            
            await currentTask?.value
            
        } catch {
            self.error = error
            state.isPlaying = false
            isLoading = false
            print("初始化出错：\(error)")
        }
    }
    
    func stop() async {
        guard !state.isTransitioning else { return }
        
        state.isTransitioning = true
        defer {
            state.isTransitioning = false
        }
        
        // 取消当前任务
        currentTask?.cancel()
        currentTask = nil
        
        state.isPlaying = false
        synthesisCompleted = true
        try? synthesizer?.stopSpeaking()
        try? await Task.sleep(nanoseconds: 200_000_000) // 等待0.2秒确保停止完成
    }
}

// MARK: - Preview Helper
extension SpeechViewModel {
    static var preview: SpeechViewModel {
        shared
    }
}