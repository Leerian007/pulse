import 'package:flutter/foundation.dart';

/// 消息投递状态。
///
/// `sending` / `failed` 的存在是**本地优先（local-first）**设计的必然结果：
/// 先把消息以 `sending` 塞进列表，用户立刻看到自己发出的气泡，
/// 网络回包后再改成 `sent` / `failed`。这和点赞的乐观更新是同一个思路。
enum MessageStatus {
  /// 本地已入队，等待"网络"。
  sending,

  /// 已被"服务端"接收。
  sent,

  /// 对方已读。
  read,

  /// 发送失败，UI 需要给出重试入口。
  failed,
}

/// 一条消息。
@immutable
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.isMine,
    required this.sentAt,
    this.status = MessageStatus.sent,
  });

  final String id;

  final String conversationId;

  final String text;

  /// 是否由当前登录用户发出。决定气泡的左右与配色。
  final bool isMine;

  final DateTime sentAt;

  final MessageStatus status;

  Message copyWith({
    String? id,
    String? conversationId,
    String? text,
    bool? isMine,
    DateTime? sentAt,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      text: text ?? this.text,
      isMine: isMine ?? this.isMine,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Message &&
        other.id == id &&
        other.conversationId == conversationId &&
        other.text == text &&
        other.isMine == isMine &&
        other.sentAt == sentAt &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(id, conversationId, text, isMine, sentAt, status);

  @override
  String toString() => 'Message($id, mine=$isMine, status=$status)';
}
