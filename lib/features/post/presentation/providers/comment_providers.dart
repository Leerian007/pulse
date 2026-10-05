import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/riverpod/async_value_ext.dart';
import '../../data/repositories/mock_comment_repository.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import 'feed_providers.dart';

/// 评论仓库的注入点。换真实后端时只改这一行。
final Provider<CommentRepository> commentRepositoryProvider =
    Provider<CommentRepository>((ref) => MockCommentRepository());

/// 某条动态的评论列表（family）。
///
/// 泛型顺序是 `<Notifier, State, Arg>`；Notifier 的参数通过构造函数注入
/// （Riverpod 3 里已经没有 `FamilyAsyncNotifier` 这个类型了）。
class CommentsNotifier extends AsyncNotifier<List<Comment>> {
  CommentsNotifier(this.postId);

  final String postId;

  @override
  Future<List<Comment>> build() {
    return ref.read(commentRepositoryProvider).fetchComments(postId);
  }

  Future<void> refresh() async {
    final AsyncValue<List<Comment>> next =
        await AsyncValue.guard<List<Comment>>(
      () => ref.read(commentRepositoryProvider).fetchComments(postId),
    );
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  /// 发表评论。
  ///
  /// ## 为什么这里**不做乐观插入**（和点赞不一样）
  ///
  /// 点赞是"身份无关"的：谁点的、点的是哪条，本地全能拼出来，所以可以
  /// 先改 UI 再补请求。评论不行 —— 它需要一个 `Author`，而"我是谁"
  /// 属于数据层（服务端根据会话决定），presentation 层拼不出来。
  ///
  /// 硬要做乐观的话只有两条路，都是坏路：
  ///  ① 在 presentation 里 import `data/mock/mock_authors.dart` 拿种子用户
  ///     → 破坏分层，而且换成真实后端时这段代码立刻作废；
  ///  ② 自己造一个假的 `Author` 占位 → 用户会看到自己的评论顶着别人的头像。
  ///
  /// 所以退一步：等服务端返回后再插入。500ms 的等待由输入框的发送态承接，
  /// 用户知道"发出去了、在处理"。这也和 `FeedNotifier.publish` 的取舍一致 ——
  /// 发动态同样不是乐观的。
  Future<bool> add(String content) async {
    final String trimmed = content.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    try {
      final Comment created = await ref
          .read(commentRepositoryProvider)
          .addComment(postId: postId, content: trimmed);

      // await 之后 provider 可能已被销毁，Riverpod 3 下必须守卫。
      if (!ref.mounted) {
        return true;
      }

      final List<Comment> latest = state.dataOrNull ?? const <Comment>[];
      state = AsyncData<List<Comment>>(
        List<Comment>.unmodifiable(<Comment>[created, ...latest]),
      );

      // 评论存在另一个仓库里，动态上的评论数得手动同步。
      ref.read(feedProvider.notifier).bumpCommentCount(postId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 评论点赞：**乐观更新 + 失败回滚**。
  ///
  /// 和 `FeedNotifier.toggleLike` 是同一套写法，连注释里的坑都一样：
  /// 所有 `await` 之后的分支都要先过 `ref.mounted`，
  /// 否则 provider 被销毁时会抛 `UnmountedRefException`。
  Future<bool> toggleLike(String commentId) async {
    final List<Comment>? snapshot = state.dataOrNull;
    if (snapshot == null) {
      return false;
    }

    // 1) 先改 UI。
    state = AsyncData<List<Comment>>(
      _mapOne(snapshot, commentId, (Comment c) => c.toggleLike()),
    );

    try {
      // 2) 再走"网络"。
      final Comment authoritative =
          await ref.read(commentRepositoryProvider).toggleLike(commentId);

      if (!ref.mounted) {
        return false;
      }

      // 3) 用服务端返回值校正。
      final List<Comment>? latest = state.dataOrNull;
      if (latest != null) {
        state = AsyncData<List<Comment>>(
          _mapOne(latest, authoritative.id, (Comment _) => authoritative),
        );
      }
      return true;
    } catch (_) {
      // 回滚。
      if (ref.mounted) {
        state = AsyncData<List<Comment>>(snapshot);
      }
      return false;
    }
  }

  /// 不可变地替换列表中的某一条。
  static List<Comment> _mapOne(
    List<Comment> comments,
    String commentId,
    Comment Function(Comment comment) update,
  ) {
    return List<Comment>.unmodifiable(<Comment>[
      for (final Comment comment in comments)
        if (comment.id == commentId) update(comment) else comment,
    ]);
  }
}

/// 某条动态的评论列表。
///
/// 这里刻意不写变量的显式类型：family provider 的具体类型名属于实现细节，
/// 交给类型推断既更短，也不会因为 Riverpod 版本升级而失配。
final commentsProvider =
    AsyncNotifierProvider.family<CommentsNotifier, List<Comment>, String>(
  CommentsNotifier.new,
);
