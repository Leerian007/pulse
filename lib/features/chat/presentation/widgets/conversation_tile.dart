import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/entities/conversation.dart';

/// 会话列表的一行。
///
/// 布局对应 iOS Messages 的行结构：头像（带在线点）→ 昵称 + 消息摘要 →
/// 时间 + 未读角标。摘要永远单行省略，所以整行高度是**恒定**的 72 ——
/// 这一点很重要，否则列表滚动时高度抖动会非常显眼。
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    this.onTap,
  });

  final Conversation conversation;
  final VoidCallback? onTap;

  /// 行高恒定，供列表项复用。
  static const double height = 72;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Pressable(
      onTap: onTap,
      scale: 0.985,
      child: Container(
        height: height,
        color: palette.surface,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: Row(
          children: <Widget>[
            AppAvatar(
              seed: conversation.id,
              imageUrl: conversation.peerAvatarUrl,
              emoji: conversation.peerEmoji,
              size: 52,
              showOnlineDot: true,
              isOnline: conversation.isOnline,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          conversation.peerName,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headline.copyWith(color: palette.label),
                        ),
                      ),
                      if (conversation.muted) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '免打扰',
                          style: AppTypography.caption2.copyWith(
                            color: palette.labelTertiary,
                          ),
                        ),
                      ],
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        formatConversationTime(conversation.lastMessageAt),
                        style: AppTypography.footnote.copyWith(
                          color: palette.labelTertiary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        CupertinoIcons.chevron_forward,
                        size: 12,
                        color: palette.labelTertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs + 1),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.subheadline.copyWith(
                            // 有未读时摘要加深，形成"这条还没看"的视觉暗示。
                            color: conversation.hasUnread
                                ? palette.label
                                : palette.labelSecondary,
                          ),
                        ),
                      ),
                      if (conversation.hasUnread) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        UnreadBadge(count: conversation.unreadCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
