import '../entities/conversation.dart';
import '../entities/message.dart';

/// 会话与消息仓库接口（domain 层）。
///
/// 会话列表和消息列表放在同一个仓库里，是因为它们共享同一份"服务端"状态：
/// 发一条消息会同时改变消息列表和会话列表的摘要 / 未读数。
/// 拆成两个仓库反而需要额外的事件同步机制。
abstract interface class ChatRepository {
  /// 拉取会话列表（按最后消息时间倒序）。
  Future<List<Conversation>> fetchConversations();

  /// 拉取某个会话的全部消息（按时间正序）。
  Future<List<Message>> fetchMessages(String conversationId);

  /// 发送消息。返回服务端确认后的实体。
  Future<Message> sendMessage({
    required String conversationId,
    required String text,
  });

  /// 把会话标记为已读。
  Future<Conversation> markAsRead(String conversationId);
}
