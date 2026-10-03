import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../mock/mock_chats.dart';

/// [ChatRepository] 的内存实现。
///
/// 关键点是**会话列表与消息线程共享同一份状态**：
/// `sendMessage` 会同时写入线程、更新会话摘要与未读数 ——
/// 这样"在详情页发消息 → 返回列表看到新摘要"这条链路才是通的。
/// 如果两个仓库各自持有一份数据，这种一致性就会在 Mock 阶段被掩盖，
/// 等接真实后端时才暴露出来。
class MockChatRepository implements ChatRepository {
  MockChatRepository({Duration? latency}) : _latency = latency ?? AppConstants.mockLatency;

  final Duration _latency;

  late final List<Conversation> _conversations = buildSeedConversations();

  late final Map<String, List<Message>> _threads = buildSeedThreads();

  int _seq = 0;

  @override
  Future<List<Conversation>> fetchConversations() async {
    await _delay();
    // 真实服务端会按最后消息时间排序，这里保持一致。
    final List<Conversation> sorted = <Conversation>[..._conversations]
      ..sort((Conversation a, Conversation b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return List<Conversation>.unmodifiable(sorted);
  }

  @override
  Future<List<Message>> fetchMessages(String conversationId) async {
    await _delay();
    return List<Message>.unmodifiable(_threadOf(conversationId));
  }

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    await _delay();

    _seq++;
    final Message message = Message(
      id: 'm_local_$_seq',
      conversationId: conversationId,
      text: text,
      isMine: true,
      sentAt: DateTime.now(),
      status: MessageStatus.sent,
    );

    _threadOf(conversationId).add(message);

    // 同步更新会话摘要（真实后端也是这么做的）。
    final int index = _conversations.indexWhere(
      (Conversation c) => c.id == conversationId,
    );
    if (index >= 0) {
      _conversations[index] = _conversations[index].copyWith(
        lastMessage: text,
        lastMessageAt: message.sentAt,
        unreadCount: 0,
      );
    }

    return message;
  }

  @override
  Future<Conversation> markAsRead(String conversationId) async {
    // 已读回执是"发完就不管"的轻请求，用一半延迟更接近真实体感。
    await Future<void>.delayed(_latency ~/ 2);

    final int index = _conversations.indexWhere(
      (Conversation c) => c.id == conversationId,
    );
    if (index < 0) {
      throw StateError('Conversation not found: $conversationId');
    }
    final Conversation updated = _conversations[index].markRead();
    _conversations[index] = updated;
    return updated;
  }

  /// 取线程；没有预置对话时按需生成一段通用短对话。
  List<Message> _threadOf(String conversationId) {
    return _threads.putIfAbsent(conversationId, () {
      final Conversation? conversation = _findConversation(conversationId);
      if (conversation == null) {
        throw StateError('Conversation not found: $conversationId');
      }
      return buildMockThread(conversationId, conversation);
    });
  }

  Conversation? _findConversation(String conversationId) {
    for (final Conversation conversation in _conversations) {
      if (conversation.id == conversationId) {
        return conversation;
      }
    }
    return null;
  }

  Future<void> _delay() => Future<void>.delayed(_latency);
}
