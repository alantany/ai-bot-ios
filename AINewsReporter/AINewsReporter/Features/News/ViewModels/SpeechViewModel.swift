import Foundation
import AVFoundation
import MicrosoftCognitiveServicesSpeech

@MainActor
final class SpeechViewModel: NSObject, ViewModelProtocol, ObservableObject {
    // MARK: - State
    struct State {
        var isTransitioning = false
        var autoPlayEnabled = true
        var lastPlayedIndex: Int?  // 添加最后播放位置的记录
    }
    
    // MARK: - Singleton
    static let shared = SpeechViewModel()
    
    // MARK: - Properties
    @Published private(set) var state = State()
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isPlaying = false
    
    // Azure Speech 配置
    private let speechConfig: SPXSpeechConfiguration?
    private var synthesizer: SPXSpeechSynthesizer?
    private var currentTask: Task<Void, Never>?
    private var shouldStopPlaying = false
    
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
                    self?.isLoading = false
                    // 只有在手动停止时才设置 isPlaying = false
                    if self?.shouldStopPlaying == true {
                        self?.isPlaying = false
                    }
                    self?.playbackFinishedContinuation?.yield()
                }
            }
            
            synthesizer?.addSynthesisCanceledEventHandler { [weak self] synthesizer, eventArgs in
                print("语音合成取消：\(String(describing: eventArgs))")
                Task { @MainActor in
                    self?.synthesisCompleted = true
                    self?.isPlaying = false
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
    
    private func escapeXMLCharacters(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
    
    private func formatTextWithBreaks(_ text: String) -> String {
        // 清理文本，移除多余的空格和省略号
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "...", with: "")
            .replacingOccurrences(of: "。。。", with: "")
        
        return cleanText + "。"
    }
    
    private func addSSMLTags(_ text: String) -> String {
        let escapedText = escapeXMLCharacters(text)
        let formattedText = formatTextWithBreaks(escapedText)
        
        // 使用SSML添加适当的语气和停顿
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="zh-CN">
            <voice name="zh-CN-XiaoxiaoNeural">
                <prosody rate="0.95" pitch="0%">
                    \(formattedText)
                </prosody>
            </voice>
        </speak>
        """
    }
    
    func play(_ text: String) async {
        guard !state.isTransitioning else { return }
        
        state.isTransitioning = true
        defer {
            state.isTransitioning = false
        }
        
        // 确保之前的播放已经停止
        shouldStopPlaying = false
        await stop()
        
        // 打印日志时解码 Unicode 转义序列
        print("""
        ========== 开始播放新闻 ==========
        文本长度：\(text.count)
        文本内容：
        \(text.removingPercentEncoding ?? text)
        ================================
        """)
        
        // 使用 Azure 语音服务播放
        do {
            guard let synthesizer = synthesizer else {
                throw NSError(domain: "SpeechViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "语音合成器未初始化"])
            }
            
            print("设置播放状态为 true")
            isPlaying = true
            isLoading = true
            synthesisCompleted = false
            
            currentTask = Task {
                do {
                    // 使用SSML格式的文本
                    let ssmlText = addSSMLTags(text)
                    print("SSML文本：\n\(ssmlText)")
                    let result = try synthesizer.speakSsml(ssmlText)
                    print("调用speakSsml返回：\(String(describing: result))")
                    
                    // 等待合成完成
                    while !synthesisCompleted && !Task.isCancelled {
                        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    }
                    
                    if Task.isCancelled {
                        print("任务被取消")
                        await MainActor.run {
                            isPlaying = false
                        }
                        return
                    }
                    
                } catch {
                    if !Task.isCancelled {
                        await MainActor.run {
                            self.error = error
                            print("设置播放状态为 false（错误）")
                            isPlaying = false
                            isLoading = false
                            print("播放出错：\(error.localizedDescription)")
                        }
                    }
                }
            }
            
            await currentTask?.value
            
        } catch {
            self.error = error
            print("设置播放状态为 false（初始化错误）")
            isPlaying = false
            isLoading = false
            print("初始化出错：\(error.localizedDescription)")
        }
    }
    
    func stop() async {
        guard !state.isTransitioning else { return }
        
        state.isTransitioning = true
        defer {
            state.isTransitioning = false
        }
        
        print("开始停止播放")
        shouldStopPlaying = true
        
        // 取消当前任务
        currentTask?.cancel()
        currentTask = nil
        
        // 立即更新状态
        isPlaying = false
        synthesisCompleted = true
        
        // 停止语音合成
        try? synthesizer?.stopSpeaking()
        
        // 等待一小段时间确保完全停止
        try? await Task.sleep(nanoseconds: 200_000_000)
        print("播放已停止")
    }
    
    // 记录最后播放的位置
    func updateLastPlayedIndex(_ index: Int) {
        state.lastPlayedIndex = index
    }
    
    // 获取上次播放位置
    func getLastPlayedIndex() -> Int? {
        return state.lastPlayedIndex
    }
}

// MARK: - Preview Helper
extension SpeechViewModel {
    static var preview: SpeechViewModel {
        shared
    }
}
