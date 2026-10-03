/// Pulse 设计系统唯一入口。
///
/// 业务代码**只需要** import 这一个文件，就能拿到颜色、间距、字号、投影、
/// 亮暗主题 —— 通过下面的 `export` 统一转发，避免每个 widget 里堆一串 import：
///
/// ```dart
/// import 'package:learning_flutter/core/theme/app_theme.dart';
/// // 之后 AppPalette / AppSpacing / AppRadius / AppTypography / AppShadows /
/// // context.palette 全部可用。
/// ```
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_palette.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

/// App 主题装配。
///
/// 设计目标：**以 Cupertino 为骨架、以 Material 3 为血肉**。
/// 换句话说，视觉与手感来自 HIG（留白、hairline、毛玻璃、连续圆角），
/// 但底层仍然用 M3 的 `ColorScheme` / widget 体系，以便继续使用
/// Material 生态里那些没有 Cupertino 对应物的组件。
abstract final class AppTheme {
  /// 全平台统一使用 iOS 的页面转场（新页从右侧滑入 + 旧页轻微左移视差）。
  ///
  /// 这是"Apple 感"里最容易被漏掉、但用户感知最强的一环：
  /// 如果转场是 Android 的淡入 + 上移，前面所有视觉工作都会被削弱。
  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
    },
  );

  /// 亮色主题（冷灰白底 + 深灰文字 + iOS 蓝）。
  static final ThemeData light = _build(AppPalette.light);

  /// 深色主题（纯黑底 + 高对比白字 + 提亮版 iOS 蓝）。
  static final ThemeData dark = _build(AppPalette.dark);

  /// 按亮度取主题，方便 `themeMode` 之外的自定义分支使用。
  static ThemeData of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  static ThemeData _build(AppPalette palette) {
    // 用 fromSeed 打底，保证 M3 那 40 多个 color role 都有合理取值，
    // 再把关键 role 覆盖成我们的 token —— 这样既不会漏字段，也完全可控。
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: palette.brightness,
    ).copyWith(
      primary: palette.accent,
      onPrimary: CupertinoColors.white,
      secondary: palette.accent,
      surface: palette.surface,
      onSurface: palette.label,
      surfaceContainerLowest: palette.canvas,
      surfaceContainerHighest: palette.surfaceRaised,
      outlineVariant: palette.separator,
      error: palette.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: scheme,

      // ── 底色 ──
      scaffoldBackgroundColor: palette.canvas,
      canvasColor: palette.canvas,

      // ── 点击反馈 ──
      // 水波纹是 Material 的签名，和 HIG 的"轻微缩放 + 触觉"直接冲突。
      // 这里彻底关掉它，所有点击反馈交给 `Pressable` 统一处理。
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,

      visualDensity: VisualDensity.standard,

      // ── 字体 ──
      textTheme: AppTypography.textTheme(
        primary: palette.label,
        secondary: palette.labelSecondary,
        tertiary: palette.labelTertiary,
      ),

      // ── 转场 ──
      pageTransitionsTheme: _pageTransitions,

      // ── 细分割线 ──
      dividerTheme: DividerThemeData(
        color: palette.separator,
        thickness: 0.5,
        space: 0.5,
      ),

      // ── 导航栏 ──
      // 刻意做成全透明 + 无投影：真正的 iOS 导航栏是"内容滚到它后面才显形"，
      // 这个行为由页面里的 `CupertinoSliverNavigationBar` 负责，
      // 这里的配置是为了让少数用 MaterialAppBar 的页面不至于突兀。
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.label,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: AppTypography.headline.copyWith(color: palette.label),
        iconTheme: IconThemeData(color: palette.accent, size: 22),
      ),

      // ── 底部弹层（iOS sheet 观感）──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surfaceRaised,
        modalBackgroundColor: palette.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: palette.labelTertiary,
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),

      // ── 列表项 ──
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        minLeadingWidth: 24,
        iconColor: palette.labelSecondary,
        textColor: palette.label,
        titleTextStyle: AppTypography.body.copyWith(color: palette.label),
        subtitleTextStyle:
            AppTypography.subheadline.copyWith(color: palette.labelSecondary),
      ),

      iconTheme: IconThemeData(color: palette.labelSecondary, size: 22),

      // ── 让所有 Cupertino 组件（SliverNavigationBar / TabBar /
      //    RefreshControl / TextField / SlidingSegmentedControl）
      //    自动继承同一套配色，不需要在每个使用处手动传色 ──
      //
      // 刻意**不**传 CupertinoTextThemeData：Cupertino 组件自带的
      // 字号阶梯本身就是按 SF Pro 设计的，比我们手写一套更准。
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: palette.brightness,
        primaryColor: palette.accent,
        scaffoldBackgroundColor: palette.canvas,
        barBackgroundColor: palette.glass,
      ),

      // ── 挂上语义化调色板，业务侧用 `context.palette` 读取 ──
      extensions: <ThemeExtension<dynamic>>[palette],
    );
  }

  /// 阴影 token 的便捷入口，省掉一个 import。
  static List<BoxShadow> cardShadow(Brightness brightness) =>
      AppShadows.cardFor(brightness);

  /// 供调试 / 设计走查：把当前主题的关键 token 打出来。
  static String describe(AppPalette palette) {
    final String mode = palette.isDark ? 'Dark' : 'Light';
    return '$mode · accent=${palette.accent} · canvas=${palette.canvas}';
  }
}
