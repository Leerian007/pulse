import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/entities/message.dart';

/// 聊天气泡。
///
/// 左右不对称的圆角（[AppRadius.bubbleMine] / [AppRadius.bubbleOther]）
/// 是"指向发送者"的视觉暗示：靠近自己那一侧的角收小。
///
/// 配色遵循 HIG：
///  - 自己：accent 实底 + 白字；
///  - 对方：浅色浮起面 + 主文字（不用灰色，灰色会读成"禁用"）。
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onRetry,
  });

  final Message message;

  /// 仅在 `status == failed` 时有意义。
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isMine = message.isMine;
    final bool failed = message.status == MessageStatus.failed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 1),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          // 气泡最大占屏宽 72% —— 太宽会失去"对话"的感觉，太窄会频繁折行。
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md + 2,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: isMine
                    ? (failed ? palette.danger : palette.accent)
                    : palette.surfaceRaised,
                borderRadius: isMine ? AppRadius.bubbleMine : AppRadius.bubbleOther,
                boxShadow: isMine
                    ? null
                    : AppShadows.cardFor(palette.brightness),
              ),
              child: Text(
                message.text,
                style: AppTypography.body.copyWith(
                  color: isMine ? Colors.white : palette.label,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _MetaLine(message: message, onRetry: onRetry),
        ],
      ),
    );
  }
}

/// 气泡下方的元信息：时间 + 投递状态。
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.message, this.onRetry});

  final Message message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool failed = message.status == MessageStatus.failed;

    final Widget status = switch (message.status) {
      MessageStatus.sending => Text(
          '发送中…',
          style: AppTypography.caption2.copyWith(color: palette.labelTertiary),
        ),
      MessageStatus.sent => Text(
          '已发送',
          style: AppTypography.caption2.copyWith(color: palette.labelTertiary),
        ),
      MessageStatus.read => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '已读',
              style: AppTypography.caption2.copyWith(color: palette.accent),
            ),
          ],
        ),
      MessageStatus.failed => Pressable(
          onTap: onRetry,
          scale: 0.94,
          borderRadius: AppRadius.xsAll,
          child: Text(
            '发送失败，点击重试',
            style: AppTypography.caption2.copyWith(
              color: palette.danger,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            formatClock(message.sentAt),
            style: AppTypography.caption2.copyWith(color: palette.labelTertiary),
          ),
          if (message.isMine) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            status,
          ],
          if (failed) const SizedBox(width: 0),
        ],
      ),
    );
  }
}
