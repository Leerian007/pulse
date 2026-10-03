import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pressable.dart';

/// 空态 / 错误态的统一视图。
///
/// 为什么不用 Material 的 `AlertDialog` 或裸 `Text`：
///  - iOS 的空态是**居中的大图标 + 一行标题 + 一句淡灰说明**，
///    层级和正文完全一致（复用 AppTypography），不能各写各的；
///  - 错误态必须给出**可执行的出口**（重试按钮），而不是一句"出错了"。
class AppStatusView extends StatelessWidget {
  const AppStatusView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;

  final String title;

  final String? message;

  /// 有出口时传入，例如 "重试" / "去逛逛"。
  final String? actionLabel;

  final VoidCallback? onAction;

  /// 紧凑模式：用于列表内部的一块区域，而不是整页。
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: compact ? 36 : 48,
              color: palette.labelTertiary,
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(color: palette.label),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTypography.subheadline.copyWith(color: palette.labelSecondary),
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              Pressable(
                onTap: onAction,
                scale: 0.94,
                borderRadius: AppRadius.pillAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppTypography.buttonLabel.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
