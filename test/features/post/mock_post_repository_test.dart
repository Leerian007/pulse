import 'package:flutter_test/flutter_test.dart';
import 'package:learning_flutter/features/post/data/repositories/mock_post_repository.dart';

/// Mock 仓库的行为测试。
///
/// 这些断言的价值不只是"测 Mock"：它们把**契约**固定了下来。
/// 将来写 `HttpPostRepository` 时，把下面的构造换成 HTTP 实现、
/// 断言原样复用，就能确认真实实现没有偏离设计。
void main() {
  /// 测试里把延迟归零，避免每个用例白等 500ms。
  MockPostRepository buildRepo() => MockPostRepository(latency: Duration.zero);

  group('MockPostRepository.fetchFeed', () {
    test('返回种子数据', () async {
      final repo = buildRepo();
      final posts = await repo.fetchFeed();

      expect(posts, hasLength(12));
      expect(posts.first.id, 'p_001');
      expect(posts.first.author.name, '林深');
    });

    test('分页按 pageSize 切片', () async {
      final repo = buildRepo();
      final firstPage = await repo.fetchFeed(page: 0, pageSize: 5);
      final secondPage = await repo.fetchFeed(page: 1, pageSize: 5);

      expect(firstPage, hasLength(5));
      expect(secondPage, hasLength(5));
      // 两页不重叠。
      expect(
        firstPage.map((p) => p.id).toSet().intersection(
              secondPage.map((p) => p.id).toSet(),
            ),
        isEmpty,
      );
    });

    test('越界分页返回空列表而不是抛错', () async {
      final repo = buildRepo();
      expect(await repo.fetchFeed(page: 99, pageSize: 20), isEmpty);
    });

    test('返回的列表不可变', () async {
      final repo = buildRepo();
      final posts = await repo.fetchFeed();
      expect(() => posts.add(posts.first), throwsUnsupportedError);
    });
  });

  group('MockPostRepository.toggleLike', () {
    test('翻转点赞状态并同步计数', () async {
      final repo = buildRepo();
      final before = await repo.fetchById('p_001');
      expect(before.likedByMe, isFalse);

      final after = await repo.toggleLike('p_001');
      expect(after.likedByMe, isTrue);
      expect(after.likeCount, before.likeCount + 1);
    });

    test('状态被"服务端"记住：重新拉取依然是翻转后的值', () async {
      final repo = buildRepo();
      final before = await repo.fetchById('p_002');

      final toggled = await repo.toggleLike('p_002');

      // 契约：翻转结果会被写回"服务端"，重新拉取拿到的是同一份状态，
      // 而不是回到种子数据。
      //
      // 这里刻意**不假设** p_002 的初始 likedByMe —— 种子数据里"已点赞"的
      // 条目是给 UI 展示实心心形用的，调整它们不应该让这条用例失效。
      final refetched = await repo.fetchById('p_002');
      expect(refetched.likedByMe, !before.likedByMe);
      expect(refetched, toggled);
    });

    test('未知 id 抛出 StateError', () async {
      final repo = buildRepo();
      await expectLater(repo.toggleLike('p_not_exist'), throwsStateError);
    });
  });

  group('MockPostRepository.create', () {
    test('新动态插到队首，且带上服务端生成的 id', () async {
      final repo = buildRepo();
      final created = await repo.create(content: '一条测试动态');

      expect(created.id, isNotEmpty);
      expect(created.author.id, 'u_me');

      final feed = await repo.fetchFeed();
      expect(feed, hasLength(13));
      expect(feed.first.id, created.id);
    });
  });

  group('每个实例状态独立', () {
    test('一个实例的点赞不会影响另一个实例', () async {
      final a = buildRepo();
      final b = buildRepo();

      await a.toggleLike('p_001');

      expect((await b.fetchById('p_001')).likedByMe, isFalse);
    });
  });
}
