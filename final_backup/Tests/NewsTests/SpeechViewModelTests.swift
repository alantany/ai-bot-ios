import XCTest
@testable import AIbotMini

final class SpeechViewModelTests: XCTestCase {
    var sut: SpeechViewModel!
    
    override func setUp() {
        super.setUp()
        sut = SpeechViewModel()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertFalse(sut.isSpeaking)
    }
    
    func testSpeak() {
        // When
        sut.speak("测试文本")
        
        // Then
        XCTAssertTrue(sut.isSpeaking)
        
        // When
        sut.stop()
        
        // Then
        XCTAssertFalse(sut.isSpeaking)
    }
} 