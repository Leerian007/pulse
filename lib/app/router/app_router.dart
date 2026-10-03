import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_status_view.dart';
import '../../features/chat/presentation/pages/chat_detail_page.dart';
import '../../features/chat/presentation/pages/messages_page.dart';
import '../../features/post/presentation/pages/feed_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../shell/main_scaffold.dart';
import 'app_routes.dart';

/// 全局路由器。
///
/// 用 Provider 包一层（而不是顶层 `final GoRouter router = ...`）带来两个好处：
///  - 生命周期跟随 `ProviderScope`，热重启 / 测试之间不会残留状态；
///  - 后续接入登录态时，只要在这里加 `refreshListenable` 或把
///    `redirect` 变成 watch 认证 provider 的闭包即可，UI 层零改动。
///
/// 注意：`app/` 作为**组合根**主动依赖各 feature 的页面，这是刻意的 ——
/// 路由表天生需要认识所有页面。`core/` 则不允许出现这种依赖。
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  // 每个分支一个 Navigator key：
  //  - `rootNavigatorKey` 给根 Navigator（详情页要挂到它上面）；
  //  - 其余三个是各 Tab 自己的栈。
  final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  final GlobalKey<NavigatorState> feedNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'feed');
  final GlobalKey<NavigatorState> messagesNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'messages');
  final GlobalKey<NavigatorState> profileNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'profile');

  final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.feed,
    // 只在 debug 下打印路由日志，正式包不带这层开销。
    debugLogDiagnostics: kDebugMode,
    routes: <RouteBase>[
      /// 三个 Tab = 三个分支。
      ///
      /// `indexedStack` 让三个分支同时保活（相当于 IndexedStack）：
      /// 切回来时滚动位置、列表状态、子页面全都还在。
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          // ── 分支 0：动态流 ──
          StatefulShellBranch(
            navigatorKey: feedNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.feed,
                name: AppRoutes.feedName,
                builder: (BuildContext context, GoRouterState state) =>
                    const FeedPage(),
              ),
            ],
          ),

          // ── 分支 1：消息 ──
          StatefulShellBranch(
            navigatorKey: messagesNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.messages,
                name: AppRoutes.messagesName,
                builder: (BuildContext context, GoRouterState state) =>
                    const MessagesPage(),
                routes: <RouteBase>[
                  GoRoute(
                    // 子路由用**相对路径**（不带前导 `/`），
                    // 于是完整路径自动是 `/messages/:conversationId`。
                    path: AppRoutes.chatDetailSegment,
                    name: AppRoutes.chatDetailName,
                    // ★ 关键：把详情页挂到**根** Navigator 上。
                    //   这样它会整页盖住底部 Tab Bar（HIG 的标准行为），
                    //   但路由栈依然归属"消息"分支 —— 切走再切回来还在。
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (BuildContext context, GoRouterState state) {
                      return ChatDetailPage(
                        conversationId: state
                            .pathParameters[AppRoutes.conversationIdParam]!,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // ── 分支 2：个人中心 ──
          StatefulShellBranch(
            navigatorKey: profileNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.profile,
                name: AppRoutes.profileName,
                builder: (BuildContext context, GoRouterState state) =>
                    const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // 根路径兜底：直接进动态流。
      GoRoute(
        path: '/',
        redirect: (BuildContext context, GoRouterState state) => AppRoutes.feed,
      ),
    ],

    // 失败的深链 / 未知路径给一个像样的页面，而不是默认的红色报错屏。
    errorBuilder: (BuildContext context, GoRouterState state) =>
        _RouteErrorScreen(location: state.uri.toString()),
  );

  ref.onDispose(router.dispose);
  return router;
});

/// 路由错误页。
class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: AppStatusView(
          icon: Icons.explore_off,
          title: '页面不存在',
          message: '找不到这条路径：\n$location',
          actionLabel: '回到动态',
          onAction: () => context.go(AppRoutes.feed),
        ),
      ),
    );
  }
}
