import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_provider.dart';
import '../core/widgets/apple_scroll_behavior.dart';
import 'router/app_router.dart';

/// App 根组件。
///
/// 它的职责只有"装配"，不含任何业务逻辑：
///  - 从 Riverpod 取路由与外观模式；
///  - 把 [AppTheme.light] / [AppTheme.dark] 交给 `MaterialApp.router`；
///  - 注入 [AppleScrollBehavior]（全平台橡皮筋回弹）与本地化代理。
///
/// 三层职责边界：
///  - `app/`（组合根）：认识所有 feature，负责装配；
///  - `core/`：基础设施，**不认识任何 feature**；
///  - `features/*`：业务模块，只认识 `core/` 和自己的 domain。
class PulseApp extends ConsumerWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ── 主题 ──
      // theme / darkTheme 都是「完整的 ThemeData」，包含 Material 与 Cupertino
      // 两套配置（后者通过 ThemeData.cupertinoOverrideTheme 挂载），
      // 所以 SliverNavigationBar / TabBar / RefreshControl 都会自动跟随。
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      // ── 路由 ──
      routerConfig: router,

      // ── 全局滚动行为：橡皮筋回弹 + 内容不足一屏时也能下拉刷新 ──
      scrollBehavior: const AppleScrollBehavior(),

      // ── 状态栏 ──
      // 用 builder 而不是 main() 里设一次：只有在这里才能读到
      // "解析后"的主题亮度（跟随系统时是系统值，不是 ThemeMode.system）。
      builder: (BuildContext context, Widget? child) {
        final Brightness brightness = Theme.of(context).brightness;
        final bool isDark = brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            // 透明状态栏，让大标题页面的毛玻璃一直延伸到屏幕顶端。
            statusBarColor: Colors.transparent,
            // Android 用 iconBrightness，iOS 用 statusBarBrightness 且语义相反：
            // 深色主题 → 白色图标；浅色主题 → 深色图标。
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: brightness,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },

      // ── 本地化 ──
      // 必须显式加上 Cupertino 的代理：MaterialApp 默认**不**提供
      // `CupertinoLocalizations`，而 CupertinoSliverNavigationBar /
      // CupertinoTextField 都会去读它（"返回"的提示语、文本框菜单等）。
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      // 不写死 locale：跟随系统。只有中文时才用中文，其余回落到英文。
    );
  }
}
