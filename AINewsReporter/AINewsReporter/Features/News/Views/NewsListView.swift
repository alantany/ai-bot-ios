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
            if speechViewModel.isPlaying {
                GIFPlayer(gifName: "speaking_robot")
                    .frame(height: 300)
                    .padding(.bottom, 20)  // 增加底部间距
            } else {
                GIFPlayer(gifName: "sleeping_robot")
                    .frame(height: 300)
                    .padding(.bottom, 20)  // 增加底部间距
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let error = viewModel.error {
                Text("加载失败：\(error.localizedDescription)")
                    .font(.system(size: 17))
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
            } else if !viewModel.news.isEmpty {
                VStack(spacing: 16) {
                    // 当前新闻标题
                    Text(viewModel.news[currentIndex].title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.1, green: 0.1, blue: 0.1))  // 更深的文字颜色
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.95, green: 0.95, blue: 1.0))  // 非常淡的蓝色背景
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 10)
                
                Spacer()
                
                // 播放控制按钮
                HStack(spacing: 50) {
                    // 播放按钮
                    Button {
                        let currentNews = viewModel.news[currentIndex]
                        speechViewModel.updateLastPlayedIndex(currentIndex)
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
                    
                    // 停止按钮
                    Button {
                        speechViewModel.stop()
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundStyle(Color(red: 0.9, green: 0.3, blue: 0.3))
                            .shadow(color: .gray.opacity(0.3), radius: 3)
                    }
                    .opacity(speechViewModel.isPlaying ? 1 : 0.4)
                    .disabled(!speechViewModel.isPlaying)
                }
                .padding(.bottom, 60)
            } else {
                Text("暂无新闻")
                    .font(.system(size: 17))
                    .foregroundColor(Color(white: 0.5))
            }
        }
        .padding()
        .background(Color.white)  // 改回纯白色背景
        .ignoresSafeArea()
        .task {
            // 设置播放下一条的回调
            speechViewModel.playNext = {
                if currentIndex < viewModel.news.count - 1 {
                    currentIndex += 1
                    let nextNews = viewModel.news[currentIndex]
                    speechViewModel.updateLastPlayedIndex(currentIndex)
                    speechViewModel.play("\(nextNews.title)。\(nextNews.content)")
                }
            }
            
            await viewModel.fetchNews()
            // 恢复上次播放位置
            if let lastIndex = speechViewModel.lastPlayedIndex {
                currentIndex = min(lastIndex, viewModel.news.count - 1)
            }
        }
    }
}

#Preview {
    NewsListView()
} 
