import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_skeleton.dart';

/// 动态卡片的骨架屏。
///
/// 关键点是**尺寸必须和真实 [PostCard] 一致**（同样的内边距、同样的头像直径、
/// 同样的行高、同样的圆角）。否则数据到达的瞬间布局会发生跳动，
/// 骨架屏反而变成了负优化。
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({
    super.key,
    this.withCover = false,
    this.phase = 0,
  });

  /// 是否画出配图区域的占位。
  final bool withCover;

  /// 相位偏移，让多张骨架屏的高光带错开。
  final double phase;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.cardAll,
        boxShadow: AppShadows.cardFor(palette.brightness),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 作者行
          Row(
            children: <Widget>[
              AppSkeleton(
                width: 42,
                height: 42,
                radius: AppRadius.pill,
                phase: phase,
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppSkeleton(width: 92, height: 14, phase: phase),
                  const SizedBox(height: AppSpacing.sm),
                  AppSkeleton(width: 132, height: 11, phase: phase),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // 正文三行
          AppSkeleton(height: 14, phase: phase),
          const SizedBox(height: AppSpacing.sm),
          AppSkeleton(height: 14, phase: phase),
          const SizedBox(height: AppSpacing.sm),
          AppSkeleton(width: 180, height: 14, phase: phase),
          if (withCover) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            AspectRatio(
              aspectRatio: 16 / 10,
              child: AppSkeleton(
                height: double.infinity,
                radius: AppRadius.md,
                phase: phase,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          // 操作栏
          Row(
            children: <Widget>[
              AppSkeleton(width: 48, height: 12, phase: phase),
              const SizedBox(width: AppSpacing.lg),
              AppSkeleton(width: 48, height: 12, phase: phase),
              const SizedBox(width: AppSpacing.lg),
              AppSkeleton(width: 48, height: 12, phase: phase),
            ],
          ),
        ],
      ),
    );
  }
}
