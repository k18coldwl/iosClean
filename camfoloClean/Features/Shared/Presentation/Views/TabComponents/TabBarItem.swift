//
//  TabBarItem.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI

/// Tab Bar单项
/// 表示单个Tab的UI元素，包含图标和标题
struct TabBarItem: View {
    let tab: TabType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // 图标 - 使用原始Figma图标，不应用模板模式
                Image(isSelected ? tab.activeIcon : tab.inactiveIcon)
                    .resizable()
                    .renderingMode(.original)
                    .frame(width: 24, height: 24)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isSelected)
                
                // 标题
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? Color.white : Color.white.opacity(0.6))
                    .animation(.easeInOut(duration: 0.1), value: isSelected)
            }
        }
        .frame(height: 44)
    }
}
