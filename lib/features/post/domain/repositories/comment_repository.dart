import '../entities/comment.dart';

/// 评论仓库**接口**（domain 层）。
///
/// 和 `PostRepository` 一样，presentation 层只认识这个接口：
///  - 现在：`MockCommentRepository`（内存 + 延迟）
///  - 以后：`HttpCommentRepository`，presentation 零改动
///
/// 失败一律抛异常，不返回 `Result<T, E>` —— 由 `AsyncValue.guard` 统一承接。
abstract interface class CommentRepository {
  /// 拉取某条动态的评论。
  ///
  /// 排序约定：**按时间正序（最早在前）**。
  ///
  /// 为什么不用"最新在前"：评论常常是**互相回应**的
  /// （见 `mock_comments.dart` 里 p_007 的三条 —— 一个提问、一个追问、一个回答）。
  /// 最新在前会把这个对话读反，逻辑就断了。
  /// UI 侧应该像聊天一样滚动到底部，而不是把新评论顶到顶部。
  ///
  /// 已知简化：分页目前是"从头切"，所以翻页拿的是更早的评论。
  /// 正确的形态是游标分页 + 取最后一页，真实后端接入时再改。
  Future<List<Comment>> fetchComments(
    String postId, {
    int page = 0,
    int pageSize = 20,
  });

  /// 发表评论，返回带上服务端 id 与时间的实体。
  Future<Comment> addComment({
    required String postId,
    required String content,
  });

  /// 切换某条评论的点赞状态，返回权威结果。
  Future<Comment> toggleLike(String commentId);
}
