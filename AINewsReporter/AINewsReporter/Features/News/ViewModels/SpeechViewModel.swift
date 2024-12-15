import Foundation
import AVFoundation
import MicrosoftCognitiveServicesSpeech

class SpeechViewModel: NSObject, ObservableObject {
    // MARK: - Singleton
    static let shared = SpeechViewModel()
    
    // MARK: - Properties
    @Published var isPlaying = false
    @Published var lastPlayedIndex: Int?
    private var isManualStop = false
    
    // Azure Speech 配置
    private var synthesizer: SPXSpeechSynthesizer?
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupSynthesizer()
    }
    
    private func setupSynthesizer() {
        do {
            let config = try SPXSpeechConfiguration(subscription: "5bdwA3BWQM17ZNYirv7n4QRfKAfLXOzFIbqqzagcojsYbmDNUNXhJQQJ99ALACYeBjFXJ3w3AAAYACOGhlDt", region: "eastus")
            config.speechSynthesisVoiceName = "zh-CN-XiaoxiaoNeural"
            synthesizer = try SPXSpeechSynthesizer(config)
            
            // 添加事件监听
            synthesizer?.addSynthesisCompletedEventHandler { [weak self] _, _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isPlaying = false
                    
                    // 只有在非手动停止时才播放下一条
                    if !self.isManualStop {
                        self.playNext?()
                    }
                    self.isManualStop = false
                }
            }
        } catch {
            print("初始化错误: \(error.localizedDescription)")
        }
    }
    
    // 播放下一条的回调
    var playNext: (() -> Void)?
    
    func play(_ text: String) {
        // 先停止当前播放
        stop(isManual: false)
        
        // 开始新的播放
        isPlaying = true
        isManualStop = false
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let synthesizer = self.synthesizer else { return }
            
            do {
                try synthesizer.speakSsml(self.addSSMLTags(text))
            } catch {
                print("播放出错: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isPlaying = false
                }
            }
        }
    }
    
    func stop(isManual: Bool = true) {
        isPlaying = false
        isManualStop = isManual
        try? synthesizer?.stopSpeaking()
    }
    
    // 记录播放位置
    func updateLastPlayedIndex(_ index: Int) {
        lastPlayedIndex = index
    }
    
    private func addSSMLTags(_ text: String) -> String {
        let escapedText = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "...", with: "")
            .replacingOccurrences(of: "。。。", with: "")
        
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="zh-CN">
            <voice name="zh-CN-XiaoxiaoNeural">
                <prosody rate="0.95" pitch="0%">
                    \(escapedText)。
                </prosody>
            </voice>
        </speak>
        """
    }
}

// MARK: - Preview Helper
extension SpeechViewModel {
    static var preview: SpeechViewModel {
        shared
    }
}
