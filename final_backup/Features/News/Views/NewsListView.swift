import SwiftUI

struct NewsListView: View {
    @StateObject var viewModel: NewsListViewModel
    @EnvironmentObject var speechViewModel: SpeechViewModel
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 分类选择器
                CategoryPicker(
                    selectedCategory: viewModel.selectedCategory,
                    onSelect: viewModel.selectCategory
                )
                .padding(.horizontal)
                
                // 新闻列表
                if viewModel.news.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        title: "暂无新闻",
                        message: "当前分类下没有新闻",
                        imageName: "newspaper"
                    )
                } else {
                    List(viewModel.news) { newsItem in
                        NewsRowView(news: newsItem)
                            .onTapGesture {
                                viewModel.markAsRead(newsItem.id)
                                speechViewModel.speak(newsItem.content)
                            }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.fetchNews()
                    }
                }
            }
            
            // 加载状态
            if viewModel.isLoading {
                LoadingView()
            }
            
            // 错误状态
            if let error = viewModel.error {
                ErrorView(error: error) {
                    viewModel.retry()
                }
            }
        }
        .navigationTitle("AI新闻播报")
        .task {
            await viewModel.fetchNews()
        }
    }
}

// MARK: - 子视图
private struct CategoryPicker: View {
    let selectedCategory: NewsCategory
    let onSelect: (NewsCategory) -> Void
    
    var body: some View {
        Picker("分类", selection: Binding(
            get: { selectedCategory },
            set: { onSelect($0) }
        )) {
            ForEach(NewsCategory.allCases, id: \.self) { category in
                Text(category.displayName)
                    .tag(category)
            }
        }
        .pickerStyle(.segmented)
        .padding(.vertical)
    }
}

private struct NewsRowView: View {
    let news: News
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(news.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(news.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Text(news.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(news.publishDate.formatted())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
} 