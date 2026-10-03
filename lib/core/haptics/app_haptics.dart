import 'package:flutter/services.dart';

/// 触觉反馈的统一入口。
///
/// 为什么不在每个按钮里直接写 `HapticFeedback.lightImpact()`？
/// 1. 强度选择会失控 —— A 页面用 light、B 页面用 medium，手感就不一致了；
/// 2. 没法一键关闭（无障碍设置、桌面端、电池省电模式都应该能关）；
/// 3. 直接调用在 Web / 桌面端会抛出 `MissingPluginException`。
///
/// 所以这里把"**语义**"映射到"**强度**"，业务侧只描述意图：
/// ```dart
/// AppHaptics.selection(); // 切 Tab、点赞
/// AppHaptics.light();     // 普通按钮
/// AppHaptics.medium();    // 长按、发送
/// AppHaptics.heavy();     // 破坏性操作
/// ```
abstract final class AppHaptics {
  /// 全局开关。设置页可以把它接到用户偏好上，无障碍场景下应该允许关闭。
  static bool enabled = true;

  /// 选择反馈：最轻的一档。
  ///
  /// 用于 Tab 切换、点赞、开关翻转 —— 这些操作**频次极高**，
  /// 一旦用了 lightImpact 就会显得"吵"。
  static void selection() => _safe(HapticFeedback.selectionClick);

  /// 轻击（`HapticFeedback.lightImpact()`）。普通按钮、卡片点击。
  static void light() => _safe(HapticFeedback.lightImpact);

  /// 中击。需要一点"分量"的操作：长按菜单、发送消息、下拉刷新触发。
  static void medium() => _safe(HapticFeedback.mediumImpact);

  /// 重击。破坏性操作与错误提示（删除、退出登录失败）。
  static void heavy() => _safe(HapticFeedback.heavyImpact);

  /// 统一兜底：
  ///  - 全局开关关闭时直接跳过；
  ///  - 平台没有触觉马达（Web / Windows / Linux）时静默忽略。
  ///
  /// 刻意**不 await**：触觉反馈不应该阻塞任何 UI 逻辑。
  static void _safe(Future<void> Function() action) {
    if (!enabled) {
      return;
    }
    try {
      action();
    } catch (_) {
      // 平台不支持触觉反馈时静默忽略，不影响任何交互。
    }
  }
}
