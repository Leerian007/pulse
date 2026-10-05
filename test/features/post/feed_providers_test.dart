import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learning_flutter/core/riverpod/async_value_ext.dart';
import 'package:learning_flutter/features/post/data/repositories/mock_post_repository.dart';
import 'package:learning_flutter/features/post/domain/entities/author.dart';
import 'package:learning_flutter/features/post/domain/entities/post.dart';
import 'package:learning_flutter/features/post/domain/repositories/post_repository.dart';
import 'package:learning_flutter/features/post/presentation/providers/composer_providers.dart';
import 'package:learning_flutter/features/post/presentation/providers/feed_providers.dart';

/// `create` 永远失败的装饰器。
///
/// 用**装饰器**而不是从头实现一遍接口：只需要覆盖一个方法，
/// 其余行为仍然走真实实现 —— 于是"回滚"这条路径是在真实数据上验证的。
/// 顺便也证明了 `PostRepository` 这个接口确实可以整体替换。
class _CreateFailsRepository implements PostRepository {
  _CreateFailsRepository(this._inner);

  final PostRepository _inner;

  @override
  Author get currentAuthor => _inner.currentAuthor;

  @override
  Future<List<Post>> fetchFeed({int page = 0, int pageSize = 20}) =>
      _inner.fetchFeed(page: page, pageSize: pageSize);

  @override
  Future<Post> fetchById(String postId) => _inner.fetchById(postId);

  @override
  Future<Post> toggleLike(String postId) => _inner.toggleLike(postId);

  @override
  Future<Post> create({
    required String content,
    List<String> images = const <String>[],
    List<String> topics = const <String>[],
    String? coverEmoji,
  }) async {
    // 必须是 `Error` 的子类：Riverpod 对 `Exception` 会自动重试，
    // 而这里要的是"一次失败就回滚"。
    throw StateError('模拟服务端拒绝');
  }
}

/// 动态流状态层的测试。
///
/// 这一层是最容易"看起来对、实际错"的地方：乐观更新、回滚、占位替换
/// 三件事都只在几百毫秒的窗口里发生，肉眼看 UI 根本分辨不出
/// "真的乐观"和"其实在等网络"。所以必须把那个窗口用断言打开。
void main() {
  /// 延迟归零：把 500ms 的窗口压成一次微任务，测试才能稳定观察中间态。
  MockPostRepository buildRepo() => MockPostRepository(latency: Duration.zero);

  /// 注意：这里**不能**写 `<Override>[...]`。
  /// `flutter_riverpod` 的 `show` 白名单里没有导出 `Override` 这个类型名，
  /// 省略类型参数让 Dart 从参数类型反推即可。
  ProviderContainer buildContainer([PostRepository? repository]) {
    return ProviderContainer.test(
      overrides: [
        postRepositoryProvider
            .overrideWithValue(repository ?? buildRepo()),
      ],
    );
  }

  group('currentAuthorProvider', () {
    test('就是仓库里的当前用户', () {
      final ProviderContainer container = buildContainer();
      expect(container.read(currentAuthorProvider).id, 'u_me');
    });
  });

  group('suggestedTopicsProvider', () {
    test('从信息流的话题里归纳：去重、保序', () async {
      final ProviderContainer container = buildContainer();
      await container.read(feedProvider.future);

      final List<String> topics = container.read(suggestedTopicsProvider);

      expect(topics, isNotEmpty);
      expect(topics.toSet(), hasLength(topics.length), reason: '出现了重复话题');
      // p_001 的话题是 ['效率', '桌面']，所以它们排在最前面 ——
      // 顺序稳定对 UI 很重要（同一批话题不该每次打开面板都换位置）。
      expect(topics.take(2), <String>['效率', '桌面']);
    });

    test('不超过上限', () async {
      final ProviderContainer container = buildContainer();
      await container.read(feedProvider.future);

      expect(
        container.read(suggestedTopicsProvider).length,
        lessThanOrEqualTo(kMaxSuggestedTopics),
      );
    });
  });

  group('FeedNotifier.publish 的乐观更新', () {
    test('返回之前流里就已经有这条动态了（本地占位）', () async {
      final ProviderContainer container = buildContainer();
      await container.read(feedProvider.future);
      final int before = container.read(feedProvider).dataOrNull!.length;

      final Future<Post?> pending =
          container.read(feedProvider.notifier).publish(content: '刚写的');

      // ★ 关键断言：还没 await，列表长度就已经变了。
      // 这就是"手指落下时红字就该亮起"在状态层的样子。
      final List<Post> during = container.read(feedProvider).dataOrNull!;
      expect(during, hasLength(before + 1));
      expect(during.first.content, '刚写的');
      expect(during.first.author.id, 'u_me', reason: '占位条目也得有作者');
      expect(during.first.id, contains('_pending_'),
          reason: '本地占位必须能一眼认出来，否则回滚时会误删真实数据');

      final Post? created = await pending;
      expect(created, isNotNull);
    });

    test('成功后占位被权威实体替换（是替换不是追加）', () async {
      final ProviderContainer container = buildContainer();
      await container.read(feedProvider.future);
      final int before = container.read(feedProvider).dataOrNull!.length;

      final Post? created =
          await container.read(feedProvider.notifier).publish(content: '刚写的');

      final List<Post> after = container.read(feedProvider).dataOrNull!;
      expect(after, hasLength(before + 1), reason: '替换不该改变条数');
      expect(after.first.id, created!.id);
      expect(
        after.where((Post post) => post.id.contains('_pending_')),
        isEmpty,
        reason: '占位条目必须被清掉，否则会留下一条永远点不动的幽灵',
      );
      // 服务端那边也真的存下来了。
      final List<Post> server =
          await container.read(postRepositoryProvider).fetchFeed();
      expect(server.first.id, created.id);
    });

    test('占位条目上就已经带着配图和话题', () async {
      final ProviderContainer container = buildContainer();
      await container.read(feedProvider.future);

      final Future<Post?> pending = container
          .read(feedProvider.notifier)
          .publish(
            content: '带图带话题',
            images: const <String>['https://picsum.photos/seed/u/900/900'],
            topics: const <String>['咖啡'],
          );

      final Post during = container.read(feedProvider).dataOrNull!.first;
      expect(during.images, hasLength(1));
      expect(during.topics, <String>['咖啡']);

      final Post? created = await pending;
      expect(created!.images, hasLength(1));
      expect(created.topics, <String>['咖啡']);
    });

    test('失败时撤回占位条目，不留幽灵动态', () async {
      final ProviderContainer container =
          buildContainer(_CreateFailsRepository(buildRepo()));
      await container.read(feedProvider.future);
      final int before = container.read(feedProvider).dataOrNull!.length;

      final Future<Post?> pending = container
          .read(feedProvider.notifier)
          .publish(content: '会失败的动态');

      // 先确认它确实乐观上屏了（否则这条用例就只是在测"什么都没发生"）。
      expect(container.read(feedProvider).dataOrNull!.first.content, '会失败的动态');

      final Post? created = await pending;

      expect(created, isNull, reason: '失败要返回 null，让面板能提示用户');
      final List<Post> after = container.read(feedProvider).dataOrNull!;
      expect(after, hasLength(before));
      expect(
        after.any((Post post) => post.content == '会失败的动态'),
        isFalse,
        reason: '失败后不能留下一条发不出去的动态',
      );
    });

    test('连续两次发布的占位 id 不撞车', () async {
      final ProviderContainer container = buildContainer();
      await container.read(feedProvider.future);
      final FeedNotifier notifier = container.read(feedProvider.notifier);

      // 不 await 第一条就发第二条 —— 这正是"手快连点两次"的场景。
      final Future<Post?> first = notifier.publish(content: '第一条');
      final Future<Post?> second = notifier.publish(content: '第二条');

      final List<Post> during = container.read(feedProvider).dataOrNull!;
      final Set<String> pendingIds = during
          .where((Post post) => post.id.contains('_pending_'))
          .map((Post post) => post.id)
          .toSet();
      expect(pendingIds, hasLength(2), reason: '两条占位条目不能用同一个 id');

      await first;
      await second;

      final List<Post> after = container.read(feedProvider).dataOrNull!;
      expect(
        after.where((Post post) => post.id.contains('_pending_')),
        isEmpty,
      );
    });
  });
}
