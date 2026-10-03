import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

/// 会话与消息的 Mock 种子数据。
///
/// 时间一律相对 `now` 计算，保证演示/截图时显示的永远是"3 分钟前"。
List<Conversation> buildSeedConversations({DateTime? now}) {
  final DateTime anchor = now ?? DateTime.now();

  return <Conversation>[
    Conversation(
      id: 'c_lin',
      peerName: '林深',
      peerHandle: 'linshen',
      peerEmoji: '🦊',
      lastMessage: '那个桌面的照片我存下来了，谢谢',
      lastMessageAt: anchor.subtract(const Duration(minutes: 3)),
      unreadCount: 2,
      isOnline: true,
    ),
    Conversation(
      id: 'c_an',
      peerName: '阿南',
      peerHandle: 'anan',
      peerEmoji: '🌿',
      lastMessage: '柠檬树今年应该还能再结一批',
      lastMessageAt: anchor.subtract(const Duration(minutes: 47)),
      unreadCount: 1,
      isOnline: true,
    ),
    Conversation(
      id: 'c_zhou',
      peerName: '周迟',
      peerHandle: 'zhouchi',
      peerEmoji: '🐳',
      lastMessage: '你说得对，骨架屏确实比转圈好',
      lastMessageAt: anchor.subtract(const Duration(hours: 4)),
    ),
    Conversation(
      id: 'c_qi',
      peerName: '祁七',
      peerHandle: 'qiqi',
      peerEmoji: '🪐',
      lastMessage: '清单我整理好了，回头发你',
      lastMessageAt: anchor.subtract(const Duration(days: 1, hours: 2)),
      unreadCount: 5,
    ),
    Conversation(
      id: 'c_mu',
      peerName: '木也',
      peerHandle: 'muye',
      peerEmoji: '☕️',
      lastMessage: '下次带你喝一支浅烘的',
      lastMessageAt: anchor.subtract(const Duration(days: 2, hours: 5)),
      muted: true,
    ),
    Conversation(
      id: 'c_shen',
      peerName: '沈迟',
      peerHandle: 'shenchi',
      peerEmoji: '🎧',
      lastMessage: '歌单链接发你了',
      lastMessageAt: anchor.subtract(const Duration(days: 6)),
    ),
  ];
}

/// 消息线程。
///
/// 只给前两个会话写了完整对话；其余会话在 [buildMockThread] 里生成一段
/// 通用的短对话，避免 Mock 数据文件膨胀得不可读。
Map<String, List<Message>> buildSeedThreads({DateTime? now}) {
  final DateTime anchor = now ?? DateTime.now();

  return <String, List<Message>>{
    'c_lin': <Message>[
      Message(
        id: 'm_lin_1',
        conversationId: 'c_lin',
        text: '看到你那条关于"留白也是生产力"的动态了',
        isMine: false,
        sentAt: anchor.subtract(const Duration(minutes: 22)),
      ),
      Message(
        id: 'm_lin_2',
        conversationId: 'c_lin',
        text: '真的是。我之前一直以为是自律问题，其实是环境问题。',
        isMine: true,
        sentAt: anchor.subtract(const Duration(minutes: 18)),
        status: MessageStatus.read,
      ),
      Message(
        id: 'm_lin_3',
        conversationId: 'c_lin',
        text: '对，环境一改，行为自动就变了，根本不用"坚持"',
        isMine: false,
        sentAt: anchor.subtract(const Duration(minutes: 12)),
      ),
      Message(
        id: 'm_lin_4',
        conversationId: 'c_lin',
        text: '话说你那张桌面的照片拍得挺好的，构图很干净',
        isMine: true,
        sentAt: anchor.subtract(const Duration(minutes: 6)),
        status: MessageStatus.read,
      ),
      Message(
        id: 'm_lin_5',
        conversationId: 'c_lin',
        text: '那个桌面的照片我存下来了，谢谢',
        isMine: false,
        sentAt: anchor.subtract(const Duration(minutes: 3)),
      ),
    ],
    'c_an': <Message>[
      Message(
        id: 'm_an_1',
        conversationId: 'c_an',
        text: '柠檬树终于结果了！',
        isMine: true,
        sentAt: anchor.subtract(const Duration(hours: 1, minutes: 20)),
        status: MessageStatus.read,
      ),
      Message(
        id: 'm_an_2',
        conversationId: 'c_an',
        text: '恭喜！十四个月也太久了',
        isMine: false,
        sentAt: anchor.subtract(const Duration(hours: 1, minutes: 5)),
      ),
      Message(
        id: 'm_an_3',
        conversationId: 'c_an',
        text: '柠檬树今年应该还能再结一批',
        isMine: false,
        sentAt: anchor.subtract(const Duration(minutes: 47)),
      ),
    ],
  };
}

/// 给没有预置对话的会话生成一段通用短线程。
///
/// 所有时间都从 [Conversation.lastMessageAt] 反推，**不读 `DateTime.now()`** ——
/// 这样只要入参不变，生成结果就是确定的，便于写断言与快照测试。
List<Message> buildMockThread(String conversationId, Conversation conversation) {
  return <Message>[
    Message(
      id: '${conversationId}_m1',
      conversationId: conversationId,
      text: '在吗？',
      isMine: false,
      sentAt: conversation.lastMessageAt.subtract(const Duration(minutes: 9)),
    ),
    Message(
      id: '${conversationId}_m2',
      conversationId: conversationId,
      text: '刚看到消息，怎么啦',
      isMine: true,
      sentAt: conversation.lastMessageAt.subtract(const Duration(minutes: 5)),
      status: MessageStatus.read,
    ),
    Message(
      id: '${conversationId}_m3',
      conversationId: conversationId,
      text: conversation.lastMessage,
      isMine: false,
      sentAt: conversation.lastMessageAt,
    ),
  ];
}
