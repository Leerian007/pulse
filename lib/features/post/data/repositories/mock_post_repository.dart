import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../mock/mock_posts.dart';

/// [PostRepository] 的内存实现。
///
/// 它模拟的是一个**有状态的服务端**，而不是"每次返回同一份常量"：
///  - `_store` 是可变列表，点赞会写到里面，所以下拉刷新之后状态还在；
///  - 每个方法都经过 `AppConstants.mockLatency`（500ms）延迟，
///    让 loading / 骨架屏 / 乐观更新这些分支在开发期就被真实覆盖到。
///
/// 换成真实后端时，这个类整体被 `HttpPostRepository` 替换，
/// `PostRepository` 接口与所有调用方都不需要改。
class MockPostRepository implements PostRepository {
  MockPostRepository({Duration? latency}) : _latency = latency ?? AppConstants.mockLatency;

  final Duration _latency;

  /// 用 `late final` 而非常量：让每条 PostRepository 实例拥有独立的可变状态，
  /// 测试之间不会互相污染。
  late final List<Post> _store = buildSeedPosts();

  int _seq = 0;

  @override
  Future<List<Post>> fetchFeed({int page = 0, int pageSize = 20}) async {
    await _delay();

    final int start = page * pageSize;
    if (start >= _store.length) {
      return const <Post>[];
    }
    final int end = (start + pageSize) > _store.length ? _store.length : start + pageSize;

    // 返回**不可变视图**：外部拿到的列表不能被改，
    // 否则 UI 层的任何误操作都会悄悄改掉"服务端数据"。
    return List<Post>.unmodifiable(_store.sublist(start, end));
  }

  @override
  Future<Post> fetchById(String postId) async {
    await _delay();
    return _findOrThrow(postId);
  }

  @override
  Future<Post> toggleLike(String postId) async {
    await _delay();

    final int index = _store.indexWhere((Post p) => p.id == postId);
    if (index < 0) {
      throw StateError('Post not found: $postId');
    }
    final Post updated = _store[index].toggleLike();
    _store[index] = updated;
    return updated;
  }

  @override
  Future<Post> create({required String content, String? coverEmoji}) async {
    await _delay();

    _seq++;
    final Post post = Post(
      id: 'p_local_$_seq',
      author: currentUser,
      content: content,
      createdAt: DateTime.now(),
      coverEmoji: coverEmoji,
      topics: const <String>['新动态'],
    );
    // 新发布的排在最前面，和真实信息流的排序一致。
    _store.insert(0, post);
    return post;
  }

  Post _findOrThrow(String postId) {
    for (final Post post in _store) {
      if (post.id == postId) {
        return post;
      }
    }
    throw StateError('Post not found: $postId');
  }

  /// 统一的"网络往返"。
  ///
  /// 单独抽出来的好处：以后想模拟 4G 抖动，只改这一处 ——
  /// 例如 `_latency + Duration(milliseconds: Random().nextInt(400))`。
  Future<void> _delay() => Future<void>.delayed(_latency);
}
