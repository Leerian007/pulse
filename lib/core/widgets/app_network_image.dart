import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 网络图片，**自带加载态与失败兜底**。
///
/// ## 为什么必须有这个组件，而不是到处写 `Image.network`
///
/// 三个理由，任何一个都足以让它值得存在：
///
///  1. **测试安全**：`flutter test` 里的 `HttpClient` 会对所有网络请求返回
///     400，即"图片一定加载失败"。没有 `errorBuilder` 时 Flutter 会把异常
///     抛进 `FlutterError.onError`，直接把 widget 测试搞挂。
///  2. **无跳变**：加载中显示 [fallback]（而不是空白），图片到位后直接替换。
///     用同一套占位做"加载中"和"加载失败"，视觉上不会闪两下。
///  3. **统一策略**：以后要换成磁盘缓存（`cached_network_image`），
///     只改这一个文件，全站生效。
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallback,
    this.width,
    this.height,
  });

  final String url;

  final BoxFit fit;

  /// 加载中与加载失败时显示的占位。
  ///
  /// 调用方通常传"渐变 + Emoji"之类**本身看起来就完整**的东西，
  /// 这样即使图永远加载不出来，界面也不像坏了。
  final Widget? fallback;

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      // 加载中：progress 不为 null 表示还没出第一帧。
      loadingBuilder: (
        BuildContext context,
        Widget child,
        ImageChunkEvent? progress,
      ) {
        if (progress == null) {
          return child;
        }
        return _placeholder(context);
      },
      // 失败：URL 失效、断网、测试环境，全走这里。
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) {
        return _placeholder(context);
      },
    );
  }

  Widget _placeholder(BuildContext context) {
    if (fallback != null) {
      return fallback!;
    }
    final AppPalette palette = context.palette;
    return ColoredBox(
      color: palette.surfaceRaised,
      child: SizedBox(width: width, height: height),
    );
  }
}
