import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// iOS 的"毛玻璃"容器：高斯模糊 + 半透明着色 + 可选细描边 + 微渐变投影。
///
/// ## 关键前提：模糊的是"背后已经画好的内容"
///
/// `BackdropFilter` 只能模糊**它自己身后**的图层。所以：
///  - 如果它背后是一层纯色背景，模糊之后看起来和普通半透明**毫无区别**
///    （这是最常见的"毛玻璃没效果"的误解来源）；
///  - 要让模糊真正可见，容器必须覆盖在**有内容**的区域之上，例如
///    `Scaffold(extendBody: true)` 让列表能滚到底部栏后面
///    （`MainScaffold` 就是这么做的）。
///
/// 另外 `BackdropFilter` 必须有裁剪边界，否则模糊会向四周溢出 ——
/// 传入 [borderRadius] 时本组件会自动 `ClipRRect`。
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.blur = 24,
    this.tint,
    this.borderRadius,
    this.border,
    this.shadows,
    this.padding,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;

  /// 模糊半径（sigma）。iOS 的 bar 大约 20～30，卡片浮层用 12～20。
  final double blur;

  /// 着色层。默认取 `context.palette.glass`（亮色 72% 白 / 深色 78% 黑）。
  final Color? tint;

  final BorderRadius? borderRadius;

  final Border? border;

  /// 微渐变投影，传 `AppShadows.floating` 之类。
  final List<BoxShadow>? shadows;

  final EdgeInsetsGeometry? padding;

  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final BorderRadius? radius = borderRadius;

    Widget surface = BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint ?? palette.glass,
          borderRadius: radius,
          border: border,
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );

    if (shadows != null && shadows!.isNotEmpty) {
      // 阴影必须画在模糊层**外面**：放进 BackdropFilter 里会被一起糊掉，
      // 结果就是"没有阴影"。
      surface = DecoratedBox(
        decoration: BoxDecoration(borderRadius: radius, boxShadow: shadows),
        child: surface,
      );
    }

    if (radius != null) {
      surface = ClipRRect(
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: surface,
      );
    }

    // 隔离重绘：否则背后内容每次滚动都会重算整棵子树的高斯模糊。
    return RepaintBoundary(child: surface);
  }
}
