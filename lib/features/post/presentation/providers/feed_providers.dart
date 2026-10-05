import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/riverpod/async_value_ext.dart';
import '../../data/repositories/mock_post_repository.dart';
import '../../domain/entities/author.dart';
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

/// 当前登录用户。
///
/// 转发自仓库的 `currentAuthor`，作用是让 UI 不必认识任何 data 层实现就能
/// 回答"我是谁"：发帖面板要显示"发到谁的主页"，乐观发布要拼出一条带作者的
/// 本地 `Post`。
///
/// 注意它不是 `AsyncValue` —— 会话信息在真实后端里也是本地缓存的，
/// 不该为"我是谁"再走一次网络（理由见 `PostRepository.currentAuthor`）。
final Provider<Author> currentAuthorProvider = Provider<Author>(
  (ref) => ref.watch(postRepositoryProvider).currentAuthor,
);

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

  /// 本地占位条目的序号。
  ///
  /// 必须**每个 Notifier 实例一份**，而不是全局自增：全局计数器会让测试之间
  /// 互相影响（同一个用例第二次跑拿到不同的 id，断言就没法写了）。
  int _localSeq = 0;

  /// 生成一个本地占位 id。
  ///
  /// 刻意带上 `_local_` 与 `_pending_` 两个片段：
  ///  - `_local_` 与 `MockDataService.localId` 的约定一致，表示"还没落库"；
  ///  - `_pending_` 更进一步，表示"连服务端都还没确认"，方便在日志里区分
  ///    "乐观插入的幽灵条目"和"已经拿到 id 的真实条目"。
  String _nextPlaceholderId() => 'p_local_pending_${++_localSeq}';

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
  ///
  /// ## 为什么这里可以乐观，而评论那边不行
  ///
  /// 乐观更新需要一个**完整的实体**，而 `Post` 必须带 `author`。
  /// 作者身份属于数据层（"我是谁"来自会话，UI 自己拼不出来），所以这里只能从
  /// [PostRepository.currentAuthor] 取。评论那边没有这个入口，于是只能等 ——
  /// 两边策略不一致的原因就是这一条，不是随手取舍。
  ///
  /// ## 三步走的顺序很重要
  ///
  /// 1. **先插一条本地占位**（id 里带 `_pending_`）：用户按下"发布"的瞬间，
  ///    流里就已经有这条动态了。面板随后关闭，露出来的就是它。
  /// 2. 再用服务端返回的**权威实体替换**占位条目 —— 拿到真正的 id 与时间。
  /// 3. 失败则**撤回**占位条目，返回 `null`，由面板提示用户重试。
  ///
  /// 为什么敢在第 1 步就上屏：这条动态的内容完全由本地决定，没有任何
  /// "服务端才知道"的信息需要等待。这也是点赞能乐观的同一个理由。
  Future<Post?> publish({
    required String content,
    List<String> images = const <String>[],
    List<String> topics = const <String>[],
    String? coverEmoji,
  }) async {
    final List<Post>? snapshot = _current;
    // 列表还没加载出来时不做乐观插入 —— 没有"队首"可以插，而且
    // 把一个错误态/加载态直接翻成"只有一条动态的数据态"是错的。
    final String? placeholderId = snapshot == null ? null : _nextPlaceholderId();

    if (snapshot != null) {
      final Post placeholder = Post(
        id: placeholderId!,
        author: ref.read(postRepositoryProvider).currentAuthor,
        content: content,
        createdAt: DateTime.now(),
        images: List<String>.unmodifiable(images),
        topics: List<String>.unmodifiable(topics),
        coverEmoji: coverEmoji,
      );
      state = AsyncData<List<Post>>(
        List<Post>.unmodifiable(<Post>[placeholder, ...snapshot]),
      );
    }

    try {
      final Post created = await ref.read(postRepositoryProvider).create(
            content: content,
            images: images,
            topics: topics,
            coverEmoji: coverEmoji,
          );

      if (!ref.mounted) {
        return created;
      }

      if (placeholderId != null) {
        // 把占位换成权威实体，并挪回队首 —— 与服务端一致
        // （`MockPostRepository.create` 也是插在 0）。
        final List<Post> latest = _current ?? const <Post>[];
        state = AsyncData<List<Post>>(
          List<Post>.unmodifiable(<Post>[
            created,
            ...latest.where((Post post) => post.id != placeholderId),
          ]),
        );
      }
      return created;
    } catch (_) {
      if (ref.mounted && placeholderId != null) {
        // 撤回占位条目。用户看到"自己刚发的那条"消失，配合面板上的错误提示，
        // 语义是自洽的（而不是留一条永远发不出去的幽灵动态）。
        final List<Post> latest = _current ?? const <Post>[];
        state = AsyncData<List<Post>>(
          List<Post>.unmodifiable(<Post>[
            ...latest.where((Post post) => post.id != placeholderId),
          ]),
        );
      }
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
