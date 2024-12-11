//
//  ContentView.swift
//  AINewsReporter
//
//  Created by huaiyuantan on 2024/12/11.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("欢迎使用 AI 新闻播报")
                    .font(.title)
                    .padding()
                
                Text("让我们一起探索 AI 新闻的魅力")
                    .foregroundColor(.blue)
                    .padding()
                
                Text("Version 1.0")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .navigationTitle("AI 新闻播报")
        }
    }
}

#Preview {
    ContentView()
}
