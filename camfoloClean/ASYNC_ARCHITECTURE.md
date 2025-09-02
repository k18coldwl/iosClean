# iOS 17 异步编程架构实现

## 🎯 架构概览

本项目已完全重构，使用iOS 17+的现代异步编程模式，遵循Clean Architecture原则：

### 核心技术栈
- **Swift 6** + **SwiftUI**
- **@Observable** 宏 (替代 ObservableObject)
- **AsyncStream** (替代 Combine Publishers)
- **async/await** (现代异步编程)
- **Clean Architecture** 分层设计

## 📱 主要改进

### 1. Presentation Layer (表现层)
```swift
@Observable
@MainActor
final class AuthViewModel {
    var currentUser: User?
    var isAuthenticated = false
    
    private func startObservingUserState() {
        userStateTask = Task { @MainActor in
            for await user in getCurrentUserUseCase.userStateSequence {
                currentUser = user
                isAuthenticated = user != nil
            }
        }
    }
}
```

**优势：**
- 使用 `@Observable` 宏，更简洁的状态管理
- 自动的UI更新，无需手动发布
- 更好的性能和内存使用

### 2. Domain Layer (领域层)
```swift
protocol AuthRepository {
    var userStateSequence: AsyncStream<User?> { get }
    func signInWithGoogle() async throws -> AuthResult
}

final class GetCurrentUserUseCase {
    var userStateSequence: AsyncStream<User?> {
        authRepository.userStateSequence
    }
}
```

**优势：**
- 使用 `AsyncStream` 进行响应式数据流
- 清晰的异步接口定义
- 更好的错误处理

### 3. Data Layer (数据层)
```swift
final class FirebaseAuthDataSource {
    lazy var userStateSequence: AsyncStream<FirebaseAuth.User?> = {
        AsyncStream<FirebaseAuth.User?> { continuation in
            let handle = auth.addStateDidChangeListener { _, user in
                continuation.yield(user)
            }
            continuation.onTermination = { _ in
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }()
}
```

**优势：**
- 原生Firebase监听器与AsyncStream的完美集成
- 自动资源清理
- 类型安全的数据流

## 🔄 数据流

```
Firebase Auth State Change
    ↓ (AsyncStream)
FirebaseAuthDataSource
    ↓ (AsyncStream + Mapping)
AuthRepositoryImpl
    ↓ (AsyncStream)
GetCurrentUserUseCase
    ↓ (AsyncStream)
@Observable AuthViewModel
    ↓ (自动UI更新)
SwiftUI Views
```

## ⚡ 性能优势

1. **内存效率**: AsyncStream 比 Combine 使用更少内存
2. **CPU效率**: @Observable 减少不必要的UI更新
3. **电池优化**: 现代异步模式更省电
4. **响应速度**: 直接的异步调用，减少中间层

## 🛠 使用示例

### 登录操作
```swift
// ViewModel中
func signInWithGoogle() {
    Task {
        await performAuthAction {
            try await signInWithGoogleUseCase.execute()
        }
    }
}

// View中
Button("Google登录") {
    viewModel.signInWithGoogle()
}
```

### 状态监听
```swift
// 自动响应用户状态变化
struct RootView: View {
    @State private var authViewModel: AuthViewModel?
    
    var body: some View {
        Group {
            if let viewModel = authViewModel {
                if viewModel.isAuthenticated {
                    MainTabView()
                } else {
                    SignInView(viewModel: viewModel)
                }
            }
        }
    }
}
```

## 🔧 配置要求

- **最低版本**: iOS 17.2+
- **Swift版本**: Swift 6
- **Xcode**: 16.0+

## 📦 依赖管理

项目使用Swift Package Manager管理依赖：
- Firebase iOS SDK 10.0+
- Google Sign-In iOS 7.0+

## 🚀 部署指南

1. 配置Firebase项目
2. 添加GoogleService-Info.plist
3. 配置URL Schemes
4. 运行项目

这个现代化的架构为应用提供了更好的性能、可维护性和用户体验。

