import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/riverpod/async_value_ext.dart';
import '../../data/repositories/mock_post_repository.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';

/// 仓库的注入点。
///
/// 业务代码永远只读这个 provider，**不要**直接 `new MockPostRepository()`。
/// 好处有两个：
///  - 换实现只改这一行（Mock → HTTP）；
///  - 测试或预览里可以一行覆盖：
///    ```dart
///    ProviderScope(
///      overrides: <Override>[
///        postRepositoryProvider.overrideWithValue(FakePostRepository()),
///      ],
///      child: const PulseApp(),
///    );
///    ```
final Provider<PostRepository> postRepositoryProvider =
    Provider<PostRepository>((ref) => MockPostRepository());

/// 动态流状态机。
///
/// 用 `AsyncNotifier` 而不是 `FutureProvider`：因为除了"读"，还需要"写"——
/// 点赞（乐观更新 + 回滚）和发布（插入到队首）都是副作用，
/// `FutureProvider` 表达不了。
class FeedNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() {
    return ref
        .read(postRepositoryProvider)
        .fetchFeed(pageSize: AppConstants.feedPageSize);
  }

  /// 当前列表。用模式匹配取值，见 `async_value_ext.dart` 里的说明。
  List<Post>? get _current => state.dataOrNull;

  /// 下拉刷新 / 重试。
  ///
  /// 刻意**不**先把 state 置成 `AsyncLoading`：那会让列表闪一下白屏。
  /// `CupertinoSliverRefreshControl` 自己会转圈，旧数据继续显示直到新数据到达 ——
  /// 这是 iOS 的标准行为，也是"不让人等"的关键。
  Future<void> refresh() async {
    final AsyncValue<List<Post>> next = await AsyncValue.guard<List<Post>>(
      () => ref
          .read(postRepositoryProvider)
          .fetchFeed(pageSize: AppConstants.feedPageSize),
    );
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  /// 点赞：乐观更新 + 失败回滚。
  ///
  /// 返回是否成功。调用方可以据此决定要不要弹一个轻提示，
  /// 但**不要**因为一次点赞失败就把整页切成错误态 ——
  /// 信息流的可用性比单条点赞的一致性重要得多。
  Future<bool> toggleLike(String postId) async {
    final List<Post>? snapshot = _current;
    if (snapshot == null) {
      // 列表都还没加载出来，忽略这次点击。
      return false;
    }

    // 1) 先改 UI：手指落下时红心就该亮起，而不是等 500ms 网络回来才动。
    state = AsyncData<List<Post>>(_mapOne(snapshot, postId, (Post p) => p.toggleLike()));

    try {
      // 2) 再走"网络"。
      final Post authoritative = await ref.read(postRepositoryProvider).toggleLike(postId);

      // Riverpod 3 的硬性纪律：`await` 之后 provider 可能已经被销毁
      // （例如期间列表被 invalidate）。此时再读 `state` / 用 `ref` 会抛
      // `UnmountedRefException`，所以必须先守一次 `ref.mounted`。
      if (!ref.mounted) {
        return false;
      }

      // 3) 用服务端返回值校正（真实后端可能把别人的点赞也计入了）。
      final List<Post>? latest = _current;
      if (latest != null) {
        state = AsyncData<List<Post>>(
          _mapOne(latest, authoritative.id, (Post _) => authoritative),
        );
      }
      return true;
    } catch (_) {
      // 回滚到点击之前。
      if (ref.mounted) {
        state = AsyncData<List<Post>>(snapshot);
      }
      return false;
    }
  }

  /// 发布新动态。成功后插到队首，用户能立刻在流里看到自己刚发的内容。
  Future<Post?> publish({required String content, String? coverEmoji}) async {
    try {
      final Post created = await ref
          .read(postRepositoryProvider)
          .create(content: content, coverEmoji: coverEmoji);

      if (!ref.mounted) {
        return created;
      }

      final List<Post>? latest = _current;
      if (latest != null) {
        state = AsyncData<List<Post>>(<Post>[created, ...latest]);
      }
      return created;
    } catch (_) {
      return null;
    }
  }

  /// 评论数增减。
  ///
  /// 评论存在**另一个仓库**（`CommentRepository`）里，所以动态的
  /// `commentCount` 不会自己跟着变，需要显式同步一次。
  ///
  /// 为什么把这个方法放在 feed 这边、而不是让两个仓库互相持有：
  /// 跨仓库的一致性属于**业务编排**，放在 Notifier 层是明账；
  /// 让 `MockCommentRepository` 去改 `MockPostRepository` 则会让 data 层
  /// 互相认识，绕开依赖倒置，换真实后端时两边都得改。
  ///
  /// 只改本地数字，不产生网络请求 —— `commentCount` 是服务端算好的展示值，
  /// 下一次拉取时会拿到准确数字。
  void bumpCommentCount(String postId, {int delta = 1}) {
    final List<Post>? latest = _current;
    if (latest == null) {
      // 动态流还没加载出来，没有可同步的对象，静默返回。
      return;
    }

    state = AsyncData<List<Post>>(
      _mapOne(latest, postId, (Post post) {
        final int next = post.commentCount + delta;
        // 与 `Post.toggleLike` 同样的下限保护。
        return post.copyWith(commentCount: next < 0 ? 0 : next);
      }),
    );
  }

  /// 不可变地替换列表中的某一条。
  ///
  /// 统一返回 `List.unmodifiable`：Riverpod 3 用 `==` 过滤更新，
  /// 而 `List` 的 `==` 是引用比较 —— 每次新建列表保证变更一定会被感知到，
  /// 同时防止外部代码持有并篡改状态里的列表。
  static List<Post> _mapOne(
    List<Post> posts,
    String postId,
    Post Function(Post post) update,
  ) {
    return List<Post>.unmodifiable(<Post>[
      for (final Post post in posts)
        if (post.id == postId) update(post) else post,
    ]);
  }
}

/// 动态流。
final AsyncNotifierProvider<FeedNotifier, List<Post>> feedProvider =
    AsyncNotifierProvider<FeedNotifier, List<Post>>(FeedNotifier.new);
