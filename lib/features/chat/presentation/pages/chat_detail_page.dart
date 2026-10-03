import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/riverpod/async_value_ext.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_status_view.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';

/// 聊天详情页。
///
/// 它在路由树里是"消息"分支的子路由，但 `parentNavigatorKey` 指向**根 Navigator**，
/// 所以在 iOS 上表现为**整页盖住底部 Tab Bar** —— 这是 HIG 的标准行为：
/// 进入对话时底栏应该消失，让位给输入栏。
class ChatDetailPage extends ConsumerStatefulWidget {
  const ChatDetailPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  @override
  void initState() {
    super.initState();
    // 进入会话即清未读。
    //
    // 放在 postFrameCallback 里，是为了避开"在 build/idle 阶段修改 provider"
    // 的时序问题（initState 期间 widget 树还没稳定）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(conversationsProvider.notifier)
          .markAsRead(widget.conversationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    final List<Conversation> conversations =
        ref.watch(conversationsProvider).dataOrNull ?? const <Conversation>[];
    final Conversation? conversation = _findConversation(conversations);

    final AsyncValue<List<Message>> thread =
        ref.watch(chatMessagesProvider(widget.conversationId));
    final List<Message> messages = thread.dataOrNull ?? const <Message>[];

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Column(
        children: <Widget>[
          _ChatHeader(
            conversation: conversation,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: _buildThreadBody(thread: thread, messages: messages),
          ),
        ],
      ),
      // Scaffold 会在键盘弹起时把 bottomNavigationBar 顶上去，
      // 于是输入栏"跟着键盘走"这个行为不需要手写。
      // 底部安全区由 ChatInputBar 自己处理。
      bottomNavigationBar: ChatInputBar(
        onSend: (String text) => ref
            .read(chatMessagesProvider(widget.conversationId).notifier)
            .send(text),
      ),
    );
  }

  Widget _buildThreadBody({
    required AsyncValue<List<Message>> thread,
    required List<Message> messages,
  }) {
    if (thread.isInitialLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 12));
    }

    if (thread.isInitialError) {
      return AppStatusView(
        icon: CupertinoIcons.exclamationmark_circle,
        title: '没能加载对话',
        message: '网络似乎不太稳定。',
        actionLabel: '重试',
        onAction: () => ref.invalidate(chatMessagesProvider(widget.conversationId)),
      );
    }

    if (messages.isEmpty) {
      return const AppStatusView(
        icon: CupertinoIcons.chat_bubble,
        title: '还没有消息',
        message: '打个招呼吧。',
        compact: true,
      );
    }

    return ListView.builder(
      // reverse: true 让列表从底部开始排布：新消息天然贴在输入栏上方，
      // 既不需要 ScrollController 手动滚到底，也不用担心插入时的跳动。
      reverse: true,
      // 键盘弹起时把内容顶上去，避免最后一条消息被键盘挡住。
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int index) {
        // reverse 之后 index 是反的，这里换算回真实顺序。
        final Message message = messages[messages.length - 1 - index];
        return MessageBubble(
          message: message,
          onRetry: message.status == MessageStatus.failed
              ? () => ref
                  .read(chatMessagesProvider(widget.conversationId).notifier)
                  .retry(message)
              : null,
        );
      },
    );
  }

  Conversation? _findConversation(List<Conversation> list) {
    for (final Conversation conversation in list) {
      if (conversation.id == widget.conversationId) {
        return conversation;
      }
    }
    return null;
  }
}

/// 聊天页顶栏：返回 + 居中标题（昵称 / 在线状态）。
///
/// 用 [Stack] 而不是 `Row` + `Expanded`：标题必须在**绝对居中**的位置
/// （和 iOS 的导航栏一致），而 Row 会被左侧按钮的宽度挤偏。
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.conversation, required this.onBack});

  final Conversation? conversation;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double ratio = MediaQuery.devicePixelRatioOf(context);
    final double topInset = MediaQuery.paddingOf(context).top;

    final String title = conversation?.peerName ?? '对话';
    final String subtitle = conversation == null
        ? ''
        : (conversation!.isOnline ? '在线' : '最近活跃');

    return GlassSurface(
      blur: 24,
      border: Border(
        bottom: BorderSide(color: palette.separator, width: 1 / ratio),
      ),
      padding: EdgeInsets.only(top: topInset),
      child: SizedBox(
        height: AppSpacing.navBarHeight,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // 居中标题
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.headline.copyWith(color: palette.label),
                ),
                if (subtitle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 1),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (conversation?.isOnline ?? false) ...<Widget>[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.online,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        subtitle,
                        style: AppTypography.caption2.copyWith(
                          color: palette.labelSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            // 左侧返回
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Pressable(
                  onTap: () {
                    AppHaptics.light();
                    onBack();
                  },
                  scale: 0.9,
                  borderRadius: AppRadius.pillAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          CupertinoIcons.back,
                          size: 22,
                          color: palette.accent,
                        ),
                        Text(
                          '消息',
                          style: AppTypography.callout.copyWith(
                            color: palette.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
