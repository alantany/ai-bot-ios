# AI 新闻播报

一个基于 SwiftUI 开发的 iOS 新闻播报应用，使用 AI 技术提供新闻摘要和语音播报功能。

## 项目描述

- 使用 SwiftUI 和 MVVM 架构
- 支持新闻列表展示、新闻详情查看
- 集成 AI 生成的新闻摘要
- 提供新闻语音播报功能（使用 Azure 语音服务）
- 遵循 SwiftLint 代码规范
- 采用模块化设计，便于维护和扩展

## 项目结构

```
AINewsReporter/
├── App/                    # 应用级别代码
├── Core/                   # 核心模块
│   ├── Common/            # 通用组件
│   │   ├── Protocols/     # 基础协议
│   │   └── Views/         # 基础视图
│   ├── Network/           # 网络服务
│   └── Storage/           # 存储服务
├── Features/              # 业务功能模块
│   └── News/             # 新闻相关功能
└── Utilities/            # 工具类
```

## 改造进度

### 1. 基础架构搭建 (✅ 完成)

- [x] 创建基本目录结构
- [x] 配置 SwiftUI 项目
- [x] 实现基础欢迎页面

### 2. 核心协议迁移 (✅ 完成)

- [x] ViewModelProtocol: MVVM 架构中 ViewModel 的基础协议
- [x] CoordinatorProtocol: 导航协调器协议
- [x] ServiceProtocol: 服务层基础协议

### 3. 基础视图组件迁移 (✅ 完成)

- [x] LoadingView: 加载状态视图
- [x] ErrorView: 错误状态视图
- [x] EmptyStateView: 空状态视图

### 4. 工具类迁移 (✅ 完成)

- [x] Constants: 全局常量定义
- [x] AppConfig: 应用配置（环境设置、功能开关）
- [x] Logger: 日志工具（支持多级别日志和网络日志）

### 5. 核心服务迁移 (✅ 完成)

- [x] 网络服务
  - [x] Endpoint: API端点定义
  - [x] NetworkService: 网络请求服务
  - [x] 错误处理
  - [x] 日志集成
- [x] 存储服务
  - [x] UserDefaults 封装
  - [x] 文件缓存管理
  - [x] 缓存清理策略
  - [x] 错误处理

### 6. 新闻功能模块迁移 (✅ 完成)

- [x] 模型层
  - [x] News: 新闻数据模型
  - [x] NewsResponse: 新闻列表响应模型
  - [x] AIResponse: AI处理响应模型
- [x] ViewModel层
  - [x] NewsListViewModel: 新闻列表（加载、刷新、分页、搜索、分类）
  - [x] NewsDetailViewModel: 新闻详情（AI摘要、语音播报、收藏）
  - [x] SpeechViewModel: 语音播报（播放控制、进度管理、缓存）
- [x] 视图层
  - [x] NewsListView: 新闻列表和播放控制界面
  - [x] RobotView: 机器人动画界面

### 7. 语音服务升级 (✅ 完成)

- [x] 集成 Azure 语音服务
  - [x] 配置服务凭证
  - [x] 实现语音合成
  - [x] 添加事件监听
  - [x] 优化状态管理
  - [x] 添加详细日志
  - [x] 验证长文本播放
  - [x] 确保播放完整性

### 8. 动画效果实现 (✅ 完成)

- [x] GIF 动画集成
  - [x] 实现 GIF 播放器组件
  - [x] 添加播放/暂停状态动画
  - [x] 优化状态管理和切换效果
  - [x] 实现位置记忆功能
  - [x] 完善自动播放逻辑

#### GIF 动画实现细节

1. 动画文件位置：
   - 路径：`AINewsReporter/Resources/`
   - 文件：
     * `speaking_robot.gif` - 播放状态动画
     * `sleeping_robot.gif` - 停止状态动画

2. 核心组件：
```swift
// GIF 播放器组件
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
```

3. 状态管理：
   - 使用 `SpeechViewModel` 管理播放状态
   - 通过 `isPlaying` 控制动画切换
   - 实现位置记忆功能，支持继续播放

4. 主要功能：
   - 播放/暂停状态自动切换动画
   - 支持立即停止播放
   - 记住上次播放位置
   - 自动连续播放多条新闻

5. 关键代码示例：
```swift
// 动画状态切换
GIFPlayer(gifName: speechViewModel.state.isPlaying ? "speaking_robot" : "sleeping_robot")
    .frame(height: 300)

// 播放控制
func togglePlayback() {
    Task {
        if speechViewModel.state.isPlaying {
            await speechViewModel.stop()
        } else {
            speechViewModel.updateLastPlayedIndex(currentIndex)
            let currentNews = viewModel.news[currentIndex]
            await speechViewModel.play("\(currentNews.title)。\(currentNews.content)")
        }
    }
}

// 位置记忆
speechViewModel.updateLastPlayedIndex(currentIndex)
if let lastIndex = speechViewModel.getLastPlayedIndex() {
    currentIndex = min(lastIndex, viewModel.news.count - 1)
}
```

6. 注意事项：
   - GIF 文件需要放在正确的资源目录
   - 动画切换时机要和语音播放同步
   - 状态变化要即时反映在界面上

### 9. 待完成任务

- [ ] 单元测试迁移
- [ ] CI/CD 配置
- [ ] 新闻分类功能
- [ ] 自定义语音设置
- [ ] 新闻搜索功能
- [ ] 收藏新闻功能
- [ ] 历史记录功能

## 开发环境

- Xcode 15+
- iOS 17.0+
- Swift 5.9+

## 如何运行

1. 克隆项目
2. 打开 AINewsReporter.xcodeproj
3. 配置 Azure 语音服务凭证
   - 在 SpeechViewModel 中设置 subscription key 和 region
4. 选择目标设备或模拟器
5. 点击运行按钮或按 Cmd+R

## 代码规范

项目使用 SwiftLint 进行代码规范检查，确保代码风格统一。主要规范包括：

- 使用空格而不是制表符
- 行尾不允许有空格
- 使用驼峰命名法
- 适当的代码缩进
- 避免强制解包 