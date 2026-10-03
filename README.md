# Pulse

极简风格的轻量社区 App。视觉与交互全面对齐 iOS / Apple Human Interface Guidelines，
底层用 Flutter + Riverpod 3 + go_router 搭建。

当前阶段：**全部后端交互使用本地 Model + Mock Repository**，统一 `Future.delayed(500ms)`
模拟网络延迟，因此 loading / 骨架屏 / 乐观更新 / 失败回滚这些分支在开发期就被完整覆盖。

## 快速开始

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## 技术选型

| 关注点 | 选择 | 理由 |
| --- | --- | --- |
| 状态管理 | `flutter_riverpod` 3.x（**不用**代码生成） | 心智负担适中；`AsyncValue` 把 loading/error 建模为 sealed 类型，漏处理分支会编译报错；override 一个 provider 即可替换整条依赖链 |
| 路由 | `go_router` 18.x | `StatefulShellRoute.indexedStack` 是"每个 Tab 独立导航栈"最干净的实现 |
| 本地化 | `flutter_localizations` | MaterialApp **不会**默认注入 `CupertinoLocalizations`，而 Cupertino 组件都会读它 |
| 字体 | 平台默认（iOS = San Francisco） | 不配 `fontFamily` 才能拿到系统级优化的 SF Pro；`AppTypography.fontFallback` 已为 Android/Web 预留 Inter 兜底链 |
| 图片资源 | 无 | 头像/配图用"稳定派生渐变 + Emoji"占位，替换点各只有一处 |

## 目录结构

```
lib/
├── main.dart                           # 入口：只做 ProviderScope 装配
│
├── app/                                # ── 组合根：认识所有 feature ──
│   ├── app.dart                        # PulseApp：MaterialApp.router + 主题 + 本地化
│   ├── router/
│   │   ├── app_routes.dart             # 路径 / 路由名 / 参数名常量
│   │   └── app_router.dart             # GoRouter + StatefulShellRoute.indexedStack
│   └── shell/
│       └── main_scaffold.dart          # ★ 底部导航容器（CupertinoTabBar）
│
├── core/                               # ── 基础设施：不认识任何 feature ──
│   ├── constants/
│   │   └── app_constants.dart          # App 名、mockLatency、分页大小
│   ├── theme/
│   │   ├── app_theme.dart              # ★ 主题装配 + 设计系统统一出口（export 下列全部）
│   │   ├── app_colors.dart             # 原始色板（Apple HIG System Colors）
│   │   ├── app_palette.dart            # 语义化调色板（ThemeExtension）+ context.palette
│   │   ├── app_typography.dart         # iOS 字号阶梯 + SF Pro tracking 表
│   │   ├── app_spacing.dart            # 间距 / 圆角 / 时长 / 曲线
│   │   ├── app_shadows.dart            # 微渐变投影（多层 + 负 spread）
│   │   └── theme_mode_provider.dart    # 浅色 / 深色 / 跟随系统
│   ├── haptics/
│   │   └── app_haptics.dart            # 触觉反馈统一入口（语义 → 强度映射）
│   ├── riverpod/
│   │   └── async_value_ext.dart        # dataOrNull / isInitialLoading / isInitialError
│   ├── utils/
│   │   └── date_format.dart            # 相对时间、时钟、计数缩写
│   └── widgets/                        # 原子组件
│       ├── pressable.dart              # ★ 缩放 + 触觉的点击回馈（替代水波纹）
│       ├── glass_surface.dart          # ★ 高斯模糊容器
│       ├── hairline_divider.dart       # 1 物理像素分割线
│       ├── app_avatar.dart             # 头像占位 + UnreadBadge
│       ├── app_skeleton.dart           # 骨架屏色块
│       ├── app_status_view.dart        # 空态 / 错误态
│       └── apple_scroll_behavior.dart  # 全平台橡皮筋回弹
│
└── features/                           # ── 业务模块：只认识 core 和自己的 domain ──
    ├── post/                           # → Tab 1「动态」
    │   ├── domain/
    │   │   ├── entities/{post,author}.dart
    │   │   └── repositories/post_repository.dart      # 抽象接口
    │   ├── data/
    │   │   ├── mock/mock_posts.dart                   # 种子数据
    │   │   └── repositories/mock_post_repository.dart # 有状态的内存实现
    │   └── presentation/
    │       ├── providers/feed_providers.dart          # postRepositoryProvider + feedProvider
    │       ├── pages/feed_page.dart
    │       └── widgets/{post_card,post_card_skeleton,post_composer_sheet}.dart
    │
    ├── chat/                           # → Tab 2「消息」
    │   ├── domain/
    │   │   ├── entities/{conversation,message}.dart
    │   │   └── repositories/chat_repository.dart
    │   ├── data/
    │   │   ├── mock/mock_chats.dart
    │   │   └── repositories/mock_chat_repository.dart
    │   └── presentation/
    │       ├── providers/chat_providers.dart          # + unreadTotalProvider（派生）
    │       ├── pages/{messages_page,chat_detail_page}.dart
    │       └── widgets/{conversation_tile,message_bubble,chat_input_bar}.dart
    │
    └── profile/                        # → Tab 3「我的」
        ├── domain/
        │   ├── entities/user_profile.dart
        │   └── repositories/profile_repository.dart
        ├── data/
        │   ├── mock/mock_profile.dart
        │   └── repositories/mock_profile_repository.dart
        └── presentation/
            ├── providers/profile_providers.dart
            ├── pages/profile_page.dart
            └── widgets/{profile_header,settings_group,theme_mode_selector}.dart
```

### 依赖方向（单向，不允许反向）

```
features/*/presentation  →  domain  ←  data
        ↓                    ↓
      core                core
        ↓
       app  （组合根，可以认识所有 feature）
```

- `core/` 里**不允许**出现 `features/` 的 import；
- `domain/` 不依赖 Flutter，也不依赖 Riverpod（只有纯 Dart 类型 + 抽象接口）；
- `data/` 实现 `domain/` 的接口，依赖方向是 data → domain（依赖倒置）；
- `app/` 是唯一可以同时认识多个 feature 的地方。

## 关键实现说明

### 1. 底部导航：每个 Tab 独立的导航栈

`MainScaffold`（`lib/app/shell/main_scaffold.dart`）是 `StatefulShellRoute` 的 shell。
三个关键决策：

- **`extendBody: true`** —— 内容延伸到 Tab Bar 之后。没有它，毛玻璃背后是一片纯色，
  模糊等于白做。这是"模糊看起来没效果"最常见的原因。
- **底部安全区注入** —— 内容既然会滚到栏底下，就必须补回
  `TabBar 高度 + Home Indicator` 的留白。实现方式是在 shell 里改一次 `MediaQuery`，
  于是 `SafeArea` 与 `ListView` 自动读到，各页面**零改动**。
  注意用的是 `viewPadding` 而非 `padding`：`extendBody` 会把 body 的
  `padding.bottom` 置零，只有 `viewPadding` 保留了设备原始安全区。
- **半透明背景** —— `CupertinoTabBar` 检测到背景不透明就会自动挂 `BackdropFilter`。

会话详情页通过 `parentNavigatorKey` 挂到**根 Navigator**，因此它会整页盖住 Tab Bar
（HIG 标准行为），但路由栈依然归属"消息"分支。

### 2. 主题：语义化调色板挂载在 ThemeData.extensions 上

- 业务代码一律写 `context.palette.labelSecondary`，**不写** `isDark ? a : b`；
- 亮 / 暗切换时所有页面同步生效，不可能漏掉某个页面；
- 个人中心的「外观」分段控件就是这套架构的一致性测试。

### 3. 触觉反馈与点击回馈

`Pressable` 统一承担：按下缩放（`AnimatedScale`，按下 100ms / 回弹 180ms 的非对称时长）
+ 触觉（`AppHaptics` 把语义映射到强度）。`ThemeData.splashFactory` 已全局设为
`NoSplash`，彻底移除水波纹。

### 4. 乐观更新与本地优先

| 操作 | 策略 | 原因 |
| --- | --- | --- |
| 点赞 | 乐观更新 + 失败回滚 | 手指落下时红心就该亮，不能等 500ms |
| 已读角标 | 乐观更新 + 静默回滚 | 未读数字是用户最敏感的即时反馈 |
| 发消息 | 本地优先（`sending` 气泡） | 用户要立刻看到"我的话发出去了"，失败改为 `failed` 并可重试 |
| 发动态 | 乐观插入到队首 | 发完立刻在流里看到自己那条 |
| 改简介 | **不**乐观 | 表单提交的心智模型是"保存 → 等一下 → 成功" |

### 5. 500ms 延迟是设计的一部分

`AppConstants.mockLatency` 被所有 MockRepository 共享。刻意保留这段延迟，
是为了让 loading / 骨架屏 / 乐观更新这些 UX 分支在开发期就真实可见 ——
把延迟改成 `Duration.zero` 之后再去补骨架屏，通常就来不及了。

## 换成真实后端时

只需要新增 `data/repositories/http_*_repository.dart` 实现同名 domain 接口，
然后改一行 provider：

```dart
final postRepositoryProvider = Provider<PostRepository>((ref) => HttpPostRepository(dio));
```

presentation 层与 domain 层**零改动**。测试同理，用
`ProviderScope(overrides: [postRepositoryProvider.overrideWithValue(FakePostRepository())])`。

## 下一步待办

- [ ] 动态详情页（`PostRepository.fetchById` 与 `PostCard.onTap` 已预留）
- [ ] 动态流分页加载（`fetchFeed(page:, pageSize:)` 已预留）
- [ ] 真实图片资源接入（替换点：`AppAvatar`、`_CoverPlaceholder`）
- [ ] `shared_preferences` 持久化 `themeModeProvider`
- [ ] 接入真实后端 + 登录态（`appRouterProvider` 加 `refreshListenable`）
- [ ] 开启 `riverpod_lint` + `custom_lint`（pubspec 里已留注释）
