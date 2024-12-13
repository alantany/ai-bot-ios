import AVFAudio
import MicrosoftCognitiveServicesSpeech

class SpeechViewModel: ObservableObject {
    @Published var isPlaying: Bool = false
    private let azureKey: String
    private let azureRegion: String
    private var synthesizer: SPXSpeechSynthesizer?
    
    static let shared = SpeechViewModel()
    
    init(azureKey: String = "", azureRegion: String = "") {
        self.azureKey = azureKey
        self.azureRegion = azureRegion
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("音频会话配置成功")
            
            NotificationCenter.default.addObserver(self,
                selector: #selector(handleInterruption),
                name: AVAudioSession.interruptionNotification,
                object: audioSession)
        } catch {
            print("音频会话配置失败：\(error.localizedDescription)")
        }
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        Task { @MainActor in
            switch type {
            case .began:
                print("音频中断开始")
                isPlaying = false
            case .ended:
                print("音频中断结束")
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        print("尝试恢复播放")
                        try? AVAudioSession.sharedInstance().setActive(true)
                    }
                }
            @unknown default:
                break
            }
        }
    }
    
    public func play(_ text: String) async {
        print("开始语音合成，文本长度：\(text.count)")
        guard !text.isEmpty else { return }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            print("音频会话已激活")
            
            let speechConfig = try SpeechConfiguration(subscription: azureKey, region: azureRegion)
            print("Azure配置创建成功")
            
            synthesizer = try SpeechSynthesizer(configuration: speechConfig)
            print("语音合成器创建成功")
            
            let ssml = createSSML(for: text)
            print("SSML文本创建成功")
            
            let result = try await synthesizer?.speakSsml(ssml)
            print("语音合成结果：\(result?.reason.rawValue ?? "未知")")
            
            if result?.reason == .canceled {
                let cancellation = try SpeechSynthesisCancellationDetails(fromResult: result)
                print("语音合成被取消：\(cancellation.errorDetails ?? "未知错误")")
                await MainActor.run { self.isPlaying = false }
            }
        } catch {
            print("语音合成错误：\(error.localizedDescription)")
            await MainActor.run { self.isPlaying = false }
        }
    }
    
    public func stop() async {
        await MainActor.run { self.isPlaying = false }
        synthesizer?.stopSpeaking()
        synthesizer = nil
    }
    
    private func createSSML(for text: String) -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="zh-CN">
            <voice name="zh-CN-XiaoxiaoNeural">
                <prosody rate="0.95" pitch="0%">
                    \(text)
                </prosody>
            </voice>
        </speak>
        """
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        try? AVAudioSession.sharedInstance().setActive(false)
    }
} 