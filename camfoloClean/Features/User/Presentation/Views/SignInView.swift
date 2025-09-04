//
//  SignInView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI

struct SignInView: View {
    @State private var viewModel: AuthViewModel
    
    init(viewModel: AuthViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Logo and Title Section
            VStack(spacing: 16) {
                Spacer()
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                Text("Welcome to CamFolo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .layoutPriority(1)
            
            // Sign In Buttons Section
            VStack(spacing: 16) {
                // Google Sign In Button
                Button(action: {
                    viewModel.signInWithGoogle()
                }) {
                    HStack {
                        Image(systemName: "globe")
                            .font(.title2)
                        
                        Text("Continue with Google")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.red)
                    .cornerRadius(28)
                }
                .disabled(viewModel.isLoading)
                
                // Apple Sign In Button
                Button(action: {
                    viewModel.signInWithApple()
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.title2)
                        
                        Text("Continue with Apple")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black)
                    .cornerRadius(28)
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            
            // Terms and Privacy Section
            VStack(spacing: 8) {
                Text("By continuing, you agree to our")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Button("Terms of Service") {
                        // Handle terms tap
                    }
                    .font(.caption)
                    
                    Text("and")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Privacy Policy") {
                        // Handle privacy tap
                    }
                    .font(.caption)
                }
            }
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .ignoresSafeArea(.all, edges: .all)
        .overlay(
            // Loading Overlay
            Group {
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea(.all)
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
        )
        .alert("Authentication Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    let viewModel = AppContainer.shared.makeAuthViewModel()
    SignInView(viewModel: viewModel)
}
