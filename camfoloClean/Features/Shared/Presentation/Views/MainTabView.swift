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
    @State private var previousTab: TabType = .capture
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 背景色
                Color.black
                    .ignoresSafeArea(.all)
                
                // 主内容区域 - 给底部TabBar留出空间
                VStack(spacing: 0) {
                    // 内容区域
                    currentTabContent
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height - tabBarHeight - bottomSafeArea(geometry)
                        )
                    
                    // TabBar 占位空间
                    Spacer()
                        .frame(height: tabBarHeight + bottomSafeArea(geometry))
                }
                
                // 自定义Tab Bar - 固定在底部
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: $selectedTab)
                        .frame(height: tabBarHeight)
                        .background(Color.clear)
                        .padding(.bottom, bottomSafeArea(geometry))
                }
            }
        }
        .ignoresSafeArea(.all)
        .navigationBarHidden(true)
        .statusBarHidden()
        .onAppear {
            print("📱 MainTabView: 使用高性能Manager模式，无需初始化ViewModel")
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            print("📱 MainTabView: Tab changed from \(oldTab) to \(newTab)")
            previousTab = oldTab
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var currentTabContent: some View {
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
    
    // MARK: - Helper Properties
    
    private var tabBarHeight: CGFloat {
        80 // 自定义TabBar的高度
    }
    
    private func bottomSafeArea(_ geometry: GeometryProxy) -> CGFloat {
        geometry.safeAreaInsets.bottom
    }
}

// MARK: - Preview

#Preview {
    let authViewModel = AppContainer.shared.makeAuthViewModel()
    MainTabView(authViewModel: authViewModel)
        .environmentObject(AppContainer.shared)
}