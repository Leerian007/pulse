import 'package:flutter/material.dart';

/// 字体与字号阶梯。
///
/// 字号、字重、**字距（tracking）** 三件套严格对齐 Apple HIG 的 Dynamic Type
/// 与 SF Pro 的官方 tracking 表。字距这一项最容易被忽略，但它恰恰是
/// "看起来像 iOS" 与 "看起来像套了 iOS 皮肤的 Android" 的分水岭：
///
///  - 小字号（<= 16pt）用**负**字距，让逐字排布更紧实；
///  - 大字号（>= 20pt）用**正**字距，避免字母粘连、提升可读性。
abstract final class AppTypography {
  /// 字体族兜底链。
  ///
  /// 这里刻意**不设置** `fontFamily`：不设置时 Flutter 会走平台默认字体，
  /// 在 iOS / iPadOS / macOS 上就是 San Francisco —— 这才是最正宗的 SF Pro，
  /// 而且是系统级优化过的字重映射。
  ///
  /// 这条 fallback 链是为了让 Android / Windows / Web 在**打包了 Inter 之后**
  /// 也能得到接近的观感（见 pubspec.yaml 中被注释的 fonts 段）。
  static const List<String> fontFallback = <String>[
    '.SF Pro Text',
    '.SF Pro Display',
    'SF Pro Text',
    'Inter',
    'Helvetica Neue',
    'Roboto',
  ];

  // MARK: - 与 iOS 一一对应的样式常量
  // 行高 = iOS 的设计行高 / 字号，Flutter 的 `height` 是倍数而非 px。

  /// Large Title · 34 / Bold · tracking +0.4
  ///
  /// 页面级大标题，通常交给 `CupertinoSliverNavigationBar` 随滚动收起。
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    height: 41 / 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    fontFamilyFallback: fontFallback,
  );

  /// Title 1 · 28 / Bold · tracking +0.36
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.36,
    fontFamilyFallback: fontFallback,
  );

  /// Title 2 · 22 / Bold · tracking +0.35
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.35,
    fontFamilyFallback: fontFallback,
  );

  /// Title 3 · 20 / Semibold · tracking +0.38
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    height: 25 / 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.38,
    fontFamilyFallback: fontFallback,
  );

  /// Headline · 17 / Semibold · tracking -0.41
  ///
  /// 用于卡片标题、列表主文案。和 [body] 同字号，只靠字重区分层次——
  /// 这是 Apple 非常典型的手法。
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    fontFamilyFallback: fontFallback,
  );

  /// Body · 17 / Regular · tracking -0.41
  ///
  /// 正文默认样式，也是动态流里帖子正文用的样式。
  static const TextStyle body = TextStyle(
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
    fontFamilyFallback: fontFallback,
  );

  /// Callout · 16 / Regular · tracking -0.32
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    height: 21 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
    fontFamilyFallback: fontFallback,
  );

  /// Subheadline · 15 / Regular · tracking -0.24
  ///
  /// 副标题（淡灰色），列表项的次要文案。
  static const TextStyle subheadline = TextStyle(
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
    fontFamilyFallback: fontFallback,
  );

  /// Footnote · 13 / Regular · tracking -0.08
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
    fontFamilyFallback: fontFallback,
  );

  /// Caption 1 · 12 / Regular · tracking 0
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    fontFamilyFallback: fontFallback,
  );

  /// Caption 2 · 11 / Regular · tracking +0.07
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    height: 13 / 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.07,
    fontFamilyFallback: fontFallback,
  );

  // MARK: - 特殊用途

  /// Tab Bar 的标签：10pt，比 caption2 更小，且刻意放宽字距。
  static const TextStyle tabLabel = TextStyle(
    fontSize: 10,
    height: 12 / 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    fontFamilyFallback: fontFallback,
  );

  /// 数字专用：等宽数字（tabular figures），
  /// 让点赞数从 9 → 10 时不会因为字符宽度变化而抖动。
  static const TextStyle tabularNumber = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.08,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    fontFamilyFallback: fontFallback,
  );

  /// 大字重的按钮文案。
  static const TextStyle buttonLabel = TextStyle(
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    fontFamilyFallback: fontFallback,
  );

  /// 生成带颜色的 [TextTheme]，供 `ThemeData` 使用。
  ///
  /// 三个颜色参数对应 iOS 的 label 三级层次，映射关系见 [AppColors] 的注释。
  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
    required Color tertiary,
  }) {
    return TextTheme(
      // display* 用大标题阶梯
      displayLarge: largeTitle.copyWith(color: primary),
      displayMedium: title1.copyWith(color: primary),
      displaySmall: title2.copyWith(color: primary),
      // headline* 用 Title3 / Headline
      headlineLarge: title3.copyWith(color: primary),
      headlineMedium: headline.copyWith(color: primary),
      headlineSmall: headline.copyWith(color: primary),
      // title* 承担卡片标题与列表主文案
      titleLarge: title2.copyWith(color: primary),
      titleMedium: headline.copyWith(color: primary),
      titleSmall: subheadline.copyWith(color: primary, fontWeight: FontWeight.w600),
      // body* 承担正文
      bodyLarge: body.copyWith(color: primary),
      bodyMedium: subheadline.copyWith(color: primary),
      bodySmall: footnote.copyWith(color: primary),
      // label* 用于按钮与表单标签
      labelLarge: buttonLabel.copyWith(color: primary),
      labelMedium: footnote.copyWith(color: secondary),
      labelSmall: caption2.copyWith(color: tertiary),
    );
  }
}
