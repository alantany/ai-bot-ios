import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("加载中...")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.top)
        }
    }
}

#Preview {
    LoadingView()
} 