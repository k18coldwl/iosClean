//
//  CustomTabBar.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI

/// 自定义Tab Bar
/// 严格按照Figma设计的样式和布局
struct CustomTabBar: View {
    @Binding var selectedTab: TabType
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabType.allCases, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            selectedTab = tab
                        }
                    }
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 34) // 为iPhone的Home Indicator预留空间
        .background(
            Rectangle()
                .fill(Color.black)
                .shadow(color: Color.white.opacity(0.1), radius: 1, x: 0, y: -1)
                .ignoresSafeArea(.all, edges: .bottom)
        )
    }
}
