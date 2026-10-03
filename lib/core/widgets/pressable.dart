import 'package:flutter/material.dart';

import '../haptics/app_haptics.dart';
import '../theme/app_theme.dart';

/// iOS 风格的点击回馈容器。
///
/// 做两件事，缺一不可：
///  1. **轻微缩放** —— 按下时缩小到 `scale`，松手回弹。iOS 的"活着"的感觉
///     几乎全部来自这个细节；
///  2. **触觉反馈** —— 按下瞬间触发 `selectionClick`，点击时触发 `lightImpact`。
///
/// 没有水波纹（`ThemeData.splashFactory` 已在 `AppTheme` 里全局关掉）。
///
/// 用法：
/// ```dart
/// Pressable(
///   onTap: () => context.push('/post/1'),
///   child: PostCard(post: post),
/// )
/// ```
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
    this.borderRadius,
  });

  final Widget child;

  /// 为空时整个组件不可点击，也不会产生任何反馈。
  final VoidCallback? onTap;

  final VoidCallback? onLongPress;

  /// 按下时缩放到的比例。
  ///
  /// 经验值：整块大卡片用 `0.98`（缩小太多会显得廉价），
  /// 小图标按钮用 `0.90`～`0.94`。
  final double scale;

  /// 是否触发触觉反馈。可以按场景关掉（例如列表项密集的快速连点）。
  final bool haptic;

  final HitTestBehavior behavior;

  /// 配合圆角卡片使用时传入，保证缩放后的内容不溢出圆角。
  final BorderRadius? borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  void _onTapDown(TapDownDetails details) {
    _setPressed(true);
    if (widget.haptic) {
      AppHaptics.selection();
    }
  }

  void _onTapUp(TapUpDetails details) => _setPressed(false);

  void _onTapCancel() => _setPressed(false);

  void _onTap() {
    if (widget.haptic) {
      AppHaptics.light();
    }
    widget.onTap?.call();
  }

  void _onLongPress() {
    if (widget.haptic) {
      AppHaptics.medium();
    }
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = AnimatedScale(
      scale: _pressed ? widget.scale : 1,
      // 按下要"跟手"（instant），回弹可以稍慢一点（fast），
      // 这样才有"按下去 → 弹回来"的层次，而不是匀速缩放。
      duration: _pressed ? AppDuration.instant : AppDuration.fast,
      curve: AppCurves.emphasized,
      child: widget.child,
    );

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _enabled ? _onTapDown : null,
      onTapUp: _enabled ? _onTapUp : null,
      onTapCancel: _enabled ? _onTapCancel : null,
      onTap: widget.onTap == null ? null : _onTap,
      onLongPress: widget.onLongPress == null ? null : _onLongPress,
      child: widget.borderRadius == null
          ? content
          : ClipRRect(borderRadius: widget.borderRadius!, child: content),
    );
  }
}
