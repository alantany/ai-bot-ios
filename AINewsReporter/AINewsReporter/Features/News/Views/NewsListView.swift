import SwiftUI

struct RobotView: View {
    let isPlaying: Bool
    @State private var waveScale: CGFloat = 1.0
    @State private var mouthOffset: CGFloat = 0
    @State private var headRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 天线、圆球和电波
            VStack(spacing: -8) { // 增加负间距，让圆球和天线更紧密
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
                        .fill(Color.accentColor.opacity(0.8))
                        .frame(width: 16, height: 16)
                }
                .frame(height: 60)
                
                // 天线
                Rectangle()
                    .frame(width: 3, height: 40)
                    .foregroundStyle(.primary)
            }
            
            // 机器人头部（简单线条风格）
            ZStack {
                // 头部外框
                RoundedRectangle(cornerRadius: 25)
                    .stroke(lineWidth: 3)
                    .frame(width: 140, height: 160)
                    .foregroundStyle(.primary)
                    .rotationEffect(.degrees(headRotation))
                
                VStack(spacing: 25) {
                    // 眼睛（更友好的表情）
                    HStack(spacing: 35) {
                        // 左眼
                        ZStack {
                            Capsule()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 30, height: 20)
                            Capsule()
                                .fill(Color.accentColor)
                                .frame(width: 12, height: 12)
                        }
                        
                        // 右眼
                        ZStack {
                            Capsule()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 30, height: 20)
                            Capsule()
                                .fill(Color.accentColor)
                                .frame(width: 12, height: 12)
                        }
                    }
                    
                    // 嘴巴（播报时变化）
                    Group {
                        if isPlaying {
                            // 播报时显示动态嘴型
                            VStack(spacing: mouthOffset) {
                                Capsule()
                                    .frame(width: 50, height: 3)
                                Capsule()
                                    .frame(width: 50, height: 3)
                            }
                            .frame(height: 20)
                        } else {
                            // 静止时显示微笑（友好的向上弧形）
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 15))
                                path.addQuadCurve(
                                    to: CGPoint(x: 50, y: 15),
                                    control: CGPoint(x: 25, y: -10) // 控制点更高，创造明显的上扬弧度
                                )
                            }
                            .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 50, height: 30)
                        }
                    }
                    .frame(height: 30)
                }
                .rotationEffect(.degrees(headRotation))
            }
            .offset(y: -3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
        VStack(spacing: 20) {
            // 机器人形象
            RobotView(isPlaying: speechViewModel.state.isPlaying)
                .frame(height: 300)
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let error = viewModel.error {
                Text("加载失败：\(error.localizedDescription)")
                    .foregroundColor(.red)
            } else if !viewModel.news.isEmpty {
                // 当前新闻标题
                Text(viewModel.news[currentIndex].title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.blue)
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
        .task {
            // 监听播放完成事件
            for await _ in speechViewModel.playbackFinished {
                if currentIndex < viewModel.news.count - 1 {
                    currentIndex += 1
                    let nextNews = viewModel.news[currentIndex]
                    await speechViewModel.play("\(nextNews.title)。\(nextNews.content)")
                }
            }
        }
    }
    
    // 播放控制
    private func togglePlayback() {
        Task {
            if speechViewModel.state.isPlaying {
                await speechViewModel.stop()
            } else {
                let currentNews = viewModel.news[currentIndex]
                await speechViewModel.play("\(currentNews.title)。\(currentNews.content)")
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
                try? await Task.sleep(nanoseconds: 500_000_000) // 等待0.5秒
                await speechViewModel.play("\(currentNews.title)。\(currentNews.content)")
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
                try? await Task.sleep(nanoseconds: 500_000_000) // 等待0.5秒
                await speechViewModel.play("\(currentNews.title)。\(currentNews.content)")
            }
        }
    }
}

#Preview {
    NewsListView()
} 