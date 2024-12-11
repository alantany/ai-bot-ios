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
                
                Text("我们即将开始精彩的旅程")
                    .foregroundColor(.gray)
            }
            .navigationTitle("AI 新闻播报")
        }
    }
}

#Preview {
    ContentView()
}
