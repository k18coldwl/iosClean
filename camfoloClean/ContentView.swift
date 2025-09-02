//
//  ContentView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Text("Welcome to CamFolo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Your camera companion app")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 这里可以添加主要功能的入口
                VStack(spacing: 20) {
                    Button("Open Camera") {
                        // TODO: 实现相机功能
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .padding(.horizontal)
                    
                    Button("Photo Gallery") {
                        // TODO: 实现图库功能
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("CamFolo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle()) // 强制使用单栈导航样式
    }
}

#Preview {
    ContentView()
}
