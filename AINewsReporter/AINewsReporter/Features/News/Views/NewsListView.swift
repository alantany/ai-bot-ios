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
            // 顶部留白
            Spacer()
                .frame(height: 20)
            
            // 动画机器人
            Group {
                if speechViewModel.isPlaying {
                    GIFPlayer(gifName: "speaking_robot")
                        .transition(.opacity.combined(with: .scale))
                } else {
                    GIFPlayer(gifName: "sleeping_robot")
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .frame(height: 300)
            .padding(.bottom, 20)
            .animation(.easeInOut(duration: 0.5), value: speechViewModel.isPlaying)
            
            // 新闻分类选择器
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach([
                        NewsListViewModel.NewsCategory.domestic,
                        .international,
                        .life,
                        .tech
                    ], id: \.self) { category in
                        Button(action: {
                            // 切换分类前保存当前位置
                            viewModel.updateCategoryLastIndex(currentIndex)
                            Task {
                                await viewModel.switchCategory(category)
                                // 切换分类后恢复该分类的上次播放位置
                                if let lastIndex = viewModel.getCategoryLastIndex() {
                                    currentIndex = min(lastIndex, viewModel.news.count - 1)
                                } else {
                                    currentIndex = 0
                                }
                            }
                        }) {
                            Text(category.title)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(viewModel.currentCategory == category ? .white : .blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(viewModel.currentCategory == category ? Color.blue : Color.white)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 10)
            
            // 内容区域
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .transition(.opacity)
                } else if let error = viewModel.error {
                    Text("加载失败：\(error.localizedDescription)")
                        .font(.system(size: 17))
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .transition(.opacity)
                } else if !viewModel.news.isEmpty {
                    VStack(spacing: 16) {
                        // 当前新闻标题
                        Text(viewModel.news[currentIndex].title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.1, green: 0.1, blue: 0.1))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(red: 0.95, green: 0.95, blue: 1.0))
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            .padding(.horizontal, 16)
                            .id(currentIndex) // 添加 id 以支持动画
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                    .padding(.vertical, 10)
                    
                    Spacer()
                    
                    // 播放控制按钮
                    HStack(spacing: 50) {
                        // 播放按钮
                        Button {
                            let currentNews = viewModel.news[currentIndex]
                            speechViewModel.updateLastPlayedIndex(currentIndex)
                            viewModel.updateCategoryLastIndex(currentIndex)  // 记录当前分类的播放位置
                            speechViewModel.play("\(currentNews.title)。\(currentNews.content)")
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .resizable()
                                .frame(width: 70, height: 70)
                                .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 1.0))
                                .shadow(color: .gray.opacity(0.3), radius: 3)
                        }
                        .opacity(speechViewModel.isPlaying ? 0.4 : 1)
                        .disabled(speechViewModel.isPlaying)
                        .buttonStyle(ScaleButtonStyle())
                        
                        // 停止按钮
                        Button {
                            // 标记当前新闻为已播放
                            let currentNews = viewModel.news[currentIndex]
                            speechViewModel.stop()
                            Task {
                                await viewModel.markNewsAsPlayed(currentNews.id)
                            }
                        } label: {
                            Image(systemName: "stop.circle.fill")
                                .resizable()
                                .frame(width: 70, height: 70)
                                .foregroundStyle(Color(red: 0.9, green: 0.3, blue: 0.3))
                                .shadow(color: .gray.opacity(0.3), radius: 3)
                        }
                        .opacity(speechViewModel.isPlaying ? 1 : 0.4)
                        .disabled(!speechViewModel.isPlaying)
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.bottom, 60)
                } else {
                    Text("暂无新闻")
                        .font(.system(size: 17))
                        .foregroundColor(Color(white: 0.5))
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
            .animation(.easeInOut(duration: 0.3), value: viewModel.news.map { $0.id })
            .animation(.easeInOut(duration: 0.3), value: currentIndex)
        }
        .padding()
        .background(Color.white)
        .ignoresSafeArea()
        .task {
            // 设置播放下一条的回调
            speechViewModel.playNext = { [weak viewModel] in
                guard let viewModel = viewModel else { return }
                
                // 标记当前新闻为已播放
                let currentNews = viewModel.news[currentIndex]
                
                // 使用 Task 包装异步操作
                Task { @MainActor in
                    await viewModel.markNewsAsPlayed(currentNews.id)
                    viewModel.updateCategoryLastIndex(currentIndex)  // 更新当前分类的播放位置
                    
                    if currentIndex < viewModel.news.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentIndex += 1
                        }
                        let nextNews = viewModel.news[currentIndex]
                        viewModel.updateCategoryLastIndex(currentIndex)  // 更新播放位置
                        speechViewModel.updateLastPlayedIndex(currentIndex)
                        speechViewModel.play("\(nextNews.title)。\(nextNews.content)")
                    } else {
                        // 已经是最后一条新闻，检查是否需要刷新
                        await viewModel.checkAndRefreshIfNeeded()
                    }
                }
            }
            
            await viewModel.preloadAllNews()
            // 恢复当前分类的上次播放位置
            if let lastIndex = viewModel.getCategoryLastIndex() {
                currentIndex = min(lastIndex, viewModel.news.count - 1)
            }
        }
    }
}

// 添加按钮缩放动画样式
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    NewsListView()
} 
