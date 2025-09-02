//
//  AuthViewModel.swift
//  camfoloClean
//
//  Created by admin on 2025/9/2.
//

import Foundation
import Observation

@Observable
@MainActor
final class AuthViewModel {
    // MARK: - Observable Properties
    var currentUser: User?
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Use Cases
    private let authUseCase: AuthUseCaseProtocol
    
    // MARK: - Private Properties
    @ObservationIgnored
    private var userStateTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(authUseCase: AuthUseCaseProtocol) {
        self.authUseCase = authUseCase
        startObservingUserState()
    }
    
    deinit {
        userStateTask?.cancel()
    }
    
    // MARK: - Setup
    private func startObservingUserState() {
        Task { @MainActor in
            let user = await authUseCase.getCurrentUser()
            currentUser = user
            isAuthenticated = user != nil
        }
    }
    
    // MARK: - Actions
    func signInWithGoogle() {
        Task {
            await performAuthAction {
                try await authUseCase.signInWithGoogle()
            }
            // Refresh user state after sign in
            startObservingUserState()
        }
    }
    
    func signInWithApple() {
        Task {
            await performAuthAction {
                try await authUseCase.signInWithApple()
            }
            // Refresh user state after sign in
            startObservingUserState()
        }
    }
    
    func signOut() {
        Task {
            await performAuthAction {
                try await authUseCase.signOut()
                return () as Void?
            }
            // Refresh user state after sign out
            startObservingUserState()
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    private func performAuthAction<T: Sendable>(_ action: @Sendable () async throws -> T?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await action()
        } catch let authError as AuthError {
            // 为网络错误提供更友好的错误信息
            switch authError {
            case .networkError(let underlyingError):
                if let nsError = underlyingError as NSError?,
                   nsError.domain == "FIRAuthErrorDomain" && nsError.code == 17020 {
                    errorMessage = "网络连接失败，请检查网络设置后重试"
                } else if let nsError = underlyingError as NSError?,
                          nsError.code == -1009 {
                    errorMessage = "网络连接不可用，请检查WiFi或移动数据连接"
                } else {
                    errorMessage = "网络错误：\(underlyingError.localizedDescription)"
                }
            case .cancelled:
                errorMessage = nil // 用户取消不显示错误
            default:
                errorMessage = authError.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
