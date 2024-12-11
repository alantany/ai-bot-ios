import SwiftUI

struct EmptyStateView: View {
    let message: String
    let systemImage: String
    
    init(message: String = "暂无数据", systemImage: String = "tray") {
        self.message = message
        self.systemImage = systemImage
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

#Preview {
    EmptyStateView()
} 