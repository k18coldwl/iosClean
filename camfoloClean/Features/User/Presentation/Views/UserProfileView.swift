//
//  UserProfileView.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import SwiftUI

struct UserProfileView: View {
    @State private var viewModel: AuthViewModel
    @State private var showingSignOut = false
    
    init(viewModel: AuthViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let user = viewModel.currentUser {
                    // User Avatar
                    AsyncImage(url: user.photoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title)
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    
                    // User Info
                    VStack(spacing: 8) {
                        Text(user.displayName ?? "Unknown User")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if let email = user.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Provider Badge
                        HStack {
                            Image(systemName: providerIcon(for: user.provider))
                                .font(.caption)
                            Text("Signed in with \(user.provider.displayName)")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    // Account Actions
                    VStack(spacing: 16) {
                        Button("Account Settings") {
                            // Handle account settings
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("Sign Out") {
                            showingSignOut = true
                        }
                        .buttonStyle(DestructiveButtonStyle())
                    }
                    .padding(.horizontal, 32)
                    
                } else {
                    // Not signed in state
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("Not signed in")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding(.top, 32)
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showingSignOut) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    viewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
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
    
    private func providerIcon(for provider: AuthProvider) -> String {
        switch provider {
        case .google:
            return "globe"
        case .apple:
            return "applelogo"
        case .email:
            return "envelope"
        }
    }
}



#Preview {
    let mockDIContainer = MockDIContainer()
    let viewModel = mockDIContainer.makeAuthViewModel()
    UserProfileView(viewModel: viewModel)
}
