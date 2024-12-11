import SwiftUI

@main
struct AIbotMiniApp: App {
    private let container = DependencyContainer.shared
    @StateObject private var speechViewModel = SpeechViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                NewsListView(viewModel: container.makeNewsListViewModel())
                    .environmentObject(speechViewModel)
            }
        }
    }
} 