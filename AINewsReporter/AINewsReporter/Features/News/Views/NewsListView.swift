import SwiftUI
import UIKit

class GIFImageView: UIView {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadGIF(named: String) {
        if let url = Bundle.main.url(forResource: named, withExtension: "gif"),
           let data = try? Data(contentsOf: url),
           let image = UIImage.gifImageWithData(data) {
            imageView.image = image
        }
    }
}

extension UIImage {
    class func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        var images = [UIImage]()
        var duration = 0.0
        
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))
                
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                   let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
                    duration += delayTime
                }
            }
        }
        
        if images.count == 1 {
            return images.first
        } else {
            return UIImage.animatedImage(with: images, duration: duration)
        }
    }
}

struct GIFPlayer: UIViewRepresentable {
    let gifName: String
    
    func makeUIView(context: Context) -> GIFImageView {
        let view = GIFImageView()
        view.loadGIF(named: gifName)
        return view
    }
    
    func updateUIView(_ uiView: GIFImageView, context: Context) {
        uiView.loadGIF(named: gifName)
    }
}

struct NewsListView: View {
    @StateObject private var viewModel = NewsListViewModel()
    @StateObject private var speechViewModel = SpeechViewModel.shared
    @State private var currentIndex = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // 动画机器人
            GIFPlayer(gifName: speechViewModel.isPlaying ? "speaking_robot" : "sleeping_robot")
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
                
                // 播放/暂停按钮
                Button(action: {
                    print("点击按钮，当前状态: \(speechViewModel.isPlaying ? "正在播放" : "已停止")")
                    togglePlayback()
                }) {
                    Image(systemName: speechViewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.blue)
                        .shadow(radius: 5)
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
            // 恢复上次播放位置
            if let lastIndex = speechViewModel.getLastPlayedIndex() {
                currentIndex = min(lastIndex, viewModel.news.count - 1)
            }
        }
        .onChange(of: speechViewModel.isPlaying) { newValue in
            print("播放状态变化: \(newValue ? "正在播放" : "已停止")")
        }
    }
    
    // 播放控制
    private func togglePlayback() {
        Task {
            if speechViewModel.isPlaying {
                print("准备停止播放")
                await speechViewModel.stop()
            } else {
                print("准备开始播放")
                await MainActor.run {
                    speechViewModel.isPlaying = true
                    print("设置播放状态为 true")
                }
                
                // 记录开始播放的位置
                speechViewModel.updateLastPlayedIndex(currentIndex)
                let currentNews = viewModel.news[currentIndex]
                print("========== 开始播放新闻 ==========")
                await speechViewModel.play("\(currentNews.title)。\(currentNews.content)")
                
                // 如果播放完成且仍在播放状态，自动播放下一条
                if currentIndex < viewModel.news.count - 1 && speechViewModel.isPlaying {
                    currentIndex += 1
                    speechViewModel.updateLastPlayedIndex(currentIndex)
                    let nextNews = viewModel.news[currentIndex]
                    print("开始播放下一条新闻")
                    try? await Task.sleep(nanoseconds: 500_000_000) // 等待0.5秒
                    if speechViewModel.isPlaying {  // 再次检查是否仍在播放状态
                        await speechViewModel.play("\(nextNews.title)。\(nextNews.content)")
                    }
                }
            }
        }
    }
}

#Preview {
    NewsListView()
} 
