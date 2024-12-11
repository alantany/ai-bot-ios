import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let imageName: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: imageName)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.title)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.gray)
        }
    }
} 