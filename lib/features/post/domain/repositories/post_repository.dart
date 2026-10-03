import '../entities/post.dart';

/// 动态仓库**接口**（domain 层）。
///
/// 这是整个架构里最重要的一条契约：presentation 层只认识这个接口，
/// 完全不知道数据从哪来。带来的直接好处：
///  - 现在：`MockPostRepository`（内存 + 500ms 延迟）
///  - 以后：`HttpPostRepository`（Dio / retrofit），presentation 层零改动
///  - 测试：`FakePostRepository` 一行 override 注入，不需要任何网络与延迟
///
/// 注意返回类型是 `Future`，且**没有** `Result<T, Error>` 包装 —— 失败直接抛异常，
/// 由 `AsyncValue.guard` / `AsyncError` 统一承接。这是 Riverpod 的惯用法，
/// 比手写 Result 类型少一层心智负担。
abstract interface class PostRepository {
  /// 拉取动态流。分页参数现在就留出来，避免将来改签名波及全链路。
  Future<List<Post>> fetchFeed({int page = 0, int pageSize = 20});

  /// 拉取单条动态。
  Future<Post> fetchById(String postId);

  /// 切换点赞，返回**服务端权威**的那条动态。
  ///
  /// 为什么返回整个 Post 而不是 void：真实后端会把别人的点赞也计入，
  /// 返回值可以用来校正乐观更新造成的偏差。
  Future<Post> toggleLike(String postId);

  /// 发布一条动态，返回创建后的实体（带上了服务端生成的 id 与时间）。
  Future<Post> create({required String content, String? coverEmoji});
}
