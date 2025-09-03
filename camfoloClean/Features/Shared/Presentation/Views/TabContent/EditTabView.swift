//
//  EditTabView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI

/// Edit Tab内容视图
/// 显示编辑功能的占位界面
struct EditTabView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // 图标
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 8) {
                Text("Edit")
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("编辑功能即将推出")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
