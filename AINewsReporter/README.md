# AI 新闻播报

一个基于 SwiftUI 开发的 iOS 新闻播报应用，使用 AI 技术提供新闻摘要和语音播报功能。

## 项目描述

- 使用 SwiftUI 和 MVVM 架构
- 支持新闻列表展示、新闻详情查看
- 集成 AI 生成的新闻摘要
- 提供新闻语音播报功能
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

### 4. 工具类迁移 (🚧 进行中)

- [x] Constants: 全局常量定义
- [ ] AppConfig: 应用配置
- [ ] Logger: 日志工具

### 5. 待完成任务

- [ ] 网络服务迁移 (NetworkService, Endpoint)
- [ ] 存储服务迁移 (StorageService)
- [ ] 新闻功能模块迁移
  - [ ] 模型层
  - [ ] ViewModel层
  - [ ] 视图层
- [ ] 单元测试迁移
- [ ] CI/CD 配置

## 开发环境

- Xcode 15+
- iOS 17.0+
- Swift 5.9+

## 如何运行

1. 克隆项目
2. 打开 AINewsReporter.xcodeproj
3. 选择目标设备或模拟器
4. 点击运行按钮或按 Cmd+R

## 代码规范

项目使用 SwiftLint 进行代码规范检查，确保代码风格统一。主要规范包括：

- 使用空格而不是制表符
- 行尾不允许有空格
- 使用驼峰命名法
- 适当的代码缩进
- 避免强制解包 