/// 全站路由常量。
///
/// 路径与名字分开定义，是为了让「改路径」和「改引用点」解耦：
/// 跳转一律用 `context.goNamed(AppRoutes.xxxName, ...)`，
/// 于是调整 URL 结构时只需要改这个文件。
abstract final class AppRoutes {
  // ── 动态流 ──
  static const String feed = '/feed';
  static const String feedName = 'feed';

  // ── 消息 ──
  static const String messages = '/messages';
  static const String messagesName = 'messages';

  /// 会话详情。它是「消息」分支的**子路由**（相对路径，不带前导斜杠），
  /// 因此它的路由栈挂在消息这一支的 Navigator 上。
  static const String chatDetailSegment = ':conversationId';
  static const String chatDetailName = 'chatDetail';

  /// 路径参数名。路由定义与跳转必须用同一个常量，避免拼写漂移。
  static const String conversationIdParam = 'conversationId';

  /// 构造会话详情的绝对路径（deep link / 推送落地页用）。
  static String chatDetail(String conversationId) => '$messages/$conversationId';

  // ── 个人中心 ──
  static const String profile = '/profile';
  static const String profileName = 'profile';

  /// 底部三个 Tab 对应的根路由，顺序必须与 `MainScaffold` 的 items 一致。
  static const List<String> tabLocations = <String>[feed, messages, profile];
}
