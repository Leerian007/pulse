import 'package:flutter/foundation.dart';

/// 会话（消息列表里的一行）。
@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.peerName,
    required this.peerHandle,
    required this.lastMessage,
    required this.lastMessageAt,
    this.peerEmoji,
    this.unreadCount = 0,
    this.isOnline = false,
    this.muted = false,
  });

  final String id;

  final String peerName;

  final String peerHandle;

  final String? peerEmoji;

  /// 最后一条消息的摘要。真实项目里这里通常是 `Message?`，
  /// 但摘要文本由服务端算好能显著减少列表的渲染成本 —— 所以保留纯文本。
  final String lastMessage;

  final DateTime lastMessageAt;

  final int unreadCount;

  final bool isOnline;

  /// 免打扰。
  final bool muted;

  bool get hasUnread => unreadCount > 0;

  Conversation copyWith({
    String? id,
    String? peerName,
    String? peerHandle,
    String? peerEmoji,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isOnline,
    bool? muted,
  }) {
    return Conversation(
      id: id ?? this.id,
      peerName: peerName ?? this.peerName,
      peerHandle: peerHandle ?? this.peerHandle,
      peerEmoji: peerEmoji ?? this.peerEmoji,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      muted: muted ?? this.muted,
    );
  }

  /// 已读：清零未读数。
  Conversation markRead() => unreadCount == 0 ? this : copyWith(unreadCount: 0);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Conversation &&
        other.id == id &&
        other.peerName == peerName &&
        other.peerHandle == peerHandle &&
        other.peerEmoji == peerEmoji &&
        other.lastMessage == lastMessage &&
        other.lastMessageAt == lastMessageAt &&
        other.unreadCount == unreadCount &&
        other.isOnline == isOnline &&
        other.muted == muted;
  }

  @override
  int get hashCode => Object.hash(
        id,
        peerName,
        peerHandle,
        peerEmoji,
        lastMessage,
        lastMessageAt,
        unreadCount,
        isOnline,
        muted,
      );

  @override
  String toString() => 'Conversation($id, $peerName, unread=$unreadCount)';
}
