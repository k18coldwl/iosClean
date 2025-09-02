# Firebase 第三方登录配置指南

## 1. Firebase 项目设置

1. 访问 [Firebase Console](https://console.firebase.google.com/)
2. 创建新项目或选择现有项目
3. 添加 iOS 应用：
   - Bundle ID: `com.camfolo.camfoloClean`
   - 下载 `GoogleService-Info.plist` 文件
   - 将文件替换到 `camfoloClean/Resources/GoogleService-Info.plist`

## 2. 启用认证方式

在 Firebase Console 中：
1. 进入 Authentication > Sign-in method
2. 启用 Google 登录
3. 启用 Apple 登录

### Google 登录配置
1. 在 Google 登录设置中，添加 iOS 客户端 ID
2. 确保项目的 SHA-1 指纹已添加（如果需要）

### Apple 登录配置
1. 在 Apple Developer Console 中配置 Sign in with Apple
2. 确保 Bundle ID 匹配
3. 在 Firebase 中添加 Apple 服务 ID

## 3. 更新配置文件

### 更新 GoogleService-Info.plist
将下载的真实 `GoogleService-Info.plist` 文件内容替换当前的占位符文件。

### 更新 Info.plist URL Schemes
在 `Info.plist` 中，将 `YOUR_REVERSED_CLIENT_ID_HERE` 替换为 GoogleService-Info.plist 中的 `REVERSED_CLIENT_ID` 值。

## 4. Xcode 项目配置

1. 确保 `GoogleService-Info.plist` 已添加到项目中
2. 在项目设置中添加 URL Schemes：
   - 添加 `REVERSED_CLIENT_ID` 作为 URL scheme
3. 启用 Sign in with Apple capability

## 5. 测试

运行应用并测试：
1. Google 登录流程
2. Apple 登录流程
3. 登出功能
4. 用户状态持久化

## 架构说明

该实现遵循 Clean Architecture 原则：

- **Domain Layer**: 包含 User、AuthResult 实体和认证用例
- **Data Layer**: Firebase 数据源和 Repository 实现
- **Presentation Layer**: SwiftUI 视图和 ViewModel
- **Core Layer**: 依赖注入容器

认证状态通过 Combine 响应式编程在整个应用中传播，确保 UI 实时更新。

