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
    this.peerAvatarUrl,
    this.peerEmoji,
    this.unreadCount = 0,
    this.isOnline = false,
    this.muted = false,
  });

  final String id;

  final String peerName;

  final String peerHandle;

  /// 对方头像地址。为 `null` 时回落到 [peerEmoji] 的渐变占位。
  ///
  /// ⚠️ 已知的模型瑕疵：`peerName` / `peerHandle` / `peerAvatarUrl` /
  /// `peerEmoji` 这四个字段其实是 `Author` 的**重复存储**，
  /// 理想形态是像 `ConversationModel.targetUser` 那样持有一个用户对象。
  /// 现在这样是为了不改动 `chat` 对 `post` 的依赖方向（feature 之间不能互相 import）。
  /// 真要治本，应该把用户实体提到 `core/domain/` 双方共用 —— 那是独立的一次重构。
  final String? peerAvatarUrl;

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

  /// 是否有真实头像可加载。
  bool get hasPeerAvatar =>
      peerAvatarUrl != null && peerAvatarUrl!.isNotEmpty;

  Conversation copyWith({
    String? id,
    String? peerName,
    String? peerHandle,
    String? peerAvatarUrl,
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
      peerAvatarUrl: peerAvatarUrl ?? this.peerAvatarUrl,
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
        other.peerAvatarUrl == peerAvatarUrl &&
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
        peerAvatarUrl,
        peerEmoji,
        lastMessage,
        lastMessageAt,
        unreadCount,
        isOnline,
        muted,
      );

  @override
  String toString() =>
      'Conversation($id, $peerName, unread=$unreadCount, avatar=${hasPeerAvatar ? "yes" : "no"})';
}
