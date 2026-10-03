import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 骨架屏色块。
///
/// Mock Repository 有 500ms 的模拟延迟，这段时间**不要**只放一个转圈：
/// iOS 的做法是画出内容的大致轮廓（骨架屏），让"即将出现的布局"提前可见，
/// 感知等待时间会明显变短，也不会出现"转圈 → 内容突现"的跳动。
///
/// 高光带用 3 段渐变 + 滑动的 [Alignment] 实现，不需要 `Matrix4` 变换。
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.sm,
    this.phase = 0,
  });

  /// 为空时撑满可用宽度。
  final double? width;

  final double height;

  final double radius;

  /// 相位偏移（0～1）。多个骨架块传不同相位，高光带会错开，看起来更"活"。
  final double phase;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDuration.breathe,
  );

  @override
  void initState() {
    super.initState();
    _controller
      ..value = widget.phase
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color base = palette.fill;
    // 深色模式下"提亮"要靠白，浅色模式下也要靠白 —— 但幅度差很多，
    // 浅色底上 10% 的白根本看不出高光。
    final Color highlight = palette.isDark
        ? Color.lerp(base, Colors.white, 0.10)!
        : Color.lerp(base, Colors.white, 0.85)!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              // 用 3 段渐变做出"一条宽度约为控件 1/3 的高光带"。
              // Alignment 的 -1/1 对应控件的左右边缘，所以下面这个
              // begin→end 跨度（2 个单位）刚好等于控件宽度。
              begin: Alignment(-2.5 + 5 * t, 0),
              end: Alignment(-0.5 + 5 * t, 0),
              colors: <Color>[base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}
