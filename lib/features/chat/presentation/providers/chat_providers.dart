import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/riverpod/async_value_ext.dart';
import '../../data/repositories/mock_chat_repository.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

/// 会话仓库的注入点。
final Provider<ChatRepository> chatRepositoryProvider =
    Provider<ChatRepository>((ref) => MockChatRepository());

/// 会话列表。
class ConversationsNotifier extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() {
    return ref.read(chatRepositoryProvider).fetchConversations();
  }

  Future<void> refresh() async {
    final AsyncValue<List<Conversation>> next =
        await AsyncValue.guard<List<Conversation>>(
      () => ref.read(chatRepositoryProvider).fetchConversations(),
    );
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  /// 标记已读。
  ///
  /// 未读角标是**用户最敏感的即时反馈**之一：点进会话后角标必须马上消失，
  /// 不能等 250ms 的"已读回执"回来。所以这里同样先改 UI 再补请求。
  Future<void> markAsRead(String conversationId) async {
    final List<Conversation>? snapshot = state.dataOrNull;
    if (snapshot == null) {
      return;
    }

    // 乐观更新：先用本地 `markRead()` 把角标清零，不等服务端。
    // 注意 `markRead` 是**实例方法**，这里传的是闭包而不是 tear-off。
    state = AsyncData<List<Conversation>>(
      _mapOne(snapshot, conversationId, (Conversation c) => c.markRead()),
    );

    try {
      final Conversation updated =
          await ref.read(chatRepositoryProvider).markAsRead(conversationId);

      // await 之后 provider 可能已被销毁，Riverpod 3 下必须守卫。
      if (!ref.mounted) {
        return;
      }

      final List<Conversation>? latest = state.dataOrNull;
      if (latest != null) {
        state = AsyncData<List<Conversation>>(
          _mapOne(latest, updated.id, (Conversation _) => updated),
        );
      }
    } catch (_) {
      // 失败就恢复角标。属于"可以静默失败"的操作，不打断用户。
      if (ref.mounted) {
        state = AsyncData<List<Conversation>>(snapshot);
      }
    }
  }

  static List<Conversation> _mapOne(
    List<Conversation> items,
    String id,
    Conversation Function(Conversation conversation) update,
  ) {
    return List<Conversation>.unmodifiable(<Conversation>[
      for (final Conversation item in items)
        if (item.id == id) update(item) else item,
    ]);
  }
}

/// 会话列表。
final AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>
    conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>(
  ConversationsNotifier.new,
);

/// 未读总数（用于底部 Tab 的角标）。
///
/// 这是一个**派生 provider**：它不持有状态，只从 [conversationsProvider]
/// 算出来。好处是角标永远不会和列表不同步 —— 不需要任何"手动通知"。
///
/// 注意：`MainScaffold` 会 watch 它，因此会话列表在 App 启动时就被拉取了，
/// 角标不需要等用户切到消息 Tab 才出现。
final Provider<int> unreadTotalProvider = Provider<int>((ref) {
  final List<Conversation> conversations =
      ref.watch(conversationsProvider).dataOrNull ?? const <Conversation>[];
  return conversations.fold<int>(
    0,
    // 免打扰的会话不计入角标。
    (int sum, Conversation c) => c.muted ? sum : sum + c.unreadCount,
  );
});

/// 某个会话的消息线程（family）。
///
/// `AsyncNotifierProvider.family` 的泛型顺序是 `<Notifier, State, Arg>`，
/// 而 Notifier 本身在 Riverpod 3 里已经统一 —— 不再有 `FamilyAsyncNotifier`，
/// 参数改为通过构造函数注入（见 [ChatMessagesNotifier.conversationId]）。
///
/// 默认 `isAutoDispose = false`：退出会话页后线程会留在缓存里。
/// 对 Mock 阶段来说这是好事（再进去不用重新等 500ms）；
/// 真实项目里应该加上自动释放，避免长会话列表把内存吃满。
class ChatMessagesNotifier extends AsyncNotifier<List<Message>> {
  ChatMessagesNotifier(this.conversationId);

  final String conversationId;

  @override
  Future<List<Message>> build() {
    return ref.read(chatRepositoryProvider).fetchMessages(conversationId);
  }

  Future<void> refresh() async {
    final AsyncValue<List<Message>> next = await AsyncValue.guard<List<Message>>(
      () => ref.read(chatRepositoryProvider).fetchMessages(conversationId),
    );
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  /// 发送消息：本地优先。
  ///
  /// 1. 立刻插入一条 `sending` 气泡 —— 用户看到自己的话"发出去了"；
  /// 2. "网络"回来后替换成服务端确认的实体；
  /// 3. 失败则把该气泡标成 `failed`（UI 会显示重试入口），
  ///    **不清空输入框**，也不回滚掉用户已经看到的内容。
  Future<void> send(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final List<Message> snapshot = state.dataOrNull ?? const <Message>[];

    _seq++;
    final Message pending = Message(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}_$_seq',
      conversationId: conversationId,
      text: trimmed,
      isMine: true,
      sentAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    state = AsyncData<List<Message>>(
      List<Message>.unmodifiable(<Message>[...snapshot, pending]),
    );

    try {
      final Message confirmed = await ref
          .read(chatRepositoryProvider)
          .sendMessage(conversationId: conversationId, text: trimmed);

      _swap(pending.id, (Message _) => confirmed);

      // 会话列表的摘要 / 排序 / 未读也要跟着变。
      // 直接 refresh 一次，让 mock 服务端重算排序 —— 真实项目里这一步
      // 应该由服务端的推送或本地增量更新完成。
      if (ref.mounted) {
        unawaited(ref.read(conversationsProvider.notifier).refresh());
      }
    } catch (_) {
      _swap(pending.id, (Message m) => m.copyWith(status: MessageStatus.failed));
    }
  }

  /// 重发失败的消息。
  Future<void> retry(Message message) async {
    _swap(message.id, (Message m) => m.copyWith(status: MessageStatus.sending));
    try {
      final Message confirmed = await ref
          .read(chatRepositoryProvider)
          .sendMessage(conversationId: conversationId, text: message.text);
      _swap(message.id, (Message _) => confirmed);
      if (ref.mounted) {
        unawaited(ref.read(conversationsProvider.notifier).refresh());
      }
    } catch (_) {
      _swap(message.id, (Message m) => m.copyWith(status: MessageStatus.failed));
    }
  }

  int _seq = 0;

  /// 不可变地就地替换一条消息。
  ///
  /// 入口处统一守 `ref.mounted`：这是所有"await 之后回写状态"的唯一通道，
  /// 把守卫放在这里比在每个调用点重复写更不容易漏。
  void _swap(String messageId, Message Function(Message message) update) {
    // Riverpod 3：provider 被销毁后再碰 `state` / `ref` 会抛
    // `UnmountedRefException`，必须显式守卫。
    if (!ref.mounted) {
      return;
    }
    final List<Message>? latest = state.dataOrNull;
    if (latest == null) {
      return;
    }
    state = AsyncData<List<Message>>(
      List<Message>.unmodifiable(<Message>[
        for (final Message m in latest)
          if (m.id == messageId) update(m) else m,
      ]),
    );
  }
}

/// 某个会话的消息线程。
///
/// 这里刻意**不写**变量的显式类型：family provider 的具体类型名
/// （`AsyncNotifierProviderFamily<Notifier, State, Arg>`）属于实现细节，
/// 交给类型推断既更短，也不会因为 Riverpod 的版本升级而失配。
final chatMessagesProvider =
    AsyncNotifierProvider.family<ChatMessagesNotifier, List<Message>, String>(
  ChatMessagesNotifier.new,
);
