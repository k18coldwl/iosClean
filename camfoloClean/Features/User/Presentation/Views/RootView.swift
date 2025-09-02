//
//  RootView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appContainer: AppContainer
    @State private var authViewModel: AuthViewModel?
    
    var body: some View {
        ZStack {
            // 背景色确保覆盖整个屏幕
            Color(.systemBackground)
                .ignoresSafeArea(.all)
            
            Group {
                if let viewModel = authViewModel {
                    if viewModel.isAuthenticated {
                        MainTabView(authViewModel: viewModel)
                            .environmentObject(appContainer)
                    } else {
                        SignInView(viewModel: viewModel)
                    }
                } else {
                    // Loading state while initializing
                    VStack {
                        Spacer()
                        ProgressView("Initializing...")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .onAppear {
            if authViewModel == nil {
                authViewModel = appContainer.diContainer.makeAuthViewModel()
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var appContainer: AppContainer
    let authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            UserProfileView(viewModel: authViewModel)
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppContainer.shared)
}
