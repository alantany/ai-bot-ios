import XCTest
@testable import AIbotMini

final class NewsListViewModelTests: XCTestCase {
    var sut: NewsListViewModel!
    var mockNetworkService: MockNetworkService!
    var mockStorageService: MockStorageService!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockStorageService = MockStorageService()
        sut = NewsListViewModel(networkService: mockNetworkService, storageService: mockStorageService)
    }
    
    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        mockStorageService = nil
        super.tearDown()
    }
    
    func testFetchNewsSuccess() async {
        // Given
        let expectedNews = [News.mock(), News.mock()]
        mockNetworkService.mockResult = .success(expectedNews)
        mockStorageService.mockFetchResult = .success([])
        
        // When
        await sut.fetchNews()
        
        // Then
        XCTAssertEqual(sut.news, expectedNews)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    func testFetchNewsFailure() async {
        // Given
        let expectedError = NSError(domain: "test", code: -1)
        mockNetworkService.mockResult = .failure(expectedError)
        mockStorageService.mockFetchResult = .success([])
        
        // When
        await sut.fetchNews()
        
        // Then
        XCTAssertTrue(sut.news.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.error)
    }
    
    func testSelectCategory() async {
        // Given
        let newCategory = NewsCategory.international
        
        // When
        sut.selectCategory(newCategory)
        
        // Then
        XCTAssertEqual(sut.selectedCategory, newCategory)
    }
}

// MARK: - Mock Services
private class MockNetworkService: NetworkService {
    var mockResult: Result<[News], Error>?
    
    override func fetch<T>(_ endpoint: Endpoint) async throws -> T where T : Decodable {
        guard let result = mockResult else {
            throw NSError(domain: "test", code: -1)
        }
        
        switch result {
        case .success(let news):
            return news as! T
        case .failure(let error):
            throw error
        }
    }
}

private class MockStorageService: StorageService {
    var mockFetchResult: Result<[News], Error>?
    var mockSaveResult: Result<Void, Error>?
    
    override func fetchNews(category: NewsCategory) async throws -> [News] {
        guard let result = mockFetchResult else {
            throw NSError(domain: "test", code: -1)
        }
        
        switch result {
        case .success(let news):
            return news
        case .failure(let error):
            throw error
        }
    }
    
    override func saveNews(_ news: [News]) async throws {
        guard let result = mockSaveResult else {
            return
        }
        
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Mock Data
extension News {
    static func mock(
        id: String = UUID().uuidString,
        title: String = "Test Title",
        content: String = "Test Content",
        category: NewsCategory = .domestic,
        publishDate: Date = Date()
    ) -> News {
        News(
            id: id,
            title: title,
            content: content,
            category: category,
            publishDate: publishDate
        )
    }
} 