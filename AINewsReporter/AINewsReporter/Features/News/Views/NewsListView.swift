import SwiftUI

struct RobotView: View {
    let isPlaying: Bool
    @State private var waveScale: CGFloat = 1.0
    @State private var mouthOffset: CGFloat = 0
    @State private var headRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 天线和电波
            ZStack {
                // 天线和顶部圆球
                VStack(spacing: 0) {
                    ZStack {
                        // 电波动画 (三个圆圈)
                        if isPlaying {
                            ForEach(0..<3) { index in
                                Circle()
                                    .stroke(Color.accentColor.opacity(0.6 - Double(index) * 0.2), lineWidth: 3)
                                    .frame(width: 30 + CGFloat(index) * 20)
                                    .scaleEffect(waveScale)
                            }
                        }
                        
                        // 顶部圆球
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 8, height: 8)
                    }
                    
                    // 天线
                    Rectangle()
                        .frame(width: 3, height: 40)
                        .foregroundStyle(.primary)
                }
            }
            .frame(height: 100) // 固定高度，防止动画时位置偏移
            
            // 机器人头部（简单线条风格）
            ZStack {
                // 头部外框
                RoundedRectangle(cornerRadius: 25)
                    .stroke(lineWidth: 3)
                    .frame(width: 140, height: 160)
                    .foregroundStyle(.primary)
                    .rotationEffect(.degrees(headRotation))
                
                VStack(spacing: 25) {
                    // 眼睛
                    HStack(spacing: 35) {
                        Circle()
                            .stroke(lineWidth: 3)
                            .frame(width: 25, height: 25)
                        Circle()
                            .stroke(lineWidth: 3)
                            .frame(width: 25, height: 25)
                    }
                    
                    // 嘴巴（播报时变化）
                    Group {
                        if isPlaying {
                            // 播报时显示动态嘴型
                            VStack(spacing: mouthOffset) {
                                Rectangle()
                                    .frame(width: 50, height: 3)
                                Rectangle()
                                    .frame(width: 50, height: 3)
                            }
                            .frame(height: 20)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.3).repeatForever()) {
                                    mouthOffset = 8
                                }
                                withAnimation(.easeInOut(duration: 2).repeatForever()) {
                                    headRotation = 2
                                }
                            }
                        } else {
                            // 静止时显示直线
                            Rectangle()
                                .frame(width: 50, height: 3)
                        }
                    }
                    .frame(height: 20)
                }
                .rotationEffect(.degrees(headRotation))
            }
        }
        .onAppear {
            if isPlaying {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                    waveScale = 2.0
                }
            }
        }
        .onChange(of: isPlaying) { newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                    waveScale = 2.0
                }
                withAnimation(.easeInOut(duration: 0.3).repeatForever()) {
                    mouthOffset = 8
                }
                withAnimation(.easeInOut(duration: 2).repeatForever()) {
                    headRotation = 2
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    waveScale = 1.0
                    mouthOffset = 0
                    headRotation = 0
                }
            }
        }
    }
}

struct NewsListView: View {
    @StateObject private var viewModel = NewsListViewModel()
    @StateObject private var speechViewModel = SpeechViewModel.shared
    @State private var currentIndex = 0
    
    var body: some View {
        VStack {
            Spacer()
            
            // 机器人形象
            RobotView(isPlaying: speechViewModel.state.isPlaying)
                .padding(.bottom, 40)
            
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
                
                Spacer()
                
                // 控制按钮
                HStack(spacing: 40) {
                    // 上一条
                    Button(action: previousNews) {
                        Image(systemName: "backward.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(currentIndex == 0)
                    
                    // 播放/暂停
                    Button(action: togglePlayback) {
                        Image(systemName: speechViewModel.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.tint)
                    }
                    
                    // 下一条
                    Button(action: nextNews) {
                        Image(systemName: "forward.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(currentIndex >= viewModel.news.count - 1)
                }
                .padding(.bottom, 50)
            } else {
                Text("暂无新闻")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .task {
            await viewModel.fetchNews()
        }
        .onReceive(speechViewModel.$state) { state in
            // 监听播放状态，当一条新闻播放完成时自动播放下一条
            if case .finished = state {
                if currentIndex < viewModel.news.count - 1 {
                    Task {
                        currentIndex += 1
                        let nextNews = viewModel.news[currentIndex]
                        await speechViewModel.updateText("\(nextNews.title)。\(nextNews.content)")
                        await speechViewModel.play()
                    }
                }
            }
        }
    }
    
    // 播放控制
    private func togglePlayback() {
        Task {
            if speechViewModel.state.isPlaying {
                await speechViewModel.pause()
            } else {
                await speechViewModel.stop()
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