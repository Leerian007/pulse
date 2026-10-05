import '../../../../core/constants/app_constants.dart';
import '../../../../core/mock/mock_data_service.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../mock/mock_authors.dart';
import '../mock/mock_comments.dart';

/// [CommentRepository] 的内存实现。
///
/// 和 `MockPostRepository` 遵循同一套纪律：
///  - `_store` 是**每个实例独立**的可变状态（用 `late final` 而不是常量），
///    所以发完评论再重新拉取，评论还在 —— Mock 模拟的是"服务端记得住"；
///  - 每个方法都经过 [AppConstants.mockLatency]，让加载态分支在开发期被走到；
///  - 返回**不可变视图**，外部改不动"服务端数据"。
///
/// 换成真实后端时整个类被 `HttpCommentRepository` 替换，
/// `CommentRepository` 接口与所有调用方都不需要动。
class MockCommentRepository implements CommentRepository {
  MockCommentRepository({Duration? latency})
      : _latency = latency ?? AppConstants.mockLatency;

  final Duration _latency;

  /// `postId` → 该动态的评论（**按时间正序，最早在前**）。
  ///
  /// 用 Map 按动态分组，而不是一个扁平大列表：评论的查询维度天然
  /// 就是"某条动态下的评论"，分组存让 `fetchComments` 变成一次哈希查找
  /// 而不是全表扫描。
  late final Map<String, List<Comment>> _store = buildSeedComments();

  int _seq = 0;

  @override
  Future<List<Comment>> fetchComments(
    String postId, {
    int page = 0,
    int pageSize = 20,
  }) async {
    await _delay();

    final List<Comment> all = _store[postId] ?? const <Comment>[];

    final int start = page * pageSize;
    if (start >= all.length) {
      return const <Comment>[];
    }
    final int end =
        (start + pageSize) > all.length ? all.length : start + pageSize;

    return List<Comment>.unmodifiable(all.sublist(start, end));
  }

  @override
  Future<Comment> addComment({
    required String postId,
    required String content,
  }) async {
    await _delay();

    final String trimmed = content.trim();
    if (trimmed.isEmpty) {
      // 空评论是**客户端校验漏了**，属于编程错误而不是业务失败，
      // 所以抛 ArgumentError 而不是返回 null —— 让它尽早暴露。
      throw ArgumentError('评论内容不能为空');
    }

    _seq++;
    final Comment created = Comment(
      id: MockDataService.localId('c', seq: _seq),
      postId: postId,
      author: currentUser,
      content: trimmed,
      createdAt: DateTime.now(),
    );

    // 追加到**末尾**，与 `fetchComments` 的"时间正序"约定一致。
    // 用 putIfAbsent 是因为这条动态可能原本没有种子评论。
    _store.putIfAbsent(postId, () => <Comment>[]).add(created);
    return created;
  }

  @override
  Future<Comment> toggleLike(String commentId) async {
    await _delay();

    // 评论 id 全局唯一，所以按 id 找到即可，不需要调用方传 postId。
    // 代价是一次 O(所有评论数) 的扫描 —— 对 Mock 规模无所谓，
    // 真实后端这条会变成 `PATCH /comments/:id/like`，压根不需要索引。
    for (final List<Comment> list in _store.values) {
      final int index = list.indexWhere((Comment c) => c.id == commentId);
      if (index >= 0) {
        final Comment updated = list[index].toggleLike();
        list[index] = updated;
        return updated;
      }
    }
    throw StateError('Comment not found: $commentId');
  }

  /// 统一的"网络往返"，与其它 Mock 仓库一致，方便以后统一注入抖动。
  Future<void> _delay() => Future<void>.delayed(_latency);
}
