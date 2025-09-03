//
//  ContentView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI
import SwiftData
import os.log

/// 应用主界面（占位页面）
/// 现在主要功能通过Tab界面提供
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appContainer: AppContainer
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 12) {
                Text("Welcome to CamFolo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("使用底部Tab导航使用相机功能")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
        .environmentObject(AppContainer.shared)
}
