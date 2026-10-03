import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/riverpod/async_value_ext.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/app_status_view.dart';
import '../../../../core/widgets/hairline_divider.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/entities/conversation.dart';
import '../providers/chat_providers.dart';
import '../widgets/conversation_tile.dart';

/// 消息（Tab 2）。
///
/// 和动态流共用同一套 sliver 结构，保证两个 Tab 的标题行为完全一致
/// （大标题随滚动收起、收起后毛玻璃渐显）。
class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Conversation>> asyncConversations =
        ref.watch(conversationsProvider);
    final ConversationsNotifier notifier = ref.read(conversationsProvider.notifier);
    final AppPalette palette = context.palette;

    final List<Conversation> conversations =
        asyncConversations.dataOrNull ?? const <Conversation>[];

    return ColoredBox(
      color: palette.canvas,
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            largeTitle: const Text('消息'),
            backgroundColor: palette.glass,
            trailing: Pressable(
              onTap: () => AppHaptics.light(),
              scale: 0.88,
              borderRadius: AppRadius.pillAll,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Icon(
                  CupertinoIcons.pencil,
                  size: 22,
                  color: palette.accent,
                ),
              ),
            ),
          ),

          CupertinoSliverRefreshControl(
            onRefresh: notifier.refresh,
          ),

          ..._buildBody(context: context, ref: ref, state: asyncConversations, conversations: conversations),
        ],
      ),
    );
  }

  List<Widget> _buildBody({
    required BuildContext context,
    required WidgetRef ref,
    required AsyncValue<List<Conversation>> state,
    required List<Conversation> conversations,
  }) {
    if (state.isInitialLoading) {
      // 会话行的骨架屏：保持与真实行一致的 72 高度，避免布局跳动。
      return <Widget>[
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => const _ConversationSkeleton(),
            childCount: 6,
          ),
        ),
      ];
    }

    if (state.isInitialError) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppStatusView(
            icon: CupertinoIcons.exclamationmark_circle,
            title: '没能加载消息',
            message: '检查一下网络，然后重试。',
            actionLabel: '重试',
            onAction: () => ref.invalidate(conversationsProvider),
          ),
        ),
      ];
    }

    if (conversations.isEmpty) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppStatusView(
            icon: CupertinoIcons.chat_bubble,
            title: '还没有对话',
            message: '在动态里找感兴趣的人聊聊吧。',
          ),
        ),
      ];
    }

    return <Widget>[
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final Conversation conversation = conversations[index];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ConversationTile(
                  conversation: conversation,
                  onTap: () => context.goNamed(
                    AppRoutes.chatDetailName,
                    // 路径参数与 GoRoute 里的 `:conversationId` 对应。
                    // 参数名用常量，避免路由定义与跳转处拼写漂移。
                    pathParameters: <String, String>{
                      AppRoutes.conversationIdParam: conversation.id,
                    },
                  ),
                ),
                // 分割线缩进到文字起始位置（头像 52 + 左右内边距），
                // 这是 iOS 列表的标志性细节。
                if (index != conversations.length - 1)
                  const HairlineDivider(
                    indent: AppSpacing.screenH + 52 + AppSpacing.md,
                  ),
              ],
            );
          },
          childCount: conversations.length,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
    ];
  }
}

/// 会话行的骨架屏。
class _ConversationSkeleton extends StatelessWidget {
  const _ConversationSkeleton();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      height: ConversationTile.height,
      color: palette.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Row(
        children: <Widget>[
          AppSkeleton(width: 52, height: 52, radius: AppRadius.pill),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AppSkeleton(width: 88, height: 14),
                const SizedBox(height: AppSpacing.sm),
                AppSkeleton(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
