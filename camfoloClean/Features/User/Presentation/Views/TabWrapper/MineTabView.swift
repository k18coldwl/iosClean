//
//  MineTabView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI

/// Mine Tab内容视图
/// 根据用户登录状态显示不同的界面：登录界面或用户资料
struct MineTabView: View {
    let authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.all)
            
            if authViewModel.isAuthenticated {
                // 已登录状态 - 显示用户资料
                UserProfileView(viewModel: authViewModel)
            } else {
                // 未登录状态 - 显示登录界面
                SignInView(viewModel: authViewModel)
            }
        }
    }
}
