import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 平台自适应的滚动行为。
///
/// 三件事：
///  1. 全平台使用 `BouncingScrollPhysics` —— iOS 的"橡皮筋"回弹，
///     Android 默认的 `Clamping` 发光效果在 HIG 语境里是不存在的；
///  2. 叠加 `AlwaysScrollableScrollPhysics`，保证内容不足一屏时
///     依然能下拉刷新（否则 `CupertinoSliverRefreshControl` 会失灵）；
///  3. 放开鼠标/触控板拖拽，让桌面端也能用"按住拖动"的方式滚动。
class AppleScrollBehavior extends MaterialScrollBehavior {
  const AppleScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
