import SwiftUI

struct NewsListView: View {
    @StateObject private var viewModel = NewsListViewModel()
    @StateObject private var speechViewModel = SpeechViewModel.shared
    @State private var currentIndex = 0
    
    var body: some View {
        VStack(spacing: 30) {
            // 机器人形象
            Image(systemName: "waveform.circle.fill")
                .resizable()
                .frame(width: 150, height: 150)
                .foregroundColor(.accentColor)
                .symbolEffect(.bounce, options: .repeating, value: speechViewModel.state.isPlaying)
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let error = viewModel.error {
                Text("加载失败：\(error.localizedDescription)")
                    .foregroundColor(.red)
            } else if !viewModel.news.isEmpty {
                // 当前新闻标题
                Text(viewModel.news[currentIndex].title)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // 控制按钮
                HStack(spacing: 40) {
                    // 上一条
                    Button(action: previousNews) {
                        Image(systemName: "backward.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                    }
                    .disabled(currentIndex == 0)
                    
                    // 播放/暂停
                    Button(action: togglePlayback) {
                        Image(systemName: speechViewModel.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.accentColor)
                    }
                    
                    // 下一条
                    Button(action: nextNews) {
                        Image(systemName: "forward.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                    }
                    .disabled(currentIndex >= viewModel.news.count - 1)
                }
            } else {
                Text("���有新闻")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .task {
            await viewModel.fetchNews()
        }
    }
    
    // 播放控制
    private func togglePlayback() {
        Task {
            if speechViewModel.state.isPlaying {
                await speechViewModel.pause()
            } else {
                let currentNews = viewModel.news[currentIndex]
                await speechViewModel.updateText("\(currentNews.title)。\(currentNews.content)")
                await speechViewModel.play()
            }
        }
    }
    
    // 上一条新闻
    private func previousNews() {
        guard currentIndex > 0 else { return }
        Task {
            let wasPlaying = speechViewModel.state.isPlaying
            await speechViewModel.stop()
            currentIndex -= 1
            if wasPlaying {
                let currentNews = viewModel.news[currentIndex]
                await speechViewModel.updateText("\(currentNews.title)。\(currentNews.content)")
                await speechViewModel.play()
            }
        }
    }
    
    // 下一条新闻
    private func nextNews() {
        guard currentIndex < viewModel.news.count - 1 else { return }
        Task {
            let wasPlaying = speechViewModel.state.isPlaying
            await speechViewModel.stop()
            currentIndex += 1
            if wasPlaying {
                let currentNews = viewModel.news[currentIndex]
                await speechViewModel.updateText("\(currentNews.title)。\(currentNews.content)")
                await speechViewModel.play()
            }
        }
    }
}

#Preview {
    NewsListView()
} 