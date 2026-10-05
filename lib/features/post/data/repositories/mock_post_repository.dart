import '../../../../core/constants/app_constants.dart';
import '../../../../core/mock/mock_data_service.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../mock/mock_authors.dart';
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

  /// "我是谁"在 Mock 里就是一个常量。
  ///
  /// 换成真实后端时这里会变成"从内存里的 session 读用户"，
  /// 而**接口签名不变** —— 这正是把它做成同步 getter 的意义。
  @override
  Author get currentAuthor => currentUser;

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
  Future<Post> create({
    required String content,
    List<String> images = const <String>[],
    List<String> topics = const <String>[],
    String? coverEmoji,
  }) async {
    await _delay();

    _seq++;
    final Post post = Post(
      // 走 `MockDataService.localId` 而不是 `'p_$_seq'`：同一微秒内连续发两条
      // 也不会撞 id（时间戳 + 序号双保险），而且 id 里的 `_local_` 片段能在
      // 日志里一眼认出"这条是本地生成的"。
      id: MockDataService.localId('p', seq: _seq),
      author: currentUser,
      content: content,
      createdAt: DateTime.now(),
      // 复制一份而不是直接引用调用方传进来的列表：面板里的 `_images` 是可变的，
      // 直接共享引用会让"发布完之后继续往草稿里加图"悄悄改掉已经发出去的动态。
      images: List<String>.unmodifiable(images),
      topics: List<String>.unmodifiable(topics),
      coverEmoji: coverEmoji,
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
