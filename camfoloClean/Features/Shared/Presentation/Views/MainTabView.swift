//
//  MainTabView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI

/// 主Tab界面
/// 基于Figma设计的四个Tab页面：Capture、Templates、Edit、Mine
/// 作为应用的主要导航容器，协调各个Tab内容的显示
struct MainTabView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject private var appContainer: AppContainer
    let authViewModel: AuthViewModel
    @State private var selectedTab: TabType = .capture
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 背景色 - 根据Figma设计使用深色背景
            Color.black
                .ignoresSafeArea(.all)
            
            // 主内容区域 - 使用ZStack布局避免TabView的内边距问题
            currentTabContent
            
            // 自定义Tab Bar - 固定在底部
            CustomTabBar(selectedTab: $selectedTab)
                .background(Color.clear)
        }
        .ignoresSafeArea(.all)
        .navigationBarHidden(true)
        .statusBarHidden()
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var currentTabContent: some View {
        ZStack {
            // 当前选中的Tab内容
            Group {
                switch selectedTab {
                case .capture:
                    CaptureTabView()
                case .templates:
                    TemplatesTabView()
                case .edit:
                    EditTabView()
                case .mine:
                    MineTabView(authViewModel: authViewModel)
                }
            }
            .ignoresSafeArea(.all)
        }
    }
}

// MARK: - Preview

#Preview {
    let authViewModel = MockDIContainer().makeAuthViewModel()
    MainTabView(authViewModel: authViewModel)
        .environmentObject(AppContainer.shared)
}
