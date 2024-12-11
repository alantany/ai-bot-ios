import Foundation
import AVFoundation

class SpeechViewModel: ObservableObject {
    @Published private(set) var isSpeaking = false
    
    private let synthesizer = AVSpeechSynthesizer()
    
    init() {
        synthesizer.delegate = self
    }
    
    func speak(_ text: String) {
        // 如果正在播放，先停止
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // 创建语音合成请求
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // 开始播放
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
} 